import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/views/video_list_view.dart';
import 'package:client/models/user_model.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';
import 'package:client/Features/payment/model/premium_state.dart';
import 'package:client/Features/payment/view_model/premium_provider.dart';

// Simple Mock Notifiers for Riverpod testing
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthViewModel {
  MockAuthNotifier(AuthState initialTestState) : super(initialTestState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPremiumNotifier extends StateNotifier<PremiumState> implements PremiumNotifier {
  MockPremiumNotifier(PremiumState initialTestState) : super(initialTestState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final freeUser = UserModel(
    firebaseUid: 'user1',
    name: 'Free User',
    email: 'free@example.com',
    phoneNumber: '1234567890',
    state: 'Delhi',
    isPremium: false,
  );

  final backendPremiumUser = UserModel(
    firebaseUid: 'user2',
    name: 'Premium User',
    email: 'premium@example.com',
    phoneNumber: '0987654321',
    state: 'Delhi',
    isPremium: true,
  );

  Widget createWidgetToTest({
    UserModel? user,
    bool superPremium = false,
  }) {
    final authState = AuthState(user: user, isLoading: false);
    final premiumState = PremiumState(
      isLoading: false,
      superPremium: superPremium,
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => MockAuthNotifier(authState)),
        premiumProvider.overrideWith((ref) => MockPremiumNotifier(premiumState)),
      ],
      child: const MaterialApp(
        home: VideoListView(),
      ),
    );
  }

  group('VideoListView Sanity & Premium Locking Tests', () {
    testWidgets('1. Renders Free Classes by default with free videos',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetToTest(user: freeUser));
      await tester.pumpAndSettle();

      expect(find.text('Strategy Videos'), findsOneWidget);
      expect(find.text('Free Classes'), findsOneWidget);
      expect(find.text('SOB'), findsOneWidget);
      expect(find.text('XAUD'), findsOneWidget);

      // Verify free class video title is displayed
      expect(find.text('Intro of Free Classes'), findsOneWidget);
      // Verify locked card teaser is visible at bottom of free classes for free user
      expect(find.text('Upgrade to Premium to Unlock'), findsOneWidget);
    });

    testWidgets('2. SOB tab locks videos and shows upgrade card for non-premium user',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetToTest(user: freeUser, superPremium: false));
      await tester.pumpAndSettle();

      // Tap SOB tab
      await tester.tap(find.text('SOB'));
      await tester.pumpAndSettle();

      // Verify SOB videos are NOT shown to non-premium user
      expect(find.text('Stock Option Buying strategy Part 1'), findsNothing);

      // Verify locked card is shown with CTA
      expect(find.text('Upgrade to Premium to Unlock'), findsOneWidget);
      expect(find.text('UPGRADE NOW TO UNLOCK'), findsOneWidget);
      expect(find.text('PREMIUM EXCLUSIVE'), findsOneWidget);
    });

    testWidgets('3. SOB tab unlocks videos when user has RevenueCat superPremium',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetToTest(user: freeUser, superPremium: true));
      await tester.pumpAndSettle();

      // Tap SOB tab
      await tester.tap(find.text('SOB'));
      await tester.pumpAndSettle();

      // Verify SOB videos are unlocked and visible
      expect(find.text('Stock Option Buying strategy Part 1'), findsOneWidget);
      expect(find.text('Stock Option Buying strategy Part 2'), findsOneWidget);
      expect(find.text('UPGRADE NOW TO UNLOCK'), findsNothing);
    });

    testWidgets('4. SOB tab unlocks videos when user has backend admin isPremium',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetToTest(user: backendPremiumUser, superPremium: false));
      await tester.pumpAndSettle();

      // Tap SOB tab
      await tester.tap(find.text('SOB'));
      await tester.pumpAndSettle();

      // Verify SOB videos are unlocked and visible via backend isPremium flag
      expect(find.text('Stock Option Buying strategy Part 1'), findsOneWidget);
      expect(find.text('UPGRADE NOW TO UNLOCK'), findsNothing);
    });

    testWidgets('5. XAUD tab shows COMING SOON state for all users',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetToTest(user: freeUser));
      await tester.pumpAndSettle();

      // Tap XAUD tab
      await tester.tap(find.text('XAUD'));
      await tester.pumpAndSettle();

      expect(find.text('XAUD Strategy'), findsOneWidget);
      expect(find.text('COMING SOON'), findsOneWidget);
    });

    testWidgets('6. Null user (unauthenticated edge case) locks SOB safely',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetToTest(user: null, superPremium: false));
      await tester.pumpAndSettle();

      // Tap SOB tab
      await tester.tap(find.text('SOB'));
      await tester.pumpAndSettle();

      // Verify locked state without null crash
      expect(find.text('Upgrade to Premium to Unlock'), findsOneWidget);
      expect(find.text('Stock Option Buying strategy Part 1'), findsNothing);
    });
  });
}
