// Appointment Service for Flutter
// Location: lib/data/services/appointment_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/appointment_model.dart';
import '../../core/services/token_service.dart';

class AppointmentService {
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

  // Helper to handle errors consistently
  Exception _handleError(dynamic e) {
    if (e is SocketException) {
      return Exception('Serveur inaccessible. Vérifiez que le backend tourne sur le port 3000.');
    } else if (e is TimeoutException) {
      return Exception('Délai dépassé. Le serveur ne répond pas.');
    }
    return Exception('Erreur: $e');
  }

  // 1. POST /api/appointments - Create new appointment
  Future<AppointmentModel> createAppointment({
    required String patientId,
    required String doctorId,
    required DateTime dateTime,
    required AppointmentType type,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/appointments'),
        headers: headers,
        body: jsonEncode({
          'patientId': patientId,
          'doctorId': doctorId,
          'dateTime': dateTime.toIso8601String(),
          'type': type.name,
          if (notes != null) 'notes': notes,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppointmentModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create appointment');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 2. GET /api/appointments/doctor/:doctorId - Get doctor's appointments
  Future<List<AppointmentModel>> getDoctorAppointments(
    String doctorId, {
    AppointmentStatus? status,
  }) async {
    try {
      print('📡 [AppointmentService] getDoctorAppointments called');
      print('   Doctor ID: $doctorId');
      print('   Status filter: ${status?.name ?? "none"}');

      final headers = await _getHeaders();
      print('   Headers: ${headers.keys.join(", ")}');

      // Add pagination parameters to get more results
      // Note: Do NOT add status to query params - backend rejects it
      final queryParams = <String, String>{
        'page': '1',
        'limit': '100', // Get up to 100 appointments
      };
      // Backend doesn't accept status in query string - we'll filter client-side
      // if (status != null) queryParams['status'] = status.name;

      final uri = Uri.parse('$baseUrl/api/appointments/doctor/$doctorId')
          .replace(queryParameters: queryParams);

      print('   Request URL: $uri');

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      print('   Response status: ${response.statusCode}');
      print('   Response body preview: ${response.body.substring(0, min(200, response.body.length))}...');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle both array response and paginated response {data: [...], total: X}
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          data = responseData['data'] as List<dynamic>;
        } else {
          throw Exception('Unexpected response format');
        }

        print('✅ Successfully parsed ${data.length} appointments');

        final appointments = data.map((json) {
          try {
            return AppointmentModel.fromJson(json);
          } catch (e) {
            print('❌ Error parsing appointment: $e');
            print('   JSON: $json');
            rethrow;
          }
        }).toList();

        // Filter by status on client side if needed (backend doesn't accept status param)
        if (status != null) {
          final filtered = appointments.where((apt) => apt.status == status).toList();
          print('✅ Filtered ${appointments.length} appointments to ${filtered.length} with status ${status.name}');
          return filtered;
        }

        return appointments;
      } else {
        print('❌ Error response: ${response.statusCode}');
        print('   Body: ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get appointments');
      }
    } catch (e) {
      print('❌ Exception in getDoctorAppointments: $e');
      throw _handleError(e);
    }
  }

  // 3. GET /api/appointments/doctor/:doctorId/upcoming - Get doctor's upcoming appointments
  Future<List<AppointmentModel>> getDoctorUpcomingAppointments(String doctorId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/appointments/doctor/$doctorId/upcoming'),
        headers: headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AppointmentModel.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get upcoming appointments');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 4. GET /api/appointments/doctor/:doctorId/stats - Get doctor's statistics
  Future<AppointmentStats> getDoctorStats(String doctorId) async {
    try {
      print('📊 [AppointmentService] getDoctorStats called');
      print('   Doctor ID: $doctorId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/appointments/doctor/$doctorId/stats');

      print('   Request URL: $uri');

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('   Parsed data: $data');

        final stats = AppointmentStats.fromJson(data);
        print('✅ Stats loaded successfully');
        print('   Total: ${stats.total}');
        print('   Pending: ${stats.pendingCount}');
        print('   Confirmed: ${stats.confirmedCount}');
        print('   Completed: ${stats.completedCount}');
        print('   Cancelled: ${stats.cancelledCount}');

        return stats;
      } else {
        print('❌ Error response: ${response.statusCode}');
        print('   Body: ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get appointment stats');
      }
    } catch (e) {
      print('❌ Exception in getDoctorStats: $e');
      throw _handleError(e);
    }
  }

  // 5. GET /api/appointments/patient/:patientId - Get patient's appointments
  Future<List<AppointmentModel>> getPatientAppointments(
    String patientId, {
    AppointmentStatus? status,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.name;
      final uri = Uri.parse('$baseUrl/api/appointments/patient/$patientId')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AppointmentModel.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get appointments');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 6. GET /api/appointments/:id - Get single appointment
  Future<AppointmentModel> getAppointmentById(String appointmentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/appointments/$appointmentId'),
        headers: headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppointmentModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get appointment');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 7. PATCH /api/appointments/:id - Update appointment (all fields)
  Future<AppointmentModel> updateAppointment(
    String appointmentId, {
    DateTime? dateTime,
    AppointmentType? type,
    AppointmentStatus? status,
    String? notes,
  }) async {
    try {
      print('✏️ [AppointmentService] updateAppointment called');
      print('   Appointment ID: $appointmentId');
      final headers = await _getHeaders();
      final body = <String, dynamic>{};

      // Add all fields that are provided
      if (dateTime != null) body['dateTime'] = dateTime.toIso8601String();
      if (type != null) body['type'] = type.name;
      if (status != null) body['status'] = status.name;
      if (notes != null) body['notes'] = notes;

      print('   Body: $body');
      final response = await http.patch(
        Uri.parse('$baseUrl/api/appointments/$appointmentId'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeout);
      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Appointment updated successfully');
        return AppointmentModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update appointment');
      }
    } catch (e) {
      print('❌ Error updating appointment: $e');
      throw _handleError(e);
    }
  }

  // 8. DELETE /api/appointments/:id - Delete appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      print('🗑️ [AppointmentService] deleteAppointment called');
      print('   Appointment ID: $appointmentId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/appointments/$appointmentId');
      print('   Request URL: $uri');

      final response = await http.delete(uri, headers: headers).timeout(_timeout);

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Appointment deleted successfully');
        return;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete appointment');
      }
    } catch (e) {
      print('❌ Error deleting appointment: $e');
      throw _handleError(e);
    }
  }

  // ============= HELPER METHODS =============

  // Helper method: Confirm appointment (shorthand for update)
  Future<AppointmentModel> confirmAppointment(String appointmentId) async {
    return updateAppointment(appointmentId, status: AppointmentStatus.CONFIRMED);
  }

  // Helper method: Cancel appointment (shorthand for update)
  Future<AppointmentModel> cancelAppointment(String appointmentId) async {
    return updateAppointment(appointmentId, status: AppointmentStatus.CANCELLED);
  }

  // Helper method: Complete appointment (shorthand for update)
  Future<AppointmentModel> completeAppointment(String appointmentId) async {
    return updateAppointment(appointmentId, status: AppointmentStatus.COMPLETED);
  }

  // Helper method: Get patient's upcoming appointments (filtered client-side)
  Future<List<AppointmentModel>> getPatientUpcomingAppointments(String patientId) async {
    final appointments = await getPatientAppointments(patientId);
    final now = DateTime.now();
    return appointments
        .where((apt) =>
            apt.dateTime.isAfter(now) &&
            (apt.status == AppointmentStatus.PENDING || apt.status == AppointmentStatus.CONFIRMED))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Helper method: Get patient's confirmed appointments
  Future<List<AppointmentModel>> getPatientConfirmedAppointments(String patientId) async {
    return getPatientAppointments(patientId, status: AppointmentStatus.CONFIRMED);
  }

  // Helper method: Get doctor's pending appointments
  Future<List<AppointmentModel>> getDoctorPendingAppointments(String doctorId) async {
    return getDoctorAppointments(doctorId, status: AppointmentStatus.PENDING);
  }
}
