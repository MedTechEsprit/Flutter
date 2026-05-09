import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

class ActivityService {
  final TokenService _tokenService = TokenService();

  /// Get activity feed for pharmacy
  /// GET /api/activities/pharmacy/{pharmacyId}/feed
  Future<List<ActivityModel>> getActivityFeed({int limit = 20}) async {
    try {
      debugPrint('📋 ========== FETCHING ACTIVITY FEED ==========');

      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      if (token == null || pharmacyId == null) {
        throw Exception('Non authentifié');
      }

        final url =
          '${ApiConstants.baseUrl}${ApiConstants.activityFeed(pharmacyId)}?limit=$limit';
      debugPrint('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
      );

      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ Found ${data.length} activity event(s)');
        return data.map((json) => ActivityModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        debugPrint('❌ 401 - Session expirée');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        debugPrint('❌ Erreur ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ getActivityFeed error: $e');
      return [];
    }
  }
}

/// Model for Activity
class ActivityModel {
  final String id;
  final String activityType;
  final String description;
  final int? points;
  final DateTime createdAt;
  final String relativeTime;

  ActivityModel({
    required this.id,
    required this.activityType,
    required this.description,
    this.points,
    required this.createdAt,
    required this.relativeTime,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['_id'] ?? '',
      activityType: json['activityType'] ?? '',
      description: json['description'] ?? '',
      points: json['points'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      relativeTime: json['relativeTime'] ?? 'À l\'instant',
    );
  }

  String get icon {
    switch (activityType) {
      case 'request_accepted':
        return '✅';
      case 'request_declined':
        return '❌';
      case 'points_earned':
        return '🎯';
      case 'badge_unlocked':
        return '🏆';
      case 'boost_activated':
        return '⚡';
      case 'review_received':
        return '⭐';
      default:
        return '📋';
    }
  }
}

