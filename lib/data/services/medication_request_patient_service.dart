import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

class MedicationRequestPatientService {
  final TokenService _tokenService = TokenService();

  Future<List<Map<String, dynamic>>> fetchMyRequests() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) return [];

      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.medicationRequestMy}',
            ),
            headers: ApiConstants.authHeaders(token),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }

      debugPrint(
        'Medication requests list error: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      debugPrint('Medication requests list exception: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createMedicationRequest({
    required String medicationName,
    required String dosage,
    required int quantity,
    String? format,
    String? urgencyLevel,
    String? patientNote,
    required List<String> targetPharmacyIds,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifie'};
      }

      final body = {
        'medicationName': medicationName,
        'dosage': dosage,
        'quantity': quantity,
        if (format != null && format.trim().isNotEmpty) 'format': format,
        if (urgencyLevel != null && urgencyLevel.trim().isNotEmpty)
          'urgencyLevel': urgencyLevel,
        if (patientNote != null && patientNote.trim().isNotEmpty)
          'patientNote': patientNote,
        'targetPharmacyIds': targetPharmacyIds,
      };

      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.medicationRequestPatient}',
            ),
            headers: ApiConstants.authHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      }

      debugPrint(
        'Medication request error: ${response.statusCode} ${response.body}',
      );
      return {
        'success': false,
        'message': 'Erreur ${response.statusCode}',
        'details': response.body,
      };
    } catch (e) {
      debugPrint('Medication request exception: $e');
      return {'success': false, 'message': 'Erreur reseau: $e'};
    }
  }
}
