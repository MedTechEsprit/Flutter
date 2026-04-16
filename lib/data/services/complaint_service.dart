import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

class ComplaintService {
  final TokenService _tokenService = TokenService();

  Future<Map<String, String>> _headers() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> createComplaint({
    required String subject,
    required String message,
    required String category,
  }) async {
    final headers = await _headers();
    final uri = Uri.parse(
      '${ApiConstants.serverBaseUrl}/api${ApiConstants.complaints}',
    );

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'subject': subject,
        'message': message,
        'category': category,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Échec envoi réclamation: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getMyComplaints() async {
    final headers = await _headers();
    final uri = Uri.parse(
      '${ApiConstants.serverBaseUrl}/api${ApiConstants.myComplaints}',
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Échec chargement réclamations: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }
}