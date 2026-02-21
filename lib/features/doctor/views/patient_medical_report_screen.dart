import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';

class PatientMedicalReportScreen extends StatelessWidget {
  final String patientName;
  const PatientMedicalReportScreen({super.key, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Dossier Médical - $patientName'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.greenGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_rounded, size: 64, color: AppColors.darkGreen),
            ),
            const SizedBox(height: 24),
            Text('Dossier Médical', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(patientName, style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Le dossier médical complet sera disponible dans une prochaine mise à jour.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
