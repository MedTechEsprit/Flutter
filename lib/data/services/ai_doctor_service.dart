import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

/// Model for AI Doctor chat response
class AiDoctorResponse {
  final String response;
  final String queryType; // single_patient, all_patients
  final String? patientId;
  final Map<String, dynamic>? context;

  AiDoctorResponse({
    required this.response,
    required this.queryType,
    this.patientId,
    this.context,
  });

  factory AiDoctorResponse.fromJson(Map<String, dynamic> json) {
    return AiDoctorResponse(
      response: json['response'] ?? '',
      queryType: json['queryType'] ?? 'unknown',
      patientId: json['patientId'],
      context: json['context'],
    );
  }
}

/// Model for urgent patient alert
class UrgentPatient {
  final String patientId;
  final String patientName;
  final List<String> flags;
  final double? lastGlucose;
  final double? avgGlucose;

  UrgentPatient({
    required this.patientId,
    required this.patientName,
    required this.flags,
    this.lastGlucose,
    this.avgGlucose,
  });

  factory UrgentPatient.fromJson(Map<String, dynamic> json) {
    return UrgentPatient(
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? 'Inconnu',
      flags: List<String>.from(json['flags'] ?? []),
      lastGlucose: (json['lastGlucose'] ?? json['lastGlucoseValue'])
          ?.toDouble(),
      avgGlucose: (json['avgGlucose'] ?? json['averageGlucose'])?.toDouble(),
    );
  }
}

/// Model for AI Doctor chat history item
class AiDoctorChatHistory {
  final String? id;
  final String question;
  final String response;
  final String queryType;
  final String? patientId;
  final DateTime? createdAt;

  AiDoctorChatHistory({
    this.id,
    required this.question,
    required this.response,
    required this.queryType,
    this.patientId,
    this.createdAt,
  });

