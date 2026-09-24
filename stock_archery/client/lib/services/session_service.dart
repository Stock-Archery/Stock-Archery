import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing active session tokens (session IDs)
/// locally (SharedPreferences) and remotely (Firebase Realtime Database).
class SessionService {
  StreamSubscription<DatabaseEvent>? _sessionSubscription;

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
  /// saves it locally, and updates it in Firebase Realtime Database.
  /// 
  /// This is called during explicit user login or user registration.
  Future<String?> saveNewSession(String uid) async {
    final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('================ [SessionService] GENERATING NEW SESSION ================');
    debugPrint('User UID: $uid');
    debugPrint('New Session ID: $newSessionId');

    // 1. Save locally to device SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('my_local_session', newSessionId);
      debugPrint('[SessionService] Saved session ID locally in SharedPreferences.');
    } catch (e) {
      debugPrint('[SessionService] ❌ Error saving session ID locally: $e');
    }

    // 2. Save remotely to Firebase Realtime Database
    if (_isFirebaseAvailable) {
      try {
        final ref = FirebaseDatabase.instance.ref("active_sessions/$uid");
        await ref.set({
          "device_id": newSessionId,
          "last_updated": ServerValue.timestamp,
        });
        debugPrint('[SessionService] Registered session ID successfully in Firebase RTDB.');
      } catch (e) {
        debugPrint('[SessionService] ❌ Error writing session ID to Firebase RTDB: $e');
      }
    } else {
      debugPrint('[SessionService] ⚠️ Firebase not available. Skipping Realtime Database write.');
    }
    
    debugPrint('========================================================================');
    return newSessionId;
  }

  /// Initial check to compare local session with database session.
  /// Registers a real-time listener if they match.
  /// Triggers [onKickOut] if there is a mismatch.
  Future<void> checkAndListenToSession(String uid, VoidCallback onKickOut) async {
    // Prevent duplicate listeners
    await cancelListener();

    if (!_isFirebaseAvailable) {
      debugPrint('[SessionService] ⚠️ Firebase unavailable. Bypassing session listener.');
      return;
    }

    debugPrint('================ [SessionService] STARTING SESSION MONITORING ================');
    debugPrint('Monitoring UID: $uid');

    try {
      final prefs = await SharedPreferences.getInstance();
      final localSessionId = prefs.getString('my_local_session');
      debugPrint('[SessionService] Local Session ID: $localSessionId');

      final ref = FirebaseDatabase.instance.ref("active_sessions/$uid");
      
      // Perform initial check on startup / resume
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final databaseSessionId = data['device_id']?.toString();
        debugPrint('[SessionService] Remote DB Session ID: $databaseSessionId');

        // Check if there is a mismatch (meaning another device logged in while this app was closed)
        if (localSessionId != null && databaseSessionId != null && databaseSessionId != localSessionId) {
          debugPrint('[SessionService] 🚨 STARTUP MISMATCH: Account active on another device! Initiating kick-out.');
          onKickOut();
          return;
        }
      } else {
        debugPrint('[SessionService] No session found in DB. First device login or DB empty.');
      }

      // Start Realtime Database listener to catch session invalidations in real-time
      debugPrint('[SessionService] Registering active listener to Firebase path: active_sessions/$uid');
      _sessionSubscription = ref.onValue.listen((DatabaseEvent event) async {
        if (event.snapshot.value != null) {
          final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          final databaseSessionId = data['device_id']?.toString();
          
          // Fetch local session ID again in case it was updated on this device
          final currentLocalSession = prefs.getString('my_local_session');

          debugPrint('[SessionService] RTDB Update - DB Session: $databaseSessionId, Local Session: $currentLocalSession');

          if (databaseSessionId != null && currentLocalSession != null && databaseSessionId != currentLocalSession) {
            debugPrint('[SessionService] 🚨 REALTIME MISMATCH: Session ID changed remotely. Initiating kick-out.');
            onKickOut();
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

  /// Retrieve local session ID
  Future<String?> getLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('my_local_session');
    } catch (e) {
      debugPrint('[SessionService] ❌ Error reading local session: $e');
      return null;
    }
  }

  /// Remove local session ID (used on user logouts)
  Future<void> clearLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('my_local_session');
      debugPrint('[SessionService] Local session cleared from SharedPreferences.');
    } catch (e) {
      debugPrint('[SessionService] ❌ Error clearing local session: $e');
    }
  }

  /// Cancel RTDB session subscription
  Future<void> cancelListener() async {
    if (_sessionSubscription != null) {
      await _sessionSubscription!.cancel();
      _sessionSubscription = null;
      debugPrint('[SessionService] RTDB listener subscription successfully cancelled.');
    }
  }
}
