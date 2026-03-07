import 'package:flutter/material.dart';

extension AppColors on BuildContext {
  // ── Backgrounds ─────────────────────────────────────────────
  Color get scaffoldBg  => const Color(0xFFE5E7EB);
  Color get cardBg      => Colors.white;
  Color get containerBg => const Color(0xFFF1F5F9);
  Color get inputFill   => const Color(0xFFF8FAFC);

  // ── Textes ───────────────────────────────────────────────────
  Color get textPrimary   => const Color(0xFF1E293B);
  Color get textSecondary => const Color(0xFF64748B);
  Color get textHint      => const Color(0xFF94A3B8);

  // ── Bordures & séparateurs ───────────────────────────────────
  Color get borderColor  => const Color(0xFFE2E8F0);
  Color get dividerColor => const Color(0xFFF1F5F9);
  Color get chevronColor => const Color(0xFFCBD5E1);
}
