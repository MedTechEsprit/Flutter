class GlucoseReading {
  final String id;
  final String patientId;
  final double value; // mg/dL
  final DateTime timestamp;
  final String type; // 'fasting', 'before_meal', 'after_meal', 'bedtime', 'random'
  final String source; // 'manual', 'glucometer'
  final String? notes;
  final String? contexte;
  final String? humeur;
  final String? activiteAvant;

  GlucoseReading({
    required this.id,
    required this.patientId,
    required this.value,
    required this.timestamp,
    required this.type,
    this.source = 'manual',
    this.notes,
    this.contexte,
    this.humeur,
    this.activiteAvant,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    // Le backend utilise l'enum: fasting, before_meal, after_meal, bedtime
    String type = json['period']?.toString() ?? 'random';
    // Accepter les valeurs telles quelles du backend
    if (!['fasting', 'before_meal', 'after_meal', 'bedtime', 'random'].contains(type)) {
      type = 'random';
    }

    return GlucoseReading(
      id: json['_id'] ?? json['id'] ?? '',
      patientId: json['patientId'] ?? json['patient'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['measuredAt'] != null
          ? DateTime.parse(json['measuredAt'].toString())
          : DateTime.now(),
      type: type,
      source: json['source'] ?? 'manual',
      notes: json['notes'],
      contexte: json['contexte'],
      humeur: json['humeur'],
      activiteAvant: json['activiteAvant'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'measuredAt': timestamp.toIso8601String(),
      'period': type, // déjà au bon format: fasting, before_meal, etc.
      'source': source,
      if (notes != null) 'notes': notes,
      if (contexte != null) 'contexte': contexte,
      if (humeur != null) 'humeur': humeur,
      if (activiteAvant != null) 'activiteAvant': activiteAvant,
    };
  }

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
