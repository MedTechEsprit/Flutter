import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/viewmodels/meal_viewmodel.dart';

/// Dummy daily targets for comparison.
class _DailyTargets {
  static const double carbs = 250;
  static const double protein = 80;
  static const double fat = 65;
  static const double calories = 2000;
}

class NutritionAnalyticsScreen extends StatelessWidget {
  const NutritionAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final (carbs, protein, fat, calories) = vm.dailyTotals;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Nutrition Analytics'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _DailySummaryCard(
            carbs: carbs,
            protein: protein,
            fat: fat,
            calories: calories,
          ),
          const SizedBox(height: 20),
          _MacroPieChartCard(carbs: carbs, protein: protein, fat: fat),
          const SizedBox(height: 20),
          _DailyCarbsBarChartCard(vm: vm),
        ],
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final double carbs;
  final double protein;
  final double fat;
  final double calories;

  const _DailySummaryCard({
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: 'Carbs',
              value: carbs,
              unit: 'g',
              target: _DailyTargets.carbs,
            ),
            _SummaryRow(
              label: 'Protein',
              value: protein,
              unit: 'g',
              target: _DailyTargets.protein,
            ),
            _SummaryRow(
              label: 'Fat',
              value: fat,
              unit: 'g',
              target: _DailyTargets.fat,
            ),
            _SummaryRow(
              label: 'Calories',
              value: calories,
              unit: 'kcal',
              target: _DailyTargets.calories,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double target;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final exceeded = value > target;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
          Text(
            '${value.toStringAsFixed(0)}$unit',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: exceeded ? AppColors.critical : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '/ ${target.toInt()}$unit',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          if (exceeded)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                'Over',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.critical),
              ),
            ),
        ],
      ),
    );
  }
}

class _MacroPieChartCard extends StatelessWidget {
  final double carbs;
  final double protein;
  final double fat;

  const _MacroPieChartCard({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final total = carbs + protein + fat;
    if (total <= 0) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: AppColors.cardBackground,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Log meals to see macro breakdown', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    final sections = [
      PieChartSectionData(
        value: carbs,
        title: '${(carbs / total * 100).toStringAsFixed(0)}%',
        color: AppColors.primaryGreen,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      PieChartSectionData(
        value: protein,
        title: '${(protein / total * 100).toStringAsFixed(0)}%',
        color: AppColors.accentBlue,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      PieChartSectionData(
        value: fat,
        title: '${(fat / total * 100).toStringAsFixed(0)}%',
        color: AppColors.softOrange,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Macro composition',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendRow(color: AppColors.primaryGreen, label: 'Carbs'),
                      _LegendRow(color: AppColors.accentBlue, label: 'Protein'),
                      _LegendRow(color: AppColors.softOrange, label: 'Fat'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _DailyCarbsBarChartCard extends StatelessWidget {
  final MealViewModel vm;

  const _DailyCarbsBarChartCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final spots = <FlSpot>[];
    final titles = <String>[];
    for (var i = 0; i < days.length; i++) {
      final dayStart = DateTime(days[i].year, days[i].month, days[i].day);
      final dayMeals = vm.getMealsInRange(dayStart, dayStart);
      final totalCarbs = dayMeals.fold<double>(0, (s, m) => s + m.carbs);
      spots.add(FlSpot(i.toDouble(), totalCarbs));
      titles.add(DateFormat('EEE').format(days[i]));
    }

    final maxY = spots.isEmpty ? 100.0 : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 20).clamp(50.0, 400.0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily carbs (last 7 days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= titles.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(titles[i], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, meta) => Text(
                          '${v.toInt()}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: spots.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.y,
                          color: AppColors.primaryGreen,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                      showingTooltipIndicators: [],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
