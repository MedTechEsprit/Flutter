import 'dart:io';

class ApiConstants {
  // Base URL Configuration
  // Pour émulateur Android: utilisez 10.0.2.2 (qui pointe vers localhost de la machine hôte)
  // Pour appareil physique: utilisez l'adresse IP de votre machine (ex: 192.168.1.X)
  // Pour iOS simulator: localhost fonctionne

  static String get baseUrl {
    // Détection automatique de la plateforme
    if (Platform.isAndroid) {
      // 10.0.2.2 est l'alias pour localhost sur l'émulateur Android
      return 'http://10.0.2.2:3001/api';
    } else {
      // iOS simulator ou desktop peut utiliser localhost
      return 'http://localhost:3001/api';
    }
  }

  // Si vous testez sur un appareil physique, remplacez par l'IP de votre PC
  // static const String baseUrl = 'http://192.168.1.XXX:3001/api';

  // Authentication Endpoints
  static const String login = '/auth/login';

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

