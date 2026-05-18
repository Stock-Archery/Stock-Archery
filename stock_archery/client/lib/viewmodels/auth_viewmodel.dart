import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/app_config.dart';

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

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

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
            
            // Sync with backend using current token
            final response = await _authService.syncProfile(idToken);
            
            state = AuthState(user: response, isLoading: false);
          } catch (e) {
            state = AuthState(
              user: null, 
              isLoading: false, 
              errorMessage: "Failed to sync profile: ${e.toString()}"
            );
          }
        }
      });
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
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );
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
