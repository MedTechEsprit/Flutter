import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/features/pharmacy/models/pharmacy_api_models.dart';
import 'package:diab_care/core/services/token_service.dart';

class MedicationRequestService {
  final TokenService _tokenService = TokenService();

  /// Fetch pending requests for current pharmacy
  /// GET /medication-request/pharmacy/{pharmacyId}/pending
  Future<List<MedicationRequestModel>> fetchPendingRequests() async {
    try {
      debugPrint('📋 ========== FETCHING PENDING REQUESTS ==========');

      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      debugPrint('🔑 Token: ${token != null ? "OK (${token.length} chars)" : "NULL"}');
      debugPrint('🆔 PharmacyId: $pharmacyId');

      if (token == null || pharmacyId == null) {
        debugPrint('❌ Token ou PharmacyId manquant!');
        throw Exception('Non authentifié');
      }

      final url = '${ApiConstants.baseUrl}${ApiConstants.pendingRequests(pharmacyId)}';
      debugPrint('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
      );

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ Reçu ${data.length} demande(s) en attente');

        // Return empty list if no requests
        if (data.isEmpty) {
          debugPrint('ℹ️ Aucune demande en attente');
          return [];
        }

        final requests = data.map((json) => MedicationRequestModel.fromJson(json)).toList();
        debugPrint('✅ Parsed ${requests.length} demande(s)');
        return requests;
      } else if (response.statusCode == 401) {
        debugPrint('❌ 401 Unauthorized - Token expiré');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        debugPrint('❌ Erreur ${response.statusCode}');
        throw Exception('Erreur lors du chargement: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
      rethrow;
    }
  }

  /// Fetch request history with filters
  /// GET /medication-request/pharmacy/{pharmacyId}/history
  Future<List<MedicationRequestModel>> fetchRequestHistory({
    int page = 1,
    int limit = 100,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? medicationName,
  }) async {
    try {
      debugPrint('📋 ========== FETCHING REQUEST HISTORY ==========');
      debugPrint('📋 Status filter: $status');

      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      debugPrint('🔑 Token: ${token != null ? "OK" : "NULL"}');
      debugPrint('🆔 PharmacyId: $pharmacyId');

      if (token == null || pharmacyId == null) {
        throw Exception('Non authentifié');
      }

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (medicationName != null) queryParams['medicationName'] = medicationName;

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.requestHistory(pharmacyId)}')
          .replace(queryParameters: queryParams);

      debugPrint('🌐 URL: $uri');

      final response = await http.get(
        uri,
        headers: ApiConstants.authHeaders(token),
      );

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response length: ${response.body.length}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Le endpoint retourne un objet paginé avec {data: [], total, page, limit, totalPages}
        List<dynamic> data;
        if (responseBody is Map && responseBody.containsKey('data')) {
          data = responseBody['data'] as List;
          debugPrint('✅ Found ${data.length} requests (paginated response)');
        } else if (responseBody is List) {
          data = responseBody;
          debugPrint('✅ Found ${data.length} requests (direct array)');
        } else {
          debugPrint('⚠️ Unexpected response format');
          return [];
        }

        if (data.isEmpty) {
          debugPrint('ℹ️ Aucune demande pour le statut: $status');
          return [];
        }

        final requests = data.map((json) => MedicationRequestModel.fromJson(json)).toList();
        debugPrint('✅ Parsed ${requests.length} demande(s) avec statut $status');

        // Filter by pharmacy response status
        if (status != null) {
          final filtered = requests.where((req) {
            final myResponse = req.getMyResponse(pharmacyId);
            if (myResponse == null) return false;
            return myResponse.status == status;
          }).toList();
          debugPrint('🔍 After filtering by pharmacy response: ${filtered.length} requests');
          return filtered;
        }

        return requests;
      } else if (response.statusCode == 401) {
        debugPrint('❌ 401 - Session expirée');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        debugPrint('❌ Erreur ${response.statusCode}');
        throw Exception('Erreur lors du chargement: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ fetchRequestHistory error: $e');
      rethrow;
    }
  }

  /// Respond to a medication request (accept/decline/ignore)
  /// PUT /medication-request/{requestId}/respond
  Future<Map<String, dynamic>> respondToRequest({
    required String requestId,
    required String status, // 'accepted', 'declined', 'ignored'
    double? indicativePrice,
    String? preparationDelay, // 'immediate', '30min', '1h', '2h', 'other'
    String? pharmacyMessage,
    DateTime? pickupDeadline,
  }) async {
    try {
      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      if (token == null || pharmacyId == null) {
        throw Exception('Non authentifié');
      }

      final body = <String, dynamic>{
        'pharmacyId': pharmacyId,
        'status': status,
      };

      if (indicativePrice != null) body['indicativePrice'] = indicativePrice;
      if (preparationDelay != null) body['preparationDelay'] = preparationDelay;
      if (pharmacyMessage != null) body['pharmacyMessage'] = pharmacyMessage;
      if (pickupDeadline != null) body['pickupDeadline'] = pickupDeadline.toIso8601String();

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.respondToRequest(requestId)}'),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Cette demande a expiré',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expirée. Veuillez vous reconnecter.',
          'sessionExpired': true,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Demande non trouvée',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: $e',
      };
    }
  }

  /// Mark a request as picked up
  /// PUT /medication-request/{requestId}/pickup
  Future<Map<String, dynamic>> markAsPickedUp(String requestId) async {
    try {
      final token = await _tokenService.getToken();

      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.markAsPickedUp(requestId)}'),
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else if (response.statusCode == 401) {
        await _tokenService.clearAuthData();
        return {
          'success': false,
          'message': 'Session expirée',
          'sessionExpired': true,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: $e',
      };
    }
  }
}

