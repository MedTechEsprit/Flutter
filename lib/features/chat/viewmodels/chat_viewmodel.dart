import 'dart:async';
import 'package:flutter/material.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/models/message_model.dart';
import 'package:diab_care/data/services/chat_service.dart';

/// Shared ViewModel for chat — works for both patient and doctor roles.
/// Manages conversation list + current conversation messages with polling.
class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final TokenService _tokenService = TokenService();

  // ── State ──────────────────────────────────────────────────────
  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _error;
  String? _currentConversationId;
  Timer? _pollTimer;

  // ── Getters ────────────────────────────────────────────────────
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get error => _error;

  int get totalUnread =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  String? get currentUserId => _tokenService.userId;
  String? get currentUserRole => _tokenService.userRole;
  String? get currentUserName {
    final data = _tokenService.userData;
    if (data == null) return null;
    final prenom = data['prenom']?.toString() ?? '';
    final nom = data['nom']?.toString() ?? '';
    return '$prenom $nom'.trim();
  }

  // ── Conversations ──────────────────────────────────────────────

  /// Load conversations for the current user's role.
  Future<void> loadConversations() async {
    // Try sync cache first, fall back to async
    String? userId = _tokenService.userId;
    String? role = _tokenService.userRole;

    // If sync cache is empty, try async load (first login scenario)
    if (userId == null || role == null) {
      userId = await _tokenService.getUserId();
      role = await _tokenService.getUserRole();
    }

    debugPrint('💬 loadConversations: userId=$userId, role=$role');

    if (userId == null || role == null) {
      debugPrint('⚠️ loadConversations: userId or role is null, skipping');
      return;
    }

    _isLoadingConversations = true;
    _error = null;
    notifyListeners();

    try {
      final isDoctor = role!.toLowerCase() == 'medecin';
      if (isDoctor) {
        debugPrint('💬 Loading DOCTOR conversations for $userId');
        _conversations = await _chatService.getDoctorConversations(userId);
      } else {
        debugPrint('💬 Loading PATIENT conversations for $userId');
        _conversations = await _chatService.getPatientConversations(userId);
      }
      debugPrint('💬 Loaded ${_conversations.length} conversations');
    } catch (e) {
      _error = 'Impossible de charger les conversations';
      debugPrint('❌ loadConversations: $e');
    }

    _isLoadingConversations = false;
    notifyListeners();
  }

  /// Create or get a conversation with a doctor (called from patient side).
  Future<ConversationModel?> startConversation(String doctorId) async {
    final userId = _tokenService.userId;
    if (userId == null) return null;

    final conv = await _chatService.createConversation(
      patientId: userId,
      doctorId: doctorId,
    );
    if (conv != null) {
      // Refresh list
      await loadConversations();
    }
    return conv;
  }

  // ── Messages ───────────────────────────────────────────────────

  /// Open a conversation: load messages + mark as read + start polling.
  Future<void> openConversation(String conversationId) async {
    _currentConversationId = conversationId;
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _chatService.getMessages(conversationId);

      // Mark as read
      final userId = _tokenService.userId;
      if (userId != null) {
        await _chatService.markAsRead(conversationId, userId);
        // Update local unread count
        _conversations = _conversations.map((c) {
          if (c.id == conversationId) {
            return ConversationModel(
              id: c.id,
              doctorId: c.doctorId,
              doctorName: c.doctorName,
              patientId: c.patientId,
              patientName: c.patientName,
              lastMessage: c.lastMessage,
              lastMessageTime: c.lastMessageTime,
              unreadCount: 0,
            );
          }
          return c;
        }).toList();
      }
    } catch (e) {
      _error = 'Impossible de charger les messages';
      debugPrint('❌ openConversation: $e');
    }

    _isLoadingMessages = false;
    notifyListeners();

    // Start polling for new messages every 3 seconds
    _startPolling(conversationId);
  }

  /// Send a message in the current conversation.
  Future<bool> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    final userId = _tokenService.userId;
    if (userId == null) return false;

    _isSending = true;
    notifyListeners();

    final msg = await _chatService.sendMessage(
      conversationId: conversationId,
      senderId: userId,
      receiverId: receiverId,
      content: content,
    );

    _isSending = false;

    if (msg != null) {
      _messages = [..._messages, msg];
      // Update conversation's last message locally
      _conversations = _conversations.map((c) {
        if (c.id == conversationId) {
          return ConversationModel(
            id: c.id,
            doctorId: c.doctorId,
            doctorName: c.doctorName,
            patientId: c.patientId,
            patientName: c.patientName,
            lastMessage: content.length > 100 ? content.substring(0, 100) : content,
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
          );
        }
        return c;
      }).toList();
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  // ── Polling ────────────────────────────────────────────────────

  void _startPolling(String conversationId) {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_currentConversationId != conversationId) {
        _stopPolling();
        return;
      }
      try {
        final newMessages = await _chatService.getMessages(conversationId);
        if (newMessages.length != _messages.length) {
          _messages = newMessages;
          // Mark new messages as read
          final userId = _tokenService.userId;
          if (userId != null) {
            _chatService.markAsRead(conversationId, userId);
          }
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Call when leaving the chat detail screen.
  void closeConversation() {
    _stopPolling();
    _currentConversationId = null;
    _messages = [];
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
