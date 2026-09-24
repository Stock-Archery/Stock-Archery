import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/app_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_provider.dart';
import 'chat_viewmodel.dart';

// Provider for raw AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  // Centralized Environment Base URL Setup
  return AuthService(baseUrl: AppConfig.baseUrl);
});

// State class for Auth State
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isKickedOut;
  final bool isInitializing;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isKickedOut = false,
    this.isInitializing = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? isKickedOut,
    bool? isInitializing,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isKickedOut: isKickedOut ?? this.isKickedOut,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;
  StreamSubscription<DatabaseEvent>? _alertsSubscription; // Subscription for real-time alert updates

  /// Tracks whether a genuine logout/forceLogout has been called in this session.
  /// This is the ONLY way user: null should be set — never from a stale stream event.
  bool _logoutWasExplicit = false;

  AuthViewModel(this._authService, this._ref) : super(AuthState(isInitializing: true)) {
    _initAuth();
  }

  /// TWO-LAYER AUTH INITIALIZATION:
  /// Layer 1: Load cached UserModel from disk IMMEDIATELY → instant logged-in UI.
  /// Layer 2: Set up Firebase Auth stream for validation/sync in the background.
  ///
  /// WHY: On some Android 13+ devices (e.g. Moto G73 5G), Firebase Auth's
  /// authStateChanges stream fires null FIRST on cold start (before the native
  /// SDK finishes reading its persisted token from encrypted storage), then fires
  /// the real user a moment later. If we rely solely on that stream, the first
  /// null event nukes the user to LoginView — causing the "silent logout on tab
  /// removal" bug. The cached profile protects against this race.
  Future<void> _initAuth() async {
    if (!_authService.isFirebaseAvailable) {
      state = state.copyWith(isInitializing: false);
      return;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // LAYER 1: Load cached profile from SharedPreferences (instant, no network)
    // ──────────────────────────────────────────────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_user_profile');
      if (cachedJson != null) {
        final cachedUser = UserModel.fromJson(jsonDecode(cachedJson));
        // Set user immediately so AuthWrapper shows MainScreen, not LoginView
        state = AuthState(user: cachedUser, isInitializing: false);
        debugPrint('[AuthViewModel] ✓ Layer 1: Cached user loaded instantly → ${cachedUser.email}');
      }
    } catch (e) {
      debugPrint('[AuthViewModel] ⚠️ Layer 1: Cache read error (non-fatal): $e');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // LAYER 2: Firebase Auth stream for ongoing validation and profile sync
    // ──────────────────────────────────────────────────────────────────────────
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        // ────────────────────────────────────────────────────────────────────
        // Firebase Auth says: "no user signed in"
        //
        // This can happen for TWO reasons:
        //   A) GENUINE LOGOUT: logout() or forceLogout() was called in this session.
        //      In that case, _logoutWasExplicit == true AND cached_user_profile
        //      has ALREADY been deleted by logout/forceLogout.
        //   B) DEVICE BUG / COLD START RACE: On Android 13+ devices, the stream
        //      fires null before the native SDK finishes reading persisted auth from
        //      encrypted storage. The user IS logged in, but the stream doesn't know yet.
        //
        // We distinguish A from B by checking _logoutWasExplicit and the cache.
        // ────────────────────────────────────────────────────────────────────

        if (_logoutWasExplicit) {
          // Case A: Genuine logout — cache was already cleared by logout/forceLogout.
          _cancelAlertsSubscription();
          _resetChatState();
          _logoutWasExplicit = false; // Reset the flag
          state = AuthState(user: null, isInitializing: false);
          debugPrint('[AuthViewModel] ✓ Genuine logout confirmed via stream.');
          return;
        }

        // Case B check: Is there still a cached profile?
        try {
          final prefs = await SharedPreferences.getInstance();
          final hasCachedProfile = prefs.getString('cached_user_profile') != null;

          if (hasCachedProfile) {
            // Cache exists but Firebase Auth says null. This is the cold-start race condition.
            // Do NOT wipe the user. Keep the cached user active.
            debugPrint('[AuthViewModel] ⚠️ Firebase Auth fired null but cached profile exists → cold-start race. Preserving session.');
            state = state.copyWith(isInitializing: false);
            return;
          }
        } catch (_) {}

        // No cache AND no explicit logout → first launch or cleared data. Show login.
        _cancelAlertsSubscription();
        _resetChatState();
        state = AuthState(user: null, isInitializing: false);
        debugPrint('[AuthViewModel] ℹ️ No cached profile, no explicit logout. Showing login screen.');

      } else {
        // ────────────────────────────────────────────────────────────────────
        // Firebase Auth says: "user is signed in" → sync profile in background
        // ────────────────────────────────────────────────────────────────────
        try {
          // If user was already loaded from cache (Layer 1), just sync in background.
          // If not yet loaded, set a fallback user so UI shows MainScreen.
          if (state.user == null) {
            state = state.copyWith(
              user: UserModel(
                firebaseUid: firebaseUser.uid,
                name: firebaseUser.displayName ?? '',
                email: firebaseUser.email ?? '',
                phoneNumber: firebaseUser.phoneNumber ?? '',
                state: '',
                isPremium: false,
              ),
              isInitializing: false,
            );
          }

          final idToken = await firebaseUser.getIdToken() ?? '';

          // Print the ID Token for debugging
          debugPrint(
            '\n================ FIREBASE ID TOKEN (BEARER TOKEN) ================',
          );
          debugPrint(idToken);
          debugPrint(
            '==================================================================\n',
          );

          // Sync with backend using current token (non-fatal on failure)
          try {
            final response = await _authService.syncProfile(idToken);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_user_profile', jsonEncode(response.toJson()));
            state = AuthState(user: response, isLoading: false, isInitializing: false);
          } catch (syncError) {
            debugPrint('[AuthViewModel] ⚠️ Backend profile sync warning (offline or server waking up): $syncError');
            // User is authenticated in Firebase Auth. Keep session active with cached/fallback user.
            state = state.copyWith(isLoading: false, isInitializing: false);
          }

          // Start listening to real-time premium updates from Firebase Realtime Database
          _listenToAlertAccessChanges(firebaseUser.uid);

          // Register FCM token now that user is synced
          try {
            final token = await FirebaseMessaging.instance.getToken();
            if (token != null) {
              // Subscribe to global topic for broadcast notifications
              await FirebaseMessaging.instance.subscribeToTopic('all_users');
              debugPrint('Subscribed to all_users topic.');

              final deviceInfo = DeviceInfoPlugin();
              String deviceId = 'unknown_device';
              String platform = 'unknown';

              if (Platform.isAndroid) {
                final info = await deviceInfo.androidInfo;
                deviceId = info.id;
                platform = 'android';
              } else if (Platform.isIOS) {
                final info = await deviceInfo.iosInfo;
                deviceId = info.identifierForVendor ?? 'unknown_ios';
                platform = 'ios';
              }

              final apiUrl = AppConfig.baseUrl;
              await http.post(
                Uri.parse('$apiUrl/user/device/register'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $idToken',
                },
                body: jsonEncode({
                  'token': token,
                  'deviceId': deviceId,
                  'platform': platform,
                }),
              );
              debugPrint('Registered FCM token post-sync.');
            }
          } catch (e) {
            debugPrint('Post-sync token registration failed: $e');
          }
        } catch (e) {
          debugPrint('[AuthViewModel] ❌ Error in auth state handler: $e');
          // Keep existing user (from cache) — don't nuke to null.
          state = state.copyWith(
            isLoading: false,
            isInitializing: false,
          );
        }
      }
    });
  }

  /// Request SMS OTP for a phone number
  Future<String?> sendOtp(String phoneNumber) async {
    debugPrint('[log] [AuthViewModel] sendOtp called for: $phoneNumber');
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final otp = await _authService.sendOtp(phoneNumber);
      debugPrint('[log] [AuthViewModel] sendOtp success');
      state = state.copyWith(isLoading: false);
      return otp;
    } catch (e) {
      debugPrint('[log] [AuthViewModel] sendOtp failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return null;
    }
  }

  /// Verify OTP only (for signup phone verification)
  Future<bool> verifyOtpOnly(String phoneNumber, String otp) async {
    debugPrint('[log] [AuthViewModel] verifyOtpOnly called for: $phoneNumber');
    try {
      await _authService.verifyOtpOnly(phoneNumber, otp);
      debugPrint('[log] [AuthViewModel] verifyOtpOnly success');
      return true;
    } catch (e) {
      debugPrint('[log] [AuthViewModel] verifyOtpOnly failed: $e');
      return false;
    }
  }

  /// Verify OTP and login with existing account
  Future<bool> loginWithOtp(String phoneNumber, String otp) async {
    debugPrint('[log] [AuthViewModel] loginWithOtp called for: $phoneNumber');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.loginWithOtp(phoneNumber, otp);

      debugPrint('[log] [AuthViewModel] loginWithOtp success, registering session...');
      await _ref.read(sessionServiceProvider).saveNewSession(user.firebaseUid);

      // Register FCM token
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseMessaging.instance.subscribeToTopic('all_users');
          debugPrint('[log] [AuthViewModel] Subscribed to all_users topic.');

          final deviceInfo = DeviceInfoPlugin();
          String deviceId = 'unknown_device';
          String platform = 'unknown';

          if (Platform.isAndroid) {
            final info = await deviceInfo.androidInfo;
            deviceId = info.id;
            platform = 'android';
          } else if (Platform.isIOS) {
            final info = await deviceInfo.iosInfo;
            deviceId = info.identifierForVendor ?? 'unknown_ios';
            platform = 'ios';
          }

          final apiUrl = AppConfig.baseUrl;
          final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (idToken != null) {
            await http.post(
              Uri.parse('$apiUrl/user/device/register'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
              body: jsonEncode({
                'token': token,
                'deviceId': deviceId,
                'platform': platform,
              }),
            );
            debugPrint('[log] [AuthViewModel] FCM token registered.');
          }
        }
      } catch (e) {
        debugPrint('[log] [AuthViewModel] FCM registration failed: $e');
      }

      // Save profile to local storage for cold-start resilience
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_profile', jsonEncode(user.toJson()));
      } catch (_) {}

      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      debugPrint('[log] [AuthViewModel] loginWithOtp failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  /// Signup a new user account
  Future<bool> signUp({
    required String name,
    required String email,
    required String phoneNumber,
    required String userState,
    required String password,
    String? occupation,
    String? tradingExperience,
    String? gender,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('[AuthViewModel] Initiating user registration for: $email');
      final user = await _authService.signUp(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        state: userState,
        password: password,
        occupation: occupation,
        tradingExperience: tradingExperience,
        gender: gender,
      );

      // Save a new session ID for this newly registered user
      debugPrint(
        '[AuthViewModel] Registration successful. Registering active session ID.',
      );
      await _ref.read(sessionServiceProvider).saveNewSession(user.firebaseUid);

      // Save profile to local storage for cold-start resilience
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_profile', jsonEncode(user.toJson()));
      } catch (_) {}

      //revenue cat me user registered
      await Purchases.logIn(user.firebaseUid);

      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      debugPrint('[AuthViewModel] ❌ Registration failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  /// Signin to existing user account
  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('[AuthViewModel] Initiating user login for: $email');
      final user = await _authService.login(email: email, password: password);

      // Save a new session ID for this newly logged-in user
      debugPrint(
        '[AuthViewModel] Login successful. Registering active session ID.',
      );
      await _ref.read(sessionServiceProvider).saveNewSession(user.firebaseUid);

      // Save profile to local storage for cold-start resilience
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_profile', jsonEncode(user.toJson()));
      } catch (_) {}

      //revenue cat me register ho gya user
      await Purchases.logIn(user.firebaseUid);

      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      debugPrint('[AuthViewModel] ❌ Login failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  /// Log out current session manually
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    debugPrint('[AuthViewModel] Executing manual logout.');

    _cancelAlertsSubscription(); // Cancel real-time subscription on logout
    _resetChatState(); // Don't leak this account's chat history into the next login

    // Clear local session ID and cached profile from shared preferences
    await _ref.read(sessionServiceProvider).clearLocalSession();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_profile');
    } catch (_) {}

    // Mark as explicit logout BEFORE signOut so the authStateChanges null handler
    // knows this is a genuine logout (not a cold-start device race).
    _logoutWasExplicit = true;
    await _authService.logout();

    //revenue cat se logout
    await Purchases.logOut();

    state = AuthState(user: null);
  }

  /// Force logout current session when duplicate login detected
  Future<void> forceLogout() async {
    state = state.copyWith(isLoading: true);
    debugPrint(
      '[AuthViewModel] 🚨 Executing force logout due to duplicate active session.',
    );
    _cancelAlertsSubscription(); // Cancel real-time subscription on logout
    _resetChatState(); // Don't leak this account's chat history into the next login
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_profile');
    } catch (_) {}

    // Mark as explicit logout BEFORE signOut so the authStateChanges null handler
    // knows this is a genuine logout (not a cold-start device race).
    _logoutWasExplicit = true;
    await _authService.logout();

    //revenue cat se logout
    await Purchases.logOut();

    // Set user to null and mark isKickedOut to true so LoginView can trigger toast
    state = AuthState(user: null, isKickedOut: true);
  }

  /// Reset the kicked out flag
  void clearKickedOut() {
    debugPrint('[AuthViewModel] Clearing kicked out flag from AuthState.');
    state = state.copyWith(isKickedOut: false);
  }

  /// Clear active error banner
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Explicit sync with backend database to pull latest user profile values
  Future<void> syncProfile() async {
    // Check if Firebase is available and there is a currently authenticated Firebase user
    if (_authService.isFirebaseAvailable && FirebaseAuth.instance.currentUser != null) {
      try {
        final idToken = await FirebaseAuth.instance.currentUser!.getIdToken() ?? '';
        final response = await _authService.syncProfile(idToken);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_user_profile', jsonEncode(response.toJson()));
        } catch (_) {}
        state = state.copyWith(user: response);
      } catch (e) {
        debugPrint('[AuthViewModel] Manual sync failed: $e');
      }
    }
  }

  // Register real-time database listener for subscription flags
  void _listenToAlertAccessChanges(String uid) {
    _cancelAlertsSubscription();
    try {
      final ref = FirebaseDatabase.instance.ref("user_alerts/$uid");
      debugPrint('[AuthViewModel] Registering RTDB listener to Firebase path: user_alerts/$uid');
      _alertsSubscription = ref.onValue.listen((DatabaseEvent event) {
        if (event.snapshot.value != null && state.user != null) {
          final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          final isSOB = data['isSOB_alert_premium'] ?? false;
          final isXaud = data['isXaud_alert_premium'] ?? false;
          final isCrypto = data['isCrypto_alert_premium'] ?? false;
          
          debugPrint('[AuthViewModel] RTDB Alert Access updated: SOB=$isSOB, XAUD=$isXaud, Crypto=$isCrypto');
          
          state = state.copyWith(
            user: state.user!.copyWith(
              isSOBAlertPremium: isSOB,
              isXaudAlertPremium: isXaud,
              isCryptoAlertPremium: isCrypto,
            ),
          );
        }
      }, onError: (err) {
        debugPrint('[AuthViewModel] ❌ Error in alert access RTDB listener: $err');
      });
    } catch (e) {
      debugPrint('[AuthViewModel] ❌ Failed to start alert access listener: $e');
    }
  }

  // Chat/chart message history lives in global providers (chatProvider,
  // chartProvider) that are never scoped to the logged-in user. Without this,
  // the previous account's AI chat messages stay visible after switching
  // accounts in the same app session.
  void _resetChatState() {
    _ref.invalidate(chatProvider);
    _ref.invalidate(chartProvider);
  }

  // Safely dispose of Realtime Database listener
  void _cancelAlertsSubscription() {
    if (_alertsSubscription != null) {
      _alertsSubscription!.cancel();
      _alertsSubscription = null;
      debugPrint('[AuthViewModel] Alert access listener subscription cancelled.');
    }
  }
}

// Global Provider for Auth state and operations
final authProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthViewModel(service, ref);
});
