import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Medical Brand Colors
  static const Color primary = Color(0xFF0D9488); // Modern Teal
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF2DD4BF);
  static const Color accent = Color(0xFF0284C7); // Cyan / Blue Accent

  // Backgrounds & Surfaces (Dark Theme)
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // Backgrounds & Surfaces (Light Theme)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Status & Verification Indicators
  static const Color statusVerified = Color(0xFF10B981); // Emerald Green
  static const Color statusReview = Color(0xFFF59E0B); // Amber / Review Required
  static const Color statusWarning = Color(0xFFF97316); // Orange / Intake Limit Reached
  static const Color statusExpired = Color(0xFFEF4444); // Crimson / Expired or Unverified
  static const Color statusInfo = Color(0xFF3B82F6); // Blue
}
