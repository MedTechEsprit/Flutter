import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/models/patient_model.dart';

class PatientService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final _tokenService = TokenService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get doctor's patients list with filters
  Future<PatientListResponse> getDoctorPatients({
    required String doctorId,
    int page = 1,
    int limit = 100,
    String status = 'all',
    String? search,
  }) async {
    try {
      print('📋 [PatientService] getDoctorPatients called');
      print('   Doctor ID: $doctorId');
      print('   Page: $page, Limit: $limit');
      print('   Status filter: $status');
      if (search != null) print('   Search query: $search');

      final headers = await _getHeaders();

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'status': status,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('$baseUrl/api/medecins/$doctorId/my-patients')
          .replace(queryParameters: queryParams);

      print('   Request URL: $uri');

      final response = await http.get(uri, headers: headers);

      print('   Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('   Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

        final result = PatientListResponse.fromJson(data);
        print('✅ Successfully loaded ${result.data.length} patients');
        print('   Total: ${result.total}');
        print('   Status counts: Stable=${result.statusCounts.stable}, Attention=${result.statusCounts.attention}, Critical=${result.statusCounts.critical}');

        return result;
      } else {
        print('❌ Error response: ${response.statusCode}');
        print('   Body: ${response.body}');

        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to load patients');
      }
    } catch (e) {
      print('❌ Exception in getDoctorPatients: $e');
      rethrow;
    }
  }

  /// Search patients by name or email
  Future<List<PatientModel>> searchPatients({
    required String doctorId,
    required String query,
  }) async {
    try {
      print('🔍 [PatientService] searchPatients called');
      print('   Doctor ID: $doctorId');
      print('   Query: $query');

      final result = await getDoctorPatients(
        doctorId: doctorId,
        search: query,
        limit: 50,
      );

      return result.data;
    } catch (e) {
      print('❌ Error searching patients: $e');
      rethrow;
    }
  }
}

