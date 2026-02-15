import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/core/theme/theme_provider.dart';
import 'package:diab_care/data/mock/mock_pharmacy_data.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';

class PharmacyProfileScreen extends StatelessWidget {
  const PharmacyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = MockPharmacyData.pharmacyStats;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.mixedGradient),
                child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 20),
                  Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)]), child: const CircleAvatar(radius: 48, backgroundColor: Colors.white, child: Icon(Icons.local_pharmacy_rounded, size: 48, color: AppColors.primaryGreen))),
                  const SizedBox(height: 16),
                  const Text('Pharmacie Centrale', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('pharmacie@diabcare.tn', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star_rounded, color: Colors.white, size: 18), const SizedBox(width: 4), Text('${stats.averageRating} / 5.0', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))])),
                ])),
              ),
            ),
          ),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _buildQuickStats(stats),
              const SizedBox(height: 24),
              _buildInfoSection(),
              const SizedBox(height: 24),
              _buildSettingsSection(context),
              const SizedBox(height: 24),
              _buildLogoutButton(context),
              const SizedBox(height: 40),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickStats(stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Row(children: [
        _statItem('${stats.totalRequests}', 'Total', Icons.list_alt_rounded),
        _divider(),
        _statItem('${stats.acceptedRequests}', 'Acceptées', Icons.check_circle_rounded),
        _divider(),
        _statItem('${stats.acceptanceRate.toStringAsFixed(0)}%', 'Taux', Icons.trending_up_rounded),
        _divider(),
        _statItem('${stats.responseTimeMinutes}m', 'Réponse', Icons.timer_rounded),
      ]),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Expanded(child: Column(children: [
      Icon(icon, color: AppColors.primaryGreen, size: 22),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]));
  }

  Widget _divider() => Container(width: 1, height: 50, color: AppColors.border);

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Informations', style: AppTextStyles.header),
        const SizedBox(height: 16),
        _infoRow(Icons.location_on_rounded, 'Adresse', '12 Rue de la Santé, Tunis'),
        _infoRow(Icons.phone_rounded, 'Téléphone', '+216 71 234 567'),
        _infoRow(Icons.access_time_rounded, 'Horaires', '08:00 - 20:00'),
        _infoRow(Icons.local_pharmacy_rounded, 'Licence', 'PH-2024-0042'),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: AppColors.greenGradient, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: AppColors.darkGreen)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))])),
      ]),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Paramètres', style: AppTextStyles.header),
        const SizedBox(height: 16),
        _settingsRow(Icons.notifications_rounded, 'Notifications', trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppColors.primaryGreen)),
        _settingsRow(Icons.dark_mode_rounded, 'Mode Sombre', trailing: Switch(value: themeProvider.isDarkMode, onChanged: (v) => themeProvider.toggleTheme(), activeColor: AppColors.primaryGreen)),
        _settingsRow(Icons.language_rounded, 'Langue', trailing: const Text('Français', style: TextStyle(color: AppColors.textSecondary))),
        _settingsRow(Icons.shield_rounded, 'Confidentialité'),
        _settingsRow(Icons.help_outline_rounded, 'Aide & Support'),
      ]),
    );
  }

  Widget _settingsRow(IconData icon, String label, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: AppColors.textSecondary)),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
        trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ]),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          final authVm = Provider.of<AuthViewModel>(context, listen: false);
          authVm.logout();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Déconnexion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}
