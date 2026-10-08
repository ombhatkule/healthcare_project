import 'package:flutter/material.dart';

/// App color palette for the healthcare application.
/// Uses a calming, professional medical theme.
abstract final class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF00897B);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDark = Color(0xFF00695C);

  // Secondary colors
  static const Color secondary = Color(0xFF5C6BC0);
  static const Color secondaryLight = Color(0xFF9FA8DA);
  static const Color secondaryDark = Color(0xFF3949AB);

  // Accent
  static const Color accent = Color(0xFF26A69A);

  // Neutral colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Divider
  static const Color divider = Color(0xFFE5E7EB);

  // Shadow
  static const Color shadow = Color(0x1A000000);
}
