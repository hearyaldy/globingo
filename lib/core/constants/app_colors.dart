import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF2ECC71);
  static const Color primaryLight = Color(0xFF58D68D);
  static const Color primaryDark = Color(0xFF27AE60);

  // Secondary Colors
  static const Color secondary = Color(0xFF3498DB);
  static const Color secondaryLight = Color(0xFF5DADE2);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textLight = Color(0xFFBDC3C7);

  // Accent Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Gradient for teacher cards
  static const LinearGradient teacherCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3498DB), Color(0xFF2ECC71)],
  );

  // Skill Radar
  static const Color radarFill = Color(0x4D2ECC71);
  static const Color radarBorder = Color(0xFF2ECC71);
  static const Color radarGrid = Color(0xFFE0E0E0);

  // Star rating
  static const Color starFilled = Color(0xFFF1C40F);
  static const Color starEmpty = Color(0xFFE0E0E0);

  // Border
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Mode toggle
  static const Color learningMode = Color(0xFF2ECC71);
  static const Color teachingMode = Color(0xFF3498DB);
}
