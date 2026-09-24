import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/models/user_model.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';
import 'package:client/viewmodels/session_provider.dart';
import 'package:client/services/session_service.dart';
import 'package:client/services/auth_service.dart';

class MockSessionService extends SessionService {
  int checkCount = 0;
  int cancelCount = 0;
  String? lastCheckedUid;

  @override
  Future<void> checkAndListenToSession(String uid, void Function() onKickOut) async {
    checkCount++;
    lastCheckedUid = uid;
  }

  @override
  Future<void> cancelListener() async {
    cancelCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionProvider Riverpod Selective Watching Tests', () {
    late MockSessionService mockSessionService;
    late ProviderContainer container;

    setUp(() {
      mockSessionService = MockSessionService();
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(AuthService(baseUrl: 'http://localhost:5000/api')),
          sessionServiceProvider.overrideWithValue(mockSessionService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('1. sessionProvider starts session monitoring when user is logged in', () async {
      // Keep provider actively listened to in Riverpod container
      container.listen(sessionProvider, (_, __) {});

      final user = UserModel(
        firebaseUid: 'test_uid_555',
        name: 'Test Trader',
        email: 'trader@test.com',
        phoneNumber: '9999999999',
        state: 'Punjab',
        isPremium: false,
      );

      // Simulate state update to logged-in user
      container.read(authProvider.notifier).state = AuthState(user: user);

      // Wait for all microtasks / event loops to finish
      await pumpEventQueue();

      expect(mockSessionService.checkCount, equals(1));
      expect(mockSessionService.lastCheckedUid, equals('test_uid_555'));
    });

    test('2. sessionProvider cancels listener when user logs out', () async {
      container.listen(sessionProvider, (_, __) {});

      final user = UserModel(
        firebaseUid: 'test_uid_555',
        name: 'Test Trader',
        email: 'trader@test.com',
        phoneNumber: '9999999999',
        state: 'Punjab',
        isPremium: false,
      );

      // Log in
      container.read(authProvider.notifier).state = AuthState(user: user);
      await pumpEventQueue();

      final cancelCountBefore = mockSessionService.cancelCount;

      // Log out
      container.read(authProvider.notifier).state = AuthState(user: null);
      await pumpEventQueue();

      expect(mockSessionService.cancelCount, greaterThan(cancelCountBefore));
    });

    test('3. Non-UID state changes (alert access, chat counts) do NOT trigger redundant session checks', () async {
      container.listen(sessionProvider, (_, __) {});

      final user = UserModel(
        firebaseUid: 'test_uid_steady',
        name: 'Steady Trader',
        email: 'steady@test.com',
        phoneNumber: '9999999999',
        state: 'Delhi',
        isPremium: false,
      );

      // Initial login
      container.read(authProvider.notifier).state = AuthState(user: user);
      await pumpEventQueue();
      expect(mockSessionService.checkCount, equals(1));

      // Update non-UID field (e.g. premium alert toggle, chat count)
      container.read(authProvider.notifier).state = AuthState(
        user: user.copyWith(isSOBAlertPremium: true, textChatCount: 2),
      );
      await pumpEventQueue();

      // checkCount should still be 1 (NOT re-instantiated because UID didn't change)
      expect(mockSessionService.checkCount, equals(1));
    });
  });
}
