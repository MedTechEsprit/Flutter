class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String senderName;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.senderName = '',
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: json['senderId'] is Map
          ? json['senderId']['_id']?.toString() ?? ''
          : json['senderId']?.toString() ?? '',
      receiverId: json['receiverId'] is Map
          ? json['receiverId']['_id']?.toString() ?? ''
          : json['receiverId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
      isRead: json['isRead'] == true,
      senderName: json['senderName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
      };
}

class ConversationModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String pharmacistId;
  final String pharmacistName;
  final String patientId;
  final String patientName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String type; // 'doctor' or 'pharmacist'

  ConversationModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.pharmacistId = '',
    this.pharmacistName = '',
    required this.patientId,
    required this.patientName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.type = 'doctor',
  });

  /// Parse from backend JSON — works for patient, doctor, and pharmacist conversations.
  factory ConversationModel.fromJson(Map<String, dynamic> json, {bool isDoctor = false}) {
    // Extract doctor info
    String doctorId = '';
    String doctorName = '';
    final doctorField = json['doctorId'];
    if (doctorField is Map) {
      doctorId = doctorField['_id']?.toString() ?? '';
      final nom = doctorField['nom']?.toString() ?? '';
      final prenom = doctorField['prenom']?.toString() ?? '';
      doctorName = 'Dr. $prenom $nom'.trim();
    } else {
      doctorId = doctorField?.toString() ?? '';
    }

    // Extract pharmacist info
    String pharmacistId = '';
    String pharmacistName = '';
    final pharmacistField = json['pharmacistId'];
    if (pharmacistField is Map) {
      pharmacistId = pharmacistField['_id']?.toString() ?? '';
      final nom = pharmacistField['nom']?.toString() ?? '';
      final prenom = pharmacistField['prenom']?.toString() ?? '';
      final nomPharmacie = pharmacistField['nomPharmacie']?.toString() ?? '';
      pharmacistName = nomPharmacie.isNotEmpty ? nomPharmacie : '$prenom $nom'.trim();
    } else {
      pharmacistId = pharmacistField?.toString() ?? '';
    }

    // Extract patient info
    String patientId = '';
    String patientName = '';
    final patientField = json['patientId'];
    if (patientField is Map) {
      patientId = patientField['_id']?.toString() ?? '';
      final nom = patientField['nom']?.toString() ?? '';
      final prenom = patientField['prenom']?.toString() ?? '';
      patientName = '$prenom $nom'.trim();
    } else {
      patientId = patientField?.toString() ?? '';
    }

    final type = json['type']?.toString() ?? (pharmacistId.isNotEmpty && doctorId.isEmpty ? 'pharmacist' : 'doctor');

    return ConversationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      doctorId: doctorId,
      doctorName: doctorName,
      pharmacistId: pharmacistId,
      pharmacistName: pharmacistName,
      patientId: patientId,
      patientName: patientName,
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'].toString()) ?? DateTime.now()
          : json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      type: type,
    );
  }

  /// The "other" person's name depending on role context:
  /// For patient: show doctor or pharmacist name
  /// For doctor: show patient name
  /// For pharmacist: show patient name
  String displayNameFor(String role) {
    final r = role.toLowerCase();
    if (r == 'medecin') return patientName;
    if (r == 'pharmacien') return patientName;
    // patient: show doctor or pharmacist
    if (type == 'pharmacist') return pharmacistName;
    return doctorName;
  }

  /// The other person's ID for sending messages
  String otherIdFor(String role) {
    final r = role.toLowerCase();
    if (r == 'medecin') return patientId;
    if (r == 'pharmacien') return patientId;
    if (type == 'pharmacist') return pharmacistId;
    return doctorId;
  }
}
