import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/features/pharmacy/services/pharmacy_auth_service.dart';

class BoostService {
  final PharmacyAuthService _authService = PharmacyAuthService();

  /// Activate a visibility boost
  /// POST /api/boost
  Future<Map<String, dynamic>> activateBoost({
    required String boostType, // '24h', 'week', 'month'
    required int radiusKm,
  }) async {
    try {
      debugPrint('⚡ ========== ACTIVATING BOOST ==========');
      debugPrint('⚡ Type: $boostType, Radius: $radiusKm km');

      final token = await _authService.getToken();
      final pharmacyId = await _authService.getPharmacyId();

      if (token == null || pharmacyId == null) {
        throw Exception('Non authentifié');
      }

      final url = '${ApiConstants.baseUrl}/boost';
      debugPrint('🌐 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({
          'pharmacyId': pharmacyId,
          'boostType': boostType,
          'radiusKm': radiusKm,
        }),
      );

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Boost activé avec succès');
        return {
          'success': true,
          'boost': data['boost'],
        };
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        debugPrint('❌ Erreur 400: ${error['message']}');
        return {
          'success': false,
          'message': error['message'] ?? 'Vous avez déjà un boost actif',
        };
      } else if (response.statusCode == 401) {
        debugPrint('❌ 401 - Session expirée');
        await _authService.logout();
        return {
          'success': false,
          'message': 'Session expirée. Veuillez vous reconnecter.',
          'sessionExpired': true,
        };
      } else {
        final error = jsonDecode(response.body);
        debugPrint('❌ Erreur ${response.statusCode}');
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur lors de l\'activation du boost',
        };
      }
    } catch (e) {
      debugPrint('❌ activateBoost error: $e');
      return {
        'success': false,
        'message': 'Erreur réseau: $e',
      };
    }
  }

  /// Get active boosts for pharmacy
  /// GET /api/boost/pharmacy/{pharmacyId}/active
  Future<List<BoostModel>> getActiveBoosts() async {
    try {
      debugPrint('⚡ ========== FETCHING ACTIVE BOOSTS ==========');

      final token = await _authService.getToken();
      final pharmacyId = await _authService.getPharmacyId();

      if (token == null || pharmacyId == null) {
        throw Exception('Non authentifié');
      }

      final url = '${ApiConstants.baseUrl}/boost/pharmacy/$pharmacyId/active';
      debugPrint('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
      );

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ Found ${data.length} active boost(s)');
        return data.map((json) => BoostModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        debugPrint('❌ 401 - Session expirée');
        await _authService.logout();
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        debugPrint('❌ Erreur ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ getActiveBoosts error: $e');
      return [];
    }
  }
}

/// Model for Boost
class BoostModel {
  final String id;
  final String boostType;
  final DateTime expiresAt;
  final int radiusKm;

  BoostModel({
    required this.id,
    required this.boostType,
    required this.expiresAt,
    required this.radiusKm,
  });

  factory BoostModel.fromJson(Map<String, dynamic> json) {
    return BoostModel(
      id: json['_id'] ?? '',
      boostType: json['boostType'] ?? '24h',
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()),
      radiusKm: json['radiusKm'] ?? 10,
    );
  }

  String get displayName {
    switch (boostType) {
      case '24h':
        return '24 Heures';
      case 'week':
        return '1 Semaine';
      case 'month':
        return '1 Mois';
      default:
        return boostType;
    }
  }

  bool get isActive {
    return expiresAt.isAfter(DateTime.now());
  }

  Duration get remainingTime {
    return expiresAt.difference(DateTime.now());
  }

  String get remainingTimeText {
    final remaining = remainingTime;
    if (remaining.inDays > 0) {
      return '${remaining.inDays}j ${remaining.inHours % 24}h restantes';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}min restantes';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}min restantes';
    } else {
      return 'Expiré';
    }
  }
}

