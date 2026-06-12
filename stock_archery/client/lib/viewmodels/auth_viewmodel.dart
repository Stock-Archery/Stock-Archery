import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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

  AuthState({this.user, this.isLoading = false, this.errorMessage});

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthViewModel(this._authService) : super(AuthState()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    if (_authService.isFirebaseAvailable) {
      _authService.authStateChanges.listen((firebaseUser) async {
        if (firebaseUser == null) {
          state = AuthState(user: null);
        } else {
          // If a firebase session already exists, sync with backend to get MongoDB profile
          try {
            state = state.copyWith(isLoading: true, clearError: true);
            final idToken = await firebaseUser.getIdToken() ?? '';
            
            // Print the ID Token so you can use it in Postman
            debugPrint('\n================ FIREBASE ID TOKEN (BEARER TOKEN) ================');
            debugPrint(idToken);
            debugPrint('==================================================================\n');
            
            // Sync with backend using current token
            final response = await _authService.syncProfile(idToken);

            state = AuthState(user: response, isLoading: false);

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
              errorMessage: "Failed to sync profile: ${e.toString()}",
            );
          }
        }
      });
    }
  }

  /// Request SMS OTP for a phone number
  Future<String?> sendOtp(String phoneNumber) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final otp = await _authService.sendOtp(phoneNumber);
      state = state.copyWith(isLoading: false);
      return otp;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return null;
    }
  }

  /// Signup a new user account
  Future<bool> signUp({
    required String name,
    required String email,
    required String phoneNumber,
    required String location,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.signUp(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        location: location,
        password: password,
      );

      //revenue cat me user registered
      await Purchases.logIn(user.firebaseUid);


      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
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
      final user = await _authService.login(email: email, password: password);

      //revenue cat me register ho gya user
      await Purchases.logIn(user.firebaseUid);


      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  /// Log out current session
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();

    //revenue cat se logout
    await Purchases.logOut();


    state = AuthState(user: null);
  }

  /// Clear active error banner
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Global Provider for Auth state and operations
final authProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthViewModel(service);
});
