import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/features/auth/services/auth_service.dart';

/// Service API unifié pour toutes les données patient
/// Consomme les endpoints NestJS: patients, glucose, medecins, pharmaciens, nutrition
class PatientApiService {
  final AuthService _authService = AuthService();

  // Utilise la même baseUrl que AuthService + préfixe /api
  String get baseUrl => '${AuthService.baseUrl}/api';

  /// Headers avec token JWT
  Future<Map<String, String>> get _authHeaders async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFIL PATIENT
  // ═══════════════════════════════════════════════════════════════

  /// GET /api/auth/profile - Récupérer le profil connecté
  Future<Map<String, dynamic>> getProfile() async {
    debugPrint('👤 ========== GET PROFILE ==========');
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Profile status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      debugPrint('❌ getProfile error: $e');
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/patients/:id - Récupérer un patient par ID
  Future<Map<String, dynamic>> getPatientById(String patientId) async {
    debugPrint('👤 GET Patient: $patientId');
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// PATCH /api/patients/:id - Mettre à jour le profil patient
  Future<Map<String, dynamic>> updatePatient(String patientId, Map<String, dynamic> updates) async {
    debugPrint('✏️ UPDATE Patient: $patientId');
    try {
      final headers = await _authHeaders;
      final response = await http.patch(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: headers,
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Mettre à jour les données stockées
        await _authService.updateStoredUserData(data);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GLYCÉMIE (GLUCOSE)
  // ═══════════════════════════════════════════════════════════════

  /// POST /api/glucose - Ajouter une mesure de glycémie
  Future<Map<String, dynamic>> addGlucoseReading({
    required double value,
    required DateTime measuredAt,
    String? period,
    String? note,
  }) async {
    debugPrint('📊 ADD Glucose: $value mg/dL');
    try {
      final headers = await _authHeaders;
      final body = {
        'value': value,
        'measuredAt': measuredAt.toIso8601String(),
        if (period != null) 'period': period,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/glucose'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 addGlucose status: ${response.statusCode}');
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/glucose/my-records - Récupérer les mesures du patient connecté
  Future<Map<String, dynamic>> getMyGlucoseRecords({int page = 1, int limit = 50}) async {
    debugPrint('📊 GET My Glucose Records (page: $page, limit: $limit)');
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/glucose/my-records?page=$page&limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/glucose?start=...&end=... - Récupérer les mesures par période
  Future<Map<String, dynamic>> getGlucoseByDateRange(DateTime start, DateTime end) async {
    debugPrint('📊 GET Glucose range: $start -> $end');
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/glucose?start=${start.toIso8601String()}&end=${end.toIso8601String()}'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/glucose/stats/weekly - Stats hebdomadaires
  Future<Map<String, dynamic>> getWeeklyStats() async {
    debugPrint('📊 GET Weekly Stats');
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/glucose/stats/weekly'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/glucose/stats/monthly - Stats mensuelles
  Future<Map<String, dynamic>> getMonthlyStats() async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/glucose/stats/monthly'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/glucose/stats/daily-average - Moyennes quotidiennes
  Future<Map<String, dynamic>> getDailyAverages({int days = 30}) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/glucose/stats/daily-average?days=$days'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/glucose/stats/alerts - Alertes hypo/hyper
  Future<Map<String, dynamic>> getGlucoseAlerts() async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/glucose/stats/alerts'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/glucose/stats/hba1c - HbA1c estimé
  Future<Map<String, dynamic>> getEstimatedHba1c() async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/glucose/stats/hba1c'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/glucose/stats/time-in-range - Temps dans la cible
  Future<Map<String, dynamic>> getTimeInRange({int days = 30}) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/glucose/stats/time-in-range?days=$days'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// DELETE /api/glucose/:id - Supprimer une mesure
  Future<Map<String, dynamic>> deleteGlucoseReading(String id) async {
    try {
      final headers = await _authHeaders;
      final response = await http.delete(
        Uri.parse('$baseUrl/glucose/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MÉDECINS
  // ═══════════════════════════════════════════════════════════════

  /// GET /api/medecins - Liste des médecins
  Future<Map<String, dynamic>> getMedecins({int page = 1, int limit = 20, String? specialite}) async {
    debugPrint('🩺 GET Medecins (page: $page)');
    try {
      final headers = await _authHeaders;
      var url = '$baseUrl/medecins?page=$page&limit=$limit';
      if (specialite != null && specialite.isNotEmpty) {
        url += '&specialite=$specialite';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/medecins/:id - Détails d'un médecin
  Future<Map<String, dynamic>> getMedecinById(String id) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/medecins/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// PATCH /api/medecins/:id/note - Noter un médecin
  Future<Map<String, dynamic>> rateMedecin(String medecinId, double note) async {
    try {
      final headers = await _authHeaders;
      final response = await http.patch(
        Uri.parse('$baseUrl/medecins/$medecinId/note'),
        headers: headers,
        body: jsonEncode({'note': note}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PHARMACIES
  // ═══════════════════════════════════════════════════════════════

  /// GET /api/pharmaciens - Liste des pharmacies
  Future<Map<String, dynamic>> getPharmacies({int page = 1, int limit = 20}) async {
    debugPrint('💊 GET Pharmacies (page: $page)');
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/pharmaciens?page=$page&limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NUTRITION
  // ═══════════════════════════════════════════════════════════════

  /// GET /api/nutrition/meals - Récupérer les repas
  Future<Map<String, dynamic>> getMeals({int page = 1, int limit = 20}) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/nutrition/meals?page=$page&limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// POST /api/nutrition/meals - Créer un repas
  Future<Map<String, dynamic>> addMeal({
    required String name,
    required DateTime eatenAt,
    required double carbs,
    double? protein,
    double? fat,
    double? calories,
    String? note,
  }) async {
    try {
      final headers = await _authHeaders;
      final body = {
        'name': name,
        'eatenAt': eatenAt.toIso8601String(),
        'carbs': carbs,
        if (protein != null) 'protein': protein,
        if (fat != null) 'fat': fat,
        if (calories != null) 'calories': calories,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/nutrition/meals'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// GET /api/nutrition/stats/daily-carbs?date=YYYY-MM-DD
  Future<Map<String, dynamic>> getDailyCarbs(String date) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/nutrition/stats/daily-carbs?date=$date'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> _handleError(http.Response response) {
    debugPrint('❌ API Error ${response.statusCode}: ${response.body}');
    try {
      final body = jsonDecode(response.body);
      String message = 'Erreur serveur';
      if (body['message'] is List) {
        message = (body['message'] as List).join(', ');
      } else if (body['message'] is String) {
        message = body['message'];
      }
      return {'success': false, 'message': message, 'statusCode': response.statusCode};
    } catch (_) {
      return {'success': false, 'message': 'Erreur de communication', 'statusCode': response.statusCode};
    }
  }
}
