import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

class DoctorService {
  String get baseUrl => ApiConstants.serverBaseUrl;
  final TokenService _tokenService = TokenService();
  final Duration _timeout = const Duration(seconds: 30);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/medecins/:id - Get doctor details
  Future<Map<String, dynamic>> getDoctorProfile(String doctorId) async {
    try {
      print('👨‍⚕️ [DoctorService] getDoctorProfile called');
      print('   Doctor ID: $doctorId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/medecins/$doctorId');

      print('   Request URL: $uri');

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Doctor profile loaded successfully');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to load doctor profile');
      }
    } catch (e) {
      print('❌ Error loading doctor profile: $e');
      throw Exception('Erreur: $e');
    }
  }

  /// GET /api/medecins/:id/status - Get doctor account status
  /// Returns: { statutCompte, isActive, _id, nom, prenom, email }
  Future<Map<String, dynamic>> getDoctorStatus(String doctorId) async {
    try {
      print('📊 [DoctorService] getDoctorStatus called');
      print('   Doctor ID: $doctorId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/medecins/$doctorId/status');

      print('   Request URL: $uri');

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Doctor status loaded successfully');
        print('   statutCompte: ${data['statutCompte']}');
        print('   isActive: ${data['isActive']}');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to load doctor status');
      }
    } catch (e) {
      print('❌ Error loading doctor status: $e');
      throw Exception('Erreur: $e');
    }
  }

  /// PATCH /api/medecins/:id/toggle-status - Toggle doctor account status (ACTIF <-> INACTIF)
  /// Returns updated doctor object with new statutCompte
  Future<Map<String, dynamic>> toggleDoctorStatus(String doctorId) async {
    try {
      print('🔄 [DoctorService] toggleDoctorStatus called');
      print('   Doctor ID: $doctorId');

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/medecins/$doctorId/toggle-status');

      print('   Request URL: $uri');

      final response = await http
          .patch(uri, headers: headers)
          .timeout(_timeout);

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Doctor status toggled successfully');
        print('   New status: ${data['statutCompte']}');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to toggle doctor status');
      }
    } catch (e) {
      print('❌ Error toggling doctor status: $e');
      throw Exception('Erreur: $e');
    }
  }

  Future<Map<String, dynamic>> updateDoctorProfile(
    String doctorId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/medecins/$doctorId');

      final response = await http
          .patch(uri, headers: headers, body: jsonEncode(updates))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Échec de mise à jour du profil');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // ignore: unused_element
  Exception _handleError(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return Exception('Pas de connexion Internet');
    } else if (e.toString().contains('TimeoutException')) {
      return Exception('Délai d\'attente dépassé');
    } else {
      return Exception('Erreur: $e');
    }
  }
}
