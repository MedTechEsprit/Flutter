class GlucoseReading {
  final String id;
  final String patientId;
  final double value; // mg/dL
  final DateTime timestamp;
  final String type; // 'fasting', 'before_meal', 'after_meal', 'bedtime', 'random'
  final String source; // 'manual', 'glucometer'
  final String? notes;

  GlucoseReading({
    required this.id,
    required this.patientId,
    required this.value,
    required this.timestamp,
    required this.type,
    this.source = 'manual',
    this.notes,
  });

  String get typeLabel {
    switch (type) {
      case 'fasting':
        return 'À jeun';
      case 'before_meal':
        return 'Avant repas';
      case 'after_meal':
        return 'Après repas';
      case 'bedtime':
        return 'Coucher';
      case 'random':
        return 'Aléatoire';
      default:
        return type;
    }
  }

  String get statusLabel {
    if (value < 70) return 'Bas';
    if (value <= 130) return 'Normal';
    if (value <= 180) return 'Élevé';
    return 'Critique';
  }

  bool get isNormal => value >= 70 && value <= 180;
  bool get isLow => value < 70;
  bool get isHigh => value > 180;
  bool get isCritical => value > 250 || value < 54;
}
