import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final glucoseVM = context.watch<GlucoseViewModel>();
    final patientVM = context.watch<PatientViewModel>();
    final latest = glucoseVM.latestReading;
    final currentValue = latest?.value ?? 120;
    final recommendations = patientVM.getRecommendations(currentValue);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Conseils personnalisés'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _getStatusGradient(currentValue),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Glycémie actuelle', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${currentValue.toInt()}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6, left: 4),
                              child: Text('mg/dL', style: TextStyle(fontSize: 14, color: Colors.white70)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(latest?.statusLabel ?? 'Normal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(_getStatusIcon(currentValue), size: 36, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Recommandations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),

            // Recommendations List
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getPriorityColor(rec['priority']).withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(rec['priority']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(rec['icon'], style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(rec['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(rec['priority']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getPriorityLabel(rec['priority']),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getPriorityColor(rec['priority'])),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(rec['description'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 20),
            // General Tips
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBlue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.lightBlue, size: 20),
                      SizedBox(width: 8),
                      Text('Rappel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.lightBlue)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ces conseils sont générés automatiquement en fonction de votre glycémie. Consultez toujours votre médecin pour des recommandations personnalisées.',
                    style: TextStyle(fontSize: 13, color: AppColors.lightBlue.withOpacity(0.8), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  LinearGradient _getStatusGradient(double value) {
    if (value > 180) return const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)]);
    if (value < 70) return const LinearGradient(colors: [Color(0xFFFFAA5C), Color(0xFFFFCC80)]);
    return AppColors.greenGradient;
  }

  IconData _getStatusIcon(double value) {
    if (value > 180) return Icons.warning_rounded;
    if (value < 70) return Icons.arrow_downward_rounded;
    return Icons.check_circle_rounded;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical': return AppColors.statusCritical;
      case 'high': return AppColors.statusWarning;
      case 'medium': return AppColors.lightBlue;
      default: return AppColors.statusGood;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'critical': return 'URGENT';
      case 'high': return 'Important';
      case 'medium': return 'Modéré';
      default: return 'Info';
    }
  }
}
