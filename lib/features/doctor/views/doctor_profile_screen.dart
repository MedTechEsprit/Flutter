import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/theme_provider.dart';
import 'package:diab_care/core/utils/profile_image_utils.dart';
import 'package:diab_care/core/widgets/animations.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:diab_care/features/notifications/views/notifications_inbox_screen.dart';
import 'package:diab_care/data/services/doctor_service.dart';
import 'package:diab_care/core/services/token_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorService _doctorService = DoctorService();
  final TokenService _tokenService = TokenService();

  bool isAvailable = true;
  bool _isLoading = true;
  bool _isTogglingStatus = false;
  bool _isUploadingPhoto = false;
  bool _isBoostLoading = false;
  bool _isBoostVerifying = false;
  bool _isLoggingOut = false;
  String? _activatingBoostType;
  Map<String, dynamic>? _doctorData;
  Map<String, dynamic>? _boostStatus;
  List<Map<String, dynamic>> _boostPlans = [];
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_doctorId == null || _isUploadingPhoto) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final bytes = await File(picked.path).readAsBytes();
      final dataUrl = ProfileImageUtils.toDataUrl(bytes);
      final updated = await _doctorService.updateDoctorProfile(_doctorId!, {
        'photoProfil': dataUrl,
      });

      final token = await _tokenService.getToken();
      if (token != null) {
        await _tokenService.saveAuthData(token: token, userData: updated);
      }

      if (!mounted) return;
      setState(() {
        _doctorData = updated;
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil mise à jour'),
          backgroundColor: AppColors.softGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur photo: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadDoctorProfile() async {
    try {
      setState(() => _isLoading = true);
      final userData = await _tokenService.getUserData();
      _doctorId = userData?['_id'];

      if (_doctorId != null) {
        final doctorData = await _doctorService.getDoctorProfile(_doctorId!);
        final statusData = await _doctorService.getDoctorStatus(_doctorId!);
        Map<String, dynamic>? boostStatus;
        List<Map<String, dynamic>> boostPlans = [];

        try {
          boostStatus = await _doctorService.getDoctorBoostStatus(_doctorId!);
          boostPlans = await _doctorService.getDoctorBoostPlans();
        } catch (_) {
          boostStatus = null;
          boostPlans = [];
        }

        setState(() {
          _doctorData = doctorData;
          _boostStatus = boostStatus;
          _boostPlans = boostPlans;
          if (statusData['isActive'] != null) {
            isAvailable = statusData['isActive'] == true;
          } else {
            isAvailable = doctorData['statutCompte'] == 'ACTIF';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur de chargement: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _refreshBoostData() async {
    if (_doctorId == null) return;

    try {
      setState(() => _isBoostLoading = true);
      final boostStatus = await _doctorService.getDoctorBoostStatus(_doctorId!);
      final boostPlans = await _doctorService.getDoctorBoostPlans();
      if (!mounted) return;

      setState(() {
        _boostStatus = boostStatus;
        _boostPlans = boostPlans;
        _isBoostLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBoostLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur boost: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _activateBoost(String boostType) async {
    if (_activatingBoostType != null) return;

    try {
      setState(() => _activatingBoostType = boostType);
      final result = await _doctorService.purchaseDoctorBoost(boostType);
      if (!mounted) return;

      setState(() {
        _boostStatus = result;
      });

      final isActive = result['isActive'] == true;
      final message = isActive
          ? 'Boost activé ✅ Votre profil est maintenant suggéré.'
          : 'Achat enregistré. Synchronisation de l\'activation en cours.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isActive
              ? AppColors.softGreen
              : AppColors.accentBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _refreshBoostData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activation impossible: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _activatingBoostType = null);
      }
    }
  }

  Future<void> _verifyBoostPayment() async {
    if (_isBoostVerifying) return;

    try {
      setState(() => _isBoostVerifying = true);
      final result = await _doctorService.verifyDoctorBoostLatestPayment();
      if (!mounted) return;

      setState(() {
        _boostStatus = result;
      });

      final isActive = result['isActive'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Boost activé ✅ Votre profil est maintenant suggéré.'
                : 'Achat détecté, mais activation non confirmée pour le moment.',
          ),
          backgroundColor: isActive
              ? AppColors.softGreen
              : AppColors.accentBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _refreshBoostData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vérification impossible: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBoostVerifying = false);
      }
    }
  }

  Future<void> _toggleAvailability() async {
    if (_doctorId == null || _isTogglingStatus) return;

    try {
      setState(() => _isTogglingStatus = true);
      final updatedData = await _doctorService.toggleDoctorStatus(_doctorId!);
      final newStatutCompte = updatedData['statutCompte'];
      final newIsActive = newStatutCompte == 'ACTIF';

      setState(() {
        _doctorData = updatedData;
        isAvailable = newIsActive;
        _isTogglingStatus = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isAvailable
                      ? 'Profil activé - Vous êtes en ligne'
                      : 'Profil désactivé - Vous êtes hors ligne',
                ),
              ],
            ),
            backgroundColor: isAvailable ? AppColors.softGreen : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isTogglingStatus = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    if (_doctorId == null || _doctorData == null) return;

    final updatedData = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _DoctorProfileEditScreen(
          doctorId: _doctorId!,
          initialData: _doctorData!,
          doctorService: _doctorService,
          tokenService: _tokenService,
        ),
      ),
    );

    if (updatedData != null && mounted) {
      setState(() => _doctorData = updatedData);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès.'),
          backgroundColor: AppColors.softGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    try {
      await context.read<AuthViewModel>().logout();
      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de deconnexion: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final profileImage = ProfileImageUtils.imageProvider(
      _doctorData?['photoProfil']?.toString(),
    );

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.softGreen),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient Header with decorative circles ──
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.mainGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        children: [
                          // Top bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Mon Profil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox.shrink(),
                            ],
                          ),
                          const SizedBox(height: 20),
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
                                          _doctorData != null
                                              ? '${_doctorData!['prenom']?[0] ?? 'D'}${_doctorData!['nom']?[0] ?? 'R'}'
                                              : 'DR',
                                          style: const TextStyle(
                                            fontSize: 28,
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
                                  onTap: _isUploadingPhoto
                                      ? null
                                      : _pickAndUploadPhoto,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: _isUploadingPhoto
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.softGreen,
                                            ),
                                          )
                                        : const Icon(
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
                            _doctorData != null
                                ? 'Dr. ${_doctorData!['prenom'] ?? ''} ${_doctorData!['nom'] ?? ''}'
                                : 'Dr. ...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _doctorData?['role'] ?? 'Médecin',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
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

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                children: [
                  // ── Availability card ──
                  FadeInSlide(
                    index: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isAvailable
                              ? [
                                  const Color(0xFF7DDAB9),
                                  const Color(0xFF5BC4A8),
                                ]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isAvailable
                                        ? AppColors.softGreen
                                        : Colors.grey)
                                    .withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isAvailable
                                  ? Icons.wifi_tethering_rounded
                                  : Icons.wifi_off_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAvailable
                                      ? 'En ligne (Actif)'
                                      : 'Hors ligne (Inactif)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAvailable
                                      ? 'Accepte de nouveaux patients'
                                      : 'Actuellement indisponible',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isTogglingStatus)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          else
                            Switch(
                              value: isAvailable,
                              activeTrackColor: Colors.white.withOpacity(0.4),
                              activeColor: Colors.white,
                              onChanged: (v) => _toggleAvailability(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Boost suggested profile ──
                  FadeInSlide(index: 1, child: _buildBoostCard()),
                  const SizedBox(height: 20),

                  // ── Contact Info ──
                  FadeInSlide(
                    index: 2,
                    child: _buildInfoCard(
                      icon: Icons.contact_mail_rounded,
                      title: 'Coordonnées',
                      color: AppColors.softGreen,
                      children: [
                        _contactRow(
                          Icons.email_rounded,
                          _doctorData?['email'] ?? 'Pas d\'email',
                          AppColors.softGreen,
                        ),
                        const Divider(height: 24, indent: 46),
                        _contactRow(
                          Icons.phone_rounded,
                          _doctorData?['telephone'] ?? 'Pas de téléphone',
                          AppColors.lightBlue,
                        ),
                        if (_doctorData?['numeroOrdre'] != null) ...[
                          const Divider(height: 24, indent: 46),
                          _contactRow(
                            Icons.badge_rounded,
                            'N° Ordre: ${_doctorData!['numeroOrdre']}',
                            const Color(0xFFFFB347),
                          ),
                        ],
                        if (_doctorData?['clinique'] != null) ...[
                          const Divider(height: 24, indent: 46),
                          _contactRow(
                            Icons.business_rounded,
                            _doctorData!['clinique'],
                            AppColors.lavender,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Stats Grid ──
                  FadeInSlide(
                    index: 3,
                    child: Row(
                      children: [
                        Expanded(
                          child: _GlowStatCard(
                            value: '0',
                            label: 'Consultations',
                            icon: Icons.medical_services_rounded,
                            color: AppColors.softGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GlowStatCard(
                            value: '0%',
                            label: 'Satisfaction',
                            icon: Icons.thumb_up_rounded,
                            color: AppColors.lightBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInSlide(
                    index: 4,
                    child: Row(
                      children: [
                        Expanded(
                          child: _GlowStatCard(
                            value: '0',
                            label: 'Demandes',
                            icon: Icons.person_add_rounded,
                            color: AppColors.warmPeach,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GlowStatCard(
                            value: '0',
                            label: 'Cette semaine',
                            icon: Icons.calendar_today_rounded,
                            color: AppColors.lavender,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Settings ──
                  FadeInSlide(
                    index: 5,
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
                        _actionBtn(
                          Icons.edit_rounded,
                          'Modifier le profil',
                          'Mettre à jour vos informations',
                          AppColors.softGreen,
                          _showEditProfileDialog,
                        ),
                        _actionBtn(
                          Icons.lock_rounded,
                          'Changer le mot de passe',
                          'Mettre à jour votre sécurité',
                          AppColors.lightBlue,
                          () {},
                        ),
                        _actionBtn(
                          Icons.notifications_rounded,
                          'Notifications',
                          'Gérer vos alertes',
                          const Color(0xFFFFB347),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationsInboxScreen(),
                              ),
                            );
                          },
                        ),
                        // Dark mode
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
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
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6B7280,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.dark_mode_rounded,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mode sombre',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      themeProvider.isDarkMode
                                          ? 'Actuellement activé'
                                          : 'Changer de thème',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: themeProvider.isDarkMode,
                                activeColor: AppColors.softGreen,
                                onChanged: (_) => themeProvider.toggleTheme(),
                              ),
                            ],
                          ),
                        ),
                        _actionBtn(
                          Icons.help_outline_rounded,
                          'Aide & Support',
                          'Obtenir de l\'assistance',
                          const Color(0xFF48BB78),
                          () {},
                        ),

                        const SizedBox(height: 24),
                        Container(
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
                              onTap: _isLoggingOut ? null : _handleLogout,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isLoggingOut)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFFF6B6B),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.logout_rounded,
                                        color: Color(0xFFFF6B6B),
                                        size: 20,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isLoggingOut
                                          ? 'Déconnexion...'
                                          : 'Se déconnecter',
                                      style: const TextStyle(
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
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
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
          padding: const EdgeInsets.all(20),
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildBoostCard() {
    final isBoostActive = _boostStatus?['isActive'] == true;
    final remainingDays = (_boostStatus?['remainingDays'] ?? 0).toString();
    final expiresAtRaw = _boostStatus?['expiresAt'];
    final expiresAt = expiresAtRaw is String
        ? DateTime.tryParse(expiresAtRaw)
        : expiresAtRaw is DateTime
        ? expiresAtRaw
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                  'Boost profil suggéré',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_isBoostLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isBoostActive
                ? 'Votre profil est suggéré (${remainingDays}j restants).'
                : 'Activez un boost pour devenir médecin suggéré.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (isBoostActive) ...[
            const SizedBox(height: 4),
            Text(
              'Expire le ${_formatDate(expiresAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_boostPlans.isEmpty)
            OutlinedButton.icon(
              onPressed: _isBoostLoading ? null : _refreshBoostData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Charger les offres'),
            )
          else
            Column(
              children: _boostPlans.map((plan) {
                final boostType = (plan['boostType'] ?? '').toString();
                final label = (plan['label'] ?? 'Boost').toString();
                final days = (plan['days'] ?? '').toString();
                final price = (plan['price'] ?? '').toString();
                final isLoadingThis = _activatingBoostType == boostType;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundPrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$label ($days jours)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$price €',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isLoadingThis
                            ? null
                            : () => _activateBoost(boostType),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoadingThis
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Acheter'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: (_isBoostLoading || _isBoostVerifying)
                ? null
                : _verifyBoostPayment,
            icon: _isBoostVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_rounded),
            label: Text(
              _isBoostVerifying ? 'Vérification...' : 'Synchroniser mes achats',
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}

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

class _GlowStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _GlowStatCard({
    required this.value,
    required this.label,
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
            style: TextStyle(
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

class _DoctorProfileEditScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> initialData;
  final DoctorService doctorService;
  final TokenService tokenService;

  const _DoctorProfileEditScreen({
    required this.doctorId,
    required this.initialData,
    required this.doctorService,
    required this.tokenService,
  });

  @override
  State<_DoctorProfileEditScreen> createState() =>
      _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<_DoctorProfileEditScreen> {
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _specialiteController;
  late final TextEditingController _cliniqueController;
  late final TextEditingController _adresseController;
  late final TextEditingController _descriptionController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(
      text: widget.initialData['nom']?.toString() ?? '',
    );
    _prenomController = TextEditingController(
      text: widget.initialData['prenom']?.toString() ?? '',
    );
    _telephoneController = TextEditingController(
      text: widget.initialData['telephone']?.toString() ?? '',
    );
    _specialiteController = TextEditingController(
      text: widget.initialData['specialite']?.toString() ?? '',
    );
    _cliniqueController = TextEditingController(
      text: widget.initialData['clinique']?.toString() ?? '',
    );
    _adresseController = TextEditingController(
      text: widget.initialData['adresseCabinet']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialData['description']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _specialiteController.dispose();
    _cliniqueController.dispose();
    _adresseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();
    final specialite = _specialiteController.text.trim();

    if (nom.isEmpty || prenom.isEmpty || specialite.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Nom, prénom et spécialité sont requis.'),
          backgroundColor: Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updates = <String, dynamic>{
        'nom': nom,
        'prenom': prenom,
        'telephone': _telephoneController.text.trim(),
        'specialite': specialite,
        'clinique': _cliniqueController.text.trim(),
        'adresseCabinet': _adresseController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      final updated = await widget.doctorService.updateDoctorProfile(
        widget.doctorId,
        updates,
      );

      final token = await widget.tokenService.getToken();
      if (token != null) {
        await widget.tokenService.saveAuthData(token: token, userData: updated);
      }

      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Échec de mise à jour: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _field('Nom', _nomController, Icons.person_outline_rounded),
              _field('Prénom', _prenomController, Icons.person_rounded),
              _field('Téléphone', _telephoneController, Icons.phone_rounded),
              _field(
                'Spécialité',
                _specialiteController,
                Icons.medical_services_rounded,
              ),
              _field('Clinique', _cliniqueController, Icons.business_rounded),
              _field(
                'Adresse cabinet',
                _adresseController,
                Icons.location_on_outlined,
              ),
              _field(
                'Description',
                _descriptionController,
                Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
