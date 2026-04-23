// ─── Pharmacy Profile ───────────────────────────────────────
class PharmacyProfile {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String role;
  final String nomPharmacie;
  final String numeroOrdre;
  final String telephonePharmacie;
  final String adressePharmacie;
  final String? photoProfil;
  final String? profileImage;
  final PharmacyLocation? location;
  final int points;
  final String badgeLevel;
  final int totalRequestsReceived;
  final int totalRequestsAccepted;
  final int totalRequestsDeclined;
  final int totalClients;
  final double totalRevenue;
  final int averageResponseTime;
  final double averageRating;
  final int totalReviews;
  final bool isOnDuty;
  final bool notificationsPush;
  final bool notificationsEmail;
  final bool notificationsSMS;
  final int visibilityRadius;
  final String statutCompte;

  PharmacyProfile({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
    required this.nomPharmacie,
    required this.numeroOrdre,
    required this.telephonePharmacie,
    required this.adressePharmacie,
    this.photoProfil,
    this.profileImage,
    this.location,
    this.points = 0,
    this.badgeLevel = 'bronze',
    this.totalRequestsReceived = 0,
    this.totalRequestsAccepted = 0,
    this.totalRequestsDeclined = 0,
    this.totalClients = 0,
    this.totalRevenue = 0,
    this.averageResponseTime = 0,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.isOnDuty = true,
    this.notificationsPush = true,
    this.notificationsEmail = true,
    this.notificationsSMS = false,
    this.visibilityRadius = 5,
    this.statutCompte = 'ACTIF',
  });

