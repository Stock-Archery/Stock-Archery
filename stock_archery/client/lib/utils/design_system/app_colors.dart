import 'package:flutter/material.dart';

/// ─── Aureum Elite Design System — Colors ────────────────────────────────────
/// Source of truth: /DESIGN.md
/// Import this file instead of hardcoding hex values.

class AppColors {
  AppColors._(); // prevent instantiation

  // ── Core Surfaces ─────────────────────────────────────────────────────────
  static const surface           = Color(0xFF16130B);
  static const surfaceDim        = Color(0xFF16130B);
  static const surfaceBright     = Color(0xFF3D392F);
  static const surfaceContainerLowest  = Color(0xFF110E07);
  static const surfaceContainerLow     = Color(0xFF1F1B13);
  static const surfaceContainer        = Color(0xFF231F17);
  static const surfaceContainerHigh    = Color(0xFF2D2A21);
  static const surfaceContainerHighest = Color(0xFF38342B);
  static const surfaceVariant    = Color(0xFF38342B);

  // ── On-Surface ────────────────────────────────────────────────────────────
  static const onSurface         = Color(0xFFEAE1D4);
  static const onSurfaceVariant  = Color(0xFFD0C5AF);
  static const inverseSurface    = Color(0xFFEAE1D4);
  static const inverseOnSurface  = Color(0xFF343027);

  // ── Primary (Gold) ────────────────────────────────────────────────────────
  static const primary           = Color(0xFFF2CA50);
  static const onPrimary         = Color(0xFF3C2F00);
  static const primaryContainer  = Color(0xFFD4AF37);
  static const onPrimaryContainer = Color(0xFF554300);
  static const inversePrimary    = Color(0xFF735C00);
  static const primaryFixed      = Color(0xFFFFE088);
  static const primaryFixedDim   = Color(0xFFE9C349);
  static const onPrimaryFixed    = Color(0xFF241A00);
  static const onPrimaryFixedVariant = Color(0xFF574500);

  // ── Secondary (Steel Blue-Grey) ───────────────────────────────────────────
  static const secondary         = Color(0xFFBDC7D6);
  static const onSecondary       = Color(0xFF27313D);
  static const secondaryContainer = Color(0xFF404A56);
  static const onSecondaryContainer = Color(0xFFAFB9C8);
  static const secondaryFixed    = Color(0xFFD9E3F3);
  static const secondaryFixedDim = Color(0xFFBDC7D6);
  static const onSecondaryFixed  = Color(0xFF131C27);
  static const onSecondaryFixedVariant = Color(0xFF3E4854);

  // ── Tertiary ──────────────────────────────────────────────────────────────
  static const tertiary          = Color(0xFFCACFD7);
  static const onTertiary        = Color(0xFF2C3137);
  static const tertiaryContainer = Color(0xFFAFB3BB);
  static const onTertiaryContainer = Color(0xFF40454C);
  static const tertiaryFixed     = Color(0xFFDEE3EB);
  static const tertiaryFixedDim  = Color(0xFFC2C7CF);
  static const onTertiaryFixed   = Color(0xFF171C22);
  static const onTertiaryFixedVariant = Color(0xFF42474E);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const error             = Color(0xFFFFB4AB);
  static const onError           = Color(0xFF690005);
  static const errorContainer    = Color(0xFF93000A);
  static const onErrorContainer  = Color(0xFFFFDAD6);

  // ── Outline / Borders ─────────────────────────────────────────────────────
  static const outline           = Color(0xFF99907C);
  static const outlineVariant    = Color(0xFF4D4635);
  static const surfaceTint       = Color(0xFFE9C349);

  // ── Background ────────────────────────────────────────────────────────────
  static const background        = Color(0xFF16130B);
  static const onBackground      = Color(0xFFEAE1D4);

  // ══════════════════════════════════════════════════════════════════════════
  // Brand-level convenience aliases (from DESIGN.md "Colors" section)
  // ══════════════════════════════════════════════════════════════════════════

  /// Primary canvas — slightly warmer than pure black.
  static const deepObsidian      = Color(0xFF0B0E11);

  /// Elevated cards / containers — "hole in the screen" effect.
  static const pureBlack         = Color(0xFF000000);

  /// Primary accent — use sparingly for CTAs, progress, premium badges.
  static const metallicGold      = Color(0xFFD4AF37);

  /// Bright gold variant for highlights.
  static const goldBright        = Color(0xFFF2CA50);

  /// Premium amber glow.
  static const premiumAmber      = Color(0xFFE9C349);

  /// Workhorse for metadata, captions, inactive states.
  static const subtleGrey        = Color(0xFF848E9C);

  /// Navigation surface — slightly lighter than deep obsidian.
  static const surfaceNav        = Color(0xFF0D1014);
}
