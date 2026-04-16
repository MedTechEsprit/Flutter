import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';
import 'package:diab_care/features/patient/widgets/glucose_chart_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _period = '7j';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GlucoseViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Mes Statistiques'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: ['7j', '14j', '30j', '90j'].map((p) {
                  final isSelected = _period == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _period = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)] : null,
                        ),
                        child: Text(
                          p,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppColors.softGreen : AppColors.textMuted),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Summary Cards
            Row(
              children: [
                Expanded(child: _SummaryCard(title: 'Moyenne', value: vm.preferredUnit == 'mmol/L' ? vm.averageGlucose.toStringAsFixed(1) : '${vm.averageGlucose.toInt()}', unit: vm.preferredUnit, icon: Icons.show_chart, color: AppColors.softGreen)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(title: 'Temps cible', value: '${vm.timeInRange.toInt()}%', unit: '70-180', icon: Icons.gps_fixed, color: AppColors.lightBlue)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _SummaryCard(title: 'Min', value: vm.preferredUnit == 'mmol/L' ? vm.minGlucose.toStringAsFixed(1) : '${vm.minGlucose.toInt()}', unit: vm.preferredUnit, icon: Icons.arrow_downward, color: AppColors.statusWarning)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(title: 'Max', value: vm.preferredUnit == 'mmol/L' ? vm.maxGlucose.toStringAsFixed(1) : '${vm.maxGlucose.toInt()}', unit: vm.preferredUnit, icon: Icons.arrow_upward, color: AppColors.statusCritical)),
              ],
            ),
            const SizedBox(height: 24),

            // Trend Chart
            _Section(
              title: 'Tendance glycémique',
              child: GlucoseChartWidget(readings: vm.weeklyReadings, height: 220, displayUnit: vm.preferredUnit),
            ),
            const SizedBox(height: 20),

            // Distribution
            _Section(
              title: 'Répartition des mesures',
              child: SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              value: vm.normalReadingsCount.toDouble(),
                              color: AppColors.statusGood,
                              title: '${vm.normalReadingsCount}',
                              titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              radius: 50,
                            ),
                            PieChartSectionData(
                              value: vm.highReadingsCount.toDouble(),
                              color: AppColors.statusWarning,
                              title: '${vm.highReadingsCount}',
                              titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              radius: 50,
                            ),
                            PieChartSectionData(
                              value: vm.lowReadingsCount.toDouble(),
                              color: AppColors.statusCritical,
                              title: '${vm.lowReadingsCount}',
                              titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              radius: 50,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(color: AppColors.statusGood, label: 'Normal (70-180)'),
                        const SizedBox(height: 10),
                        _LegendItem(color: AppColors.statusWarning, label: 'Élevé (>180)'),
                        const SizedBox(height: 10),
                        _LegendItem(color: AppColors.statusCritical, label: 'Bas (<70)'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Time in Range Bar
            _Section(
              title: 'Temps dans la cible',
              child: Column(
                children: [
                  _RangeBar(label: 'Très élevé (>250)', percent: 5, color: Colors.red.shade700),
                  const SizedBox(height: 8),
                  _RangeBar(label: 'Élevé (181-250)', percent: 15, color: AppColors.statusWarning),
                  const SizedBox(height: 8),
                  _RangeBar(label: 'Cible (70-180)', percent: vm.timeInRange, color: AppColors.statusGood),
                  const SizedBox(height: 8),
                  _RangeBar(label: 'Bas (54-69)', percent: 8, color: AppColors.statusWarning),
                  const SizedBox(height: 8),
                  _RangeBar(label: 'Très bas (<54)', percent: 2, color: Colors.red.shade700),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.unit, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _RangeBar({required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text('${percent.toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
