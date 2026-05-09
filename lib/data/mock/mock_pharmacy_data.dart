import '../models/pharmacy_models.dart';

class MockPharmacyData {
  // Static getter aliases for direct property access
  static PharmacyStats get pharmacyStats => getPharmacyStats();
  static List<BadgeLevel> get badges => getAllBadges();
  static List<PerformanceMetric> get performanceMetrics => getPerformanceMetrics();
  static List<ActivityEvent> get activityEvents => getRecentActivity();
  static List<Review> get reviews => getReviews();
  static Map<String, List<MedicationRequest>> get requestsByStatus => {
    'pending': getPendingRequests(),
    'accepted': getAcceptedRequests(),
    'declined': getDeclinedRequests(),
    'expired': getExpiredRequests(),
  };

  static PharmacyStats getPharmacyStats() {
    return PharmacyStats(
      totalRequests: 24,
      acceptedRequests: 18,
      newClients: 15,
      estimatedRevenue: 1800,
      growthPercentage: 12,
      pendingRequests: 3,
    );
  }

  static BadgeLevel getCurrentBadge() {
    return BadgeLevel(
      name: 'PARTENAIRE ARGENT',
      icon: '🥈',
      pointsRequired: 300,
      currentPoints: 285,
      advantages: [
        'Badge Argent visible pour patients',
        'Priorité modérée dans recherches',
        'Analytics détaillés',
      ],
      isUnlocked: true,
    );
  }

  static List<BadgeLevel> getAllBadges() {
    return [
      BadgeLevel(name: 'Bronze Partner', icon: '🥉', pointsRequired: 50, currentPoints: 285, advantages: ['Badge Bronze', 'Visibilité de base'], isUnlocked: true),
      BadgeLevel(name: 'Silver Partner', icon: '🥈', pointsRequired: 150, currentPoints: 285, advantages: ['Badge Argent', 'Priorité modérée', 'Analytics'], isUnlocked: true),
      BadgeLevel(name: 'Gold Partner', icon: '🥇', pointsRequired: 300, currentPoints: 285, advantages: ['Position Top 5', 'Badge Or prestige', 'Boost gratuit 1x/mois'], isUnlocked: false),
      BadgeLevel(name: 'Platinum Partner', icon: '🏆', pointsRequired: 500, currentPoints: 285, advantages: ['Position Top 3', 'Badge Platinum', 'Support prioritaire'], isUnlocked: false),
      BadgeLevel(name: 'Diamant Partner', icon: '⭐', pointsRequired: 1000, currentPoints: 285, advantages: ['Position #1', 'Badge Diamant', 'Tous les avantages'], isUnlocked: false),
    ];
  }

  static List<MedicationRequest> getPendingRequests() {
    final now = DateTime.now();
    return [
      MedicationRequest(id: 'REQ001', patientId: 'A2847', patientName: 'Ahmed K.', medicationName: 'Lantus SoloStar 100 UI/ml', quantity: 5, dosage: '100 UI/ml - Stylo pré-rempli', patientNote: 'Besoin urgent pour demain matin', status: RequestStatus.pending, timestamp: now.subtract(const Duration(minutes: 25)), isUrgent: true),
      MedicationRequest(id: 'REQ002', patientId: 'B3921', patientName: 'Leila M.', medicationName: 'Metformine 850mg', quantity: 3, dosage: '850mg - Boîte de 60 comprimés', status: RequestStatus.pending, timestamp: now.subtract(const Duration(minutes: 45)), isUrgent: false),
      MedicationRequest(id: 'REQ003', patientId: 'C1456', patientName: 'Karim B.', medicationName: 'NovoRapid FlexPen', quantity: 2, dosage: '100 UI/ml - Stylo pré-rempli', patientNote: 'Pour ce soir si possible', status: RequestStatus.pending, timestamp: now.subtract(const Duration(minutes: 18)), isUrgent: true),
    ];
  }

