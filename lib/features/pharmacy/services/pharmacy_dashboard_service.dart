import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/features/pharmacy/models/pharmacy_api_models.dart';
import 'package:diab_care/core/services/token_service.dart';

class PharmacyDashboardService {
  final TokenService _tokenService = TokenService();

  /// Load complete dashboard data
  /// GET /pharmaciens/{pharmacyId}/dashboard
  Future<PharmacyDashboardModel?> loadDashboard() async {
    try {
      debugPrint('🔄 PharmacyDashboardService.loadDashboard() appelé');

      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      debugPrint('🔑 Token: ${token != null ? "Present (${token.length} chars)" : "NULL"}');
      debugPrint('🆔 PharmacyId: $pharmacyId');

      if (token == null || pharmacyId == null) {
        debugPrint('❌ Token ou PharmacyId manquant!');
        throw Exception('Non authentifié');
      }

      final url = '${ApiConstants.baseUrl}${ApiConstants.pharmacyDashboard(pharmacyId)}';
      debugPrint('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
      );

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        debugPrint('✅ Dashboard chargé avec succès');
        final data = jsonDecode(response.body);
        debugPrint('📄 Data keys: ${data.keys.toList()}');
        debugPrint('📊 Pharmacy points: ${data['pharmacy']?['points']}');
        debugPrint('📊 Total requests: ${data['stats']?['totalRequestsReceived']}');
        debugPrint('📊 Accepted: ${data['stats']?['totalRequestsAccepted']}');
        debugPrint('📊 Declined: ${data['stats']?['totalRequestsDeclined']}');
        final model = PharmacyDashboardModel.fromJson(data);
        debugPrint('✅ Model created successfully');
        return model;
      } else if (response.statusCode == 401) {
        debugPrint('❌ 401 Unauthorized');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        debugPrint('❌ Erreur: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception dans loadDashboard: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Load dashboard with direct token and pharmacyId (no storage lookup)
  Future<PharmacyDashboardModel?> loadDashboardDirect({
    required String token,
    required String pharmacyId,
  }) async {
    try {
      debugPrint('🔄 PharmacyDashboardService.loadDashboardDirect() appelé');
      debugPrint('🔑 Token: Present (${token.length} chars)');
      debugPrint('🆔 PharmacyId: $pharmacyId');

      final url = '${ApiConstants.baseUrl}${ApiConstants.pharmacyDashboard(pharmacyId)}';
      debugPrint('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
      );

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Dashboard chargé avec succès');
        final data = jsonDecode(response.body);
        debugPrint('📄 Data keys: ${data.keys.toList()}');
        return PharmacyDashboardModel.fromJson(data);
      } else if (response.statusCode == 401) {
        debugPrint('❌ 401 Unauthorized');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        debugPrint('❌ Erreur: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception dans loadDashboardDirect: $e');
      rethrow;
    }
  }

  /// Load basic stats only
  /// GET /pharmaciens/{id}/stats
  Future<DashboardStats?> loadBasicStats() async {
    try {
      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      if (token == null || pharmacyId == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.pharmacyStats(pharmacyId)}'),
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardStats.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Load monthly stats for charts
  /// GET /pharmaciens/{id}/stats/monthly
  Future<List<MonthlyStats>> loadMonthlyStats() async {
    try {
      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      if (token == null || pharmacyId == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.monthlyStats(pharmacyId)}'),
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((m) => MonthlyStats.fromJson(m)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Load activity feed
  /// GET /activity/pharmacy/{id}/feed
  Future<List<ApiActivityEvent>> loadActivityFeed() async {
    try {
      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      if (token == null || pharmacyId == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.activityFeed(pharmacyId)}'),
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((a) => ApiActivityEvent.fromJson(a)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Load review summary
  /// GET /review/pharmacy/{pharmacyId}/summary
  Future<Map<String, dynamic>?> loadReviewSummary() async {
    try {
      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      if (token == null || pharmacyId == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviewSummary(pharmacyId)}'),
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

