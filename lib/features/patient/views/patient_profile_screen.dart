import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/theme_provider.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<PatientViewModel>().patient;
    final glucoseVM = context.watch<GlucoseViewModel>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.mainGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          patient != null ? patient.name.split(' ').map((n) => n[0]).take(2).join() : 'P',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(patient?.name ?? 'Patient', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(patient?.email ?? '', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health Info
                  _SectionTitle(title: 'Informations de santé'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Type de diabète', value: patient?.diabetesType ?? '-'),
                        const Divider(height: 20),
                        _InfoRow(label: 'Groupe sanguin', value: patient?.bloodType ?? '-'),
                        const Divider(height: 20),
                        _InfoRow(label: 'HbA1c', value: '${patient?.hba1c ?? '-'}%'),
                        const Divider(height: 20),
                        _InfoRow(label: 'IMC', value: '${patient?.bmi ?? '-'}'),
                        const Divider(height: 20),
                        _InfoRow(label: 'Poids', value: '${patient?.weight ?? '-'} kg'),
                        const Divider(height: 20),
                        _InfoRow(label: 'Taille', value: '${patient?.height ?? '-'} cm'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  _SectionTitle(title: 'Statistiques'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Mesures', value: '${glucoseVM.readings.length}', icon: Icons.analytics, color: AppColors.softGreen)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'Temps cible', value: '${glucoseVM.timeInRange.toInt()}%', icon: Icons.gps_fixed, color: AppColors.lightBlue)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'Moyenne', value: '${glucoseVM.averageGlucose.toInt()}', icon: Icons.show_chart, color: AppColors.lavender)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Personal Info
                  _SectionTitle(title: 'Informations personnelles'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Téléphone', value: patient?.phone ?? '-'),
                        const Divider(height: 20),
                        _InfoRow(label: 'Âge', value: '${patient?.age ?? '-'} ans'),
                        const Divider(height: 20),
                        _InfoRow(label: 'Contact d\'urgence', value: patient?.emergencyContact ?? '-'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Settings
                  _SectionTitle(title: 'Paramètres'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Mode sombre', style: TextStyle(fontSize: 15)),
                          secondary: const Icon(Icons.dark_mode_outlined),
                          value: themeProvider.isDarkMode,
                          onChanged: (_) => themeProvider.toggleTheme(),
                          activeColor: AppColors.softGreen,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined),
                          title: const Text('Notifications', style: TextStyle(fontSize: 15)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('Langue', style: TextStyle(fontSize: 15)),
                          trailing: const Text('Français', style: TextStyle(color: AppColors.textMuted)),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusCritical,
                        side: const BorderSide(color: AppColors.statusCritical),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
