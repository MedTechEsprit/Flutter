// Appointment Model for Flutter
// Location: lib/data/models/appointment_model.dart

/// Enum for appointment type
enum AppointmentType {
  ONLINE,
  PHYSICAL;

  String get displayName {
    switch (this) {
      case AppointmentType.ONLINE:
        return 'Online';
      case AppointmentType.PHYSICAL:
        return 'Physical';
    }
  }

  static AppointmentType fromString(String value) {
    return AppointmentType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => AppointmentType.PHYSICAL,
    );
  }
}

/// Enum for appointment status
enum AppointmentStatus {
  PENDING,
  CONFIRMED,
  COMPLETED,
  CANCELLED;

  String get displayName {
    switch (this) {
      case AppointmentStatus.PENDING:
        return 'Pending';
      case AppointmentStatus.CONFIRMED:
        return 'Confirmed';
      case AppointmentStatus.COMPLETED:
        return 'Completed';
      case AppointmentStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => AppointmentStatus.PENDING,
    );
  }
}

class AppointmentModel {
  final String id;
  final String patientId;
  final String? patientName;
  final String doctorId;
  final String? doctorName;
  final String? doctorSpecialty;
  final DateTime dateTime;
  final AppointmentType type;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.doctorId,
    this.doctorName,
    this.doctorSpecialty,
    required this.dateTime,
    required this.type,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // From JSON (from backend response)
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id'] as String,
      patientId: json['patientId'] is String
          ? json['patientId'] as String
          : (json['patientId']['_id'] as String? ?? ''),
      patientName: json['patientName'] as String? ??
          (json['patientId'] is Map ? '${json['patientId']['nom'] ?? ''} ${json['patientId']['prenom'] ?? ''}'.trim() : null),
      doctorId: json['doctorId'] is String
          ? json['doctorId'] as String
          : (json['doctorId']['_id'] as String? ?? ''),
      doctorName: json['doctorName'] as String? ??
          (json['doctorId'] is Map ? '${json['doctorId']['nom'] ?? ''} ${json['doctorId']['prenom'] ?? ''}'.trim() : null),
      doctorSpecialty: json['doctorSpecialty'] as String? ??
          (json['doctorId'] is Map ? json['doctorId']['speciality'] as String? : null),
      dateTime: DateTime.parse(json['dateTime'] as String),
      type: AppointmentType.fromString(json['type'] as String),
      status: AppointmentStatus.fromString(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // To JSON (for sending to backend)
  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'dateTime': dateTime.toIso8601String(),
      'type': type.name, // ONLINE or PHYSICAL
      'status': status.name, // PENDING, CONFIRMED, etc.
      if (notes != null) 'notes': notes,
    };
  }

  // Helper method to get formatted date
  String get formattedDate {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Helper method to get formatted time
  String get formattedTime {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Helper method to get formatted date and time
  String get formattedDateTime {
    return '$formattedDate at $formattedTime';
  }

  // Status color helper
  String get statusColor {
    switch (status) {
      case AppointmentStatus.CONFIRMED:
        return 'green';
      case AppointmentStatus.PENDING:
        return 'orange';
      case AppointmentStatus.COMPLETED:
        return 'blue';
      case AppointmentStatus.CANCELLED:
        return 'red';
    }
  }

  // Type icon helper
  String get typeIcon {
    return type == AppointmentType.ONLINE ? '💻' : '🏥';
  }

  // Copy with method for updates
  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    DateTime? dateTime,
    AppointmentType? type,
    AppointmentStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model for doctor appointment statistics
class AppointmentStats {
  final int total;
  final Map<AppointmentStatus, int> byStatus;
  final Map<AppointmentType, int> byType;

  AppointmentStats({
    required this.total,
    required this.byStatus,
    required this.byType,
  });

  factory AppointmentStats.fromJson(Map<String, dynamic> json) {
    print('📊 Parsing AppointmentStats from JSON: $json');

    // Handle byStatus - can be either an array or a map
    Map<AppointmentStatus, int> statusMap = {};

    if (json['byStatus'] is List) {
      // Backend format: [{"_id": "PENDING", "count": 3}, ...]
      final byStatusArray = json['byStatus'] as List<dynamic>;
      for (var item in byStatusArray) {
        final statusName = item['_id'] as String;
        final count = item['count'] as int;

        try {
          final status = AppointmentStatus.fromString(statusName);
          statusMap[status] = count;
        } catch (e) {
          print('⚠️ Unknown status: $statusName');
        }
      }

      // Initialize missing statuses with 0
      for (var status in AppointmentStatus.values) {
        if (!statusMap.containsKey(status)) {
          statusMap[status] = 0;
        }
      }

      // Also check top-level completed and cancelled fields
      if (json.containsKey('completed')) {
        statusMap[AppointmentStatus.COMPLETED] = json['completed'] as int;
      }
      if (json.containsKey('cancelled')) {
        statusMap[AppointmentStatus.CANCELLED] = json['cancelled'] as int;
      }
    } else if (json['byStatus'] is Map) {
      // Alternative format: {"PENDING": 3, "CONFIRMED": 0, ...}
      final byStatusJson = json['byStatus'] as Map<String, dynamic>;
      statusMap = {
        AppointmentStatus.PENDING: byStatusJson['PENDING'] as int? ?? 0,
        AppointmentStatus.CONFIRMED: byStatusJson['CONFIRMED'] as int? ?? 0,
        AppointmentStatus.COMPLETED: byStatusJson['COMPLETED'] as int? ?? 0,
        AppointmentStatus.CANCELLED: byStatusJson['CANCELLED'] as int? ?? 0,
      };
    } else {
      // Default: all zeros
      statusMap = {
        AppointmentStatus.PENDING: 0,
        AppointmentStatus.CONFIRMED: 0,
        AppointmentStatus.COMPLETED: 0,
        AppointmentStatus.CANCELLED: 0,
      };
    }

    // Handle byType (if present)
    Map<AppointmentType, int> typeMap = {};
    if (json['byType'] is Map) {
      final byTypeJson = json['byType'] as Map<String, dynamic>;
      typeMap = {
        AppointmentType.ONLINE: byTypeJson['ONLINE'] as int? ?? 0,
        AppointmentType.PHYSICAL: byTypeJson['PHYSICAL'] as int? ?? 0,
      };
    } else {
      typeMap = {
        AppointmentType.ONLINE: 0,
        AppointmentType.PHYSICAL: 0,
      };
    }

    print('✅ Parsed stats: total=${json['total']}, pending=${statusMap[AppointmentStatus.PENDING]}');

    return AppointmentStats(
      total: json['total'] as int? ?? 0,
      byStatus: statusMap,
      byType: typeMap,
    );
  }

  int get pendingCount => byStatus[AppointmentStatus.PENDING] ?? 0;
  int get confirmedCount => byStatus[AppointmentStatus.CONFIRMED] ?? 0;
  int get completedCount => byStatus[AppointmentStatus.COMPLETED] ?? 0;
  int get cancelledCount => byStatus[AppointmentStatus.CANCELLED] ?? 0;
  int get onlineCount => byType[AppointmentType.ONLINE] ?? 0;
  int get physicalCount => byType[AppointmentType.PHYSICAL] ?? 0;
}


