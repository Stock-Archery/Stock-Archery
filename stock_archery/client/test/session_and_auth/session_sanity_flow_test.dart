import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/services/session_service.dart';
import 'package:client/models/user_model.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session & Auth Complete Sanity Lifecycle Tests', () {
    late SessionService sessionService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sessionService = SessionService();
    });

    test('Flow 1: Fresh Login -> Session Generation -> Local Persistence', () async {
      final uid = 'user_sanity_001';
      final generatedSession = await sessionService.saveNewSession(uid);

      expect(generatedSession, isNotNull);
      expect(generatedSession!.isNotEmpty, isTrue);

      // Verify local storage
      final localSession = await sessionService.getLocalSession();
      expect(localSession, equals(generatedSession));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('my_local_session'), equals(generatedSession));
    });

    test('Flow 2: App Restart / Reopen -> Verified matching session keeps user logged in', () async {
      final uid = 'user_sanity_002';
      final activeSession = 'session_timestamp_12345';
      
      // Simulate existing session in SharedPreferences
      SharedPreferences.setMockInitialValues({'my_local_session': activeSession});

      final localSession = await sessionService.getLocalSession();
      expect(localSession, equals(activeSession));

      // In mock/offline or matching state, no kick-out occurs
      bool kickOutCalled = false;
      await sessionService.checkAndListenToSession(uid, () {
        kickOutCalled = true;
      });

      expect(kickOutCalled, isFalse);
    });

    test('Flow 3: User Kickout -> State Transition to isKickedOut', () {
      final user = UserModel(
        firebaseUid: 'user_sanity_003',
        name: 'Amit Patel',
        email: 'amit@gmail.com',
        phoneNumber: '9876543210',
        state: 'Rajasthan',
        isPremium: false,
      );

      var authState = AuthState(user: user, isKickedOut: false);
      expect(authState.user, isNotNull);
      expect(authState.isKickedOut, isFalse);

      // Trigger kickout
      authState = AuthState(user: null, isKickedOut: true);
      expect(authState.user, isNull);
      expect(authState.isKickedOut, isTrue);

      // Toast shown -> clearKickedOut called
      authState = authState.copyWith(isKickedOut: false);
      expect(authState.isKickedOut, isFalse);
    });

    test('Flow 4: Manual Logout -> Clears local session and resets state cleanly', () async {
      final uid = 'user_sanity_004';
      await sessionService.saveNewSession(uid);
      expect(await sessionService.getLocalSession(), isNotNull);

      // Execute logout cleanup
      await sessionService.cancelListener();
      await sessionService.clearLocalSession();

      expect(await sessionService.getLocalSession(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('my_local_session'), isNull);
    });

    test('Flow 5: Re-login after kickout works seamlessly with a new unique session ID', () async {
      final uid = 'user_sanity_005';
      
      // First session
      final session1 = await sessionService.saveNewSession(uid);
      await Future.delayed(const Duration(milliseconds: 10)); // Ensure different timestamp
      
      // Cleared after kickout
      await sessionService.clearLocalSession();
      expect(await sessionService.getLocalSession(), isNull);

      // Second session (re-login)
      final session2 = await sessionService.saveNewSession(uid);
      expect(session2, isNotNull);
      expect(session2, isNot(equals(session1)));
      expect(await sessionService.getLocalSession(), equals(session2));
    });
  });
}
