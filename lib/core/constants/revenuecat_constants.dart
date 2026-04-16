class RevenueCatConstants {
  // Inject with --dart-define flags at build/run time.
  static const String androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const String iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );

  static const String premiumEntitlementId = String.fromEnvironment(
    'REVENUECAT_PREMIUM_ENTITLEMENT_ID',
    defaultValue: 'premium',
  );
  static const String premiumPackageId = String.fromEnvironment(
    'REVENUECAT_PREMIUM_PACKAGE_ID',
    defaultValue: r'$rc_monthly',
  );

  static const String doctorBoostEntitlementId = String.fromEnvironment(
    'REVENUECAT_DOCTOR_BOOST_ENTITLEMENT_ID',
    defaultValue: 'doctor_boost',
  );
  static const String doctorBoost24hPackageId = String.fromEnvironment(
    'REVENUECAT_BOOST_24H_PACKAGE_ID',
    defaultValue: 'boost_24h',
  );
  static const String doctorBoostWeekPackageId = String.fromEnvironment(
    'REVENUECAT_BOOST_WEEK_PACKAGE_ID',
    defaultValue: 'boost_week',
  );
  static const String doctorBoostMonthPackageId = String.fromEnvironment(
    'REVENUECAT_BOOST_MONTH_PACKAGE_ID',
    defaultValue: 'boost_month',
  );
}
