import 'package:flutter_test/flutter_test.dart';
import 'package:client/models/user_model.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';

void main() {
  group('AuthState & UserModel Integrity Tests', () {
    test('1. AuthState initial state is configured correctly', () {
      final state = AuthState(isInitializing: true);
      expect(state.isInitializing, isTrue);
      expect(state.user, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isKickedOut, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('2. AuthState copyWith preserves existing values and updates specified fields', () {
      final user = UserModel(
        firebaseUid: 'uid_123',
        name: 'Test Trader',
        email: 'test@stockarchery.com',
        phoneNumber: '9876543210',
        state: 'Maharashtra',
        isPremium: false,
      );

      final state = AuthState(user: user);
      expect(state.user?.name, equals('Test Trader'));

      // Test kicking out state update
      final kickedOutState = state.copyWith(isKickedOut: true);
      expect(kickedOutState.isKickedOut, isTrue);
      expect(kickedOutState.user, equals(user));

      // Test clearing error
      final errorState = kickedOutState.copyWith(errorMessage: 'Network timeout');
      expect(errorState.errorMessage, equals('Network timeout'));

      final clearedErrorState = errorState.copyWith(clearError: true);
      expect(clearedErrorState.errorMessage, isNull);
    });

    test('3. UserModel JSON serialization and deserialization retains alert flags and chat counts', () {
      final json = {
        'firebaseUid': 'uid_abc_999',
        'name': 'Rahul Sharma',
        'email': 'rahul@gmail.com',
        'phoneNumber': '9988776655',
        'state': 'Delhi',
        'isPremium': true,
        'isSOB_alert_premium': true,
        'isXaud_alert_premium': false,
        'isCrypto_alert_premium': true,
        'textChatCount': 3,
      };

      final user = UserModel.fromJson(json);

      expect(user.firebaseUid, equals('uid_abc_999'));
      expect(user.name, equals('Rahul Sharma'));
      expect(user.isPremium, isTrue);
      expect(user.isSOBAlertPremium, isTrue);
      expect(user.isXaudAlertPremium, isFalse);
      expect(user.isCryptoAlertPremium, isTrue);
      expect(user.textChatCount, equals(3));

      // Test copyWith on UserModel
      final updatedUser = user.copyWith(isXaudAlertPremium: true, textChatCount: 4);
      expect(updatedUser.isXaudAlertPremium, isTrue);
      expect(updatedUser.textChatCount, equals(4));
      expect(updatedUser.isSOBAlertPremium, isTrue); // Preserved
    });

    test('4. UserModel handles null alert fields and fallback gracefully', () {
      final json = {
        'firebaseUid': 'uid_minimal',
        'name': 'Minimal User',
        'email': 'minimal@test.com',
        'phoneNumber': '1122334455',
        'state': 'Gujarat',
      };

      final user = UserModel.fromJson(json);

      expect(user.firebaseUid, equals('uid_minimal'));
      expect(user.isPremium, isFalse);
      expect(user.isSOBAlertPremium, isFalse);
      expect(user.isXaudAlertPremium, isFalse);
      expect(user.isCryptoAlertPremium, isFalse);
      expect(user.textChatCount, equals(0));
    });
  });
}
