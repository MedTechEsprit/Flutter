import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diab_care/data/models/glucose_reading_model.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';

class GlucoseViewModel extends ChangeNotifier {
  final _tokenService = TokenService();

  List<GlucoseReading> _readings = [];
  List<GlucoseReading> _weeklyReadings = [];
  bool _isLoading = false;
  String _filterType = 'all'; // all, fasting, before_meal, after_meal, bedtime
  String _preferredUnit = 'mg/dL'; // 'mg/dL' or 'mmol/L'

  List<GlucoseReading> get readings => _filterType == 'all'
      ? _readings
      : _readings.where((r) => r.type == _filterType).toList();
  List<GlucoseReading> get weeklyReadings => _weeklyReadings;
  bool get isLoading => _isLoading;
  String get filterType => _filterType;
  String get preferredUnit => _preferredUnit;

  GlucoseReading? get latestReading => _readings.isNotEmpty ? _readings.first : null;

  double get averageGlucose {
    if (_readings.isEmpty) return 0;
    return _readings.map((r) => r.valueIn(_preferredUnit)).reduce((a, b) => a + b) / _readings.length;
  }

  double get minGlucose {
    if (_readings.isEmpty) return 0;
    return _readings.map((r) => r.valueIn(_preferredUnit)).reduce((a, b) => a < b ? a : b);
  }

  double get maxGlucose {
    if (_readings.isEmpty) return 0;
    return _readings.map((r) => r.valueIn(_preferredUnit)).reduce((a, b) => a > b ? a : b);
  }

  double get timeInRange {
    if (_readings.isEmpty) return 0;
    final inRange = _readings.where((r) => r.valueInMgDl >= 70 && r.valueInMgDl <= 180).length;
    return (inRange / _readings.length) * 100;
  }

  int get lowReadingsCount => _readings.where((r) => r.valueInMgDl < 70).length;
  int get highReadingsCount => _readings.where((r) => r.valueInMgDl > 180).length;
  int get normalReadingsCount => _readings.where((r) => r.valueInMgDl >= 70 && r.valueInMgDl <= 180).length;

  /// Format a value for display in the preferred unit
  String formatValue(double mgDlValue) {
    if (_preferredUnit == 'mmol/L') {
      return (mgDlValue / 18.0182).toStringAsFixed(1);
    }
    return mgDlValue.toInt().toString();
  }

  Future<void> loadReadings() async {
    _isLoading = true;
    notifyListeners();

    // Load preferred unit from local prefs
    final prefs = await SharedPreferences.getInstance();
    _preferredUnit = prefs.getString('glucose_unit') ?? 'mg/dL';

    final token = await _tokenService.getToken();
    if (token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Fetch all records (paginated, high limit to get enough)
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/glucose/my-records?page=1&limit=100'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        _readings = data.map((j) => GlucoseReading.fromJson(j as Map<String, dynamic>)).toList();

        // Weekly readings = last 7 days
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        _weeklyReadings = _readings.where((r) => r.timestamp.isAfter(sevenDaysAgo)).toList();
      } else {
        debugPrint('❌ Load glucose: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Load glucose error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addReadingToApi({
    required double value,
    required String period,
    required String unit,
    String? note,
    DateTime? measuredAt,
  }) async {
    final token = await _tokenService.getToken();
    if (token == null) return false;

    try {
      final payload = <String, dynamic>{
        'value': value,
        'measuredAt': (measuredAt ?? DateTime.now()).toIso8601String(),
        'period': period,
        'unit': unit,
      };
      if (note != null && note.isNotEmpty) payload['note'] = note;

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/glucose'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newReading = GlucoseReading.fromJson(data);
        _readings.insert(0, newReading);

        // Refresh weekly
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        _weeklyReadings = _readings.where((r) => r.timestamp.isAfter(sevenDaysAgo)).toList();

        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Add glucose: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Add glucose error: $e');
      return false;
    }
  }

  Future<void> setPreferredUnit(String unit) async {
    _preferredUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('glucose_unit', unit);
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
    for (final reading in readings) {
      final key = '${reading.timestamp.year}-${reading.timestamp.month.toString().padLeft(2, '0')}-${reading.timestamp.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(reading);
    }
    return grouped;
  }
}
