import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/session_service.dart';
import 'auth_viewmodel.dart';
import 'package:flutter/foundation.dart';

/// Provider for accessing the SessionService instance.
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});

/// Riverpod Provider that coordinates single-device login enforcement by
/// monitoring the AuthState.
/// 
/// If a user is logged in, it starts/re-starts monitoring the session path in Realtime Database.
/// If a user logs out, it cancels the Realtime Database listener.
final sessionProvider = Provider<void>((ref) {
  final sessionService = ref.watch(sessionServiceProvider);
  final authState = ref.watch(authProvider);
  final user = authState.user;

  if (user != null) {
    debugPrint('[SessionProvider] User logged in: ${user.name} (${user.email}). Starting active session monitor.');
    
    // We execute the check asynchronously to prevent triggering layout/build cycle warnings in Riverpod
    Future.microtask(() async {
      await sessionService.checkAndListenToSession(user.firebaseUid, () async {
        debugPrint('[SessionProvider] 🚨 Forceful kick-out triggered! Clearing local session and executing forceLogout().');
        
        // 1. Terminate listener and delete session token locally
        await sessionService.cancelListener();
        await sessionService.clearLocalSession();
        
        // 2. Perform Firebase & RevenueCat sign out and flag the AuthState as isKickedOut = true
        await ref.read(authProvider.notifier).forceLogout();
      });
    });
  } else {
    debugPrint('[SessionProvider] User logged out (or null). Disabling active session monitor.');
    sessionService.cancelListener();
  }

  // Ensure listener is cancelled if the provider gets disposed or re-initialized
  ref.onDispose(() {
    debugPrint('[SessionProvider] Disposing. Cleaning up listeners.');
    sessionService.cancelListener();
  });
});
