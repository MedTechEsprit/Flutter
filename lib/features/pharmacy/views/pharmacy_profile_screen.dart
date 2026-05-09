import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/utils/profile_image_utils.dart';
import 'package:diab_care/core/widgets/animations.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:diab_care/features/notifications/views/notifications_inbox_screen.dart';
import 'package:diab_care/features/pharmacy/views/pharmacy_location_picker_screen.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  bool _isUploadingPhoto = false;
  bool _isSavingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<PharmacyViewModel>();
      if (viewModel.dashboardData == null &&
          viewModel.dashboardState != LoadingState.loading) {
        viewModel.loadDashboard();
      }
    });
  }

  Future<void> _openLocationOptions(PharmacyViewModel viewModel) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Localisation pharmacie',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.my_location_rounded),
                title: const Text('Detecter automatiquement'),
                subtitle: const Text('Utiliser la position actuelle'),
                onTap: () => Navigator.pop(ctx, 'auto'),
              ),
              ListTile(
                leading: const Icon(Icons.map_rounded),
                title: const Text('Choisir sur la carte'),
                subtitle: const Text('Placer manuellement le point'),
                onTap: () => Navigator.pop(ctx, 'manual'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (action == null) return;
    if (action == 'auto') {
      await _setAutoLocation(viewModel);
    } else {
      await _setManualLocation(viewModel);
    }
  }

  Future<void> _setAutoLocation(PharmacyViewModel viewModel) async {
    if (_isSavingLocation) return;

    setState(() => _isSavingLocation = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Service de localisation desactive');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permission localisation refusee');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));

      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final pm = placemarks.first;
          final parts = [
            pm.street,
            pm.locality,
            pm.administrativeArea,
            pm.country,
          ].where((e) => e != null && e.trim().isNotEmpty).cast<String>().toList();
          address = parts.join(', ');
        }
      } catch (_) {
        // Keep coordinates even if reverse geocoding fails.
      }

      final ok = await viewModel.updatePharmacyLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        adressePharmacie: address,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Localisation mise a jour avec succes.'
                : 'Echec de mise a jour de la localisation.',
          ),
          backgroundColor: ok ? AppColors.softGreen : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Localisation: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingLocation = false);
      }
    }
  }

  Future<void> _setManualLocation(PharmacyViewModel viewModel) async {
    if (_isSavingLocation) return;

    final currentLocation = viewModel.pharmacyProfile?.location;
    final initial = (currentLocation?.latitude != null &&
            currentLocation?.longitude != null)
        ? LatLng(currentLocation!.latitude!, currentLocation.longitude!)
        : null;

    final picked = await Navigator.push<PharmacyLocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PharmacyLocationPickerScreen(initialLocation: initial),
      ),
    );

    if (picked == null) return;
    setState(() => _isSavingLocation = true);

    try {
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          picked.latitude,
          picked.longitude,
        );
        if (placemarks.isNotEmpty) {
          final pm = placemarks.first;
          final parts = [
            pm.street,
            pm.locality,
            pm.administrativeArea,
            pm.country,
          ].where((e) => e != null && e.trim().isNotEmpty).cast<String>().toList();
          address = parts.join(', ');
        }
      } catch (_) {}

      final ok = await viewModel.updatePharmacyLocation(
        latitude: picked.latitude,
        longitude: picked.longitude,
        adressePharmacie: address,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Position enregistree avec succes.'
                : 'Echec enregistrement de la position.',
          ),
          backgroundColor: ok ? AppColors.softGreen : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingLocation = false);
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;

    final messenger = ScaffoldMessenger.of(context);
    final pharmacyViewModel = context.read<PharmacyViewModel>();

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
      final ok = await pharmacyViewModel.updateProfilePhoto(dataUrl);

      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);

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
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
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
    return Consumer<PharmacyViewModel>(
      builder: (context, viewModel, child) {
        final pharmacy = viewModel.pharmacyProfile;
        final stats = viewModel.pharmacyStats;
        final profileImage = ProfileImageUtils.imageProvider(
          pharmacy?.displayProfileImage,
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: CustomScrollView(
            slivers: [
              // ── Gradient Header with decorative circles ──
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
                                      backgroundColor: Colors.white,
                                      backgroundImage: profileImage,
                                      child: profileImage == null
                                          ? const Icon(
                                              Icons.local_pharmacy_rounded,
                                              size: 44,
                                              color: AppColors.primaryGreen,
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
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: _isUploadingPhoto
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color:
                                                          AppColors.softGreen,
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
                                pharmacy?.nomPharmacie ?? 'Pharmacie',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pharmacy?.email ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
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
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    children: [
                      // ── Quick Stats ──
                      if (stats != null) ...[
                        FadeInSlide(
                          index: 0,
                          child: Row(
                            children: [
                              Expanded(
                                child: _GlowStatCard(
                                  label: 'Demandes',
                                  value: '${stats.totalRequests}',
                                  icon: Icons.inbox_rounded,
                                  color: AppColors.softGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _GlowStatCard(
                                  label: 'Acceptées',
                                  value: '${stats.acceptedRequests}',
                                  icon: Icons.check_circle_rounded,
                                  color: AppColors.lightBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _GlowStatCard(
                                  label: 'Clients',
                                  value: '${stats.newClients}',
                                  icon: Icons.people_rounded,
                                  color: AppColors.lavender,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Informations ──
                      if (pharmacy != null) ...[
                        FadeInSlide(
                          index: 1,
                          child: _buildInfoCard(
                            icon: Icons.info_rounded,
                            title: 'Informations',
                            color: AppColors.softGreen,
                            children: [
                              _buildInfoRow(
                                Icons.person_rounded,
                                'Nom',
                                '${pharmacy.nom} ${pharmacy.prenom}',
                                AppColors.softGreen,
                              ),
                              const Divider(height: 24, indent: 46),
                              _buildInfoRow(
                                Icons.email_rounded,
                                'Email',
                                pharmacy.email,
                                AppColors.lightBlue,
                              ),
                              const Divider(height: 24, indent: 46),
                              _buildInfoRow(
                                Icons.phone_rounded,
                                'Téléphone',
                                pharmacy.displayTelephone,
                                const Color(0xFFFFB347),
                              ),
                              const Divider(height: 24, indent: 46),
                              _buildInfoRow(
                                Icons.location_on_rounded,
                                'Adresse',
                                pharmacy.adressePharmacie,
                                const Color(0xFFFF6B6B),
                              ),
                              const Divider(height: 24, indent: 46),
                              _buildInfoRow(
                                Icons.badge_rounded,
                                'N° d\'ordre',
                                pharmacy.numeroOrdre,
                                AppColors.lavender,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else
                        FadeInSlide(
                          index: 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
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
                            child: const Center(
                              child: Text(
                                'Aucune information disponible',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        ),

                      // ── Activity Mode & Settings ──
                      FadeInSlide(
                        index: 2,
                        child: _buildActivityCard(context, viewModel),
                      ),
                      const SizedBox(height: 24),

                      FadeInSlide(
                        index: 2,
                        child: _buildLocationCard(context, viewModel),
                      ),
                      const SizedBox(height: 24),

                      // ── Settings list ──
                      FadeInSlide(
                        index: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6B7280,
                                    ).withOpacity(0.1),
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
                                  _settingsTile(
                                    Icons.notifications_rounded,
                                    'Notifications',
                                    AppColors.softGreen,
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
                                  const Divider(
                                    height: 1,
                                    indent: 60,
                                    endIndent: 16,
                                  ),
                                  _settingsTile(
                                    Icons.tune_rounded,
                                    'Paramètres',
                                    AppColors.lightBlue,
                                    () {},
                                  ),
                                  const Divider(
                                    height: 1,
                                    indent: 60,
                                    endIndent: 16,
                                  ),
                                  _settingsTile(
                                    Icons.help_outline_rounded,
                                    'Aide',
                                    const Color(0xFF48BB78),
                                    () {},
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
                        index: 4,
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
                                final navigator = Navigator.of(context);
                                final authVm = Provider.of<AuthViewModel>(
                                  context,
                                  listen: false,
                                );
                                final pharmacyVm =
                                    Provider.of<PharmacyViewModel>(
                                      context,
                                      listen: false,
                                    );
                                await pharmacyVm.logout(clearAuthData: false);
                                await authVm.logout();
                                if (!mounted) return;
                                navigator.pushNamedAndRemoveUntil(
                                  '/',
                                  (route) => false,
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
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
                                      'Déconnexion',
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
      },
    );
  }

  Widget _buildLocationCard(BuildContext context, PharmacyViewModel viewModel) {
    final profile = viewModel.pharmacyProfile;
    final location = profile?.location;
    final hasLocation = location?.latitude != null && location?.longitude != null;
    final lat = location?.latitude;
    final lng = location?.longitude;

    return _buildInfoCard(
      icon: Icons.location_searching_rounded,
      title: 'Localisation de la pharmacie',
      color: AppColors.lightBlue,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Cette position est utilisee pour recevoir les demandes des patients a proximite.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasLocation
                    ? AppColors.softGreen.withOpacity(0.14)
                    : Colors.orange.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                hasLocation ? 'Configuree' : 'Non configuree',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: hasLocation ? AppColors.softGreen : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          hasLocation
              ? 'Lat: ${lat!.toStringAsFixed(6)} • Lng: ${lng!.toStringAsFixed(6)}'
              : 'Aucune coordonnee GPS enregistree.',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSavingLocation
                ? null
                : () => _openLocationOptions(viewModel),
            icon: _isSavingLocation
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.edit_location_alt_rounded),
            label: Text(
              _isSavingLocation
                  ? 'Mise a jour...'
                  : 'Configurer ma localisation',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
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
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(height: 20, color: AppColors.border.withOpacity(0.5)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, PharmacyViewModel viewModel) {
    final isOnline = viewModel.pharmacyProfile?.isOnDuty ?? true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [const Color(0xFF7DDAB9), const Color(0xFF5BC4A8)]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.softGreen : Colors.grey).withOpacity(
              0.3,
            ),
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
              isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
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
                  isOnline ? 'En ligne' : 'Hors ligne',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnline
                      ? 'Vous recevez des demandes'
                      : 'Vous ne recevez plus de demandes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOnline,
            activeTrackColor: Colors.white.withOpacity(0.4),
            activeColor: Colors.white,
            onChanged: (value) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        value
                            ? Icons.power_settings_new_rounded
                            : Icons.power_off_rounded,
                        color: value ? AppColors.softGreen : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(value ? 'Passer en ligne' : 'Passer hors ligne'),
                    ],
                  ),
                  content: Text(
                    value
                        ? 'En passant en ligne, vous recevrez des demandes de médicaments des patients à proximité.'
                        : 'En passant hors ligne, vous ne recevrez plus de nouvelles demandes.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: value
                            ? AppColors.softGreen
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        value ? 'Passer en ligne' : 'Passer hors ligne',
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await viewModel.updateOnlineStatus(value);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            value
                                ? Icons.check_circle_rounded
                                : Icons.info_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            value
                                ? 'Vous êtes maintenant en ligne'
                                : 'Vous êtes maintenant hors ligne',
                          ),
                        ],
                      ),
                      backgroundColor: value
                          ? AppColors.softGreen
                          : Colors.grey,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
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
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
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
