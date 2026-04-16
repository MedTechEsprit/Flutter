import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/theme_provider.dart';
import 'package:diab_care/core/utils/profile_image_utils.dart';
import 'package:diab_care/core/widgets/animations.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';
import 'package:diab_care/features/patient/views/medical_profile_form_screen.dart';
import 'package:diab_care/data/services/subscription_service.dart';
import 'package:diab_care/features/ai/views/premium_subscription_screen.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final patientViewModel = context.read<PatientViewModel>();

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (picked == null || !context.mounted) return;

      final bytes = await File(picked.path).readAsBytes();
      final dataUrl = ProfileImageUtils.toDataUrl(bytes);

      final ok = await patientViewModel.updateProfilePhoto(dataUrl);
      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Photo de profil mise à jour'
                : 'Impossible de mettre à jour la photo',
          ),
          backgroundColor: ok ? AppColors.softGreen : const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur photo: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<PatientViewModel>().patient;
    final glucoseVM = context.watch<GlucoseViewModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final profileImage = ProfileImageUtils.imageProvider(patient?.avatarUrl);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header with decorative circles ──
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        children: [
                          // Title row
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Mon Profil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Avatar
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  backgroundImage: profileImage,
                                  child: profileImage == null
                                      ? Text(
                                          patient != null
                                              ? patient.name
                                                    .split(' ')
                                                    .map(
                                                      (n) => n.isNotEmpty
                                                          ? n[0]
                                                          : '',
                                                    )
                                                    .take(2)
                                                    .join()
                                              : 'P',
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: () => _pickAndUploadPhoto(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: AppColors.softGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            patient?.name ?? 'Patient',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            patient?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          if (patient?.profilMedicalComplete == true) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Profil médical complété',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Decorative circles
                Positioned(
                  top: 20,
                  right: -20,
                  child: _DecorativeCircle(size: 80, opacity: 0.06),
                ),
                Positioned(
                  top: 60,
                  right: 30,
                  child: _DecorativeCircle(size: 30, opacity: 0.04),
                ),
                Positioned(
                  top: 30,
                  left: -15,
                  child: _DecorativeCircle(size: 50, opacity: 0.05),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Edit Medical Profile Button ──
                  FadeInSlide(
                    index: 0,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7DDAB9), Color(0xFF5BC4A8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.softGreen.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MedicalProfileFormScreen(
                                  isPostRegistration: false,
                                ),
                              ),
                            );
                            if (result == true && context.mounted) {
                              context
                                  .read<PatientViewModel>()
                                  .refreshPatientProfile();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.edit_note_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  patient?.profilMedicalComplete == true
                                      ? 'Modifier le profil médical'
                                      : 'Compléter le profil médical',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Glucose Stats Row ──
                  FadeInSlide(
                    index: 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: _GlowStatCard(
                            label: 'Mesures',
                            value: '${glucoseVM.readings.length}',
                            icon: Icons.analytics_rounded,
                            color: AppColors.softGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GlowStatCard(
                            label: 'Temps cible',
                            value: '${glucoseVM.timeInRange.toInt()}%',
                            icon: Icons.gps_fixed_rounded,
                            color: AppColors.lightBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GlowStatCard(
                            label: 'Moyenne',
                            value: '${glucoseVM.averageGlucose.toInt()}',
                            icon: Icons.show_chart_rounded,
                            color: AppColors.lavender,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  FadeInSlide(
                    index: 2,
                    child: const _SubscriptionProfileCard(),
                  ),
                  const SizedBox(height: 20),

                  // ── Informations personnelles ──
                  _buildSection(
                    index: 2,
                    icon: Icons.person_rounded,
                    title: 'Informations personnelles',
                    color: AppColors.softGreen,
                    children: [
                      _InfoRow(
                        label: 'Téléphone',
                        value: patient?.phone ?? '-',
                      ),
                      _InfoRow(
                        label: 'Âge',
                        value: patient != null && patient.age > 0
                            ? '${patient.age} ans'
                            : '-',
                      ),
                      _InfoRow(
                        label: 'Taille',
                        value: patient?.height != null
                            ? '${patient!.height!.toStringAsFixed(0)} cm'
                            : '-',
                      ),
                      _InfoRow(
                        label: 'Poids',
                        value: patient?.weight != null
                            ? '${patient!.weight!.toStringAsFixed(1)} kg'
                            : '-',
                      ),
                      _InfoRow(
                        label: 'IMC',
                        value: patient?.bmi != null
                            ? patient!.bmi!.toStringAsFixed(1)
                            : '-',
                      ),
                      _InfoRow(
                        label: 'Groupe sanguin',
                        value: patient?.bloodType ?? '-',
                      ),
                      _InfoRow(
                        label: 'Contact urgence',
                        value: patient?.emergencyContact ?? '-',
                      ),
                    ],
                  ),

                  // ── Informations diabète ──
                  _buildSection(
                    index: 3,
                    icon: Icons.bloodtype_rounded,
                    title: 'Informations diabète',
                    color: AppColors.warmPeach,
                    children: [
                      _InfoRow(
                        label: 'Type de diabète',
                        value: patient?.diabetesType ?? '-',
                      ),
                      _InfoRow(
                        label: 'Date diagnostic',
                        value: patient?.diagnosisDate != null
                            ? '${patient!.diagnosisDate!.day.toString().padLeft(2, '0')}/${patient.diagnosisDate!.month.toString().padLeft(2, '0')}/${patient.diagnosisDate!.year}'
                            : '-',
                      ),
                      _InfoRow(
                        label: 'Glycémie à jeun moy.',
                        value: patient?.glycemieAJeunMoyenne != null
                            ? '${patient!.glycemieAJeunMoyenne!.toStringAsFixed(0)} mg/dL'
                            : '-',
                      ),
                      _InfoRow(
                        label: 'HbA1c',
                        value: patient?.hba1c != null
                            ? '${patient!.hba1c!.toStringAsFixed(1)}%'
                            : '-',
                      ),
                      _InfoRow(
                        label: 'Fréquence mesure',
                        value: patient?.frequenceMesureGlycemie ?? '-',
                      ),
                    ],
                  ),

                  // ── Traitement ──
                  _buildSection(
                    index: 4,
                    icon: Icons.medication_rounded,
                    title: 'Traitement actuel',
                    color: AppColors.lightBlue,
                    children: [
                      _InfoRow(
                        label: 'Insuline',
                        value: patient?.prendInsuline == true ? 'Oui' : 'Non',
                      ),
                      if (patient?.prendInsuline == true) ...[
                        _InfoRow(
                          label: 'Type insuline',
                          value: patient?.typeInsuline ?? '-',
                        ),
                        _InfoRow(
                          label: 'Dose quotidienne',
                          value: patient?.doseQuotidienneInsuline != null
                              ? '${patient!.doseQuotidienneInsuline!.toStringAsFixed(0)} UI'
                              : '-',
                        ),
                        _InfoRow(
                          label: 'Fréq. injections',
                          value: patient?.frequenceInjection != null
                              ? '${patient!.frequenceInjection}/jour'
                              : '-',
                        ),
                      ],
                      _InfoRow(
                        label: 'Capteur glucose',
                        value: patient?.utiliseCapteurGlucose == true
                            ? 'Oui'
                            : 'Non',
                      ),
                      if (patient?.traitements.isNotEmpty == true)
                        _InfoRow(
                          label: 'Traitements',
                          value: patient!.traitements.join(', '),
                        ),
                    ],
                  ),

                  // ── Antécédents ──
                  if (_hasAntecedents(patient))
                    _buildChipSection(
                      index: 5,
                      icon: Icons.history_rounded,
                      title: 'Antécédents médicaux',
                      color: const Color(0xFFFFB347),
                      items: [
                        if (patient!.antecedentsFamiliauxDiabete)
                          'Antécédents familiaux',
                        if (patient.hypertension) 'Hypertension',
                        if (patient.maladiesCardiovasculaires)
                          'Maladies cardiovasculaires',
                        if (patient.problemesRenaux) 'Problèmes rénaux',
                        if (patient.problemesOculaires) 'Problèmes oculaires',
                        if (patient.neuropathieDiabetique) 'Neuropathie',
                      ],
                    ),

                  // ── Complications ──
                  if (_hasComplications(patient))
                    _buildChipSection(
                      index: 6,
                      icon: Icons.warning_rounded,
                      title: 'Complications actuelles',
                      color: const Color(0xFFFF6B6B),
                      items: [
                        if (patient!.piedDiabetique) 'Pied diabétique',
                        if (patient.ulceres) 'Ulcères',
                        if (patient.hypoglycemiesFrequentes)
                          'Hypoglycémies fréquentes',
                        if (patient.hyperglycemiesFrequentes)
                          'Hyperglycémies fréquentes',
                        if (patient.hospitalisationsRecentes)
                          'Hospitalisations récentes',
                      ],
                    ),

                  // ── Analyses biologiques ──
                  if (_hasLabResults(patient))
                    _buildSection(
                      index: 7,
                      icon: Icons.science_rounded,
                      title: 'Analyses biologiques',
                      color: AppColors.lavender,
                      children: [
                        if (patient!.cholesterolTotal != null)
                          _InfoRow(
                            label: 'Cholestérol total',
                            value:
                                '${patient.cholesterolTotal!.toStringAsFixed(2)} g/L',
                          ),
                        if (patient.hdl != null)
                          _InfoRow(
                            label: 'HDL',
                            value: '${patient.hdl!.toStringAsFixed(2)} g/L',
                          ),
                        if (patient.ldl != null)
                          _InfoRow(
                            label: 'LDL',
                            value: '${patient.ldl!.toStringAsFixed(2)} g/L',
                          ),
                        if (patient.triglycerides != null)
                          _InfoRow(
                            label: 'Triglycérides',
                            value:
                                '${patient.triglycerides!.toStringAsFixed(2)} g/L',
                          ),
                        if (patient.creatinine != null)
                          _InfoRow(
                            label: 'Créatinine',
                            value:
                                '${patient.creatinine!.toStringAsFixed(1)} mg/L',
                          ),
                        if (patient.microAlbuminurie != null)
                          _InfoRow(
                            label: 'Micro-albuminurie',
                            value:
                                '${patient.microAlbuminurie!.toStringAsFixed(1)} mg/L',
                          ),
                      ],
                    ),

                  // ── Allergies & Maladies ──
                  if ((patient?.allergies.isNotEmpty == true) ||
                      (patient?.maladiesChroniques.isNotEmpty == true))
                    _buildSection(
                      index: 8,
                      icon: Icons.local_hospital_rounded,
                      title: 'Allergies & Maladies chroniques',
                      color: const Color(0xFFFF6B6B),
                      children: [
                        if (patient!.allergies.isNotEmpty)
                          _InfoRow(
                            label: 'Allergies',
                            value: patient.allergies.join(', '),
                          ),
                        if (patient.maladiesChroniques.isNotEmpty)
                          _InfoRow(
                            label: 'Maladies chroniques',
                            value: patient.maladiesChroniques.join(', '),
                          ),
                      ],
                    ),

                  // ── Mode de vie ──
                  if (patient?.niveauActivitePhysique != null ||
                      patient?.habitudesAlimentaires != null ||
                      patient?.tabac != null)
                    _buildSection(
                      index: 9,
                      icon: Icons.directions_run_rounded,
                      title: 'Mode de vie',
                      color: const Color(0xFF48BB78),
                      children: [
                        if (patient!.niveauActivitePhysique != null)
                          _InfoRow(
                            label: 'Activité physique',
                            value: patient.niveauActivitePhysique!,
                          ),
                        if (patient.habitudesAlimentaires != null)
                          _InfoRow(
                            label: 'Alimentation',
                            value: patient.habitudesAlimentaires!,
                          ),
                        if (patient.tabac != null)
                          _InfoRow(label: 'Tabac', value: patient.tabac!),
                      ],
                    ),

                  const SizedBox(height: 4),

                  // ── Settings Section ──
                  FadeInSlide(
                    index: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B7280).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: Color(0xFF6B7280),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Paramètres',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text(
                                  'Mode sombre',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                secondary: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6B7280,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.dark_mode_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 18,
                                  ),
                                ),
                                value: themeProvider.isDarkMode,
                                onChanged: (_) => themeProvider.toggleTheme(),
                                activeTrackColor: AppColors.softGreen
                                    .withOpacity(0.5),
                                thumbColor: WidgetStateProperty.resolveWith((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.selected))
                                    return AppColors.softGreen;
                                  return null;
                                }),
                              ),
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              _SettingsTile(
                                icon: Icons.notifications_rounded,
                                title: 'Notifications',
                                color: const Color(0xFFFFB347),
                                onTap: () {},
                              ),
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              _SettingsTile(
                                icon: Icons.language_rounded,
                                title: 'Langue',
                                color: AppColors.lightBlue,
                                trailing: Text(
                                  'Français',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Logout ──
                  FadeInSlide(
                    index: 11,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await context.read<AuthViewModel>().logout();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFFFF6B6B),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Se déconnecter',
                                  style: TextStyle(
                                    color: Color(0xFFFF6B6B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section builders ──
  Widget _buildSection({
    required int index,
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    final filtered = children.whereType<_InfoRow>().toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FadeInSlide(
        index: index,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (int i = 0; i < filtered.length; i++) ...[
                    filtered[i],
                    if (i < filtered.length - 1)
                      Divider(
                        height: 20,
                        color: AppColors.border.withOpacity(0.5),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipSection({
    required int index,
    required IconData icon,
    required String title,
    required Color color,
    required List<String> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FadeInSlide(
        index: index,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _hasAntecedents(patient) {
    if (patient == null) return false;
    return patient.antecedentsFamiliauxDiabete ||
        patient.hypertension ||
        patient.maladiesCardiovasculaires ||
        patient.problemesRenaux ||
        patient.problemesOculaires ||
        patient.neuropathieDiabetique;
  }

  static bool _hasComplications(patient) {
    if (patient == null) return false;
    return patient.piedDiabetique ||
        patient.ulceres ||
        patient.hypoglycemiesFrequentes ||
        patient.hyperglycemiesFrequentes ||
        patient.hospitalisationsRecentes;
  }

  static bool _hasLabResults(patient) {
    if (patient == null) return false;
    return patient.cholesterolTotal != null ||
        patient.hdl != null ||
        patient.ldl != null ||
        patient.triglycerides != null ||
        patient.creatinine != null ||
        patient.microAlbuminurie != null;
  }
}

// ── Private Widgets ──

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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _GlowStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

class _SubscriptionProfileCard extends StatefulWidget {
  const _SubscriptionProfileCard();

  @override
  State<_SubscriptionProfileCard> createState() =>
      _SubscriptionProfileCardState();
}

class _SubscriptionProfileCardState extends State<_SubscriptionProfileCard> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  late Future<SubscriptionStatus> _subscriptionFuture;

  @override
  void initState() {
    super.initState();
    _subscriptionFuture = _subscriptionService.getMySubscription();
  }

  Future<void> _refresh() async {
    setState(() {
      _subscriptionFuture = _subscriptionService.getMySubscription();
    });
    await _subscriptionFuture;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FutureBuilder<SubscriptionStatus>(
        future: _subscriptionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.accentGold,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Abonnement Premium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Impossible de charger le statut d\'abonnement.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              ],
            );
          }

          final sub = snapshot.data!;
          final isActive = sub.isActive;
          final currencyCode = sub.currency.toUpperCase();
          final currencyLabel = currencyCode == 'EUR' ? '€' : currencyCode;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFB88700),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Abonnement Premium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.successGreen.withValues(alpha: 0.25)
                          : AppColors.warningOrange.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF1F8F51)
                            : const Color(0xFFB36A00),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${sub.planName} • ${sub.amount} $currencyLabel/mois',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isActive
                    ? 'Expire le ${_formatDate(sub.expiresAt)}'
                    : 'Aucun abonnement actif',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Actualiser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PremiumSubscriptionScreen(),
                          ),
                        );
                        if (!mounted) return;
                        _refresh();
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(isActive ? 'Gérer' : 'Souscrire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
