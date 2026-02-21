import 'package:flutter/material.dart';

class AppColors {
  // ─── Primary Colors ───
  static const Color primaryGreen = Color(0xFF7DDAB9);
  static const Color secondaryGreen = Color(0xFF5BC4A8);
  static const Color lightGreen = Color(0xFFB7E4C7);
  static const Color mintGreen = Color(0xFFD4F1E8);
  static const Color darkGreen = Color(0xFF4A9B7F);
  static const Color softGreen = Color(0xFF7DDAB9);

  // ─── Accent Blue ───
  static const Color primaryBlue = Color(0xFF9BC4E2);
  static const Color secondaryBlue = Color(0xFFCCE5FF);
  static const Color accentBlue = Color(0xFF6FA8DC);
  static const Color lightBlue = Color(0xFFE8F4FF);

  // ─── Warm / Accent ───
  static const Color warmPeach = Color(0xFFFFB4A2);
  static const Color lavender = Color(0xFFD5C6E0);

  // ─── Backgrounds ───
  static const Color background = Color(0xFFF8FAFB);
  static const Color backgroundPrimary = Color(0xFFF8FAFB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFEFF);
  static const Color secondaryBackground = Color(0xFFF5F7FA);

  // ─── Text Colors ───
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);
  static const Color textMuted = Color(0xFFCBD5E0);

  // ─── Status Colors ───
  static const Color stable = Color(0xFF95D5B2);
  static const Color attention = Color(0xFFFFD97D);
  static const Color critical = Color(0xFFFFB4A2);
  static const Color softOrange = Color(0xFFFDB777);
  static const Color errorRed = Color(0xFFFEB2B2);
  static const Color successGreen = Color(0xFF9AE6B4);
  static const Color warningOrange = Color(0xFFFBD38D);
  static const Color accentGold = Color(0xFFFBD38D);

  // ─── Status Aliases (glucose) ───
  static const Color statusGood = Color(0xFF95D5B2);
  static const Color statusWarning = Color(0xFFFFD97D);
  static const Color statusCritical = Color(0xFFFFB4A2);

  // ─── Status Backgrounds ───
  static const Color statusPendingBg = Color(0xFFFFF9E6);
  static const Color statusSuccessBg = Color(0xFFE6F9F0);
  static const Color statusErrorBg = Color(0xFFFFF0F0);
  static const Color statusInfoBg = Color(0xFFEBF8FF);

  // ─── Dark Theme ───
  static const Color darkBackground = Color(0xFF1A202C);
  static const Color darkCard = Color(0xFF2D3748);
  static const Color darkSoftGreen = Color(0xFF5FB89A);
  static const Color darkLightBlue = Color(0xFF7AA5C4);

  // ─── Gradients ───
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7DDAB9), Color(0xFF9BC4E2)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF9FE2BF), Color(0xFFD4F1E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFFA7C7E7), Color(0xFFE8F4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFBD38D), Color(0xFFFED7AA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mixedGradient = LinearGradient(
    colors: [Color(0xFF9FE2BF), Color(0xFFA7C7E7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows ───
  static Color shadowLight = const Color(0xFF000000).withOpacity(0.03);
  static Color shadowMedium = const Color(0xFF000000).withOpacity(0.06);

  // ─── Border ───
  static const Color border = Color(0xFFE8ECF0);
}
