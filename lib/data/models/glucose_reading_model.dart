class GlucoseReading {
  final String id;
  final String patientId;
  final double value; // stored value in chosen unit
  final DateTime timestamp;
  final String type; // 'fasting', 'before_meal', 'after_meal', 'bedtime', 'random'
  final String source; // 'manual', 'glucometer'
  final String unit; // 'mg/dL' or 'mmol/L'
  final String? notes;

  GlucoseReading({
    required this.id,
    required this.patientId,
    required this.value,
    required this.timestamp,
    required this.type,
    this.source = 'manual',
    this.unit = 'mg/dL',
    this.notes,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      value: (json['value'] is num) ? (json['value'] as num).toDouble() : double.tryParse(json['value']?.toString() ?? '0') ?? 0,
      timestamp: json['measuredAt'] != null
          ? DateTime.tryParse(json['measuredAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: json['period']?.toString() ?? 'fasting',
      source: json['source']?.toString() ?? 'manual',
      unit: json['unit']?.toString() ?? 'mg/dL',
      notes: json['note']?.toString(),
    );
  }

  /// Value displayed in mg/dL regardless of stored unit
  double get valueInMgDl => unit == 'mmol/L' ? value * 18.0182 : value;

  /// Value displayed in mmol/L regardless of stored unit
  double get valueInMmolL => unit == 'mg/dL' ? value / 18.0182 : value;

  /// Get value in a specified display unit
  double valueIn(String displayUnit) =>
      displayUnit == 'mmol/L' ? valueInMmolL : valueInMgDl;

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

  /// Status based on mg/dL thresholds
  String get statusLabel {
    final mgdl = valueInMgDl;
    if (mgdl < 70) return 'Bas';
    if (mgdl <= 130) return 'Normal';
    if (mgdl <= 180) return 'Élevé';
    return 'Critique';
  }

  bool get isNormal => valueInMgDl >= 70 && valueInMgDl <= 180;
  bool get isLow => valueInMgDl < 70;
  bool get isHigh => valueInMgDl > 180;
  bool get isCritical => valueInMgDl > 250 || valueInMgDl < 54;
}