  factory AiDoctorChatHistory.fromJson(Map<String, dynamic> json) {
    return AiDoctorChatHistory(
      id: json['_id'] ?? json['id'],
      question: json['question'] ?? json['message'] ?? '',
      response: json['response'] ?? '',
      queryType: json['queryType'] ?? '',
      patientId: json['patientId'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class PatientMedicalReport {
  final String patientId;
  final DateTime? generatedAt;
  final Map<String, dynamic> sourceMetrics;
  final String title;
  final String executiveSummary;
  final List<String> patientOverview;
  final List<String> clinicalFindings;
  final List<String> riskAssessment;
  final List<String> treatmentPlan;
  final List<String> lifestylePlan;
  final List<String> followUpPlan;
  final List<String> alerts;
  final String physicianNotes;

  PatientMedicalReport({
    required this.patientId,
    required this.generatedAt,
    required this.sourceMetrics,
    required this.title,
    required this.executiveSummary,
    required this.patientOverview,
    required this.clinicalFindings,
    required this.riskAssessment,
    required this.treatmentPlan,
    required this.lifestylePlan,
    required this.followUpPlan,
    required this.alerts,
    required this.physicianNotes,
  });

  factory PatientMedicalReport.fromJson(Map<String, dynamic> json) {
    final report =
        (json['report'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    List<String> parseList(dynamic value, String fallback) {
      if (value is List) {
        final parsed = value
            .map((e) => e?.toString() ?? '')
            .where((e) => e.trim().isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
      return <String>[fallback];
    }

    return PatientMedicalReport(
      patientId: json['patientId']?.toString() ?? '',
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString())
          : null,
      sourceMetrics:
          (json['sourceMetrics'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
      title: report['title']?.toString() ?? 'Rapport medical detaille',
      executiveSummary:
          report['executiveSummary']?.toString() ?? 'Resume non disponible.',
      patientOverview: parseList(
        report['patientOverview'],
        'Apercu patient non disponible.',
      ),
      clinicalFindings: parseList(
        report['clinicalFindings'],
        'Constats cliniques non disponibles.',
      ),
      riskAssessment: parseList(
        report['riskAssessment'],
        'Evaluation du risque non disponible.',
      ),
      treatmentPlan: parseList(
        report['treatmentPlan'],
        'Plan therapeutique non disponible.',
      ),
      lifestylePlan: parseList(
        report['lifestylePlan'],
        'Plan de mode de vie non disponible.',
      ),
      followUpPlan: parseList(
        report['followUpPlan'],
        'Plan de suivi non disponible.',
      ),
      alerts: parseList(report['alerts'], 'Aucune alerte critique.'),
      physicianNotes:
          report['physicianNotes']?.toString() ??
          'La decision finale appartient au medecin traitant.',
    );
  }
}

/// Service for AI Doctor (Clinical AI assistant for doctors)
/// Endpoints:
///   POST /api/ai-doctor/chat/:patientId — Ask about one patient
///   POST /api/ai-doctor/chat             — Ask about all patients
///   GET  /api/ai-doctor/urgent           — Urgent patient alerts (no Ollama)
///   GET  /api/ai-doctor/history          — Chat history
class AiDoctorService {
  final TokenService _tokenService = TokenService();
  final Duration _timeout = const Duration(
    seconds: 300,
  ); // 5 min for multi-patient

  String get _baseUrl => ApiConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ask the AI about a specific patient
  Future<AiDoctorResponse> chatAboutPatient({
    required String patientId,
    required String message,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl${ApiConstants.aiDoctorChatPatient(patientId)}',
            ),
            headers: headers,
            body: jsonEncode({'message': message}),
          )
          .timeout(_timeout);

      debugPrint(
        '👨‍⚕️ [AiDoctorService] chatAboutPatient: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AiDoctorResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur AI Doctor');
      }
    } catch (e) {
      debugPrint('❌ [AiDoctorService] chatAboutPatient error: $e');
      rethrow;
    }
  }

  /// Ask the AI about all patients (population view)
  Future<AiDoctorResponse> chatAboutAllPatients(String message) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl${ApiConstants.aiDoctorChatAll}'),
            headers: headers,
            body: jsonEncode({'message': message}),
          )
          .timeout(_timeout);

      debugPrint(
        '👨‍⚕️ [AiDoctorService] chatAboutAllPatients: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AiDoctorResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur AI Doctor (tous patients)');
      }
    } catch (e) {
      debugPrint('❌ [AiDoctorService] chatAboutAllPatients error: $e');
      rethrow;
    }
  }

  /// Get urgent patient alerts (instant, no Ollama)
  Future<List<UrgentPatient>> getUrgentAlerts() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$_baseUrl${ApiConstants.aiDoctorUrgent}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '🚨 [AiDoctorService] getUrgentAlerts: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data is List
            ? data
            : (data['patients'] ?? data['urgent'] ?? []);
        return items.map((json) => UrgentPatient.fromJson(json)).toList();
      } else {
        throw Exception('Erreur chargement alertes urgentes');
      }
    } catch (e) {
      debugPrint('❌ [AiDoctorService] getUrgentAlerts error: $e');
      rethrow;
    }
  }

  /// Get chat history
  Future<List<AiDoctorChatHistory>> getHistory({
    String? patientId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      var url =
          '$_baseUrl${ApiConstants.aiDoctorHistory}?page=$page&limit=$limit';
      if (patientId != null) url += '&patientId=$patientId';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('👨‍⚕️ [AiDoctorService] getHistory: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data is List
            ? data
            : (data['data'] ?? data['history'] ?? []);
        return items.map((json) => AiDoctorChatHistory.fromJson(json)).toList();
      } else {
        throw Exception('Erreur chargement historique AI Doctor');
      }
    } catch (e) {
      debugPrint('❌ [AiDoctorService] getHistory error: $e');
      rethrow;
    }
  }

  Future<PatientMedicalReport> getPatientMedicalReport(String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl${ApiConstants.aiDoctorMedicalReport(patientId)}',
            ),
            headers: headers,
          )
          .timeout(_timeout);

      debugPrint(
        '📄 [AiDoctorService] getPatientMedicalReport: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PatientMedicalReport.fromJson(data);
      }

      String message = 'Erreur generation rapport medical';
      try {
        final error = jsonDecode(response.body);
        if (error is Map && error['message'] != null) {
          message = error['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    } catch (e) {
      debugPrint('❌ [AiDoctorService] getPatientMedicalReport error: $e');
      rethrow;
    }
  }
}
