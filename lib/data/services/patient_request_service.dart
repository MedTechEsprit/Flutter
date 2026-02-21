// Patient Request Service for Flutter
// Location: lib/data/services/patient_request_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/patient_request_model.dart';
import '../../core/services/token_service.dart';

class PatientRequestService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const Duration _timeout = Duration(seconds: 10);

  final TokenService _tokenService = TokenService();

  Future<String?> _getToken() async {
    return await _tokenService.getToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Exception _handleError(dynamic e) {
    if (e is SocketException) {
      return Exception('Server unreachable. Check backend connection.');
    } else if (e is TimeoutException) {
      return Exception('Request timeout. Server not responding.');
    }
    return Exception('Error: $e');
  }

  // 1. GET /api/doctors/:doctorId/patient-requests - Get pending patient requests
  Future<List<PatientRequestModel>> getPatientRequests(String doctorId) async {
    try {
      print('📋 [PatientRequestService] getPatientRequests called');
      print('   Doctor ID: $doctorId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/doctors/$doctorId/patient-requests');

      print('   Request URL: $uri');

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final requests = data.map((json) => PatientRequestModel.fromJson(json)).toList();
        print('✅ Successfully loaded ${requests.length} patient requests');
        return requests;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to load patient requests');
      }
    } catch (e) {
      print('❌ Error loading patient requests: $e');
      throw _handleError(e);
    }
  }

  // 2. POST /api/doctors/:id/patient-requests/:requestId/accept - Accept patient request
  Future<PatientRequestModel> acceptPatientRequest(String doctorId, String requestId) async {
    try {
      print('✅ [PatientRequestService] acceptPatientRequest called');
      print('   Doctor ID: $doctorId');
      print('   Request ID: $requestId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/doctors/$doctorId/patient-requests/$requestId/accept');

      print('   Request URL: $uri');

      final response = await http.post(uri, headers: headers).timeout(_timeout);

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Patient request accepted successfully');

        // Note: After acceptance, backend returns patientId as string, not object
        // We don't need to parse it as PatientRequestModel since we just reload the list
        return PatientRequestModel(
          id: data['_id'],
          patientId: PatientInfo(
            id: data['patientId'].toString(), // Convert to string in case it's already string
            nom: '',
            prenom: '',
            email: '',
            role: 'PATIENT',
          ),
          doctorId: data['doctorId'],
          status: data['status'],
          requestDate: data['requestDate'],
          urgentNote: data['urgentNote'],
          createdAt: data['createdAt'],
          updatedAt: data['updatedAt'],
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to accept patient request');
      }
    } catch (e) {
      print('❌ Error accepting patient request: $e');
      throw _handleError(e);
    }
  }

  // 3. POST /api/doctors/:id/patient-requests/:requestId/decline - Decline patient request
  Future<PatientRequestModel> declinePatientRequest(
    String doctorId,
    String requestId, {
    String? declineReason,
  }) async {
    try {
      print('❌ [PatientRequestService] declinePatientRequest called');
      print('   Doctor ID: $doctorId');
      print('   Request ID: $requestId');
      print('   Decline reason: $declineReason');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/doctors/$doctorId/patient-requests/$requestId/decline');

      // Backend requires declineReason field, use default if not provided
      final body = <String, dynamic>{
        'declineReason': (declineReason != null && declineReason.isNotEmpty)
            ? declineReason
            : 'No reason provided',
      };

      print('   Request URL: $uri');
      print('   Body: $body');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeout);

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Patient request declined successfully');

        // Note: After decline, backend returns patientId as string, not object
        // We don't need to parse it as PatientRequestModel since we just reload the list
        return PatientRequestModel(
          id: data['_id'],
          patientId: PatientInfo(
            id: data['patientId'].toString(),
            nom: '',
            prenom: '',
            email: '',
            role: 'PATIENT',
          ),
          doctorId: data['doctorId'],
          status: data['status'],
          requestDate: data['requestDate'],
          urgentNote: data['urgentNote'],
          createdAt: data['createdAt'],
          updatedAt: data['updatedAt'],
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to decline patient request');
      }
    } catch (e) {
      print('❌ Error declining patient request: $e');
      throw _handleError(e);
    }
  }
}

