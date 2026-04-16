import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

class NotificationService {
  String get baseUrl => ApiConstants.serverBaseUrl;
  static const Duration _timeout = Duration(seconds: 12);

  final TokenService _tokenService = TokenService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Exception _handleError(dynamic error) {
    if (error is SocketException) {
      return Exception('Serveur inaccessible. Vérifiez la connexion backend.');
    }
    if (error is TimeoutException) {
      return Exception('Délai dépassé. Le serveur ne répond pas.');
    }
    return Exception('Erreur: $error');
  }

  Future<List<Map<String, dynamic>>> getNotifications({
    bool unreadOnly = false,
    String? type,
    int? limit,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParameters = <String, String>{
        if (unreadOnly) 'unreadOnly': 'true',
        if (type != null && type.isNotEmpty) 'type': type,
        if (limit != null) 'limit': '$limit',
      };

      final uri = Uri.parse('$baseUrl/api/notifications').replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.whereType<Map<String, dynamic>>().toList();
      }

      throw Exception('Impossible de charger les notifications');
    } catch (error) {
      throw _handleError(error);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/notifications/unread-count'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['count'] ?? 0) as int;
      }

      throw Exception('Impossible de récupérer le compteur');
    } catch (error) {
      throw _handleError(error);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Impossible de marquer la notification comme lue');
      }
    } catch (error) {
      throw _handleError(error);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/api/notifications/read-all'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Impossible de marquer toutes les notifications comme lues');
      }
    } catch (error) {
      throw _handleError(error);
    }
  }
}
