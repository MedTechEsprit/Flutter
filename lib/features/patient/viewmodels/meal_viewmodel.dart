import 'package:flutter/material.dart';
import 'package:diab_care/data/models/meal_entry_model.dart';
import 'package:uuid/uuid.dart';

/// Local state for meal logging: CRUD and queries. No backend.
class MealViewModel extends ChangeNotifier {
  final List<MealEntry> _meals = [];
  static const _uuid = Uuid();

  List<MealEntry> get meals => List.unmodifiable(_meals);

  void addMeal(MealEntry entry) {
    _meals.insert(0, entry);
    notifyListeners();
  }

  void updateMeal(MealEntry entry) {
    final i = _meals.indexWhere((m) => m.id == entry.id);
    if (i >= 0) {
      _meals[i] = entry;
      notifyListeners();
    }
  }

  void deleteMeal(String id) {
    _meals.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  MealEntry? getMealById(String id) {
    try {
      return _meals.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Meals in range [start, end] (dates only, time ignored for filtering).
  List<MealEntry> getMealsInRange(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return _meals.where((m) {
      final d = DateTime(m.time.year, m.time.month, m.time.day);
      return (d.isAtSameMomentAs(startDate) || d.isAfter(startDate)) &&
          (d.isAtSameMomentAs(endDate) || d.isBefore(endDate));
    }).toList();
  }

  /// Today only.
  List<MealEntry> get mealsToday =>
      getMealsInRange(DateTime.now(), DateTime.now());

  /// Last 7 days.
  List<MealEntry> get mealsThisWeek {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    return getMealsInRange(DateTime(start.year, start.month, start.day), now);
  }

  /// This calendar month.
  List<MealEntry> get mealsThisMonth {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return getMealsInRange(start, now);
  }

  /// Group meals by date (date string key).
  Map<String, List<MealEntry>> getMealsGroupedByDate(List<MealEntry> list) {
    final map = <String, List<MealEntry>>{};
    for (final m in list) {
      final key = '${m.time.year}-${m.time.month.toString().padLeft(2, '0')}-${m.time.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(m);
    }
    for (final key in map.keys) {
      map[key]!.sort((a, b) => b.time.compareTo(a.time));
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return Map.fromEntries(keys.map((k) => MapEntry(k, map[k]!)));
  }

  /// Totals for a list of meals.
  void totalsFor(List<MealEntry> list,
      {required void Function(double carbs, double protein, double fat, double calories) onResult}) {
    double c = 0, p = 0, f = 0, cal = 0;
    for (final m in list) {
      c += m.carbs;
      p += m.protein;
      f += m.fat;
      cal += m.effectiveCalories;
    }
    onResult(c, p, f, cal);
  }

  /// Daily totals for today.
  (double carbs, double protein, double fat, double calories) get dailyTotals {
    double c = 0, p = 0, f = 0, cal = 0;
    for (final m in mealsToday) {
      c += m.carbs;
      p += m.protein;
      f += m.fat;
      cal += m.effectiveCalories;
    }
    return (c, p, f, cal);
  }

  /// Create new entry with generated id.
  MealEntry createEntry({
    required String mealType,
    required double carbs,
    required double protein,
    required double fat,
    double? calories,
    String? notes,
    required DateTime time,
    List<String>? composition,
  }) {
    return MealEntry(
      id: _uuid.v4(),
      mealType: mealType,
      carbs: carbs,
      protein: protein,
      fat: fat,
      calories: calories,
      notes: notes,
      time: time,
      composition: composition,
    );
  }
}
