import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/services/token_service.dart';

class OrderService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  final TokenService _tokenService = TokenService();

  Future<Map<String, String>> get _headers async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Patient ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> createOrder(String patientId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/patient/$patientId'),
        headers: await _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Erreur de commande');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyOrders(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/patient/$patientId'),
        headers: await _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> cancelOrder(String orderId, String patientId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/patient/$patientId/cancel'),
        headers: await _headers,
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Pharmacist ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPharmacistOrders(String pharmacistId, {String? status}) async {
    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      final uri = Uri.parse('$baseUrl/orders/pharmacist/$pharmacistId').replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri, headers: await _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateOrderStatus(String orderId, String pharmacistId, String status, {String? note}) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (note != null) body['note'] = note;
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/pharmacist/$pharmacistId/status'),
        headers: await _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getPharmacistOrderStats(String pharmacistId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/pharmacist/$pharmacistId/stats'),
        headers: await _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (e) {
      return {};
    }
  }
}
