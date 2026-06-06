import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primaryMid = Color(0xFF871DAD);
  static const Color primaryDark = Color(0xFF5B0E91);
  static const Color primaryLight = Color(0xFFB44FD4);
  static const Color primaryAccent = Color(0xFFD8A8F0);
  static const Color primaryVeryLight = Color(0xFFF4F0FA);

  // Background
  static const Color scaffoldBg = Color(0xFFF8F9FA);
  static const Color cardBg = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF888888);
  static const Color textLight = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF2E9B5B);
  static const Color warning = Color(0xFFE8A317);
  static const Color error = Color(0xFFD32F2F);

  // Border & Dividers
  static const Color border = Color(0xFFE0E0E0);
  
  // Onboarding Backgrounds
  static const Color onboarding1 = Color(0xFF9E92C4);
  static const Color onboarding2 = Color(0xFF094988);
  static const Color onboarding3 = Color(0xFFFFBE02);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primaryMid, primaryLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFE8CBFA), Color(0xFFD4A0F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
