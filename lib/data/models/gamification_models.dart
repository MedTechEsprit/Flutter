// 🎮 Gamification Models - Points, Badges, Rankings, Ratings

// ─────────────────────────────────────────────────────────────
// POINTS & STATS
// ─────────────────────────────────────────────────────────────

class PointsStatsResponse {
  final int currentPoints;
  final Badge badge;
  final Ranking ranking;
  final Statistics statistics;
  final TodayStats today;
  final List<String> unlockedBadges;
  final List<BadgeThreshold> badgeThresholds;

  PointsStatsResponse({
    required this.currentPoints,
    required this.badge,
    required this.ranking,
    required this.statistics,
    required this.today,
    required this.unlockedBadges,
    required this.badgeThresholds,
  });

  factory PointsStatsResponse.fromJson(Map<String, dynamic> json) {
    return PointsStatsResponse(
      currentPoints: json['currentPoints'] ?? 0,
      badge: Badge.fromJson(json['badge'] ?? {}),
      ranking: Ranking.fromJson(json['ranking'] ?? {}),
      statistics: Statistics.fromJson(json['statistics'] ?? {}),
      today: TodayStats.fromJson(json['today'] ?? {}),
      unlockedBadges: List<String>.from(json['unlockedBadges'] ?? []),
      badgeThresholds: (json['badgeThresholds'] as List?)
          ?.map((e) => BadgeThreshold.fromJson(e))
          .toList() ?? [],
    );
  }
}

class Badge {
  final String name;
  final String emoji;
  final String description;

