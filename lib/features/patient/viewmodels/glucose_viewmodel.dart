import 'package:flutter/material.dart';
import 'package:diab_care/data/models/glucose_reading_model.dart';
import 'package:diab_care/features/patient/services/patient_api_service.dart';

class GlucoseViewModel extends ChangeNotifier {
  List<GlucoseReading> _readings = [];
  List<GlucoseReading> _weeklyReadings = [];
  bool _isLoading = false;
  String _filterType = 'all'; // all, fasting, before_meal, after_meal, bedtime
  String? _error;

  final PatientApiService _apiService = PatientApiService();

  // Stats depuis l'API
  Map<String, dynamic>? _weeklyStats;
  Map<String, dynamic>? _monthlyStats;
  double? _estimatedHba1c;
  Map<String, dynamic>? _timeInRangeData;

  List<GlucoseReading> get readings => _filterType == 'all'
      ? _readings
      : _readings.where((r) => r.type == _filterType).toList();
  List<GlucoseReading> get allReadings => _readings;
  List<GlucoseReading> get weeklyReadings => _weeklyReadings;
  bool get isLoading => _isLoading;
  String get filterType => _filterType;
  String? get error => _error;
  Map<String, dynamic>? get weeklyStats => _weeklyStats;
  Map<String, dynamic>? get monthlyStats => _monthlyStats;
  double? get estimatedHba1c => _estimatedHba1c;

  GlucoseReading? get latestReading => _readings.isNotEmpty ? _readings.first : null;

  double get averageGlucose {
    if (_readings.isEmpty) return 0;
    return _readings.map((r) => r.value).reduce((a, b) => a + b) / _readings.length;
  }

  double get minGlucose {
    if (_readings.isEmpty) return 0;
    return _readings.map((r) => r.value).reduce((a, b) => a < b ? a : b);
  }

  double get maxGlucose {
    if (_readings.isEmpty) return 0;
    return _readings.map((r) => r.value).reduce((a, b) => a > b ? a : b);
  }

  double get timeInRange {
    if (_timeInRangeData != null) {
      return (_timeInRangeData!['inRange'] as num?)?.toDouble() ?? 0;
    }
    if (_readings.isEmpty) return 0;
    final inRange = _readings.where((r) => r.value >= 70 && r.value <= 180).length;
    return (inRange / _readings.length) * 100;
  }

  int get lowReadingsCount => _readings.where((r) => r.value < 70).length;
  int get highReadingsCount => _readings.where((r) => r.value > 180).length;
  int get normalReadingsCount => _readings.where((r) => r.value >= 70 && r.value <= 180).length;

  /// Charge les lectures de glycémie depuis l'API
  Future<void> loadReadings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Charger les lectures
      final readingsResult = await _apiService.getMyGlucoseRecords();
      if (readingsResult['success'] == true && readingsResult['data'] != null) {
        final List<dynamic> readingsList = readingsResult['data'] is List
            ? readingsResult['data']
            : (readingsResult['data']['data'] ?? []);
        _readings = readingsList
            .map((json) => GlucoseReading.fromJson(json as Map<String, dynamic>))
            .toList();
        // Trier par date décroissante
        _readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        debugPrint('✅ ${_readings.length} lectures de glycémie chargées');
      }

      // Charger les stats hebdomadaires
      final weeklyResult = await _apiService.getWeeklyStats();
      if (weeklyResult['success'] == true) {
        _weeklyStats = weeklyResult['data'];
        debugPrint('✅ Stats hebdomadaires chargées');
      }

      // Charger l'HbA1c estimée
      final hba1cResult = await _apiService.getEstimatedHba1c();
      if (hba1cResult['success'] == true && hba1cResult['data'] != null) {
        _estimatedHba1c = (hba1cResult['data']['estimatedHba1c'] as num?)?.toDouble();
        debugPrint('✅ HbA1c estimée: $_estimatedHba1c');
      }

      // Charger le time in range
      final tirResult = await _apiService.getTimeInRange();
      if (tirResult['success'] == true && tirResult['data'] != null) {
        _timeInRangeData = tirResult['data'];
      }

      // Lectures de la semaine
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      _weeklyReadings = _readings
          .where((r) => r.timestamp.isAfter(weekAgo))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur loadReadings: $e');
      _error = 'Erreur de chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajoute une lecture de glycémie via l'API
  Future<bool> addReading(GlucoseReading reading) async {
    try {
      // Le backend attend les valeurs de l'enum GlucosePeriod: fasting, before_meal, after_meal, bedtime
      final result = await _apiService.addGlucoseReading(
        value: reading.value,
        measuredAt: reading.timestamp,
        period: reading.type, // déjà au bon format: 'fasting', 'before_meal', etc.
        note: reading.notes,
      );
      if (result['success'] == true) {
        debugPrint('✅ Lecture ajoutée avec succès');
        // Recharger les données
        await loadReadings();
        return true;
      } else {
        debugPrint('❌ Erreur ajout lecture: ${result['message']}');
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception ajout lecture: $e');
      _error = 'Erreur: $e';
      notifyListeners();
      return false;
    }
  }

  /// Supprime une lecture de glycémie
  Future<bool> deleteReading(String readingId) async {
    try {
      final result = await _apiService.deleteGlucoseReading(readingId);
      if (result['success'] == true) {
        _readings.removeWhere((r) => r.id == readingId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur suppression: $e');
      return false;
    }
  }

  void setFilter(String type) {
    _filterType = type;
    notifyListeners();
  }

  List<GlucoseReading> getReadingsForDate(DateTime date) {
    return _readings.where((r) =>
      r.timestamp.year == date.year &&
      r.timestamp.month == date.month &&
      r.timestamp.day == date.day
    ).toList();
  }

  Map<String, List<GlucoseReading>> get readingsGroupedByDate {
    final Map<String, List<GlucoseReading>> grouped = {};
    for (final reading in _readings) {
      final key = '${reading.timestamp.year}-${reading.timestamp.month.toString().padLeft(2, '0')}-${reading.timestamp.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(reading);
    }
    return grouped;
  }
}
