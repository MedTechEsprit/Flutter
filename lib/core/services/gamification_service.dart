// 🎮 Gamification Service - Gère tous les appels API de gamification
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/models/gamification_models.dart';

class GamificationService {
  final TokenService _tokenService = TokenService();

  // ─────────────────────────────────────────────────────────────
  // 1️⃣ GET /pharmaciens/:id/points/stats
  // ─────────────────────────────────────────────────────────────
  Future<PointsStatsResponse> getPointsStats(String pharmacyId) async {
    try {
      debugPrint('🎮 ========== FETCHING POINTS STATS ==========');
      debugPrint('📍 Pharmacy ID: $pharmacyId');

      final token = await _tokenService.getToken();
      if (token == null) throw Exception('❌ Token manquant - Non authentifié');

      final url = '${ApiConstants.baseUrl}${ApiConstants.pointsStats(pharmacyId)}';
      debugPrint('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Points stats reçues avec succès');
        return PointsStatsResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('❌ Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('❌ Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Exception getPointsStats: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2️⃣ GET /pharmaciens/:id/points/ranking
  // ─────────────────────────────────────────────────────────────
  Future<RankingResponse> getRanking(String pharmacyId) async {
    try {
      debugPrint('🎮 ========== FETCHING RANKING ==========');
      debugPrint('📍 Pharmacy ID: $pharmacyId');

      final token = await _tokenService.getToken();
      if (token == null) throw Exception('❌ Token manquant');

      final url = '${ApiConstants.baseUrl}${ApiConstants.pointsRanking(pharmacyId)}';
      debugPrint('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Ranking reçu avec succès');
        return RankingResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('❌ Session expirée');
      } else {
        throw Exception('❌ Erreur ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception getRanking: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3️⃣ GET /pharmaciens/:id/points/history/today
  // ─────────────────────────────────────────────────────────────
  Future<List<PointsHistoryItem>> getDailyHistory(String pharmacyId) async {
    try {
      debugPrint('🎮 ========== FETCHING DAILY HISTORY ==========');
      debugPrint('📍 Pharmacy ID: $pharmacyId');

      final token = await _tokenService.getToken();
      if (token == null) throw Exception('❌ Token manquant');

      final url = '${ApiConstants.baseUrl}${ApiConstants.pointsHistoryToday(pharmacyId)}';
      debugPrint('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final history = data.map((e) => PointsHistoryItem.fromJson(e)).toList();
        debugPrint('✅ Historique journalier reçu: ${history.length} entrées');
        return history;
      } else if (response.statusCode == 401) {
        throw Exception('❌ Session expirée');
      } else {
        throw Exception('❌ Erreur ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception getDailyHistory: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4️⃣ GET /pharmaciens/points/badges (PUBLIC)
  // ─────────────────────────────────────────────────────────────
  Future<List<BadgeThreshold>> getBadgeThresholds() async {
    try {
      debugPrint('🎮 ========== FETCHING BADGE THRESHOLDS ==========');

      final url = '${ApiConstants.baseUrl}${ApiConstants.badgeThresholds}';
      debugPrint('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final badges = data.map((e) => BadgeThreshold.fromJson(e)).toList();
        debugPrint('✅ Badge thresholds reçus: ${badges.length} badges');
        return badges;
      } else {
        throw Exception('❌ Erreur ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception getBadgeThresholds: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 5️⃣ PUT /medication-request/:id/respond
  // Répondre à une demande de médicament (avec calcul de points)
  // ─────────────────────────────────────────────────────────────
  Future<RespondToRequestResponse> respondToRequest(
    String requestId,
    RespondToRequestDto dto,
  ) async {
    try {
      debugPrint('🎮 ========== RESPOND TO REQUEST ==========');
      debugPrint('📋 Request ID: $requestId');
      debugPrint('🏪 Pharmacy ID: ${dto.pharmacyId}');
      debugPrint('📊 Status: ${dto.status}');

      final token = await _tokenService.getToken();
      if (token == null) throw Exception('❌ Token manquant');

      final url = '${ApiConstants.baseUrl}${ApiConstants.respondToRequest(requestId)}';
      debugPrint('🌐 URL: $url');

      final body = jsonEncode(dto.toJson());
      debugPrint('📤 Request body: $body');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
        body: body,
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = RespondToRequestResponse.fromJson(data);
        debugPrint('✅ Réponse enregistrée avec succès');

        if (result.pharmacyResponses.isNotEmpty) {
          final pharmacy = result.pharmacyResponses.first;
          debugPrint('💎 Points gagnés: ${pharmacy.pointsAwarded}');
          debugPrint('📊 Breakdown: ${pharmacy.pointsBreakdown.reason}');
        }

        return result;
      } else if (response.statusCode == 401) {
        throw Exception('❌ Session expirée');
      } else {
        throw Exception('❌ Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Exception respondToRequest: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 6️⃣ POST /ratings
  // Créer une évaluation client (points de bonus pour la pharmacie)
  // ─────────────────────────────────────────────────────────────
  Future<RatingResponse> createRating(CreateRatingDto dto) async {
    try {
      debugPrint('⭐ ========== CREATE RATING ==========');
      debugPrint('⭐ Stars: ${dto.stars}');
      debugPrint('🏪 Pharmacy ID: ${dto.pharmacyId}');

      final url = '${ApiConstants.baseUrl}${ApiConstants.createRating}';
      debugPrint('🌐 URL: $url');

      final body = jsonEncode(dto.toJson());
      debugPrint('📤 Request body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
        body: body,
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = RatingResponse.fromJson(data);
        debugPrint('✅ Évaluation enregistrée avec succès');
        debugPrint('💎 Points gagnés: ${result.pointsAwarded}');
        if (result.penaltyApplied != 0) {
          debugPrint('⚠️ Pénalité appliquée: ${result.penaltyApplied}');
        }
        return result;
      } else {
        throw Exception('❌ Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Exception createRating: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────────

  /// Récupérer le badge actuel basé sur les points
  BadgeThreshold? getCurrentBadge(int points, List<BadgeThreshold> thresholds) {
    // Trier par minPoints décroissant pour trouver le badge actuel
    final sorted = List<BadgeThreshold>.from(thresholds)
        ..sort((a, b) => b.minPoints.compareTo(a.minPoints));

    for (final badge in sorted) {
      if (points >= badge.minPoints) {
        return badge;
      }
    }
    return null;
  }

  /// Récupérer le prochain badge
  BadgeThreshold? getNextBadge(int points, List<BadgeThreshold> thresholds) {
    final sorted = List<BadgeThreshold>.from(thresholds)
        ..sort((a, b) => a.minPoints.compareTo(b.minPoints));

    for (final badge in sorted) {
      if (points < badge.minPoints) {
        return badge;
      }
    }
    return null;
  }

  /// Calculer la progression vers le prochain badge
  Map<String, dynamic> calculateBadgeProgress(
    int currentPoints,
    List<BadgeThreshold> thresholds,
  ) {
    final currentBadge = getCurrentBadge(currentPoints, thresholds);
    final nextBadge = getNextBadge(currentPoints, thresholds);

    if (nextBadge == null) {
      return {
        'currentBadge': currentBadge,
        'nextBadge': null,
        'progress': 100,
        'pointsNeeded': 0,
      };
    }

    final currentMin = currentBadge?.minPoints ?? 0;
    final nextMin = nextBadge.minPoints;
    final range = nextMin - currentMin;
    final progress = ((currentPoints - currentMin) / range * 100).toInt();

    return {
      'currentBadge': currentBadge,
      'nextBadge': nextBadge,
      'progress': progress.clamp(0, 100),
      'pointsNeeded': (nextMin - currentPoints).clamp(0, nextMin),
    };
  }
}

