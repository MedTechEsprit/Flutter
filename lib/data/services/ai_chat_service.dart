import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

/// Response model for AI Chat
class AiChatResponse {
  final String response;
  final Map<String, dynamic>? context;

  AiChatResponse({required this.response, this.context});

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      response: json['response'] ?? '',
      context: json['context'],
    );
  }
}

/// Service for AI Chat (Patient chatbot - diabetes/nutrition assistant)
/// Endpoint: POST /api/ai-chat
class AiChatService {
  final TokenService _tokenService = TokenService();
  final Duration _timeout = const Duration(seconds: 240);

  String get _baseUrl => ApiConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Send a message to the AI chatbot
  /// Returns AI response with optional context (glucoseStats, nutritionStats)
  Future<AiChatResponse> sendMessage(String message) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.aiChat}'),
        headers: headers,
        body: jsonEncode({'message': message}),
      ).timeout(_timeout);

      debugPrint('🤖 [AiChatService] sendMessage: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AiChatResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur du service AI Chat');
      }
    } catch (e) {
      debugPrint('❌ [AiChatService] sendMessage error: $e');
      rethrow;
    }
  }
}
