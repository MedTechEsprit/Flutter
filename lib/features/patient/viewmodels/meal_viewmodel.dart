import 'package:flutter/material.dart';
import 'package:diab_care/data/models/meal_entry_model.dart';
import 'package:diab_care/features/patient/services/patient_api_service.dart';

/// ViewModel for nutrition / meal tracking.
/// Connects to NestJS /api/nutrition endpoints via PatientApiService.
class MealViewModel extends ChangeNotifier {
  final PatientApiService _api = PatientApiService();

  List<MealEntry> _meals = [];
  bool _isLoading = false;
  String? _error;

  List<MealEntry> get meals => _meals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Filtered lists ───────────────────────────────────────────
  List<MealEntry> get mealsToday {
    final now = DateTime.now();
    return _meals.where((m) =>
        m.time.year == now.year &&
        m.time.month == now.month &&
        m.time.day == now.day).toList();
  }

  List<MealEntry> get mealsThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _meals.where((m) => m.time.isAfter(weekStart)).toList();
  }

  List<MealEntry> get mealsThisMonth {
    final now = DateTime.now();
    return _meals.where((m) =>
        m.time.year == now.year && m.time.month == now.month).toList();
  }

  // ── Daily totals (carbs, protein, fat, calories) ─────────────
  (double, double, double, double) get dailyTotals {
    final today = mealsToday;
    double c = 0, p = 0, f = 0, cal = 0;
    for (final m in today) {
      c += m.carbs;
      p += m.protein;
      f += m.fat;
      cal += m.calories ?? 0;
    }
    return (c, p, f, cal);
  }

  // ── Group meals by date ──────────────────────────────────────
  Map<DateTime, List<MealEntry>> getMealsGroupedByDate(List<MealEntry> list) {
    final map = <DateTime, List<MealEntry>>{};
    for (final m in list) {
      final key = DateTime(m.time.year, m.time.month, m.time.day);
      map.putIfAbsent(key, () => []).add(m);
    }
    // Sort keys descending
    final sorted = Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
    return sorted;
  }

  // ── CRUD ─────────────────────────────────────────────────────

  /// Load meals from API
  Future<void> loadMeals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.getMeals(page: 1, limit: 100);
      if (result['success'] == true) {
        final data = result['data'];
        // Backend returns paginated { data: [...], total, page, ... }
        List rawList;
        if (data is Map && data.containsKey('data')) {
          rawList = data['data'] as List;
        } else if (data is List) {
          rawList = data;
        } else {
          rawList = [];
        }
        _meals = rawList
            .map((json) => MealEntry.fromJson(json as Map<String, dynamic>))
            .toList();
        _meals.sort((a, b) => b.time.compareTo(a.time));
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) {
      _error = 'Erreur: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a MealEntry object (helper used by screens before calling addMeal)
  MealEntry createEntry({
    required String mealType,
    required double carbs,
    required double protein,
    required double fat,
    double? calories,
    String? notes,
    DateTime? time,
    List<String>? composition,
    String? source,
    int? confidence,
  }) {
    return MealEntry(
      mealType: mealType,
      carbs: carbs,
      protein: protein,
      fat: fat,
      calories: calories,
      notes: notes,
      time: time ?? DateTime.now(),
      composition: composition,
      source: source,
      confidence: confidence,
    );
  }

  /// Add a meal
  Future<bool> addMeal(MealEntry entry) async {
    try {
      final result = await _api.addMeal(
        name: entry.mealType,
        eatenAt: entry.time,
        carbs: entry.carbs,
        protein: entry.protein,
        fat: entry.fat,
        calories: entry.calories,
        note: entry.notes,
      );

      if (result['success'] == true) {
        final created = MealEntry.fromJson(result['data'] as Map<String, dynamic>);
        _meals.insert(0, created);
        notifyListeners();
        return true;
      }
      _error = result['message']?.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update a meal (locally; re-add via API)
  Future<bool> updateMeal(MealEntry entry) async {
    // For now, update locally since backend may not have PATCH endpoint
    final idx = _meals.indexWhere((m) => m.id == entry.id);
    if (idx != -1) {
      _meals[idx] = entry;
      notifyListeners();
    }
    // Optionally call API update here when available
    return true;
  }

  /// Delete a meal by id (locally)
  Future<bool> deleteMeal(String? id) async {
    if (id == null) return false;
    _meals.removeWhere((m) => m.id == id);
    notifyListeners();
    return true;
  }

  /// Get meals within a date range (inclusive, day-level)
  List<MealEntry> getMealsInRange(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _meals.where((m) =>
        !m.time.isBefore(startDay) && !m.time.isAfter(endDay)).toList();
  }
}
