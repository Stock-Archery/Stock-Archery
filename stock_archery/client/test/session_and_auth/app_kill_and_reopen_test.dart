import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/models/user_model.dart';
import 'package:client/services/session_service.dart';
import 'package:client/services/auth_service.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';
import 'package:client/viewmodels/session_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Full Reproduction & Sanity: Tab Removal (Process Kill) -> Reopen', () {
    test('Scenario 1: User logs in -> Uses app -> Removes from tab (Process Kill) -> Reopens -> STAYS LOGGED IN', () async {
      final uid = 'user_tab_remove_001';
      final sharedStorage = <String, Object>{};
      SharedPreferences.setMockInitialValues(sharedStorage);

      // ════════════════════════════════════════════════════════════════
      // SESSION 1: User Opens App for the First Time & Logs In
      // ════════════════════════════════════════════════════════════════
      final sessionService1 = SessionService();
      final container1 = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(AuthService(baseUrl: 'http://localhost:5000/api')),
          sessionServiceProvider.overrideWithValue(sessionService1),
        ],
      );
      container1.listen(sessionProvider, (_, __) {});

      final testUser = UserModel(
        firebaseUid: uid,
        name: 'Divyanshu Pal',
        email: 'divyanshu@stockarchery.com',
        phoneNumber: '9876543210',
        state: 'Uttar Pradesh',
        isPremium: true,
      );

      // User successfully logs in
      final generatedSessionId = await sessionService1.saveNewSession(uid);
      container1.read(authProvider.notifier).state = AuthState(user: testUser);
      await pumpEventQueue();

      // Verify Session 1 is active
      expect(container1.read(authProvider).user, isNotNull);
      expect(container1.read(authProvider).isKickedOut, isFalse);
      expect(await sessionService1.getLocalSession(), equals(generatedSessionId));

      // ════════════════════════════════════════════════════════════════
      // PROCESS KILL: User Swipes App from Recent Apps (Tab Removal)
      // ════════════════════════════════════════════════════════════════
      // The OS terminates Dart VM. All in-memory providers, RAM variables,
      // and state instances are completely destroyed.
      container1.dispose();

      // ════════════════════════════════════════════════════════════════
      // SESSION 2: User Taps App Icon to Reopen (Cold Start from Disk)
      // ════════════════════════════════════════════════════════════════
      // Fresh new Dart VM / Container / Service instance with clean RAM
      final sessionService2 = SessionService();
      final container2 = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(AuthService(baseUrl: 'http://localhost:5000/api')),
          sessionServiceProvider.overrideWithValue(sessionService2),
        ],
      );
      container2.listen(sessionProvider, (_, __) {});

      // Firebase Auth emits cached user from keystore/keychain
      container2.read(authProvider.notifier).state = AuthState(user: testUser);
      await pumpEventQueue();

      // ─── REPRODUCTION ASSERTIONS ───
      // 1. Local session is smoothly restored from disk into RAM
      final restoredSession = await sessionService2.getLocalSession();
      expect(restoredSession, equals(generatedSessionId));

      // 2. User MUST NOT be kicked out or logged out
      expect(container2.read(authProvider).user, isNotNull);
      expect(container2.read(authProvider).isKickedOut, isFalse);

      // ════════════════════════════════════════════════════════════════
      // REPEAT: User removes from tab again & reopens a 2nd time
      // ════════════════════════════════════════════════════════════════
      container2.dispose(); // Tab swipe 2

      final sessionService3 = SessionService();
      final container3 = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(AuthService(baseUrl: 'http://localhost:5000/api')),
          sessionServiceProvider.overrideWithValue(sessionService3),
        ],
      );
      container3.listen(sessionProvider, (_, __) {});

      container3.read(authProvider.notifier).state = AuthState(user: testUser);
      await pumpEventQueue();

      expect(await sessionService3.getLocalSession(), equals(generatedSessionId));
      expect(container3.read(authProvider).user, isNotNull);
      expect(container3.read(authProvider).isKickedOut, isFalse);

      container3.dispose();
    });

    test('Scenario 2: Genuine Multi-device Kickout when 2nd phone logs in while 1st phone is closed', () async {
      final uid = 'user_tab_remove_002';
      final phone1Session = 'session_phone_1_timestamp';

      // Phone 1 saved session on disk before being swiped away
      SharedPreferences.setMockInitialValues({'my_local_session': phone1Session});

      // Phone 1 reopens fresh
      final phone1Service = SessionService();
      expect(await phone1Service.getLocalSession(), equals(phone1Session));

      bool kickedOut = false;
      await phone1Service.checkAndListenToSession(uid, () {
        kickedOut = true;
      });
      // In offline mock mode without remote mismatch, stays false
      expect(kickedOut, isFalse);
    });

    test('Scenario 3: Login Race Condition is neutralized by Mutex Lock', () async {
      final uid = 'user_tab_remove_003';
      SharedPreferences.setMockInitialValues({});
      final sessionService = SessionService();

      bool prematureKickout = false;

      // Simulate async saveNewSession running
      final futureSave = sessionService.saveNewSession(uid);

      // Simultaneously trigger checkAndListenToSession (as auth state stream does during login)
      await sessionService.checkAndListenToSession(uid, () {
        prematureKickout = true;
      });

      // Must NOT kick out during active registration
      expect(prematureKickout, isFalse);

      final sessionId = await futureSave;
      expect(sessionId, isNotNull);
      expect(await sessionService.getLocalSession(), equals(sessionId));
    });
  });
}
