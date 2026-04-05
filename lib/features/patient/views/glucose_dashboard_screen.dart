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
import 'package:diab_care/core/widgets/animations.dart';

class GlucoseDashboardScreen extends StatelessWidget {
  const GlucoseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final glucoseVM = context.watch<GlucoseViewModel>();
    final patientVM = context.watch<PatientViewModel>();
    final patient = patientVM.patient;
    final latest = glucoseVM.latestReading;
    final unit = glucoseVM.preferredUnit;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════════
          // GRADIENT HEADER WITH DECORATIVE CIRCLES
          // ═══════════════════════════════════════════
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  decoration: const BoxDecoration(
                    gradient: AppColors.mainGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (patient?.name ?? 'P').substring(0, 1).toUpperCase(),
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Bonjour 👋', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                                      const SizedBox(height: 2),
                                      Text(
                                        patient?.name ?? 'Patient',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Consumer<ChatViewModel>(
                                    builder: (context, chatVM, _) => _GlassButton(
                                      icon: Icons.message_rounded,
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationListScreen())),
                                      badge: chatVM.totalUnread,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _GlassButton(icon: Icons.notifications_rounded, onTap: () {}),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Glucose hero card (glassmorphic)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.08)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.bloodtype_rounded, color: Colors.white, size: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Glycémie actuelle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9))),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            latest != null
                                                ? (unit == 'mmol/L' ? latest.valueInMmolL.toStringAsFixed(1) : '${latest.valueInMgDl.toInt()}')
                                                : '--',
                                            style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: Colors.white, height: 1, letterSpacing: -1),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 10, left: 4),
                                            child: Text(unit, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _getStatusBgColor(latest),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [BoxShadow(color: _getStatusBgColor(latest).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                                        ),
                                        child: Text(
                                          latest?.statusLabel ?? 'Aucune mesure',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _getStatusTextColor(latest)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: SizedBox(
                                    width: 110,
                                    child: GlucoseMinChart(readings: glucoseVM.weeklyReadings, height: 80, displayUnit: unit),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Decorative circles
                Positioned(top: -20, right: -30, child: _DecorativeCircle(size: 100, opacity: 0.06)),
                Positioned(top: 60, right: 40, child: _DecorativeCircle(size: 50, opacity: 0.04)),
                Positioned(bottom: 40, left: -20, child: _DecorativeCircle(size: 70, opacity: 0.05)),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // QUICK ACTIONS — Gradient Cards
          // ═══════════════════════════════════════════
          SliverToBoxAdapter(
            child: FadeInSlide(
              index: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Expanded(child: _GradientActionCard(
                      icon: Icons.add_circle_rounded,
                      label: 'Ajouter\nmesure',
                      gradient: const LinearGradient(colors: [Color(0xFF7DDAB9), Color(0xFF5BC4A8)]),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGlucoseScreen())),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _GradientActionCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'Mes\nstatistiques',
                      gradient: const LinearGradient(colors: [Color(0xFF9BC4E2), Color(0xFF6FA8DC)]),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen())),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _GradientActionCard(
                      icon: Icons.lightbulb_rounded,
                      label: 'Conseils\npersonnalisés',
                      gradient: const LinearGradient(colors: [Color(0xFFFFB4A2), Color(0xFFFF9A85)]),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendationsScreen())),
                    )),
                  ],
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════
          // STATS ROW — Tinted Cards with Icon
          // ═══════════════════════════════════════════
          SliverToBoxAdapter(
            child: FadeInSlide(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Expanded(child: _TintedStatCard(
                      label: 'Moyenne',
                      value: unit == 'mmol/L' ? glucoseVM.averageGlucose.toStringAsFixed(1) : '${glucoseVM.averageGlucose.toInt()}',
                      unit: unit,
                      color: AppColors.softGreen,
                      icon: Icons.show_chart_rounded,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _TintedStatCard(
                      label: 'Temps cible',
                      value: '${glucoseVM.timeInRange.toInt()}',
                      unit: '%',
                      color: AppColors.accentBlue,
                      icon: Icons.gps_fixed_rounded,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _TintedStatCard(
                      label: 'HbA1c',
                      value: '${patient?.hba1c ?? '-'}',
                      unit: '%',
                      color: AppColors.lavender,
                      icon: Icons.science_rounded,
                    )),
                  ],
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════
          // WEEKLY CHART
          // ═══════════════════════════════════════════
          SliverToBoxAdapter(
            child: FadeInSlide(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.primaryGreen.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gradient accent strip
                      Container(
                        height: 4,
                        decoration: const BoxDecoration(
                          gradient: AppColors.mainGradient,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.softGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.trending_up_rounded, color: AppColors.softGreen, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('Tendance sur 7 jours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen())),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.softGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('Voir plus →', style: TextStyle(color: AppColors.softGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(width: 12, height: 3, decoration: BoxDecoration(color: AppColors.statusWarning.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 6),
                                Text('Zone cible: ${AppConstants.normalGlucoseMin.toInt()}-${AppConstants.normalGlucoseMax.toInt()} $unit', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GlucoseChartWidget(readings: glucoseVM.weeklyReadings, height: 180, displayUnit: unit),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════
          // RECENT READINGS HEADER
          // ═══════════════════════════════════════════
          SliverToBoxAdapter(
            child: FadeInSlide(
              index: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history_rounded, color: AppColors.accentBlue, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text('Mesures récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Tout voir →', style: TextStyle(color: AppColors.accentBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
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
                  return FadeInSlide(
                    index: 4 + index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlucoseCard(reading: readings[index], displayUnit: unit),
                    ),
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

// ─────────────────────────────────────
// Decorative circle for header
// ─────────────────────────────────────
class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorativeCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

// ─────────────────────────────────────
// Glass-style header button
// ─────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _GlassButton({required this.icon, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badge > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFC5252)]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.4), blurRadius: 6)],
                ),
                child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────
// Gradient action card
// ─────────────────────────────────────
class _GradientActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _GradientActionCard({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// Tinted stat card with icon
// ─────────────────────────────────────
class _TintedStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _TintedStatCard({required this.label, required this.value, required this.unit, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withOpacity(0.5), size: 14),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: TextStyle(fontSize: 10, color: color.withOpacity(0.5), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
