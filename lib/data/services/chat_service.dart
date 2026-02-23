import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/features/auth/services/auth_service.dart';
import 'package:diab_care/data/models/message_model.dart';

/// Service for conversation & message API calls.
/// Endpoints (all under /api prefix):
///   POST   /conversations
///   GET    /patients/:id/conversations
///   GET    /doctors/:id/conversations
///   GET    /conversations/:id/messages?page=&limit=
///   POST   /conversations/:id/messages
///   PATCH  /conversations/:id/read/:userId
class ChatService {
  final AuthService _authService = AuthService();

  String get _baseUrl => '${AuthService.baseUrl}/api';

  Future<Map<String, String>> get _authHeaders async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Conversations ──────────────────────────────────────────────

  /// Create or get existing conversation between patient & doctor.
  Future<ConversationModel?> createConversation({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations'),
        headers: headers,
        body: jsonEncode({'patientId': patientId, 'doctorId': doctorId}),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📩 createConversation: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ConversationModel.fromJson(data);
      }
      debugPrint('❌ createConversation error: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ createConversation exception: $e');
      return null;
    }
  }

  /// Get all conversations for a patient (populates doctor info).
  Future<List<ConversationModel>> getPatientConversations(String patientId) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$_baseUrl/patients/$patientId/conversations'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      debugPrint('📬 getPatientConversations: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => ConversationModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ getPatientConversations: $e');
      return [];
    }
  }

  /// Get all conversations for a doctor (populates patient info).
  Future<List<ConversationModel>> getDoctorConversations(String doctorId) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$_baseUrl/doctors/$doctorId/conversations'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      debugPrint('📬 getDoctorConversations: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => ConversationModel.fromJson(j, isDoctor: true)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ getDoctorConversations: $e');
      return [];
    }
  }

  // ── Messages ───────────────────────────────────────────────────

  /// Get paginated messages for a conversation (oldest first).
  Future<List<MessageModel>> getMessages(String conversationId, {int page = 1, int limit = 50}) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations/$conversationId/messages?page=$page&limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      debugPrint('💬 getMessages: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List messages = data['messages'] ?? data['data'] ?? data;
        return messages.map((j) => MessageModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ getMessages: $e');
      return [];
    }
  }

  /// Send a message in a conversation.
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/$conversationId/messages'),
        headers: headers,
        body: jsonEncode({
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📤 sendMessage: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MessageModel.fromJson(data);
      }
      debugPrint('❌ sendMessage error: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ sendMessage exception: $e');
      return null;
    }
  }

  /// Mark all messages in a conversation as read for a given user.
  Future<bool> markAsRead(String conversationId, String userId) async {
    try {
      final headers = await _authHeaders;
      final response = await http.patch(
        Uri.parse('$_baseUrl/conversations/$conversationId/read/$userId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint('✅ markAsRead: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ markAsRead: $e');
      return false;
    }
  }
}