  factory PharmacyProfile.fromJson(Map<String, dynamic> json) {
    return PharmacyProfile(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone']?.toString() ?? '',
      role: json['role'] ?? '',
      nomPharmacie: json['nomPharmacie'] ?? '',
      numeroOrdre: json['numeroOrdre'] ?? '',
      telephonePharmacie: json['telephonePharmacie'] ?? '',
      adressePharmacie: json['adressePharmacie'] ?? json['adresse'] ?? '',
      photoProfil: json['photoProfil']?.toString(),
      profileImage: json['profileImage']?.toString(),
      location: json['location'] != null
          ? PharmacyLocation.fromJson(json['location'])
          : null,
      points: json['points'] ?? 0,
      badgeLevel: json['badgeLevel'] ?? 'bronze',
      totalRequestsReceived: json['totalRequestsReceived'] ?? 0,
      totalRequestsAccepted: json['totalRequestsAccepted'] ?? 0,
      totalRequestsDeclined: json['totalRequestsDeclined'] ?? 0,
      totalClients: json['totalClients'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      averageResponseTime: json['averageResponseTime'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      isOnDuty: json['isOnDuty'] ?? true,
      notificationsPush: json['notificationsPush'] ?? true,
      notificationsEmail: json['notificationsEmail'] ?? true,
      notificationsSMS: json['notificationsSMS'] ?? false,
      visibilityRadius: json['visibilityRadius'] ?? 5,
      statutCompte: json['statutCompte'] ?? 'ACTIF',
    );
  }

  String? get displayProfileImage {
    if (photoProfil != null && photoProfil!.trim().isNotEmpty) {
      return photoProfil;
    }
    if (profileImage != null && profileImage!.trim().isNotEmpty) {
      return profileImage;
    }
    return null;
  }

  String get displayTelephone {
    if (telephone.trim().isNotEmpty) return telephone;
    return telephonePharmacie;
  }
}

class PharmacyLocation {
  final String type;
  final List<double> coordinates;

  PharmacyLocation({required this.type, required this.coordinates});

  factory PharmacyLocation.fromJson(Map<String, dynamic> json) {
    return PharmacyLocation(
      type: json['type'] ?? 'Point',
      coordinates:
          (json['coordinates'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }

  double? get longitude => coordinates.isNotEmpty ? coordinates[0] : null;
  double? get latitude => coordinates.length > 1 ? coordinates[1] : null;

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }
}

// ─── Dashboard Stats ───────────────────────────────────────
class DashboardStats {
  final int totalRequestsReceived;
  final int totalRequestsAccepted;
  final int totalRequestsDeclined;
  final int totalClients;
  final double totalRevenue;
  final int averageResponseTime;
  final double averageRating;
  final int totalReviews;
  final double acceptanceRate;
  final double responseRate;

  DashboardStats({
    required this.totalRequestsReceived,
    required this.totalRequestsAccepted,
    required this.totalRequestsDeclined,
    required this.totalClients,
    required this.totalRevenue,
    required this.averageResponseTime,
    required this.averageRating,
    required this.totalReviews,
    required this.acceptanceRate,
    required this.responseRate,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalRequestsReceived: json['totalRequestsReceived'] ?? 0,
      totalRequestsAccepted: json['totalRequestsAccepted'] ?? 0,
      totalRequestsDeclined: json['totalRequestsDeclined'] ?? 0,
      totalClients: json['totalClients'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      averageResponseTime: json['averageResponseTime'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      acceptanceRate: (json['acceptanceRate'] ?? 0).toDouble(),
      responseRate: (json['responseRate'] ?? 0).toDouble(),
    );
  }
}

// ─── Monthly Stats ───────────────────────────────────────
class MonthlyStats {
  final String month;
  final int requestsCount;
  final int acceptedCount;
  final int clientsCount;
  final double revenue;

  MonthlyStats({
    required this.month,
    required this.requestsCount,
    required this.acceptedCount,
    required this.clientsCount,
    required this.revenue,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      month: json['month'] ?? '',
      requestsCount: json['requestsCount'] ?? 0,
      acceptedCount: json['acceptedCount'] ?? 0,
      clientsCount: json['clientsCount'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

// ─── Badge Progression ───────────────────────────────────────
class BadgeProgression {
  final int currentPoints;
  final String currentBadge;
  final int pointsToNextLevel;
  final String nextBadgeName;

  BadgeProgression({
    required this.currentPoints,
    required this.currentBadge,
    required this.pointsToNextLevel,
    required this.nextBadgeName,
  });

  factory BadgeProgression.fromJson(Map<String, dynamic> json) {
    return BadgeProgression(
      currentPoints: json['currentPoints'] ?? 0,
      currentBadge: json['currentBadge'] ?? 'bronze',
      pointsToNextLevel: json['pointsToNextLevel'] ?? 0,
      nextBadgeName: json['nextBadgeName'] ?? '',
    );
  }

  double get progressPercentage {
    if (nextBadgeName == 'max') return 100.0;
    final badgeThresholds = {
      'bronze': 50,
      'silver': 100,
      'gold': 150,
      'platinum': 200,
    };
    final threshold = badgeThresholds[currentBadge] ?? 50;
    return (currentPoints % threshold) / threshold * 100;
  }

  String get badgeIcon {
    switch (currentBadge) {
      case 'bronze':
        return '🥉';
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      case 'platinum':
        return '🏆';
      case 'diamond':
        return '💎';
      default:
        return '🥉';
    }
  }

  String get badgeDisplayName {
    switch (currentBadge) {
      case 'bronze':
        return 'Bronze Partner';
      case 'silver':
        return 'Silver Partner';
      case 'gold':
        return 'Gold Partner';
      case 'platinum':
        return 'Platinum Partner';
      case 'diamond':
        return 'Diamond Partner';
      default:
        return 'Bronze Partner';
    }
  }
}

// ─── Performance Comparison ───────────────────────────────────────
class PerformanceComparison {
  final int pharmacyAverageResponseTime;
  final int sectorAverage;
  final double pharmacyAverageRating;
  final double sectorAverageRating;
  final int topPercentage;

  PerformanceComparison({
    required this.pharmacyAverageResponseTime,
    required this.sectorAverage,
    required this.pharmacyAverageRating,
    required this.sectorAverageRating,
    required this.topPercentage,
  });

  factory PerformanceComparison.fromJson(Map<String, dynamic> json) {
    return PerformanceComparison(
      pharmacyAverageResponseTime: json['pharmacyAverageResponseTime'] ?? 0,
      sectorAverage: json['sectorAverage'] ?? 0,
      pharmacyAverageRating: (json['pharmacyAverageRating'] ?? 0).toDouble(),
      sectorAverageRating: (json['sectorAverageRating'] ?? 0).toDouble(),
      topPercentage: json['topPercentage'] ?? 0,
    );
  }
}

// ─── Value Proposition ───────────────────────────────────────
class ValueProposition {
  final EquivalentAdvertisingCost equivalentAdvertisingCost;
  final double pharmacyPays;
  final double annualSavings;

  ValueProposition({
    required this.equivalentAdvertisingCost,
    required this.pharmacyPays,
    required this.annualSavings,
  });

  factory ValueProposition.fromJson(Map<String, dynamic> json) {
    return ValueProposition(
      equivalentAdvertisingCost: EquivalentAdvertisingCost.fromJson(
        json['equivalentAdvertisingCost'] ?? {},
      ),
      pharmacyPays: (json['pharmacyPays'] ?? 0).toDouble(),
      annualSavings: (json['annualSavings'] ?? 0).toDouble(),
    );
  }
}

class EquivalentAdvertisingCost {
  final double targetedAds;
  final double localSEO;
  final double analytics;
  final double totalValue;

  EquivalentAdvertisingCost({
    required this.targetedAds,
    required this.localSEO,
    required this.analytics,
    required this.totalValue,
  });

  factory EquivalentAdvertisingCost.fromJson(Map<String, dynamic> json) {
    return EquivalentAdvertisingCost(
      targetedAds: (json['targetedAds'] ?? 0).toDouble(),
      localSEO: (json['localSEO'] ?? 0).toDouble(),
      analytics: (json['analytics'] ?? 0).toDouble(),
      totalValue: (json['totalValue'] ?? 0).toDouble(),
    );
  }
}

// ─── Annual Projection ───────────────────────────────────────
class AnnualProjection {
  final int estimatedYearlyClients;
  final double estimatedYearlyRevenue;

  AnnualProjection({
    required this.estimatedYearlyClients,
    required this.estimatedYearlyRevenue,
  });

  factory AnnualProjection.fromJson(Map<String, dynamic> json) {
    return AnnualProjection(
      estimatedYearlyClients: json['estimatedYearlyClients'] ?? 0,
      estimatedYearlyRevenue: (json['estimatedYearlyRevenue'] ?? 0).toDouble(),
    );
  }
}

// ─── Activity Event ───────────────────────────────────────
class ApiActivityEvent {
  final String id;
  final String pharmacyId;
  final String activityType;
  final String description;
  final double? amount;
  final int? points;
  final String relativeTime;
  final DateTime createdAt;

  ApiActivityEvent({
    required this.id,
    required this.pharmacyId,
    required this.activityType,
    required this.description,
    this.amount,
    this.points,
    required this.relativeTime,
    required this.createdAt,
  });

  factory ApiActivityEvent.fromJson(Map<String, dynamic> json) {
    return ApiActivityEvent(
      id: json['_id'] ?? '',
      pharmacyId: json['pharmacyId'] ?? '',
      activityType: json['activityType'] ?? '',
      description: json['description'] ?? '',
      amount: json['amount']?.toDouble(),
      points: json['points'],
      relativeTime: json['relativeTime'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get icon {
    switch (activityType) {
      case 'request_received':
        return '🟡';
      case 'request_accepted':
        return '🟢';
      case 'request_declined':
        return '🔴';
      case 'client_pickup':
        return '🟢';
      case 'review_received':
        return '⭐';
      case 'points_earned':
        return '🔵';
      case 'badge_unlocked':
        return '🏅';
      case 'boost_activated':
        return '🚀';
      default:
        return '📋';
    }
  }
}

// ─── Review ───────────────────────────────────────
class ApiReview {
  final String id;
  final String patientName;
  final int rating;
  final String comment;
  final String timestamp;
  final DateTime createdAt;

  ApiReview({
    required this.id,
    required this.patientName,
    required this.rating,
    required this.comment,
    required this.timestamp,
    required this.createdAt,
  });

  factory ApiReview.fromJson(Map<String, dynamic> json) {
    return ApiReview(
      id: json['_id'] ?? '',
      patientName: json['patientName'] ?? 'Patient anonyme',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      timestamp: json['relativeTime'] ?? json['timestamp'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// ─── Full Dashboard Model ───────────────────────────────────────
class PharmacyDashboardModel {
  final PharmacyProfile pharmacy;
  final DashboardStats stats;
  final List<MonthlyStats> monthlyStats;
  final int pendingRequestsCount;
  final List<ApiActivityEvent> recentActivity;
  final List<ApiReview> recentReviews;
  final BadgeProgression badgeProgression;
  final PerformanceComparison performanceComparison;
  final ValueProposition valueProposition;
  final AnnualProjection annualProjection;
  final int missedOpportunitiesCount;

  PharmacyDashboardModel({
    required this.pharmacy,
    required this.stats,
    required this.monthlyStats,
    required this.pendingRequestsCount,
    required this.recentActivity,
    required this.recentReviews,
    required this.badgeProgression,
    required this.performanceComparison,
    required this.valueProposition,
    required this.annualProjection,
    required this.missedOpportunitiesCount,
  });

  factory PharmacyDashboardModel.fromJson(Map<String, dynamic> json) {
    return PharmacyDashboardModel(
      pharmacy: PharmacyProfile.fromJson(json['pharmacy'] ?? {}),
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
      monthlyStats:
          (json['monthlyStats'] as List?)
              ?.map((m) => MonthlyStats.fromJson(m))
              .toList() ??
          [],
      pendingRequestsCount: json['pendingRequestsCount'] ?? 0,
      recentActivity:
          (json['recentActivity'] as List?)
              ?.map((a) => ApiActivityEvent.fromJson(a))
              .toList() ??
          [],
      recentReviews:
          (json['recentReviews'] as List?)
              ?.map((r) => ApiReview.fromJson(r))
              .toList() ??
          [],
      badgeProgression: BadgeProgression.fromJson(
        json['badgeProgression'] ?? {},
      ),
      performanceComparison: PerformanceComparison.fromJson(
        json['performanceComparison'] ?? {},
      ),
      valueProposition: ValueProposition.fromJson(
        json['valueProposition'] ?? {},
      ),
      annualProjection: AnnualProjection.fromJson(
        json['annualProjection'] ?? {},
      ),
      missedOpportunitiesCount: json['missedOpportunitiesCount'] ?? 0,
    );
  }
}

// ─── Medication Request Model ───────────────────────────────────────
class MedicationRequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String medicationName;
  final String dosage;
  final int quantity;
  final String format;
  final String urgencyLevel;
  final String patientNote;
  final String globalStatus;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PharmacyResponseModel> pharmacyResponses;

  MedicationRequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.medicationName,
    required this.dosage,
    required this.quantity,
    required this.format,
    required this.urgencyLevel,
    required this.patientNote,
    required this.globalStatus,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.pharmacyResponses,
  });

  factory MedicationRequestModel.fromJson(Map<String, dynamic> json) {
    String patientId = '';
    String patientName = '';
    final patientField = json['patientId'];
    if (patientField is Map<String, dynamic>) {
      patientId = patientField['_id']?.toString() ?? '';
      final prenom = patientField['prenom']?.toString() ?? '';
      final nom = patientField['nom']?.toString() ?? '';
      patientName = '$prenom $nom'.trim();
      if (patientName.isEmpty) {
        patientName =
            patientField['fullName']?.toString() ??
            patientField['name']?.toString() ??
            '';
      }
    } else {
      patientId = patientField?.toString() ?? '';
    }

    if (patientName.isEmpty) {
      patientName =
          json['patientName']?.toString() ??
          json['patientFullName']?.toString() ??
          '';
    }

    return MedicationRequestModel(
      id: json['_id'] ?? '',
      patientId: patientId,
      patientName: patientName,
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      quantity: json['quantity'] ?? 0,
      format: json['format'] ?? '',
      urgencyLevel: json['urgencyLevel'] ?? 'normal',
      patientNote: json['patientNote'] ?? '',
      globalStatus: json['globalStatus'] ?? 'open',
      expiresAt:
          DateTime.tryParse(json['expiresAt'] ?? '') ??
          DateTime.now().add(const Duration(hours: 2)),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      pharmacyResponses:
          (json['pharmacyResponses'] as List?)
              ?.map((r) => PharmacyResponseModel.fromJson(r))
              .toList() ??
          [],
    );
  }

  bool get isUrgent =>
      urgencyLevel == 'urgent' || urgencyLevel == 'très urgent';

  /// Get the response for the current pharmacy
  PharmacyResponseModel? getMyResponse(String myPharmacyId) {
    try {
      return pharmacyResponses.firstWhere((r) => r.pharmacyId == myPharmacyId);
    } catch (e) {
      return null;
    }
  }

  /// Calculate time remaining before expiration
  Duration get timeRemaining => expiresAt.difference(DateTime.now());
  bool get isExpired => timeRemaining.isNegative;
}

class PharmacyResponseModel {
  final String pharmacyId;
  final String status;
  final int? responseTime;
  final double? indicativePrice;
  final String? preparationDelay;
  final String? pharmacyMessage;
  final DateTime? pickupDeadline;
  final DateTime? respondedAt;

  PharmacyResponseModel({
    required this.pharmacyId,
    required this.status,
    this.responseTime,
    this.indicativePrice,
    this.preparationDelay,
    this.pharmacyMessage,
    this.pickupDeadline,
    this.respondedAt,
  });

  factory PharmacyResponseModel.fromJson(Map<String, dynamic> json) {
    return PharmacyResponseModel(
      pharmacyId: json['pharmacyId'] ?? '',
      status: json['status'] ?? 'pending',
      responseTime: json['responseTime'],
      indicativePrice: json['indicativePrice']?.toDouble(),
      preparationDelay: json['preparationDelay'],
      pharmacyMessage: json['pharmacyMessage'],
      pickupDeadline: json['pickupDeadline'] != null
          ? DateTime.tryParse(json['pickupDeadline'])
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.tryParse(json['respondedAt'])
          : null,
    );
  }
}
