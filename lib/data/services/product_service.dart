import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/services/token_service.dart';

class ProductService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  final TokenService _tokenService = TokenService();

  Future<Map<String, String>> get _headers async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Marketplace (patient) ──────────────────────────────────────

  Future<Map<String, dynamic>> getMarketplace({int page = 1, int limit = 20, String? search, String? category}) async {
    try {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (category != null && category.isNotEmpty) params['category'] = category;
      final uri = Uri.parse('$baseUrl/products/marketplace').replace(queryParameters: params);
      final response = await http.get(uri, headers: await _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'data': [], 'total': 0};
    } catch (e) {
      return {'data': [], 'total': 0};
    }
  }

  Future<Map<String, dynamic>?> getProduct(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id'), headers: await _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Pharmacist CRUD ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyProducts(String pharmacistId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/pharmacist/$pharmacistId'),
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

  Future<Map<String, dynamic>?> createProduct(String pharmacistId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/pharmacist/$pharmacistId'),
        headers: await _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProduct(String id, String pharmacistId, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/products/$id/pharmacist/$pharmacistId'),
        headers: await _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String id, String pharmacistId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id/pharmacist/$pharmacistId'),
        headers: await _headers,
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
