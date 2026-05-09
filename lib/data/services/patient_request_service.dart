// Patient Request Service for Flutter
// Location: lib/data/services/patient_request_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import '../models/patient_request_model.dart';
import '../../core/services/token_service.dart';

class PatientRequestService {
  String get baseUrl => ApiConstants.serverBaseUrl;
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
          requestType: data['requestType']?.toString() ?? 'patient_link',
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
          requestType: data['requestType']?.toString() ?? 'patient_link',
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

  // 4. POST /api/patients/:patientId/request-doctor - Create patient request to doctor
  Future<bool> createPatientRequest({
    required String patientId,
    required String doctorId,
    String? urgentNote,
    String requestType = 'patient_link',
  }) async {
    try {
      print('📤 [PatientRequestService] createPatientRequest');
      print('   Patient ID: $patientId → Doctor ID: $doctorId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/patients/$patientId/request-doctor');

      final body = <String, dynamic>{'doctorId': doctorId};
      if (urgentNote != null && urgentNote.isNotEmpty) {
        body['urgentNote'] = urgentNote;
      }
      body['requestType'] = requestType;

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeout);

      print('   Response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Patient request created');
        return true;
      } else {
        final error = jsonDecode(response.body);
        final msg = error['message'] ?? 'Failed to create request';
        print('❌ $msg');
        throw Exception(msg);
      }
    } catch (e) {
      print('❌ Error creating patient request: $e');
      throw _handleError(e);
    }
  }

  // 5. GET /api/patients/:patientId/my-requests - Get patient's sent requests
  Future<List<Map<String, dynamic>>> getMyRequests(String patientId) async {
    try {
      print('📋 [PatientRequestService] getMyRequests for $patientId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/patients/$patientId/my-requests');

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      print('   Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Got ${data.length} requests');
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load requests');
      }
    } catch (e) {
      print('❌ Error loading my requests: $e');
      throw _handleError(e);
    }
  }

  // 6. GET /api/glucose/patient/:patientId/records - Get patient glucose records (doctor)
  Future<List<Map<String, dynamic>>> getPatientGlucoseRecords(String patientId) async {
    try {
      print('📊 [PatientRequestService] getPatientGlucoseRecords for $patientId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/glucose/patient/$patientId/records?page=1&limit=100');

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      print('   Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        print('✅ Got ${data.length} glucose records');
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error loading glucose records: $e');
      return [];
    }
  }

  // 7. GET /api/patients/:id - Get patient full profile (doctor)
  Future<Map<String, dynamic>?> getPatientProfile(String patientId) async {
    try {
      print('👤 [PatientRequestService] getPatientProfile for $patientId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/patients/$patientId');

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      print('   Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error loading patient profile: $e');
      return null;
    }
  }

  Future<bool> getDoctorAccessStatusForDoctor({
    required String doctorId,
    required String patientId,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/doctors/$doctorId/patients/$patientId/access-status');
      final response = await http.get(uri, headers: headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['enabled'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> getDoctorAccessStatusForPatient({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/patients/$patientId/doctors/$doctorId/access-status');
      final response = await http.get(uri, headers: headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['enabled'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setDoctorAccessByPatient({
    required String patientId,
    required String doctorId,
    required bool enabled,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/api/patients/$patientId/doctors/$doctorId/access');
    final response = await http.patch(
      uri,
      headers: headers,
      body: jsonEncode({'enabled': enabled}),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['enabled'] == true;
    }

    String message = 'Impossible de modifier l\'autorisation';
    try {
      final data = jsonDecode(response.body);
      final raw = data is Map<String, dynamic> ? data['message'] : null;
      if (raw is List && raw.isNotEmpty) {
        message = raw.first.toString();
      } else if (raw != null) {
        message = raw.toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  Future<bool> requestDoctorAccess({
    required String doctorId,
    required String patientId,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/api/doctors/$doctorId/patients/$patientId/request-access');

    final response = await http.post(uri, headers: headers).timeout(_timeout);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    String message = 'Impossible d\'envoyer la demande';
    try {
      final data = jsonDecode(response.body);
      final raw = data is Map<String, dynamic> ? data['message'] : null;
      if (raw is List && raw.isNotEmpty) {
        message = raw.first.toString();
      } else if (raw != null) {
        message = raw.toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  Future<List<Map<String, dynamic>>> getPendingDoctorAccessRequests(String patientId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/api/patients/$patientId/pending-doctor-access-requests');
    final response = await http.get(uri, headers: headers).timeout(_timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> respondDoctorAccessRequest({
    required String patientId,
    required String requestId,
    required bool accept,
    String? declineReason,
  }) async {
    final headers = await _getHeaders();
    final path = accept
        ? '$baseUrl/api/patients/$patientId/doctor-access-requests/$requestId/accept'
        : '$baseUrl/api/patients/$patientId/doctor-access-requests/$requestId/decline';

    final response = await http.post(
      Uri.parse(path),
      headers: headers,
      body: accept ? null : jsonEncode({'declineReason': declineReason ?? 'Refusée par le patient'}),
    ).timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Impossible de répondre à la demande');
    }
  }
}