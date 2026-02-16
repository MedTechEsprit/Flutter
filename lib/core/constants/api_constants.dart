import 'dart:io';

class ApiConstants {
  // Base URL Configuration
  // Pour émulateur Android: utilisez 10.0.2.2 (qui pointe vers localhost de la machine hôte)
  // Pour appareil physique: utilisez l'adresse IP de votre machine (ex: 192.168.1.X)
  // Pour iOS simulator: localhost fonctionne

  static String get baseUrl {
    // Détection automatique de la plateforme
    if (Platform.isAndroid) {
      // IP locale du PC pour test sur téléphone physique
      return 'http://174.20.1.16:3000/api';
    } else {
      // iOS simulator ou desktop peut utiliser localhost
      return 'http://localhost:3000/api';
    }
  }

  // Si vous testez sur un appareil physique, remplacez par l'IP de votre PC
  // static const String baseUrl = 'http://192.168.1.XXX:3000/api';

  // Authentication Endpoints
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';

  // Patient Endpoints
  static const String patients = '/patients';
  static String patientById(String id) => '/patients/$id';

  // Glucose Endpoints
  static const String glucose = '/glucose';
  static const String glucoseMyRecords = '/glucose/my-records';
  static String glucoseDateRange(String start, String end) => '/glucose/range?startDate=$start&endDate=$end';
  static const String glucoseWeeklyStats = '/glucose/stats/weekly';
  static const String glucoseMonthlyStats = '/glucose/stats/monthly';
  static const String glucoseDailyAverages = '/glucose/stats/daily-averages';
  static const String glucoseAlerts = '/glucose/alerts';
  static const String glucoseEstimatedHba1c = '/glucose/stats/estimated-hba1c';
  static const String glucoseTimeInRange = '/glucose/stats/time-in-range';
  static String glucoseDelete(String id) => '/glucose/$id';

  // Medecin Endpoints
  static const String medecins = '/medecins';
  static String medecinById(String id) => '/medecins/$id';
  static String rateMedecin(String id) => '/medecins/$id/noter';

  // Pharmacien Endpoints
  static const String pharmaciens = '/pharmaciens';
  static String pharmacienById(String id) => '/pharmaciens/$id';

  // Nutrition Endpoints
  static const String meals = '/nutrition/meals';
  static const String dailyCarbs = '/nutrition/daily-carbs';

  // Medication Requests Endpoints
  static String pendingRequests(String pharmacyId) => '/medication-request/pharmacy/$pharmacyId/pending';
  static String requestHistory(String pharmacyId) => '/medication-request/pharmacy/$pharmacyId/history';
  static String respondToRequest(String requestId) => '/medication-request/$requestId/respond';
  static String markAsPickedUp(String requestId) => '/medication-request/$requestId/pickup';

  // Pharmacy Dashboard Endpoints
  static String pharmacyDashboard(String pharmacyId) => '/pharmaciens/$pharmacyId/dashboard';
  static String pharmacyStats(String pharmacyId) => '/pharmaciens/$pharmacyId/stats';
  static String monthlyStats(String pharmacyId) => '/pharmaciens/$pharmacyId/stats/monthly';

  // Activity Feed
  static String activityFeed(String pharmacyId) => '/activity/pharmacy/$pharmacyId/feed';

  // Reviews
  static String reviewSummary(String pharmacyId) => '/review/pharmacy/$pharmacyId/summary';

  // Boost
  static String activeBoost(String pharmacyId) => '/boost/pharmacy/$pharmacyId/active';

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

