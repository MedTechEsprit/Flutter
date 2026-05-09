import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

String? _asString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

/// Model for a single pattern detection result
class PatternDetection {
  final bool detected;
  final String? frequency;
  final String? riskLevel;
  final String? recommendation;
  final Map<String, dynamic> raw;

  PatternDetection({
    required this.detected,
    this.frequency,
    this.riskLevel,
    this.recommendation,
    required this.raw,
  });

  factory PatternDetection.fromJson(Map<String, dynamic> json) {
    return PatternDetection(
      detected: _asBool(json['detected']),
      frequency: _asString(json['frequency']),
      riskLevel: _asString(json['riskLevel']),
      recommendation: _asString(json['recommendation']),
      raw: json,
    );
  }
}

/// Model for overall assessment
class OverallAssessment {
  final String controlLevel;
  final int criticalPatternsCount;
  final bool doctorConsultationNeeded;
  final String urgencyLevel;
  final List<String> topPriorities;
  final String summary;

  OverallAssessment({
    required this.controlLevel,
    required this.criticalPatternsCount,
    required this.doctorConsultationNeeded,
    required this.urgencyLevel,
    required this.topPriorities,
    required this.summary,
  });

  factory OverallAssessment.fromJson(Map<String, dynamic> json) {
    return OverallAssessment(
      controlLevel: _asString(json['controlLevel']) ?? 'unknown',
      criticalPatternsCount: _asInt(json['criticalPatternsCount']),
      doctorConsultationNeeded: _asBool(json['doctorConsultationNeeded']),
      urgencyLevel: _asString(json['urgencyLevel']) ?? 'low',
      topPriorities: _asStringList(json['topPriorities']),
      summary: _asString(json['summary']) ?? '',
    );
  }
}

/// Full AI Pattern analysis result
class AiPatternAnalysis {
  final String? id;
  final PatternDetection? nocturnalHypoglycemia;
  final PatternDetection? postMealSpikes;
  final PatternDetection? riskTimeWindows;
  final PatternDetection? glycemicControlDegradation;
  final OverallAssessment? overallAssessment;
  final bool isFallback;
  final String? triggerType; // manual, cron
  final DateTime? createdAt;
  final Map<String, dynamic>? statistics;

  AiPatternAnalysis({
    this.id,
    this.nocturnalHypoglycemia,
    this.postMealSpikes,
    this.riskTimeWindows,
    this.glycemicControlDegradation,
    this.overallAssessment,
    this.isFallback = false,
    this.triggerType,
    this.createdAt,
    this.statistics,
  });

  factory AiPatternAnalysis.fromJson(Map<String, dynamic> json) {
    // The patterns may be nested inside an 'analysis' or 'patterns' key
    final analysis =
        _asMap(json['analysis']) ?? _asMap(json['patterns']) ?? json;

    return AiPatternAnalysis(
      id: _asString(json['_id'] ?? json['id']),
      nocturnalHypoglycemia: _asMap(analysis['nocturnalHypoglycemia']) != null
          ? PatternDetection.fromJson(
              _asMap(analysis['nocturnalHypoglycemia'])!,
            )
          : null,
      postMealSpikes: _asMap(analysis['postMealSpikes']) != null
          ? PatternDetection.fromJson(_asMap(analysis['postMealSpikes'])!)
          : null,
      riskTimeWindows: _asMap(analysis['riskTimeWindows']) != null
          ? PatternDetection.fromJson(_asMap(analysis['riskTimeWindows'])!)
          : null,
      glycemicControlDegradation:
          _asMap(analysis['glycemicControlDegradation']) != null
          ? PatternDetection.fromJson(
              _asMap(analysis['glycemicControlDegradation'])!,
            )
          : null,
      overallAssessment: _asMap(analysis['overallAssessment']) != null
          ? OverallAssessment.fromJson(_asMap(analysis['overallAssessment'])!)
          : null,
      isFallback: _asBool(json['isFallback']),
      triggerType: _asString(json['triggerType']),
      createdAt: _asString(json['createdAt']) != null
          ? DateTime.tryParse(_asString(json['createdAt'])!)
          : null,
      statistics: _asMap(json['statistics']) ?? _asMap(json['globalStats']),
    );
  }

  /// Get count of detected patterns
  int get detectedCount {
    int count = 0;
    if (nocturnalHypoglycemia?.detected == true) count++;
    if (postMealSpikes?.detected == true) count++;
    if (riskTimeWindows?.detected == true) count++;
    if (glycemicControlDegradation?.detected == true) count++;
    return count;
  }
}

/// Service for AI Pattern (30-day glucose pattern detection)
/// Endpoints:
///   POST /api/ai-pattern         — Manual analysis
///   GET  /api/ai-pattern/latest  — Last result
///   GET  /api/ai-pattern/history — History
///   GET  /api/ai-pattern/:id     — Detail
class AiPatternService {
  final TokenService _tokenService = TokenService();
  final Duration _analysisTimeout = const Duration(minutes: 7);
  final Duration _readTimeout = const Duration(seconds: 60);

  String get _baseUrl => ApiConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Trigger a manual pattern analysis
  Future<AiPatternAnalysis> analyzePatterns() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl${ApiConstants.aiPattern}'),
            headers: headers,
            body: jsonEncode({}),
          )
          .timeout(_analysisTimeout);

      debugPrint(
        '🔍 [AiPatternService] analyzePatterns: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AiPatternAnalysis.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur analyse de patterns');
      }
    } catch (e) {
      debugPrint('❌ [AiPatternService] analyzePatterns error: $e');
      rethrow;
    }
  }

  /// Get the latest pattern analysis
  Future<AiPatternAnalysis?> getLatest() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$_baseUrl${ApiConstants.aiPatternLatest}'),
            headers: headers,
          )
          .timeout(_readTimeout);

      debugPrint('🔍 [AiPatternService] getLatest: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null || (data is Map && data.isEmpty)) return null;
        return AiPatternAnalysis.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [AiPatternService] getLatest error: $e');
      return null;
    }
  }

  /// Get pattern analysis history
  Future<List<AiPatternAnalysis>> getHistory({
    int page = 1,
    int limit = 20,
    String? triggerType,
  }) async {
    try {
      final headers = await _getHeaders();
      var url =
          '$_baseUrl${ApiConstants.aiPatternHistory}?page=$page&limit=$limit';
      if (triggerType != null) url += '&triggerType=$triggerType';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_readTimeout);

      debugPrint('🔍 [AiPatternService] getHistory: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data is List
            ? data
            : (data['data'] ?? data['patterns'] ?? []);
        return items
            .whereType<Map>()
            .map((json) => Map<String, dynamic>.from(json))
            .map(AiPatternAnalysis.fromJson)
            .toList();
      } else {
        throw Exception('Erreur chargement historique patterns');
      }
    } catch (e) {
      debugPrint('❌ [AiPatternService] getHistory error: $e');
      rethrow;
    }
  }

  /// Get a specific analysis by ID
  Future<AiPatternAnalysis> getDetail(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$_baseUrl${ApiConstants.aiPatternDetail(id)}'),
            headers: headers,
          )
          .timeout(_readTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AiPatternAnalysis.fromJson(data);
      } else {
        throw Exception('Erreur chargement détail pattern');
      }
    } catch (e) {
      debugPrint('❌ [AiPatternService] getDetail error: $e');
      rethrow;
    }
  }
}
