class AppConstants {
  // App Info
  static const String appName = 'DiabCare';
  static const String appVersion = '1.0.0';

  // Glucose Ranges (mg/dL)
  static const double glucoseLow = 70.0;
  static const double glucoseNormalMin = 80.0;
  static const double glucoseNormalMax = 130.0;
  static const double glucoseHighMin = 180.0;
  static const double glucoseCritical = 250.0;

  // Aliases
  static const double normalGlucoseMin = glucoseNormalMin;
  static const double normalGlucoseMax = glucoseNormalMax;

  // Target Ranges
  static const double fastingMin = 80.0;
  static const double fastingMax = 130.0;
  static const double postMealMax = 180.0;

  // HbA1c
  static const double hba1cNormal = 5.7;
  static const double hba1cPreDiabetes = 6.5;
  static const double hba1cDiabetes = 7.0;

  // User Roles
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';
  static const String rolePharmacy = 'pharmacy';
}
