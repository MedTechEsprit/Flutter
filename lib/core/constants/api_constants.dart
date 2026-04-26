class ApiConstants {
  // Source unique d'URL backend.
  // Emulateur Android Studio (run typique): 10.0.2.2 pointe vers localhost du PC.
  // Telephone reel (sans Render): utilisez --dart-define=API_BASE_URL=http://<IP_PC_WIFI>:3000
  static const String _defaultServerBaseUrl = 'https://nestjs-mu65.onrender.com/';
  static const String _serverBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultServerBaseUrl,
  );

  static String get serverBaseUrl {
    // Normalise pour éviter les doubles slashs quand on concatène avec /api.
    return _serverBaseUrlFromEnv.endsWith('/')
        ? _serverBaseUrlFromEnv.substring(0, _serverBaseUrlFromEnv.length - 1)
        : _serverBaseUrlFromEnv;
  }

  // Base API commune
  static String get baseUrl => '$serverBaseUrl/api';

  // Authentication Endpoints
  static const String login = '/auth/login';
  static const String googleMobileLogin = '/auth/google/mobile';

  // Google Sign-In config
  // Inject with --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  // Medication Requests Endpoints
  static String pendingRequests(String pharmacyId) =>
      '/medication-request/pharmacy/$pharmacyId/pending';
  static String requestHistory(String pharmacyId) =>
      '/medication-request/pharmacy/$pharmacyId/history';
  static String respondToRequest(String requestId) =>
      '/medication-request/$requestId/respond';
  static String markAsPickedUp(String requestId) =>
      '/medication-request/$requestId/pickup';
  static String cancelMedicationRequest(String requestId) =>
      '/medication-request/$requestId/cancel';
  static const String medicationRequestPatient = '/medication-request/patient';
  static const String medicationRequestMy = '/medication-request/patient/my';

  // Complaints Endpoints
  static const String complaints = '/complaints';
  static const String myComplaints = '/complaints/my';

  // Pharmacy Dashboard Endpoints
  static String pharmacyDashboard(String pharmacyId) =>
      '/pharmaciens/$pharmacyId/dashboard';
  static String pharmacyStats(String pharmacyId) =>
      '/pharmaciens/$pharmacyId/stats';
  static String monthlyStats(String pharmacyId) =>
      '/pharmaciens/$pharmacyId/stats/monthly';

  // Activity Feed
  static String activityFeed(String pharmacyId) =>
      '/activity/pharmacy/$pharmacyId/feed';

  // Reviews
  static String reviewSummary(String pharmacyId) =>
      '/review/pharmacy/$pharmacyId/summary';

  // Boost
  static String activeBoost(String pharmacyId) =>
      '/boost/pharmacy/$pharmacyId/active';

  // 🎮 Gamification Endpoints (PHARMACY ONLY)
  static String pointsStats(String pharmacyId) =>
      '/pharmaciens/$pharmacyId/points/stats';
  static String pointsRanking(String pharmacyId) =>
      '/pharmaciens/$pharmacyId/points/ranking';
  static String pointsHistoryToday(String pharmacyId) =>
      '/pharmaciens/$pharmacyId/points/history/today';
  static const String badgeThresholds = '/pharmaciens/points/badges';
  static const String createRating = '/ratings';

  // ─── AI Chat Endpoints (Patient) ───
  static const String aiChat = '/ai-chat';

  // ─── AI Food Analyzer Endpoints (Patient) ───
  static const String aiFoodAnalyzer = '/ai-food-analyzer';

  // ─── AI Prediction Endpoints (Patient) ───
  static const String aiPrediction = '/ai-prediction';
  static String aiPredictionPostMeal(String mealId) =>
      '/ai-prediction/post-meal/$mealId';
  static const String aiPredictionHistory = '/ai-prediction/history';
  static String aiPredictionDetail(String id) => '/ai-prediction/$id';

  // ─── AI Doctor Endpoints (Medecin) ───
  static String aiDoctorChatPatient(String patientId) =>
      '/ai-doctor/chat/$patientId';
  static const String aiDoctorChatAll = '/ai-doctor/chat';
  static const String aiDoctorUrgent = '/ai-doctor/urgent';
  static const String aiDoctorHistory = '/ai-doctor/history';
  static String aiDoctorMedicalReport(String patientId) =>
      '/ai-doctor/report/$patientId';

  // ─── Doctor Boost Endpoints (Medecin) ───
  static const String doctorBoostPlans = '/medecins/boost/plans';
  static const String doctorBoostMe = '/medecins/boost/me';
  static const String doctorBoostVerifyLatest = '/medecins/boost/verify-latest';
  static String doctorBoostStatus(String doctorId) =>
      '/medecins/$doctorId/boost/status';
  static String doctorBoostActivate(String doctorId) =>
      '/medecins/$doctorId/boost/activate';

  // ─── AI Pattern Endpoints (Patient) ───
  static const String aiPattern = '/ai-pattern';
  static const String aiPatternLatest = '/ai-pattern/latest';
  static const String aiPatternHistory = '/ai-pattern/history';
  static String aiPatternDetail(String id) => '/ai-pattern/$id';

  // Default Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Auth Headers
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
