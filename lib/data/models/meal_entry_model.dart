/// Model representing a meal entry for nutrition tracking
class MealEntry {
  final String? id;
  final String mealType; // Breakfast, Lunch, Dinner, Snack
  final DateTime time;
  final double carbs;
  final double protein;
  final double fat;
  final double? calories;
  final String? notes;
  final List<String>? composition;
  final String? source; // manual, ai
  final int? confidence;

  MealEntry({
    this.id,
    required this.mealType,
    required this.time,
    required this.carbs,
    required this.protein,
    required this.fat,
    this.calories,
    this.notes,
    this.composition,
    this.source,
    this.confidence,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      mealType: json['name'] ?? json['mealType'] ?? 'Snack',
      time: json['eatenAt'] != null
          ? DateTime.tryParse(json['eatenAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      calories: json['calories'] != null ? (json['calories']).toDouble() : null,
      notes: json['note']?.toString(),
      composition: json['composition'] != null
          ? List<String>.from(json['composition'])
          : null,
      source: json['source']?.toString(),
      confidence: json['confidence'] != null ? (json['confidence'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': mealType,
      'eatenAt': time.toIso8601String(),
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      if (calories != null) 'calories': calories,
      if (notes != null && notes!.isNotEmpty) 'note': notes,
      if (source != null) 'source': source,
      if (confidence != null) 'confidence': confidence,
    };
  }

  MealEntry copyWith({
    String? id,
    String? mealType,
    DateTime? time,
    double? carbs,
    double? protein,
    double? fat,
    double? calories,
    String? notes,
    List<String>? composition,
    String? source,
    int? confidence,
  }) {
    return MealEntry(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      time: time ?? this.time,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      calories: calories ?? this.calories,
      notes: notes ?? this.notes,
      composition: composition ?? this.composition,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
    );
  }
}
