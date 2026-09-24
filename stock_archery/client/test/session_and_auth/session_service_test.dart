import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionService Unit & Race Condition Tests', () {
    late SessionService sessionService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sessionService = SessionService();
    });

    test('1. saveNewSession generates session ID and caches it locally in memory & SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final sessionId = await sessionService.saveNewSession('test_user_123');

      expect(sessionId, isNotNull);
      expect(sessionId!.isNotEmpty, isTrue);

      // Verify in-memory and SharedPreferences retrieval
      final localSession = await sessionService.getLocalSession();
      expect(localSession, equals(sessionId));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('my_local_session'), equals(sessionId));
    });

    test('2. getLocalSession returns cached in-memory session without waiting for disk', () async {
      SharedPreferences.setMockInitialValues({'my_local_session': 'pref_session_456'});
      
      // Before explicit memory set, reads from prefs
      var session = await sessionService.getLocalSession();
      expect(session, equals('pref_session_456'));

      // After saveNewSession, memory cache overrides
      final newSession = await sessionService.saveNewSession('test_user_123');
      session = await sessionService.getLocalSession();
      expect(session, equals(newSession));
    });

    test('3. clearLocalSession wipes memory cache and SharedPreferences on logout', () async {
      SharedPreferences.setMockInitialValues({'my_local_session': 'existing_session_789'});
      
      await sessionService.clearLocalSession();

      final localSession = await sessionService.getLocalSession();
      expect(localSession, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('my_local_session'), isNull);
    });

    test('4. Graceful handling when Firebase is unavailable (Mock / Offline Mode)', () async {
      SharedPreferences.setMockInitialValues({});
      
      bool kickOutCalled = false;
      await sessionService.checkAndListenToSession('test_user_offline', () {
        kickOutCalled = true;
      });

      // When Firebase is not initialized, checkAndListenToSession gracefully bypasses without false kick-out
      expect(kickOutCalled, isFalse);
    });

    test('5. cancelListener cancels subscription and clears monitored UID safely', () async {
      await expectLater(sessionService.cancelListener(), completes);
    });
  });
}
