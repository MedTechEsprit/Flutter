/// Local model for a logged meal (manual or AI-captured).
class MealEntry {
  final String id;
  final String mealType; // Breakfast, Lunch, Dinner, Snack
  final double carbs;
  final double protein;
  final double fat;
  final double? calories;
  final String? notes;
  final DateTime time;
  /// What the meal is composed of (e.g. Chicken, Meat, Eggs, Salad).
  final List<String>? composition;

  MealEntry({
    required this.id,
    required this.mealType,
    required this.carbs,
    required this.protein,
    required this.fat,
    this.calories,
    this.notes,
    required this.time,
    this.composition,
  });

  MealEntry copyWith({
    String? id,
    String? mealType,
    double? carbs,
    double? protein,
    double? fat,
    double? calories,
    String? notes,
    DateTime? time,
    List<String>? composition,
  }) {
    return MealEntry(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      calories: calories ?? this.calories,
      notes: notes ?? this.notes,
      time: time ?? this.time,
      composition: composition ?? this.composition,
    );
  }

  /// Display label for meal type.
  String get mealTypeLabel => mealType;

  /// Estimated calories from macros if not set (4 kcal/g carbs & protein, 9 kcal/g fat).
  double get effectiveCalories =>
      calories ?? (carbs * 4 + protein * 4 + fat * 9);
}
