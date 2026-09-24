import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing active session tokens (session IDs)
/// locally (in-memory + SharedPreferences) and remotely (Firebase Realtime Database).
class SessionService {
  StreamSubscription<DatabaseEvent>? _sessionSubscription;

  /// In-memory cache of the currently active session ID for instantaneous reads
  /// without waiting for asynchronous SharedPreferences disk I/O.
  String? _currentLocalSessionId;

  /// Mutex/Lock flag indicating an active login or session generation is in progress.
  /// Prevents any race condition where an auth state change listener executes
  /// startup/stream checks before the new session is fully written.
  bool _isRegisteringSession = false;

  /// Currently monitored Firebase UID to prevent duplicate listener setup
  String? _currentMonitoredUid;

  /// Helper to check if Firebase is initialized.
  /// Bypasses database operations if Firebase is not configured (mock mode).
  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Generates a new session ID based on current timestamp,
  /// saves it locally (memory + SharedPreferences), and updates it in Firebase Realtime Database.
  /// 
  /// This is called during explicit user login or user registration.
  Future<String?> saveNewSession(String uid) async {
    final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _isRegisteringSession = true;
    _currentLocalSessionId = newSessionId;

    debugPrint('================ [SessionService] GENERATING NEW SESSION ================');
    debugPrint('User UID: $uid');
    debugPrint('New Session ID: $newSessionId');

    // 1. Save locally to device SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('my_local_session', newSessionId);
      debugPrint('[SessionService] ✓ Saved session ID locally in SharedPreferences.');
    } catch (e) {
      debugPrint('[SessionService] ❌ Error saving session ID locally: $e');
    }

    // 2. Save remotely to Firebase Realtime Database
    if (_isFirebaseAvailable) {
      final ref = FirebaseDatabase.instance.ref("active_sessions/$uid");
      const maxAttempts = 3;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          await ref.set({
            "device_id": newSessionId,
            "last_updated": ServerValue.timestamp,
          });
          debugPrint('[SessionService] ✓ Registered session ID successfully in Firebase RTDB.');
          break;
        } catch (e) {
          debugPrint('[SessionService] ❌ Error writing session ID to Firebase RTDB (attempt $attempt/$maxAttempts): $e');
          if (attempt == maxAttempts) {
            debugPrint('[SessionService] ⚠️ RTDB write reached max attempts.');
          } else {
            await Future.delayed(Duration(milliseconds: 300 * attempt));
          }
        }
      }
    } else {
      debugPrint('[SessionService] ⚠️ Firebase not available. Skipping Realtime Database write.');
    }
    
    // Unlock after write finishes
    _isRegisteringSession = false;
    debugPrint('========================================================================');
    return newSessionId;
  }

  /// Initial check to compare local session with database session.
  /// Registers a real-time listener if they match.
  /// Triggers [onKickOut] if there is a verified remote mismatch.
  Future<void> checkAndListenToSession(String uid, VoidCallback onKickOut) async {
    // If we are currently in the middle of generating/saving a new session, skip check to prevent race condition
    if (_isRegisteringSession) {
      debugPrint('[SessionService] Active session registration in progress. Skipping premature kick-out check.');
      return;
    }

    // If already monitoring this exact user and listener is active, avoid teardown-recreation churn
    if (_currentMonitoredUid == uid && _sessionSubscription != null) {
      debugPrint('[SessionService] Session monitor already active for UID: $uid');
      return;
    }

    // Cancel any previous user's subscription
    await cancelListener();
    _currentMonitoredUid = uid;

    if (!_isFirebaseAvailable) {
      debugPrint('[SessionService] ⚠️ Firebase unavailable. Bypassing session listener.');
      return;
    }

    debugPrint('================ [SessionService] STARTING SESSION MONITORING ================');
    debugPrint('Monitoring UID: $uid');

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Read local session ID from memory cache first, then SharedPreferences
      var localSessionId = _currentLocalSessionId ?? prefs.getString('my_local_session');
      if (localSessionId != null) {
        _currentLocalSessionId = localSessionId;
      }
      debugPrint('[SessionService] Initial Local Session ID: $localSessionId');

      final ref = FirebaseDatabase.instance.ref("active_sessions/$uid");
      
      // Perform initial check on startup / resume
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final databaseSessionId = data['device_id']?.toString();
        debugPrint('[SessionService] Remote DB Session ID: $databaseSessionId');

        // Check if there is a mismatch (meaning another device logged in while this app was closed)
        if (localSessionId != null && databaseSessionId != null && databaseSessionId != localSessionId) {
          // Verify we aren't currently in the middle of registering a new session on this device
          if (!_isRegisteringSession && _currentLocalSessionId != databaseSessionId) {
            debugPrint('[SessionService] 🚨 STARTUP MISMATCH: Account active on another device! Initiating kick-out.');
            onKickOut();
            return;
          }
        }
      } else {
        debugPrint('[SessionService] No session found in DB. First device login or DB empty.');
      }

      // Start Realtime Database listener to catch session invalidations in real-time
      debugPrint('[SessionService] Registering active listener to Firebase path: active_sessions/$uid');
      _sessionSubscription = ref.onValue.listen((DatabaseEvent event) async {
        if (_isRegisteringSession) {
          return; // Ignore updates caused by our own local login in progress
        }

        if (event.snapshot.value != null) {
          final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          final databaseSessionId = data['device_id']?.toString();
          
          final currentLocalSession = _currentLocalSessionId ?? prefs.getString('my_local_session');

          debugPrint('[SessionService] RTDB Update - DB Session: $databaseSessionId, Local Session: $currentLocalSession');

          if (databaseSessionId != null && currentLocalSession != null && databaseSessionId != currentLocalSession) {
            if (!_isRegisteringSession) {
              debugPrint('[SessionService] 🚨 REALTIME MISMATCH: Session ID changed remotely. Initiating kick-out.');
              onKickOut();
            }
          }
        }
      }, onError: (error) {
        debugPrint('[SessionService] ❌ Error in Realtime Database listener: $error');
      });
    } catch (e) {
      debugPrint('[SessionService] ❌ Failed to initialize session monitoring: $e');
    }
    debugPrint('=============================================================================');
  }

  /// Retrieve local session ID (from memory cache or SharedPreferences)
  Future<String?> getLocalSession() async {
    if (_currentLocalSessionId != null) return _currentLocalSessionId;
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLocalSessionId = prefs.getString('my_local_session');
      return _currentLocalSessionId;
    } catch (e) {
      debugPrint('[SessionService] ❌ Error reading local session: $e');
      return null;
    }
  }

  /// Remove local session ID (used on user logouts)
  Future<void> clearLocalSession() async {
    _currentLocalSessionId = null;
    _currentMonitoredUid = null;
    _isRegisteringSession = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('my_local_session');
      debugPrint('[SessionService] Local session cleared from memory and SharedPreferences.');
    } catch (e) {
      debugPrint('[SessionService] ❌ Error clearing local session: $e');
    }
  }

  /// Cancel RTDB session subscription
  Future<void> cancelListener() async {
    _currentMonitoredUid = null;
    if (_sessionSubscription != null) {
      await _sessionSubscription!.cancel();
      _sessionSubscription = null;
      debugPrint('[SessionService] RTDB listener subscription successfully cancelled.');
    }
  }
}
