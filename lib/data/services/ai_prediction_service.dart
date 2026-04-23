import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

/// Model for a glucose prediction result
class AiPrediction {
  final String? id;
  final double predictedValue;
  final double? estimatedValue4h;
  final int confidence;
  final String trend;
  final String riskLevel;
  final String riskType;
  final String summary;
  final String explanation;
  final String timeToAction;
  final List<String> recommendations;
  final List<String> alerts;
  final bool isFallback;
  final Map<String, dynamic>? glucoseSnapshot;
  final Map<String, dynamic>? mealSnapshot;
  final String? triggerType;
  final DateTime? createdAt;

  AiPrediction({
    this.id,
    required this.predictedValue,
    this.estimatedValue4h,
    required this.confidence,
    required this.trend,
    required this.riskLevel,
    this.riskType = 'none',
    required this.summary,
    this.explanation = '',
    this.timeToAction = 'monitor',
    required this.recommendations,
    this.alerts = const [],
    this.isFallback = false,
    this.glucoseSnapshot,
    this.mealSnapshot,
    this.triggerType,
    this.createdAt,
  });

  /// Parse from backend response which can be:
  /// - Direct predict: { predictionId, prediction: {...}, glucoseSnapshot, ... }
  /// - History item:   { _id, prediction: {...}, glucoseSnapshot, ... }
  factory AiPrediction.fromJson(Map<String, dynamic> json) {
    // The prediction data may be nested under 'prediction' key or at root level
    final pred = json['prediction'] is Map<String, dynamic>
        ? json['prediction'] as Map<String, dynamic>
        : json;

    return AiPrediction(
      id: json['predictionId'] ?? json['_id'] ?? json['id'],
      predictedValue: _toDouble(pred['estimatedValue2h'] ?? pred['predictedValue'] ?? 0),
      estimatedValue4h: pred['estimatedValue4h'] != null ? _toDouble(pred['estimatedValue4h']) : null,
      confidence: _toInt(pred['confidence'] ?? 0),
      trend: pred['trend'] ?? 'stable',
      riskLevel: pred['riskLevel'] ?? 'low',
      riskType: pred['riskType'] ?? 'none',
      summary: pred['summary'] ?? '',
      explanation: pred['explanation'] ?? '',
      timeToAction: pred['timeToAction'] ?? 'monitor',
      recommendations: List<String>.from(pred['recommendations'] ?? []),
      alerts: List<String>.from(pred['alerts'] ?? []),
      isFallback: json['isFallback'] ?? false,
      glucoseSnapshot: json['glucoseSnapshot'],
      mealSnapshot: json['mealSnapshot'],
      triggerType: json['triggerType'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  static double _toDouble(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
  static int _toInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

  /// Friendly trend label
  String get trendLabel {
    switch (trend) {
      case 'increase':
        return 'En hausse ↗';
      case 'decrease':
        return 'En baisse ↘';
      case 'worsening':
        return 'En hausse ↗';
      case 'improving':
        return 'En baisse ↘';
      case 'rising':
        return 'En hausse ↗';
      case 'falling':
        return 'En baisse ↘';
      default:
        return 'Stable →';
    }
  }

  /// Risk level color helper
  String get riskLevelLabel {
    switch (riskLevel) {
      case 'critical':
        return 'Critique';
      case 'high':
        return 'Élevé';
      case 'moderate':
        return 'Modéré';
      default:
        return 'Faible';
    }
  }

  /// Whether trend is going up
  bool get isRising => trend == 'increase' || trend == 'worsening' || trend == 'rising';
}

/// Service for AI Prediction (glucose trend prediction 2-4h)
/// Endpoints:
///   POST /api/ai-prediction           — Manual prediction
///   POST /api/ai-prediction/post-meal/:mealId — Post-meal prediction
///   GET  /api/ai-prediction/history    — History
///   GET  /api/ai-prediction/:id        — Detail
class AiPredictionService {
  final TokenService _tokenService = TokenService();
  final Duration _timeout = const Duration(seconds: 120);

  String get _baseUrl => ApiConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Request a manual glucose prediction
  Future<AiPrediction> predict() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.aiPrediction}'),
        headers: headers,
        body: jsonEncode({}),
      ).timeout(_timeout);

      debugPrint('📈 [AiPredictionService] predict: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AiPrediction.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur de prédiction');
      }
    } catch (e) {
      debugPrint('❌ [AiPredictionService] predict error: $e');
      rethrow;
    }
  }

  /// Request a post-meal prediction
  Future<AiPrediction> predictPostMeal(String mealId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.aiPredictionPostMeal(mealId)}'),
        headers: headers,
        body: jsonEncode({}),
      ).timeout(_timeout);

      debugPrint('📈 [AiPredictionService] predictPostMeal: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AiPrediction.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur de prédiction post-repas');
      }
    } catch (e) {
      debugPrint('❌ [AiPredictionService] predictPostMeal error: $e');
      rethrow;
    }
  }

  /// Get prediction history
  Future<List<AiPrediction>> getHistory({int page = 1, int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.aiPredictionHistory}?page=$page&limit=$limit'),
        headers: headers,
      ).timeout(_timeout);

      debugPrint('📈 [AiPredictionService] getHistory: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data is List ? data : (data['data'] ?? data['predictions'] ?? []);
        return items.map((json) => AiPrediction.fromJson(json)).toList();
      } else {
        throw Exception('Erreur chargement historique prédictions');
      }
    } catch (e) {
      debugPrint('❌ [AiPredictionService] getHistory error: $e');
      rethrow;
    }
  }

  /// Get a single prediction by ID
  Future<AiPrediction> getDetail(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.aiPredictionDetail(id)}'),
        headers: headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AiPrediction.fromJson(data);
      } else {
        throw Exception('Erreur chargement prédiction');
      }
    } catch (e) {
      debugPrint('❌ [AiPredictionService] getDetail error: $e');
      rethrow;
    }
  }
}
