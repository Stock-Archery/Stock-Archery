/// ─── Aureum Elite Design System — Spacing & Radii ───────────────────────────
/// Source of truth: /DESIGN.md
///
/// The 8px Rule: all dimensions must be multiples of 8.

class AppSpacing {
  AppSpacing._();

  static const double base = 8;

  // ── Common multiples ──────────────────────────────────────────────────────
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 16;
  static const double lg   = 24;
  static const double xl   = 32;
  static const double xxl  = 48;

  // ── Container margins ─────────────────────────────────────────────────────
  static const double containerMarginDesktop = 48;
  static const double containerMarginMobile  = 20;
  static const double gutter     = 24;
  static const double cardPadding = 24;

  // ── Vertical rhythm (video cards) ─────────────────────────────────────────
  static const double cardGap = 32;
}

class AppRadii {
  AppRadii._();

  static const double sm      = 4;   // 0.25rem
  static const double base    = 8;   // 0.5rem
  static const double md      = 12;  // 0.75rem
  static const double lg      = 16;  // 1rem
  static const double xl      = 24;  // 1.5rem
  static const double full    = 9999;
}
