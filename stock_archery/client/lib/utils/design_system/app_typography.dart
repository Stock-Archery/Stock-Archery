import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─── Aureum Elite Design System — Typography ────────────────────────────────
/// Source of truth: /DESIGN.md
///
/// Dual-font approach:
///   • Montserrat — geometric, bold for headings
///   • Inter — maximum readability for body / data

class AppTypography {
  AppTypography._();

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle displayLg({Color? color}) => GoogleFonts.montserrat(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 56 / 48,
        letterSpacing: -0.96, // -0.02em
        color: color,
      );

  // ── Headline ──────────────────────────────────────────────────────────────
  static TextStyle headlineLg({Color? color}) => GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        letterSpacing: -0.32, // -0.01em
        color: color,
      );

  static TextStyle headlineLgMobile({Color? color}) => GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: color,
      );

  // ── Title ─────────────────────────────────────────────────────────────────
  static TextStyle titleMd({Color? color}) => GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: color,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle bodyLg({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: color,
      );

  static TextStyle bodyMd({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: color,
      );

  // ── Label ─────────────────────────────────────────────────────────────────
  static TextStyle labelSm({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.6, // 0.05em
        color: color,
      );
}
