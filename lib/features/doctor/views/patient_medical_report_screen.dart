import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/services/ai_doctor_service.dart';

class PatientMedicalReportScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  const PatientMedicalReportScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientMedicalReportScreen> createState() =>
      _PatientMedicalReportScreenState();
}

class _PatientMedicalReportScreenState
    extends State<PatientMedicalReportScreen> {
  final AiDoctorService _service = AiDoctorService();
  late Future<PatientMedicalReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _service.getPatientMedicalReport(widget.patientId);
  }

  Future<void> _reload() async {
    setState(() {
      _reportFuture = _service.getPatientMedicalReport(widget.patientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: FutureBuilder<PatientMedicalReport>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF22C1C3)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 56,
                            color: AppColors.errorRed,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Unable to load the medical report.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final report = snapshot.data;
                if (report == null) {
                  return const Center(child: Text('Report unavailable.'));
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  color: const Color(0xFF22C1C3),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildHeader(report),
                      const SizedBox(height: 12),
                      _buildSection('Executive summary', [
                        report.executiveSummary,
                      ], Icons.summarize_rounded),
                      _buildSection(
                        'Patient overview',
                        report.patientOverview,
                        Icons.person_outline_rounded,
                      ),
                      _buildSection(
                        'Clinical findings',
                        report.clinicalFindings,
                        Icons.medical_information_outlined,
                      ),
                      _buildSection(
                        'Risk assessment',
                        report.riskAssessment,
                        Icons.warning_amber_rounded,
                      ),
                      _buildSection(
                        'Treatment plan',
                        report.treatmentPlan,
                        Icons.medication_outlined,
                      ),
                      _buildSection(
                        'Lifestyle plan',
                        report.lifestylePlan,
                        Icons.monitor_heart_outlined,
                      ),
                      _buildSection(
                        'Follow-up plan',
                        report.followUpPlan,
                        Icons.event_note_rounded,
                      ),
                      _buildSection(
                        'Alerts',
                        report.alerts,
                        Icons.notifications_active_outlined,
                        isAlert: true,
                      ),
                      _buildSection('Clinical note', [
                        report.physicianNotes,
                      ], Icons.edit_note_rounded),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22C1C3), Color(0xFF5B86E5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Medical record',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.patientName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Regenerate report',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PatientMedicalReport report) {
    final generatedAt = report.generatedAt;
    final glucoseCount =
        report.sourceMetrics['glucoseRecordsAnalyzed']?.toString() ?? '0';
    final mealsCount = report.sourceMetrics['mealsAnalyzed']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22C1C3), Color(0xFF5B86E5)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            generatedAt == null
                ? 'Generated: unknown'
                : 'Generated: ${generatedAt.day}/${generatedAt.month}/${generatedAt.year} ${generatedAt.hour.toString().padLeft(2, '0')}:${generatedAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip('Glucose: $glucoseCount'),
              _metricChip('Meals: $mealsCount'),
              _metricChip('Patient: ${widget.patientName}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> lines,
    IconData icon, {
    bool isAlert = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlert
              ? AppColors.errorRed.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isAlert ? AppColors.errorRed : AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isAlert ? AppColors.errorRed : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isAlert ? AppColors.errorRed : AppColors.softGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
