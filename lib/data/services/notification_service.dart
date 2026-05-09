import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

class NotificationApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isTemporary;

  NotificationApiException(
    this.message, {
    this.statusCode,
    this.isTemporary = false,
  });

  @override
  String toString() => message;
}

class NotificationService {
  String get baseUrl => ApiConstants.serverBaseUrl;
  static const Duration _timeout = Duration(seconds: 12);

  final TokenService _tokenService = TokenService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    if (token == null || token.isEmpty) {
      throw NotificationApiException(
        'Utilisateur non authentifié',
        statusCode: 401,
      );
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  NotificationApiException _handleError(dynamic error) {
    if (error is NotificationApiException) {
      return error;
    }

    if (error is SocketException) {
      return NotificationApiException(
        'Serveur inaccessible. Vérifiez la connexion backend.',
        isTemporary: true,
      );
    }

    if (error is TimeoutException) {
      return NotificationApiException(
        'Délai dépassé. Le serveur ne répond pas.',
        isTemporary: true,
      );
    }

    return NotificationApiException('Erreur: $error');
  }

  NotificationApiException _responseError(http.Response response) {
    String message = 'Erreur notification (${response.statusCode})';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final backendMessage = body['message'];
        if (backendMessage is List) {
          message = backendMessage.join(', ');
        } else if (backendMessage is String && backendMessage.isNotEmpty) {
          message = backendMessage;
        }
      }
    } catch (_) {}

    final temporary = response.statusCode >= 500 || response.statusCode == 429;
    return NotificationApiException(
      message,
      statusCode: response.statusCode,
      isTemporary: temporary,
    );
  }

  Future<void> registerDeviceToken({
    required String fcmToken,
    required String userType,
    required String userId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/notifications/register-token'),
            headers: headers,
            body: jsonEncode({
              'fcmToken': fcmToken,
              'userType': userType,
              'userId': userId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw _responseError(response);
      }
    } catch (error) {
      throw _handleError(error);
    }
  }

  Future<void> removeDeviceToken({
    required String fcmToken,
    required String userType,
    required String userId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/notifications/remove-token'),
            headers: headers,
            body: jsonEncode({
              'fcmToken': fcmToken,
              'userType': userType,
              'userId': userId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _responseError(response);
      }
    } catch (error) {
      throw _handleError(error);
    }
  }

  Future<List<Map<String, dynamic>>> getMyNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/notifications/my-notifications').replace(
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
        },
      );

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList();
        }

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is List) {
            return data.whereType<Map<String, dynamic>>().toList();
          }
        }

        return [];
      }

      throw _responseError(response);
    } catch (error) {
      throw _handleError(error);
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications({
    bool unreadOnly = false,
    String? type,
    int? limit,
  }) async {
    final all = await getMyNotifications(limit: limit ?? 50);
    final filtered = all.where((item) {
      final isUnread = item['isRead'] != true;
      final matchesUnread = !unreadOnly || isUnread;
      final matchesType =
          type == null ||
          type.isEmpty ||
          (item['type']?.toString().toLowerCase() == type.toLowerCase());
      return matchesUnread && matchesType;
    }).toList();

    filtered.sort((a, b) {
      final left = DateTime.tryParse((a['createdAt'] ?? a['timestamp'] ?? '').toString());
      final right = DateTime.tryParse((b['createdAt'] ?? b['timestamp'] ?? '').toString());
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });

    return filtered;
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

      throw _responseError(response);
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

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _responseError(response);
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

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _responseError(response);
      }
    } catch (error) {
      throw _handleError(error);
    }
  }
}