  static List<MedicationRequest> getAcceptedRequests() {
    final now = DateTime.now();
    return [
      MedicationRequest(id: 'REQ004', patientId: 'D7832', patientName: 'Fatma H.', medicationName: 'Glucophage 1000mg', quantity: 2, dosage: '1000mg - Boîte de 60 comprimés', status: RequestStatus.accepted, timestamp: now.subtract(const Duration(hours: 2)), price: 45.0, pickupDeadline: now.add(const Duration(hours: 4)), pharmacyMessage: 'Votre commande est prête', preparationTimeMinutes: 0, isPickedUp: false),
      MedicationRequest(id: 'REQ005', patientId: 'E2194', patientName: 'Mohamed S.', medicationName: 'Lantus SoloStar 100 UI/ml', quantity: 3, dosage: '100 UI/ml - Stylo pré-rempli', status: RequestStatus.accepted, timestamp: now.subtract(const Duration(hours: 5)), price: 120.0, pickupDeadline: now.subtract(const Duration(minutes: 30)), preparationTimeMinutes: 30, isPickedUp: true),
    ];
  }

  static List<MedicationRequest> getDeclinedRequests() {
    final now = DateTime.now();
    return [
      MedicationRequest(id: 'REQ006', patientId: 'F9283', patientName: 'Salma T.', medicationName: 'Trulicity 1.5mg', quantity: 1, dosage: '1.5mg - Stylo pré-rempli', status: RequestStatus.declined, timestamp: now.subtract(const Duration(days: 1)), declineReason: 'Stock épuisé'),
    ];
  }

  static List<MedicationRequest> getExpiredRequests() {
    final now = DateTime.now();
    return [
      MedicationRequest(id: 'REQ007', patientId: 'G4567', patientName: 'Youssef L.', medicationName: 'Jardiance 25mg', quantity: 2, dosage: '25mg - Boîte de 30 comprimés', status: RequestStatus.expired, timestamp: now.subtract(const Duration(hours: 3))),
    ];
  }

  static List<MedicationRequest> getAllRequests() {
    return [...getPendingRequests(), ...getAcceptedRequests(), ...getDeclinedRequests(), ...getExpiredRequests()];
  }

  static List<PerformanceMetric> getPerformanceMetrics() {
    return [
      PerformanceMetric(label: 'Temps de Réponse Moyen', yourValue: '18 min', stars: 5, benchmark: 'Moyenne secteur: 45min', badge: '🎯 Vous êtes dans le TOP 10% !'),
      PerformanceMetric(label: 'Taux d\'Acceptation', yourValue: '75%', stars: 4, benchmark: 'Moyenne secteur: 58%', badge: '💪 Continuez comme ça !'),
    ];
  }

  static List<ActivityEvent> getRecentActivity() {
    return [
      ActivityEvent(icon: '🟢', description: 'Patient Karim a retiré sa commande', timestamp: 'Il y a 5min', value: '+85 TND', type: ActivityType.success),
      ActivityEvent(icon: '🟡', description: 'Nouvelle demande reçue: Lantus', timestamp: 'Il y a 18min', type: ActivityType.pending),
      ActivityEvent(icon: '🟢', description: 'Patient Leila vous a mis 5⭐', timestamp: 'Il y a 1h', value: '💬 "Très rapides et disponibles!"', type: ActivityType.success),
      ActivityEvent(icon: '🟢', description: 'Patient Ahmed a confirmé réservation', timestamp: 'Il y a 2h', value: '+120 TND', type: ActivityType.success),
      ActivityEvent(icon: '🔵', description: 'Vous avez atteint 280 points', timestamp: 'Il y a 3h', value: '🏅 +5 pts', type: ActivityType.achievement),
    ];
  }

  static List<Review> getReviews() {
    return [
      Review(patientName: 'Ahmed K.', rating: 5, comment: 'Trouvé mon insuline en 20min grâce à cette pharmacie. Merci DiabCare!', timestamp: 'Il y a 2 jours'),
      Review(patientName: 'Leila M.', rating: 5, comment: 'Très rapides et disponibles!', timestamp: 'Il y a 1h'),
      Review(patientName: 'Mohamed S.', rating: 4, comment: 'Service correct, bonne disponibilité.', timestamp: 'Il y a 5 jours'),
    ];
  }

  static List<String> getMotivationalMessages() {
    return [
      '🎉 Bravo ! Vous avez gagné 3 nouveaux clients aujourd\'hui grâce à DiabCare',
      '💰 Votre CA DiabCare ce mois : 1,800 TND (+12%)',
      '🏆 Félicitations ! Vous êtes maintenant TOP 5 dans votre zone',
    ];
  }
}
