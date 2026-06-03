import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToastUtil {
  /// Shows a successful green toast
  static void showSuccess(BuildContext context, String title, {String? description}) {
    _showOverlay(
      context: context,
      title: title,
      description: description,
      bgColor: const Color(0xFFF0FDF4),
      borderColor: const Color(0xFFBBF7D0),
      iconColor: const Color(0xFF16A34A),
      icon: Icons.check_circle_outlined,
    );
  }

  /// Shows a red error toast
  static void showError(BuildContext context, String title, {String? description}) {
    _showOverlay(
      context: context,
      title: title,
      description: description,
      bgColor: const Color(0xFFFEF2F2),
      borderColor: const Color(0xFFFEE2E2),
      iconColor: const Color(0xFFDC2626),
      icon: Icons.cancel_outlined,
    );
  }

  /// Shows a blue info toast
  static void showInfo(BuildContext context, String title, {String? description}) {
    _showOverlay(
      context: context,
      title: title,
      description: description,
      bgColor: const Color(0xFFF0F9FF),
      borderColor: const Color(0xFFBAE6FD),
      iconColor: const Color(0xFF0284C7),
      icon: Icons.info_outline,
    );
  }

  /// Shows a yellow warning toast
  static void showWarning(BuildContext context, String title, {String? description}) {
    _showOverlay(
      context: context,
      title: title,
      description: description,
      bgColor: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFEF3C7),
      iconColor: const Color(0xFFD97706),
      icon: Icons.error_outline,
    );
  }

  static void _showOverlay({
    required BuildContext context,
    required String title,
    String? description,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required IconData icon,
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        title: title,
        description: description,
        bgColor: bgColor,
        borderColor: borderColor,
        iconColor: iconColor,
        icon: icon,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String title;
  final String? description;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.title,
    this.description,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _yAnimation = Tween<double>(begin: -80, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _timer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _yAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: widget.borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          if (widget.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.description!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: const Icon(
                        Icons.close,
                        color: Colors.black26,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
