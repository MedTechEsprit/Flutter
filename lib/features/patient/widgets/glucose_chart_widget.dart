import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/models/glucose_reading_model.dart';
import 'package:intl/intl.dart';

class GlucoseChartWidget extends StatelessWidget {
  final List<GlucoseReading> readings;
  final double height;
  final bool showLabels;
  final String displayUnit;

  const GlucoseChartWidget({
    super.key,
    required this.readings,
    this.height = 200,
    this.showLabels = true,
    this.displayUnit = 'mg/dL',
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Aucune donnée disponible', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    final spots = readings.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: showLabels,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= readings.length) return const SizedBox.shrink();
                  if (readings.length > 7 && idx % 2 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd/MM').format(readings[idx].timestamp),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 40,
                interval: 50,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 40,
          maxY: 250,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(y: 70, color: AppColors.statusWarning.withOpacity(0.3), strokeWidth: 1, dashArray: [5, 5]),
              HorizontalLine(y: 180, color: AppColors.statusWarning.withOpacity(0.3), strokeWidth: 1, dashArray: [5, 5]),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.softGreen,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final reading = readings[index];
                  Color dotColor = AppColors.statusGood;
                  if (reading.isHigh || reading.isLow) dotColor = AppColors.statusWarning;
                  if (reading.isCritical) dotColor = AppColors.statusCritical;
                  return FlDotCirclePainter(
                    radius: 4,
                    color: dotColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.softGreen.withOpacity(0.3), AppColors.softGreen.withOpacity(0.0)],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final reading = readings[spot.x.toInt()];
                  return LineTooltipItem(
                    '${displayUnit == 'mmol/L' ? reading.valueInMmolL.toStringAsFixed(1) : reading.valueInMgDl.toInt()} $displayUnit\n${DateFormat('HH:mm dd/MM').format(reading.timestamp)}',
                    const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class GlucoseMinChart extends StatelessWidget {
  final List<GlucoseReading> readings;
  final double height;
  final String displayUnit;

  const GlucoseMinChart({super.key, required this.readings, this.height = 60, this.displayUnit = 'mg/dL'});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) return SizedBox(height: height);

    final spots = readings.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.valueIn(displayUnit));
    }).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.softGreen,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.softGreen.withOpacity(0.2), AppColors.softGreen.withOpacity(0.0)],
                ),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}
