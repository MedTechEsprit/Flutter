class MedicationRequest {
  final String id;
  final String patientId;
  final String patientName;
  final String medicationName;
  final int quantity;
  final String dosage;
  final String? patientNote;
  final RequestStatus status;
  final DateTime timestamp;
  final bool isUrgent;
  final String? declineReason;
  final double? price;
  final DateTime? pickupDeadline;
  final String? pharmacyMessage;
  final int? preparationTimeMinutes;
  final bool isPickedUp;

  MedicationRequest({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.medicationName,
    required this.quantity,
    required this.dosage,
    this.patientNote,
    required this.status,
    required this.timestamp,
    this.isUrgent = false,
    this.declineReason,
    this.price,
    this.pickupDeadline,
    this.pharmacyMessage,
    this.preparationTimeMinutes,
    this.isPickedUp = false,
  });
}

enum RequestStatus {
  pending,
  accepted,
  declined,
  expired,
}

class PharmacyStats {
  final int totalRequests;
  final int acceptedRequests;
  final int newClients;
  final double estimatedRevenue;
  final double growthPercentage;
  final int pendingRequests;
  final double averageRating;
  final int totalReviews;
  final int responseTimeMinutes;

  PharmacyStats({
    required this.totalRequests,
    required this.acceptedRequests,
    required this.newClients,
    required this.estimatedRevenue,
    required this.growthPercentage,
    required this.pendingRequests,
    this.averageRating = 4.8,
    this.totalReviews = 42,
    this.responseTimeMinutes = 18,
  });

  double get acceptanceRate => totalRequests > 0 ? (acceptedRequests / totalRequests) * 100 : 0;
}

class BadgeLevel {
  final String name;
  final String icon;
  final int pointsRequired;
  final int currentPoints;
  final List<String> advantages;
  final bool isUnlocked;

  BadgeLevel({
    required this.name,
    required this.icon,
    required this.pointsRequired,
    required this.currentPoints,
    required this.advantages,
    required this.isUnlocked,
  });

  double get progress => currentPoints / pointsRequired;
  int get pointsRemaining => pointsRequired - currentPoints;
  int get maxPoints => pointsRequired;
}

class PerformanceMetric {
  final String label;
  final String yourValue;
  final int stars;
  final String benchmark;
  final String badge;

  PerformanceMetric({
    required this.label,
    required this.yourValue,
    required this.stars,
    required this.benchmark,
    required this.badge,
  });

  String get value => yourValue;
}

class ActivityEvent {
  final String icon;
  final String description;
  final String timestamp;
  final String? value;
  final ActivityType type;

  ActivityEvent({
    required this.icon,
    required this.description,
    required this.timestamp,
    this.value,
    required this.type,
  });
}

enum ActivityType {
  success,
  pending,
  info,
  achievement,
}

class Review {
  final String patientName;
  final int rating;
  final String comment;
  final String timestamp;

  Review({
    required this.patientName,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });
}
