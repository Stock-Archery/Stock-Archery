import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../viewmodels/server_status_viewmodel.dart';

/// Top-of-homepage tracker: "Admin Server Awake:" + Check button.
/// Hits the server health endpoint; shows "Waking up" with background
/// backoff polling until the server responds, then "Ready to use".
class ServerAwakeTracker extends StatelessWidget {
  const ServerAwakeTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerStatusViewModel>(
      builder: (context, vm, _) {
        final isAwake = vm.state == ServerAwakeState.awake;
        final isWaking = vm.state == ServerAwakeState.waking;
        final isChecking = vm.state == ServerAwakeState.checking;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAwake
                  ? Colors.green.withOpacity(0.4)
                  : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              _StatusDot(state: vm.state),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Server Awake:',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(vm),
                      style: GoogleFonts.outfit(
                        color: isAwake ? Colors.green : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ActionButton(
                isAwake: isAwake,
                isWaking: isWaking,
                isChecking: isChecking,
                attempt: vm.attempt,
                onCheck: vm.check,
                onCancel: vm.cancel,
              ),
            ],
          ),
        );
      },
    );
  }

  String _subtitle(ServerStatusViewModel vm) {
    return switch (vm.state) {
      ServerAwakeState.unknown => 'Not checked yet',
      ServerAwakeState.checking => 'Pinging server…',
      ServerAwakeState.waking =>
        'Retrying in background (try ${vm.attempt}) — tap to stop',
      ServerAwakeState.awake => 'Server is live',
    };
  }
}

class _StatusDot extends StatelessWidget {
  final ServerAwakeState state;

  const _StatusDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      ServerAwakeState.unknown => Colors.white24,
      ServerAwakeState.checking => const Color(0xFF6366F1),
      ServerAwakeState.waking => Colors.orange,
      ServerAwakeState.awake => Colors.green,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isAwake;
  final bool isWaking;
  final bool isChecking;
  final int attempt;
  final VoidCallback onCheck;
  final VoidCallback onCancel;

  const _ActionButton({
    required this.isAwake,
    required this.isWaking,
    required this.isChecking,
    required this.attempt,
    required this.onCheck,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (isAwake) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 18),
            const SizedBox(width: 6),
            Text(
              'Ready to use',
              style: GoogleFonts.outfit(
                color: Colors.green,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (isChecking || isWaking) {
      return ElevatedButton(
        onPressed: isWaking ? onCancel : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          disabledBackgroundColor:
              const Color(0xFF6366F1).withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isWaking ? 'Waking up…' : 'Checking…',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onCheck,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        'Check',
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}
