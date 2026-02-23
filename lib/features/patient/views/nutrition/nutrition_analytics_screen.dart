import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/viewmodels/meal_viewmodel.dart';
import 'package:diab_care/features/patient/views/nutrition/meal_logging_screen.dart';

class NutritionAnalyticsScreen extends StatelessWidget {
  const NutritionAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    final (carbs, protein, fat, calories) = vm.dailyTotals;

    return Scaffold(
      backgroundColor: AppColors.mintGreen,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _CircularMacroCard(
            carbs: carbs,
            protein: protein,
            fat: fat,
            calories: calories,
          ),
          const SizedBox(height: 24),
          _ActivitiesCard(vm: vm),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MealLoggingScreen()),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}

class _CircularMacroCard extends StatelessWidget {
  final double carbs;
  final double protein;
  final double fat;
  final double calories;

  const _CircularMacroCard({
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular chart
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                  ),
                ),
                // Pie chart
                SizedBox(
                  width: 180,
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: carbs,
                          color: AppColors.darkGreen,
                          radius: 60,
                          title: '',
                        ),
                        PieChartSectionData(
                          value: protein,
                          color: AppColors.softOrange,
                          radius: 60,
                          title: '',
                        ),
                        PieChartSectionData(
                          value: fat,
                          color: AppColors.warningOrange,
                          radius: 60,
                          title: '',
                        ),
                      ],
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                    ),
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total KCal',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      calories.toInt().toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Macro labels
          _MacroRow(
            color: AppColors.warningOrange,
            label: 'Protein',
            value: '${protein.toInt()}KCal',
          ),
          const SizedBox(height: 12),
          _MacroRow(
            color: AppColors.darkGreen,
            label: 'Carbs',
            value: '${carbs.toInt()}KCal',
          ),
          const SizedBox(height: 12),
          _MacroRow(
            color: AppColors.softOrange,
            label: 'Fat',
            value: '${fat.toInt()}KCal',
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _MacroRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActivitiesCard extends StatelessWidget {
  final MealViewModel vm;

  const _ActivitiesCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Last 7 day',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Line chart
          SizedBox(
            height: 200,
            child: _ActivityLineChart(vm: vm),
          ),
        ],
      ),
    );
  }
}

class _ActivityLineChart extends StatelessWidget {
  final MealViewModel vm;

  const _ActivityLineChart({required this.vm});

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

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= titles.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    titles[i],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primaryGreen,
                  strokeWidth: 2,
                  strokeColor: AppColors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryGreen.withOpacity(0.1),
            ),
          ),
        ],
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
      ),
    );
  }
}

