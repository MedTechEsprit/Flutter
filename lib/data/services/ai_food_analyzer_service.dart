import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

/// Model for detailed AI advice from food analysis
/// Maps to backend DetailedAdvice fields
class DetailedAdvice {
  final String summary;
  final String glucoseImpact;
  final String expectedGlucoseRise;
  final String riskLevel;
  final String personalizedRisk;
  final List<String> recommendations;
  final String portionAdvice;
  final String timingAdvice;
  final List<String> alternativeSuggestions;
  final String exerciseRecommendation;

  DetailedAdvice({
    required this.summary,
    required this.glucoseImpact,
    required this.expectedGlucoseRise,
    required this.riskLevel,
    required this.personalizedRisk,
    required this.recommendations,
    required this.portionAdvice,
    required this.timingAdvice,
    required this.alternativeSuggestions,
    required this.exerciseRecommendation,
  });

  factory DetailedAdvice.fromJson(Map<String, dynamic> json) {
    return DetailedAdvice(
      summary: json['summary'] ?? '',
      glucoseImpact: json['glucoseImpact'] ?? '',
      expectedGlucoseRise: json['expectedGlucoseRise'] ?? '',
      riskLevel: json['riskLevel'] ?? '',
      personalizedRisk: json['personalizedRisk'] ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      portionAdvice: json['portionAdvice'] ?? '',
      timingAdvice: json['timingAdvice'] ?? '',
      alternativeSuggestions: List<String>.from(json['alternativeSuggestions'] ?? []),
      exerciseRecommendation: json['exerciseRecommendation'] ?? '',
    );
  }

  /// Check if there is meaningful advice
  bool get hasContent => summary.isNotEmpty || recommendations.isNotEmpty || glucoseImpact.isNotEmpty;
}

/// Full response from the AI Food Analyzer
class AiFoodAnalysisResponse {
  final Map<String, dynamic>? meal;
  final Map<String, dynamic>? imageAnalysis;
  final String? aiAdvice;
  final DetailedAdvice? detailedAdvice;

  AiFoodAnalysisResponse({
    this.meal,
    this.imageAnalysis,
    this.aiAdvice,
    this.detailedAdvice,
  });

  factory AiFoodAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AiFoodAnalysisResponse(
      meal: json['meal'],
      imageAnalysis: json['image_analysis'] ?? json['ollama_detection'],
      aiAdvice: json['ai_advice'] ?? json['report']?['summary'],
      detailedAdvice: json['detailedAdvice'] != null
          ? DetailedAdvice.fromJson(json['detailedAdvice'])
          : null,
    );
  }

  /// Helper to get meal name
  String get mealName =>
      meal?['name'] ?? imageAnalysis?['food_name'] ?? imageAnalysis?['name'] ?? 'Repas inconnu';

  /// Helper to get calories
  double get calories =>
      _toDouble(meal?['calories'] ?? imageAnalysis?['calories'] ?? 0);

  /// Helper to get carbs
  double get carbs =>
      _toDouble(meal?['carbs'] ?? imageAnalysis?['carbs'] ?? 0);

  /// Helper to get protein
  double get protein =>
      _toDouble(meal?['protein'] ?? imageAnalysis?['protein'] ?? 0);

  /// Helper to get fat
  double get fat =>
      _toDouble(meal?['fat'] ?? imageAnalysis?['fat'] ?? 0);

  /// Health note from image analysis
  String? get healthNote => imageAnalysis?['health_note'];

  /// Confidence from meal
  int get confidence => (meal?['confidence'] ?? 0) as int;

  static double _toDouble(dynamic v) =>
      (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
}

/// Full persisted AI analysis linked to a meal.
class AiFoodAnalysisDetail {
  final String? id;
  final String mealId;
  final String? patientId;
  final String? imageUrl;
  final Map<String, dynamic> analysisResult;
  final DetailedAdvice? detailedAdvice;
  final Map<String, dynamic>? fullReport;
  final Map<String, dynamic>? ollamaDetection;
  final bool isFallback;
  final DateTime? createdAt;

  AiFoodAnalysisDetail({
    this.id,
    required this.mealId,
    this.patientId,
    this.imageUrl,
    required this.analysisResult,
    this.detailedAdvice,
    this.fullReport,
    this.ollamaDetection,
    required this.isFallback,
    this.createdAt,
  });

  factory AiFoodAnalysisDetail.fromJson(Map<String, dynamic> json) {
    return AiFoodAnalysisDetail(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      mealId: json['mealId']?.toString() ?? '',
      patientId: json['patientId']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      analysisResult: Map<String, dynamic>.from(json['analysisResult'] ?? const {}),
      detailedAdvice: json['detailedAdvice'] is Map<String, dynamic>
          ? DetailedAdvice.fromJson(json['detailedAdvice'] as Map<String, dynamic>)
          : null,
      fullReport: json['fullReport'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['fullReport'] as Map<String, dynamic>)
          : null,
      ollamaDetection: json['ollamaDetection'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['ollamaDetection'] as Map<String, dynamic>)
          : null,
      isFallback: json['isFallback'] == true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  String get summary {
    return fullReport?['summary']?.toString() ??
        detailedAdvice?.summary ??
        analysisResult['diabeticAdvice']?.toString() ??
        '';
  }

  List<String> get recommendations {
    final fromReport = fullReport?['diabetic_assessment']?['recommendations'];
    if (fromReport is List) {
      return fromReport.map((e) => e.toString()).toList();
    }
    return detailedAdvice?.recommendations ?? const [];
  }

  List<String> get warnings {
    final w = fullReport?['warnings'];
    if (w is List) {
      return w.map((e) => e.toString()).toList();
    }
    return const [];
  }
}

/// Service for AI Food Analyzer
/// Endpoint: POST /api/ai-food-analyzer
class AiFoodAnalyzerService {
  final TokenService _tokenService = TokenService();
  final Duration _timeout = const Duration(seconds: 180);

  String get _baseUrl => ApiConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Analyze a food image
  /// [imageUrl] - URL of the food image to analyze
  Future<AiFoodAnalysisResponse> analyzeFood({
    required String imageUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.aiFoodAnalyzer}'),
        headers: headers,
        body: jsonEncode({
          'image_url': imageUrl,
        }),
      ).timeout(_timeout);

      debugPrint('🍽️ [AiFoodAnalyzerService] analyzeFood: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AiFoodAnalysisResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur analyse alimentaire');
      }
    } catch (e) {
      debugPrint('❌ [AiFoodAnalyzerService] analyzeFood error: $e');
      rethrow;
    }
  }

  /// Get full persisted AI analysis by meal ID.
  /// Returns null when the meal exists but has no AI analysis.
  Future<AiFoodAnalysisDetail?> getAnalysisByMeal(String mealId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.aiFoodAnalyzer}/meal/$mealId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint('🍽️ [AiFoodAnalyzerService] getAnalysisByMeal: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AiFoodAnalysisDetail.fromJson(data);
      }

      if (response.statusCode == 404) {
        return null;
      }

      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur chargement détail analyse IA');
    } catch (e) {
      debugPrint('❌ [AiFoodAnalyzerService] getAnalysisByMeal error: $e');
      rethrow;
    }
  }
}
