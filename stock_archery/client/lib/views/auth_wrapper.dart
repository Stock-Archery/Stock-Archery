import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/session_provider.dart';
import 'login_view.dart';
import 'main_navigation_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch sessionProvider to instantiate/manage the single-device login listener
    ref.watch(sessionProvider);

    final authState = ref.watch(authProvider);
    final authService = ref.read(authServiceProvider);

    // If it's loading, show a beautiful splash screen
    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.gps_fixed_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "ArrowAI",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Determine logged in state (either via verified Firebase or Mock session)
    final isLoggedIn = authState.user != null || (!authService.isFirebaseAvailable && authService.isMockLoggedIn);

    if (isLoggedIn) {
      return const MainNavigationScreen();
    } else {
      return const LoginView();
    }
  }
}