  Badge({
    required this.name,
    required this.emoji,
    required this.description,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class Ranking {
  final int rank;
  final int totalPharmacies;
  final int percentile;

  Ranking({
    required this.rank,
    required this.totalPharmacies,
    required this.percentile,
  });

  factory Ranking.fromJson(Map<String, dynamic> json) {
    return Ranking(
      rank: json['rank'] ?? 0,
      totalPharmacies: json['totalPharmacies'] ?? 0,
      percentile: json['percentile'] ?? 0,
    );
  }
}

class Statistics {
  final int totalRequests;
  final int totalAccepted;
  final int totalDeclined;
  final int acceptanceRate;
  final int averageResponseTime;
  final int totalClients;
  final double averageRating;
  final int totalReviews;

  Statistics({
    required this.totalRequests,
    required this.totalAccepted,
    required this.totalDeclined,
    required this.acceptanceRate,
    required this.averageResponseTime,
    required this.totalClients,
    required this.averageRating,
    required this.totalReviews,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalRequests: json['totalRequests'] ?? 0,
      totalAccepted: json['totalAccepted'] ?? 0,
      totalDeclined: json['totalDeclined'] ?? 0,
      acceptanceRate: json['acceptanceRate'] ?? 0,
      averageResponseTime: json['averageResponseTime'] ?? 0,
      totalClients: json['totalClients'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }
}

class TodayStats {
  final int pointsEarned;
  final int activitiesCount;

  TodayStats({
    required this.pointsEarned,
    required this.activitiesCount,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      pointsEarned: json['pointsEarned'] ?? 0,
      activitiesCount: json['activitiesCount'] ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BADGES
// ─────────────────────────────────────────────────────────────

class BadgeThreshold {
  final String badge;
  final String emoji;
  final int minPoints;
  final dynamic maxPoints; // Can be int or "Infinity"
  final String description;

  BadgeThreshold({
    required this.badge,
    required this.emoji,
    required this.minPoints,
    required this.maxPoints,
    required this.description,
  });

  factory BadgeThreshold.fromJson(Map<String, dynamic> json) {
    return BadgeThreshold(
      badge: json['badge'] ?? '',
      emoji: json['emoji'] ?? '',
      minPoints: json['minPoints'] ?? 0,
      maxPoints: json['maxPoints'] ?? 'Infinity',
      description: json['description'] ?? '',
    );
  }

  // Helper: Check if maxPoints is infinity
  bool get isInfinity => maxPoints == 'Infinity' || maxPoints == null;

  // Helper: Get max points as int or large number
  int get maxPointsInt => isInfinity ? 999999 : (maxPoints as int);
}

// ─────────────────────────────────────────────────────────────
// RANKING
// ─────────────────────────────────────────────────────────────

class RankingResponse {
  final String pharmacyId;
  final int rank;
  final int totalPharmacies;
  final int percentile;
  final int points;
  final String nomPharmacie;

  RankingResponse({
    required this.pharmacyId,
    required this.rank,
    required this.totalPharmacies,
    required this.percentile,
    required this.points,
    required this.nomPharmacie,
  });

  factory RankingResponse.fromJson(Map<String, dynamic> json) {
    return RankingResponse(
      pharmacyId: json['pharmacyId'] ?? '',
      rank: json['rank'] ?? 0,
      totalPharmacies: json['totalPharmacies'] ?? 0,
      percentile: json['percentile'] ?? 0,
      points: json['points'] ?? 0,
      nomPharmacie: json['nomPharmacie'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────
// POINTS HISTORY
// ─────────────────────────────────────────────────────────────

class PointsHistoryItem {
  final DateTime timestamp;
  final int points;
  final String description;
  final List<String> breakdown;

  PointsHistoryItem({
    required this.timestamp,
    required this.points,
    required this.description,
    required this.breakdown,
  });

  factory PointsHistoryItem.fromJson(Map<String, dynamic> json) {
    return PointsHistoryItem(
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      points: json['points'] ?? 0,
      description: json['description'] ?? '',
      breakdown: List<String>.from(json['breakdown'] ?? []),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RESPOND TO REQUEST MODELS
// ─────────────────────────────────────────────────────────────

class RespondToRequestDto {
  final String pharmacyId;
  final String status; // "accepted", "unavailable", "declined", "ignored"
  final double? indicativePrice;
  final String? preparationDelay; // "immediate", "30min", "1h", "2h", "other"
  final String? pharmacyMessage;
  final DateTime? pickupDeadline;

  RespondToRequestDto({
    required this.pharmacyId,
    required this.status,
    this.indicativePrice,
    this.preparationDelay,
    this.pharmacyMessage,
    this.pickupDeadline,
  });

  Map<String, dynamic> toJson() => {
    'pharmacyId': pharmacyId,
    'status': status,
    if (indicativePrice != null) 'indicativePrice': indicativePrice,
    if (preparationDelay != null) 'preparationDelay': preparationDelay,
    if (pharmacyMessage != null) 'pharmacyMessage': pharmacyMessage,
    if (pickupDeadline != null) 'pickupDeadline': pickupDeadline?.toIso8601String(),
  };
}

class RespondToRequestResponse {
  final String id;
  final List<PharmacyResponse> pharmacyResponses;

  RespondToRequestResponse({
    required this.id,
    required this.pharmacyResponses,
  });

  factory RespondToRequestResponse.fromJson(Map<String, dynamic> json) {
    return RespondToRequestResponse(
      id: json['_id'] ?? json['id'] ?? '',
      pharmacyResponses: (json['pharmacyResponses'] as List?)
          ?.map((e) => PharmacyResponse.fromJson(e))
          .toList() ?? [],
    );
  }
}

class PharmacyResponse {
  final String pharmacyId;
  final String status;
  final int pointsAwarded;
  final PointsBreakdown pointsBreakdown;
  final int responseTime;
  final DateTime respondedAt;

  PharmacyResponse({
    required this.pharmacyId,
    required this.status,
    required this.pointsAwarded,
    required this.pointsBreakdown,
    required this.responseTime,
    required this.respondedAt,
  });

  factory PharmacyResponse.fromJson(Map<String, dynamic> json) {
    return PharmacyResponse(
      pharmacyId: json['pharmacyId'] ?? '',
      status: json['status'] ?? '',
      pointsAwarded: json['pointsAwarded'] ?? 0,
      pointsBreakdown: PointsBreakdown.fromJson(json['pointsBreakdown'] ?? {}),
      responseTime: json['responseTime'] ?? 0,
      respondedAt: DateTime.tryParse(json['respondedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class PointsBreakdown {
  final int basePoints;
  final int bonusPoints;
  final String reason;

  PointsBreakdown({
    required this.basePoints,
    required this.bonusPoints,
    required this.reason,
  });

  factory PointsBreakdown.fromJson(Map<String, dynamic> json) {
    return PointsBreakdown(
      basePoints: json['basePoints'] ?? 0,
      bonusPoints: json['bonusPoints'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }

  int get totalPoints => basePoints + bonusPoints;
}

// ─────────────────────────────────────────────────────────────
// RATING MODELS
// ─────────────────────────────────────────────────────────────

class CreateRatingDto {
  final String patientId;
  final String pharmacyId;
  final String medicationRequestId;
  final int stars;
  final String? comment;
  final bool medicationAvailable;
  final int? speedRating;
  final int? courtesynRating;

  CreateRatingDto({
    required this.patientId,
    required this.pharmacyId,
    required this.medicationRequestId,
    required this.stars,
    this.comment,
    required this.medicationAvailable,
    this.speedRating,
    this.courtesynRating,
  });

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'pharmacyId': pharmacyId,
    'medicationRequestId': medicationRequestId,
    'stars': stars,
    if (comment != null && comment!.isNotEmpty) 'comment': comment,
    'medicationAvailable': medicationAvailable,
    if (speedRating != null) 'speedRating': speedRating,
    if (courtesynRating != null) 'courtesynRating': courtesynRating,
  };
}

class RatingResponse {
  final String id;
  final String pharmacyId;
  final int stars;
  final int pointsAwarded;
  final int penaltyApplied;
  final DateTime createdAt;

  RatingResponse({
    required this.id,
    required this.pharmacyId,
    required this.stars,
    required this.pointsAwarded,
    required this.penaltyApplied,
    required this.createdAt,
  });

  factory RatingResponse.fromJson(Map<String, dynamic> json) {
    return RatingResponse(
      id: json['_id'] ?? json['id'] ?? '',
      pharmacyId: json['pharmacyId'] ?? '',
      stars: json['stars'] ?? 0,
      pointsAwarded: json['pointsAwarded'] ?? 0,
      penaltyApplied: json['penaltyApplied'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GAMIFICATION EVENT (for UI/UX)
// ─────────────────────────────────────────────────────────────

enum GamificationEventType {
  pointsEarned,
  badgeUnlocked,
  penaltyApplied,
  ratingReceived,
  rankingChanged,
}

class GamificationEvent {
  final GamificationEventType type;
  final int points;
  final String? badgeName;
  final String? badgeEmoji;
  final String description;
  final List<String>? breakdown;
  final int? beforePoints;
  final int? afterPoints;
  final String? reason;
  final DateTime timestamp;

  GamificationEvent({
    required this.type,
    required this.points,
    this.badgeName,
    this.badgeEmoji,
    required this.description,
    this.breakdown,
    this.beforePoints,
    this.afterPoints,
    this.reason,
    required this.timestamp,
  });
}

