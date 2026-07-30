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
import 'session_provider.dart';

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

  AuthViewModel(this._authService, this._ref) : super(AuthState(isInitializing: true)) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    if (_authService.isFirebaseAvailable) {
      _authService.authStateChanges.listen((firebaseUser) async {
        if (firebaseUser == null) {
          _cancelAlertsSubscription(); // Cancel listener on logout
          state = AuthState(user: null, isInitializing: false);
        } else {
          // If a firebase session already exists, sync with backend to get MongoDB profile
          try {
            state = state.copyWith(isLoading: true, clearError: true);
            final idToken = await firebaseUser.getIdToken() ?? '';

            // Print the ID Token so you can use it in Postman
            debugPrint(
              '\n================ FIREBASE ID TOKEN (BEARER TOKEN) ================',
            );
            debugPrint(idToken);
            debugPrint(
              '==================================================================\n',
            );

            // Sync with backend using current token
            final response = await _authService.syncProfile(idToken);

            state = AuthState(user: response, isLoading: false, isInitializing: false);

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
            state = AuthState(
              user: null,
              isLoading: false,
              isInitializing: false,
              errorMessage: "Failed to sync profile: ${e.toString()}",
            );
          }
        }
      });
    } else {
      state = state.copyWith(isInitializing: false);
    }
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

    // Clear local session ID from shared preferences
    await _ref.read(sessionServiceProvider).clearLocalSession();

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
