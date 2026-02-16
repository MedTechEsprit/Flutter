import 'package:flutter/material.dart';
import 'package:diab_care/data/models/glucose_reading_model.dart';
import 'package:diab_care/data/mock/mock_patient_data.dart';

class GlucoseViewModel extends ChangeNotifier {
  List<GlucoseReading> _readings = [];
  List<GlucoseReading> _weeklyReadings = [];
  bool _isLoading = false;
  String _filterType = 'all'; // all, fasting, before_meal, after_meal, bedtime

  List<GlucoseReading> get readings => _filterType == 'all'
      ? _readings
      : _readings.where((r) => r.type == _filterType).toList();
  List<GlucoseReading> get weeklyReadings => _weeklyReadings;
  bool get isLoading => _isLoading;
  String get filterType => _filterType;

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
    if (_readings.isEmpty) return 0;
    final inRange = _readings.where((r) => r.value >= 70 && r.value <= 180).length;
    return (inRange / _readings.length) * 100;
  }

  int get lowReadingsCount => _readings.where((r) => r.value < 70).length;
  int get highReadingsCount => _readings.where((r) => r.value > 180).length;
  int get normalReadingsCount => _readings.where((r) => r.value >= 70 && r.value <= 180).length;

  void loadReadings() {
    _isLoading = true;
    notifyListeners();

    _readings = MockPatientData.getGlucoseReadings();
    _weeklyReadings = MockPatientData.getWeeklyReadings();

    _isLoading = false;
    notifyListeners();
  }

  void addReading(GlucoseReading reading) {
    _readings.insert(0, reading);
    notifyListeners();
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
