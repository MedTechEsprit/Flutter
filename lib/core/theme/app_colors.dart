import 'package:flutter/material.dart';

class AppColors {
  // ─── Primary Colors (Cyan/Teal) ───
  static const Color primaryGreen = Color(0xFF22C1C3); // Replaced with #22c1c3
  static const Color secondaryGreen = Color(
    0xFF74EBD5,
  ); // Replaced with #74ebd5
  static const Color lightGreen = Color(0xFFE0F7FA);
  static const Color mintGreen = Color(0xFF74EBD5);
  static const Color darkGreen = Color(0xFF1E9B9D);
  static const Color softGreen = Color(0xFF74EBD5);

  // ─── Accent Blue & Purple ───
  static const Color primaryBlue = Color(0xFF5B86E5); // Replaced with #5B86E5
  static const Color secondaryBlue = Color(0xFFACB6E5); // Replaced with #ACB6E5
  static const Color accentBlue = Color(0xFF5B86E5);
  static const Color lightBlue = Color(0xFFE8EAF6);

  // ─── Warm / Accent ───
  static const Color warmPeach = Color(0xFFFDBB2D); // Replaced with #fdbb2d
  static const Color lavender = Color(0xFFACB6E5);

  // ─── Backgrounds ───
  static const Color background = Color(0xFFF8FAFB);
  static const Color backgroundPrimary = Color(0xFFF8FAFB);
  static const Color doctorBackground = Color(0xFFEFF6FF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFEFF);
  static const Color secondaryBackground = Color(0xFFF5F7FA);

  // ─── Text Colors ───
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);
  static const Color textMuted = Color(0xFFCBD5E0);

  // ─── Status Colors ───
  static const Color stable = Color(0xFF74EBD5);
  static const Color attention = Color(0xFFFDBB2D);
  static const Color critical = Color(0xFFFDBB2D); // Warning orange
  static const Color softOrange = Color(0xFFFDBB2D);
  static const Color errorRed = Color(0xFFFEB2B2);
  static const Color successGreen = Color(0xFF22C1C3);
  static const Color warningOrange = Color(0xFFFDBB2D);
  static const Color accentGold = Color(0xFFFDBB2D);

  // ─── Status Aliases (glucose) ───
  static const Color statusGood = Color(0xFF74EBD5);
  static const Color statusWarning = Color(0xFFFDBB2D);
  static const Color statusCritical = Color(0xFFFEB2B2);

  // ─── Status Backgrounds ───
  static const Color statusPendingBg = Color(0xFFFFF9E6);
  static const Color statusSuccessBg = Color(0xFFE0F7FA);
  static const Color statusErrorBg = Color(0xFFFFF0F0);
  static const Color statusInfoBg = Color(0xFFE8EAF6);

  // ─── Dark Theme ───
  static const Color darkBackground = Color(0xFF1A202C);
  static const Color darkCard = Color(0xFF2D3748);
  static const Color darkSoftGreen = Color(0xFF22C1C3);
  static const Color darkLightBlue = Color(0xFF5B86E5);

  // ─── Gradients ───
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF74EBD5), Color(0xFFACB6E5)], // #74ebd5 to #ACB6E5
  );

  static const LinearGradient doctorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C1C3), Color(0xFF5B86E5)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF22C1C3), Color(0xFF74EBD5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFFACB6E5), Color(0xFF5B86E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFDBB2D), Color(0xFFFFD54F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mixedGradient = LinearGradient(
    colors: [Color(0xFF74EBD5), Color(0xFF5B86E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows ───
  static Color shadowLight = const Color(0xFF000000).withOpacity(0.03);
  static Color shadowMedium = const Color(0xFF000000).withOpacity(0.06);

  // ─── Border ───
  static const Color border = Color(0xFFE8ECF0);

  // ─── Unified Design Constants ───
  static const double cardRadius = 16.0;
  static const double headerRadius = 28.0;
  static const double inputRadius = 16.0;
  static const double navBarRadius = 24.0;

  /// Standard card shadow used across all screens
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Elevated card shadow for featured/highlighted cards
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: primaryGreen.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
}
