import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/theme_provider.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';
import 'package:diab_care/features/patient/views/medical_profile_form_screen.dart';

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
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          patient != null ? patient.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join() : 'P',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(patient?.name ?? 'Patient', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(patient?.email ?? '', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                      if (patient?.profilMedicalComplete == true)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Profil médical complété', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
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
                  // ── Edit Medical Profile Button ─────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MedicalProfileFormScreen(isPostRegistration: false)),
                        );
                        if (result == true && context.mounted) {
                          context.read<PatientViewModel>().refreshPatientProfile();
                        }
                      },
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: Text(patient?.profilMedicalComplete == true ? 'Modifier le profil médical' : 'Compléter le profil médical'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.softGreen,
                        side: const BorderSide(color: AppColors.softGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Informations personnelles ──────────────────
                  const _SectionTitle(title: 'Informations personnelles'),
                  const SizedBox(height: 12),
                  _buildCard([
                    _InfoRow(label: 'Téléphone', value: patient?.phone ?? '-'),
                    _InfoRow(label: 'Âge', value: patient != null && patient.age > 0 ? '${patient.age} ans' : '-'),
                    _InfoRow(label: 'Taille', value: patient?.height != null ? '${patient!.height!.toStringAsFixed(0)} cm' : '-'),
                    _InfoRow(label: 'Poids', value: patient?.weight != null ? '${patient!.weight!.toStringAsFixed(1)} kg' : '-'),
                    _InfoRow(label: 'IMC', value: patient?.bmi != null ? patient!.bmi!.toStringAsFixed(1) : '-'),
                    _InfoRow(label: 'Groupe sanguin', value: patient?.bloodType ?? '-'),
                    _InfoRow(label: 'Contact urgence', value: patient?.emergencyContact ?? '-'),
                  ]),
                  const SizedBox(height: 20),

                  // ── Informations diabète ───────────────────────
                  const _SectionTitle(title: 'Informations diabète'),
                  const SizedBox(height: 12),
                  _buildCard([
                    _InfoRow(label: 'Type de diabète', value: patient?.diabetesType ?? '-'),
                    _InfoRow(label: 'Date diagnostic', value: patient?.diagnosisDate != null ? '${patient!.diagnosisDate!.day.toString().padLeft(2, '0')}/${patient.diagnosisDate!.month.toString().padLeft(2, '0')}/${patient.diagnosisDate!.year}' : '-'),
                    _InfoRow(label: 'Glycémie à jeun moy.', value: patient?.glycemieAJeunMoyenne != null ? '${patient!.glycemieAJeunMoyenne!.toStringAsFixed(0)} mg/dL' : '-'),
                    _InfoRow(label: 'HbA1c', value: patient?.hba1c != null ? '${patient!.hba1c!.toStringAsFixed(1)}%' : '-'),
                    _InfoRow(label: 'Fréquence mesure', value: patient?.frequenceMesureGlycemie ?? '-'),
                  ]),
                  const SizedBox(height: 20),

                  // ── Traitement ─────────────────────────────────
                  const _SectionTitle(title: 'Traitement actuel'),
                  const SizedBox(height: 12),
                  _buildCard([
                    _InfoRow(label: 'Insuline', value: patient?.prendInsuline == true ? 'Oui' : 'Non'),
                    if (patient?.prendInsuline == true) ...[
                      _InfoRow(label: 'Type insuline', value: patient?.typeInsuline ?? '-'),
                      _InfoRow(label: 'Dose quotidienne', value: patient?.doseQuotidienneInsuline != null ? '${patient!.doseQuotidienneInsuline!.toStringAsFixed(0)} UI' : '-'),
                      _InfoRow(label: 'Fréq. injections', value: patient?.frequenceInjection != null ? '${patient!.frequenceInjection}/jour' : '-'),
                    ],
                    _InfoRow(label: 'Capteur glucose', value: patient?.utiliseCapteurGlucose == true ? 'Oui' : 'Non'),
                    if (patient?.traitements.isNotEmpty == true)
                      _InfoRow(label: 'Traitements', value: patient!.traitements.join(', ')),
                  ]),
                  const SizedBox(height: 20),

                  // ── Antécédents ────────────────────────────────
                  if (_hasAntecedents(patient)) ...[
                    const _SectionTitle(title: 'Antécédents médicaux'),
                    const SizedBox(height: 12),
                    _buildChipSection([
                      if (patient!.antecedentsFamiliauxDiabete) 'Antécédents familiaux',
                      if (patient.hypertension) 'Hypertension',
                      if (patient.maladiesCardiovasculaires) 'Maladies cardiovasculaires',
                      if (patient.problemesRenaux) 'Problèmes rénaux',
                      if (patient.problemesOculaires) 'Problèmes oculaires',
                      if (patient.neuropathieDiabetique) 'Neuropathie',
                    ]),
                    const SizedBox(height: 20),
                  ],

                  // ── Complications ──────────────────────────────
                  if (_hasComplications(patient)) ...[
                    const _SectionTitle(title: 'Complications actuelles'),
                    const SizedBox(height: 12),
                    _buildChipSection([
                      if (patient!.piedDiabetique) 'Pied diabétique',
                      if (patient.ulceres) 'Ulcères',
                      if (patient.hypoglycemiesFrequentes) 'Hypoglycémies fréquentes',
                      if (patient.hyperglycemiesFrequentes) 'Hyperglycémies fréquentes',
                      if (patient.hospitalisationsRecentes) 'Hospitalisations récentes',
                    ]),
                    const SizedBox(height: 20),
                  ],

                  // ── Analyses biologiques ───────────────────────
                  if (_hasLabResults(patient)) ...[
                    const _SectionTitle(title: 'Analyses biologiques'),
                    const SizedBox(height: 12),
                    _buildCard([
                      if (patient!.cholesterolTotal != null) _InfoRow(label: 'Cholestérol total', value: '${patient.cholesterolTotal!.toStringAsFixed(2)} g/L'),
                      if (patient.hdl != null) _InfoRow(label: 'HDL', value: '${patient.hdl!.toStringAsFixed(2)} g/L'),
                      if (patient.ldl != null) _InfoRow(label: 'LDL', value: '${patient.ldl!.toStringAsFixed(2)} g/L'),
                      if (patient.triglycerides != null) _InfoRow(label: 'Triglycérides', value: '${patient.triglycerides!.toStringAsFixed(2)} g/L'),
                      if (patient.creatinine != null) _InfoRow(label: 'Créatinine', value: '${patient.creatinine!.toStringAsFixed(1)} mg/L'),
                      if (patient.microAlbuminurie != null) _InfoRow(label: 'Micro-albuminurie', value: '${patient.microAlbuminurie!.toStringAsFixed(1)} mg/L'),
                    ]),
                    const SizedBox(height: 20),
                  ],

                  // ── Allergies & Maladies ───────────────────────
                  if ((patient?.allergies.isNotEmpty == true) || (patient?.maladiesChroniques.isNotEmpty == true)) ...[
                    const _SectionTitle(title: 'Allergies & Maladies chroniques'),
                    const SizedBox(height: 12),
                    _buildCard([
                      if (patient!.allergies.isNotEmpty) _InfoRow(label: 'Allergies', value: patient.allergies.join(', ')),
                      if (patient.maladiesChroniques.isNotEmpty) _InfoRow(label: 'Maladies chroniques', value: patient.maladiesChroniques.join(', ')),
                    ]),
                    const SizedBox(height: 20),
                  ],

                  // ── Mode de vie ────────────────────────────────
                  if (patient?.niveauActivitePhysique != null || patient?.habitudesAlimentaires != null || patient?.tabac != null) ...[
                    const _SectionTitle(title: 'Mode de vie'),
                    const SizedBox(height: 12),
                    _buildCard([
                      if (patient!.niveauActivitePhysique != null) _InfoRow(label: 'Activité physique', value: patient.niveauActivitePhysique!),
                      if (patient.habitudesAlimentaires != null) _InfoRow(label: 'Alimentation', value: patient.habitudesAlimentaires!),
                      if (patient.tabac != null) _InfoRow(label: 'Tabac', value: patient.tabac!),
                    ]),
                    const SizedBox(height: 20),
                  ],

                  // ── Statistiques glycémie ──────────────────────
                  const _SectionTitle(title: 'Statistiques glycémie'),
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

                  // ── Settings ───────────────────────────────────
                  const _SectionTitle(title: 'Paramètres'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Mode sombre', style: TextStyle(fontSize: 15)),
                          secondary: const Icon(Icons.dark_mode_outlined),
                          value: themeProvider.isDarkMode,
                          onChanged: (_) => themeProvider.toggleTheme(),
                          activeTrackColor: AppColors.softGreen.withValues(alpha: 0.5),
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return AppColors.softGreen;
                            return null;
                          }),
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

                  // ── Logout ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthViewModel>().logout();
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      },
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

  static bool _hasAntecedents(patient) {
    if (patient == null) return false;
    return patient.antecedentsFamiliauxDiabete || patient.hypertension || patient.maladiesCardiovasculaires || patient.problemesRenaux || patient.problemesOculaires || patient.neuropathieDiabetique;
  }

  static bool _hasComplications(patient) {
    if (patient == null) return false;
    return patient.piedDiabetique || patient.ulceres || patient.hypoglycemiesFrequentes || patient.hyperglycemiesFrequentes || patient.hospitalisationsRecentes;
  }

  static bool _hasLabResults(patient) {
    if (patient == null) return false;
    return patient.cholesterolTotal != null || patient.hdl != null || patient.ldl != null || patient.triglycerides != null || patient.creatinine != null || patient.microAlbuminurie != null;
  }

  static Widget _buildCard(List<Widget> children) {
    final filtered = children.whereType<_InfoRow>().toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(
        children: [
          for (int i = 0; i < filtered.length; i++) ...[
            filtered[i],
            if (i < filtered.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }

  static Widget _buildChipSection(List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) => Chip(
          label: Text(item, style: const TextStyle(fontSize: 12, color: Colors.white)),
          backgroundColor: AppColors.softGreen,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: BorderSide.none,
        )).toList(),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
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
