import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/views/auth_wrapper.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';
import 'package:client/services/auth_service.dart';

void main() {
  testWidgets('AuthWrapper shows loading splash indicator when isInitializing is true', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(AuthService(baseUrl: 'http://localhost:5000/api')),
      ],
    );
    container.read(authProvider.notifier).state = AuthState(isInitializing: true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AuthWrapper(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Trade Genie'), findsOneWidget);
  });
}
