import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

class MedicationRequestPatientService {
  final TokenService _tokenService = TokenService();

  Future<List<Map<String, dynamic>>> fetchNearbyPharmacies({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/pharmaciens/nearby').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
          'radius': radiusKm.toString(),
        },
      );

      final response = await http
          .get(uri, headers: ApiConstants.defaultHeaders)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }

      debugPrint('Nearby pharmacies error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Nearby pharmacies exception: $e');
      return [];
    }
  }

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
    List<String>? targetPharmacyIds,
    double? patientLatitude,
    double? patientLongitude,
    double? radiusKm,
    String? medicationId,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifie'};
      }

      final body = {
        'medicationName': medicationName,
        if (medicationId != null && medicationId.trim().isNotEmpty)
          'medicationId': medicationId,
        'dosage': dosage,
        'quantity': quantity,
        if (format != null && format.trim().isNotEmpty) 'format': format,
        if (urgencyLevel != null && urgencyLevel.trim().isNotEmpty)
          'urgencyLevel': urgencyLevel,
        if (patientNote != null && patientNote.trim().isNotEmpty)
          'patientNote': patientNote,
        if (targetPharmacyIds != null && targetPharmacyIds.isNotEmpty)
          'targetPharmacyIds': targetPharmacyIds,
        if (patientLatitude != null) 'patientLatitude': patientLatitude,
        if (patientLongitude != null) 'patientLongitude': patientLongitude,
        if (radiusKm != null) 'radiusKm': radiusKm,
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
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return {
            'success': true,
            'request': decoded['request'] ?? decoded,
            'contactedPharmacies':
                (decoded['contactedPharmacies'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                <Map<String, dynamic>>[],
            'radiusKm': decoded['radiusKm'],
          };
        }
        return {'success': true, 'contactedPharmacies': <Map<String, dynamic>>[]};
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

  Future<Map<String, dynamic>> cancelRequest(String requestId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifie'};
      }

      final response = await http
          .put(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.cancelMedicationRequest(requestId)}',
            ),
            headers: ApiConstants.authHeaders(token),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return {'success': true};
      }

      String message = 'Erreur ${response.statusCode}';
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            final raw = decoded['message'];
            if (raw is List) {
              message = raw.join(', ');
            } else {
              message = raw.toString();
            }
          }
        } catch (_) {}
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erreur reseau: $e'};
    }
  }

}
