import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/models/glucose_reading_model.dart';
import 'package:intl/intl.dart';

class GlucoseCard extends StatelessWidget {
  final GlucoseReading reading;
  final VoidCallback? onTap;
  final String displayUnit;

  const GlucoseCard({super.key, required this.reading, this.onTap, this.displayUnit = 'mg/dL'});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            // Value
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayUnit == 'mmol/L'
                          ? reading.valueInMmolL.toStringAsFixed(1)
                          : '${reading.valueInMgDl.toInt()}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getStatusColor()),
                    ),
                    const SizedBox(width: 4),
                    Text(displayUnit, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(reading.statusLabel, style: TextStyle(fontSize: 12, color: _getStatusColor(), fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            // Type & time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_getTypeLabel(), style: const TextStyle(fontSize: 11, color: AppColors.softGreen, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 6),
                Text(DateFormat('HH:mm').format(reading.timestamp), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(DateFormat('dd/MM').format(reading.timestamp), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              reading.source == 'glucometer' ? Icons.bluetooth : Icons.edit,
              size: 16,
              color: reading.source == 'glucometer' ? AppColors.lightBlue : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (reading.isCritical) return AppColors.statusCritical;
    if (reading.isHigh) return AppColors.statusWarning;
    if (reading.isLow) return AppColors.statusWarning;
    return AppColors.statusGood;
  }

  String _getTypeLabel() {
    switch (reading.type) {
      case 'fasting': return 'À jeun';
      case 'before_meal': return 'Avant repas';
      case 'after_meal': return 'Après repas';
      case 'bedtime': return 'Coucher';
      default: return 'Aléatoire';
    }
  }
}
