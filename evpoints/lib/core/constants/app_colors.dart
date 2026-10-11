import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette — electric teal/emerald
  static const Color primary = Color(0xFF00C896);
  static const Color primaryDark = Color(0xFF009E78);
  static const Color primaryLight = Color(0xFF80E4CA);
  static const Color primaryGlow = Color(0xFF00C89640);

  // Secondary / accent
  static const Color accent = Color(0xFF6C63FF);
  static const Color accentLight = Color(0xFF6C63FF26);

  // Background & surface
  static const Color background = Color(0xFFF0F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F9F8);

  // Status colors
  static const Color error = Color(0xFFFF4757);
  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFFA502);

  // Text
  static const Color textPrimary = Color(0xFF0D1F1A);
  static const Color textSecondary = Color(0xFF607D73);
  static const Color textHint = Color(0xFFABBDB6);

  // Charger status
  static const Color available = Color(0xFF2ED573);
  static const Color unavailable = Color(0xFFFF4757);

  // UI elements
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0EDE9);
  static const Color shadow = Color(0x14000000);
  static const Color shadowDeep = Color(0x28000000);

  // Charger-type badges
  static const Color acBadge = Color(0xFF4776E6);
  static const Color dcBadge = Color(0xFFFF4757);
  static const Color fastChargeBadge = Color(0xFFFFA502);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00A878)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00876A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF009E78), Color(0xFF00735A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
