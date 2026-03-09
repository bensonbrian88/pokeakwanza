import 'package:flutter/material.dart';

class AppColors {
  // Primary teal palette
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444);

  // legacy aliases / extras
  static const Color surface = Colors.white;
  static const Color textDark =
      textPrimary; // alias for backwards compatibility
  static const Color textMuted = textSecondary;
  static const Color success = Color(0xFF10B981);
  static const Color lightGrey = Color(0xFFF1F5F9);
  static const Color shadow = Color(0x0A000000);

  // additional helper colors
  static const Color accent = primaryLight;
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color textGrey = Color(0xFF94A3B8);
  static const Color error = danger;
}
