import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/constants/app_constants.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';
import 'package:diab_care/features/patient/widgets/glucose_chart_widget.dart';
import 'package:diab_care/features/patient/widgets/glucose_card.dart';
import 'package:diab_care/features/patient/views/add_glucose_screen.dart';
import 'package:diab_care/features/patient/views/statistics_screen.dart';
import 'package:diab_care/features/patient/views/recommendations_screen.dart';

import 'package:diab_care/features/chat/views/chat_screen.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';

class GlucoseDashboardScreen extends StatelessWidget {
  const GlucoseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final glucoseVM = context.watch<GlucoseViewModel>();
    final patientVM = context.watch<PatientViewModel>();
    final patient = patientVM.patient;
    final latest = glucoseVM.latestReading;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // Gradient Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.mainGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bonjour,', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                              const SizedBox(height: 4),
                              Text(patient?.name ?? 'Patient', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          Row(
                            children: [
                              Consumer<ChatViewModel>(
                                builder: (context, chatVM, _) => _HeaderButton(
                                  icon: Icons.message_rounded,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationListScreen())),
                                  badge: chatVM.totalUnread,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _HeaderButton(icon: Icons.notifications_rounded, onTap: () {}),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Current Glucose Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                                      Text(
                                        latest != null ? '${latest.value.toInt()}' : '--',
                                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 8, left: 4),
                                        child: Text('mg/dL', style: TextStyle(fontSize: 14, color: Colors.white70)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusBgColor(latest),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      latest?.statusLabel ?? 'Aucune mesure',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getStatusTextColor(latest)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Min chart
                            SizedBox(
                              width: 120,
                              child: GlucoseMinChart(readings: glucoseVM.weeklyReadings, height: 80),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(child: _ActionButton(icon: Icons.add_circle_outline, label: 'Ajouter\nmesure', color: AppColors.softGreen, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGlucoseScreen())))),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionButton(icon: Icons.bar_chart_rounded, label: 'Mes\nstatistiques', color: AppColors.lightBlue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen())))),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionButton(icon: Icons.lightbulb_outline, label: 'Conseils\npersonnalisés', color: AppColors.warmPeach, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendationsScreen())))),
                ],
              ),
            ),
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(child: _StatMiniCard(label: 'Moyenne', value: '${glucoseVM.averageGlucose.toInt()}', unit: 'mg/dL', color: AppColors.softGreen)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatMiniCard(label: 'Temps cible', value: '${glucoseVM.timeInRange.toInt()}', unit: '%', color: AppColors.lightBlue)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatMiniCard(label: 'HbA1c', value: '${patient?.hba1c ?? '-'}', unit: '%', color: AppColors.lavender)),
                ],
              ),
            ),
          ),

          // Weekly Chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tendance sur 7 jours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen())),
                          child: const Text('Voir plus', style: TextStyle(color: AppColors.softGreen, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Range indicator
                    Row(
                      children: [
                        Container(width: 12, height: 3, decoration: BoxDecoration(color: AppColors.statusWarning.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 6),
                        Text('Zone cible: ${AppConstants.normalGlucoseMin.toInt()}-${AppConstants.normalGlucoseMax.toInt()} mg/dL', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlucoseChartWidget(readings: glucoseVM.weeklyReadings, height: 180),
                  ],
                ),
              ),
            ),
          ),

          // Recent Readings Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mesures récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Tout voir', style: TextStyle(color: AppColors.softGreen, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),

          // Recent Readings List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final readings = glucoseVM.readings;
                  if (index >= readings.length || index >= 5) return null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlucoseCard(reading: readings[index]),
                  );
                },
                childCount: glucoseVM.readings.length.clamp(0, 5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBgColor(dynamic reading) {
    if (reading == null) return Colors.white24;
    if (reading.isCritical) return Colors.red.shade100;
    if (reading.isHigh || reading.isLow) return Colors.orange.shade100;
    return Colors.green.shade100;
  }

  Color _getStatusTextColor(dynamic reading) {
    if (reading == null) return Colors.white;
    if (reading.isCritical) return Colors.red.shade700;
    if (reading.isHigh || reading.isLow) return Colors.orange.shade700;
    return Colors.green.shade700;
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _HeaderButton({required this.icon, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatMiniCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
