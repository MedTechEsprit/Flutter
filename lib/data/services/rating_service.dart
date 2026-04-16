import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

class RatingService {
  final TokenService _tokenService = TokenService();

  Future<void> createRating({
    required String pharmacyId,
    required String medicationRequestId,
    required int stars,
    required bool medicationAvailable,
    String? comment,
    int? speedRating,
    int? courtesyRating,
  }) async {
    final token = await _tokenService.getToken();
    final patientId = await _tokenService.getUserId();

    if (token == null || patientId == null) {
      throw Exception('Non authentifie');
    }

    final body = <String, dynamic>{
      'patientId': patientId,
      'pharmacyId': pharmacyId,
      'medicationRequestId': medicationRequestId,
      'stars': stars,
      'medicationAvailable': medicationAvailable,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
      if (speedRating != null) 'speedRating': speedRating,
      if (courtesyRating != null) 'courtesynRating': courtesyRating,
    };

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createRating}'),
      headers: ApiConstants.authHeaders(token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    if (response.body.isNotEmpty) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) {
          throw Exception(data['message'].toString());
        }
      } catch (_) {
        // Fall through to generic error
      }
    }

    throw Exception('Erreur lors de l\'envoi de l\'avis');
  }
}
