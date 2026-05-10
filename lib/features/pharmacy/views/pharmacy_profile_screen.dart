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
import 'package:diab_care/data/models/pharmacy_models.dart';
import 'package:diab_care/features/pharmacy/models/pharmacy_api_models.dart';
import 'package:diab_care/features/pharmacy/views/pharmacy_requests_screen.dart';
import 'package:diab_care/features/notifications/views/notifications_inbox_screen.dart';

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
        final points = pharmacy?.points ?? 0;
        final badgeLevel = pharmacy?.badgeLevel ?? 'bronze';
        
        final profileImage = ProfileImageUtils.imageProvider(
          pharmacy?.displayProfileImage,
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: RefreshIndicator(
            onRefresh: () => viewModel.loadDashboard(),
            color: AppColors.primaryGreen,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // ── Header Premium ──
                SliverToBoxAdapter(
                  child: _buildPremiumHeader(
                    context, 
                    pharmacy, 
                    profileImage, 
                    badgeLevel, 
                    points
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Statut d'Activité (Switch) ──
                        FadeInSlide(
                          index: 0,
                          child: _buildActivityCard(context, viewModel),
                        ),
                        const SizedBox(height: 24),

                        // ── Performance Grid ──
                        _buildSectionTitle(Icons.analytics_rounded, 'Performance Réelle'),
                        const SizedBox(height: 12),
                        FadeInSlide(
                          index: 1,
                          child: _buildPerformanceGrid(stats, points),
                        ),
                        const SizedBox(height: 24),

                        // ── Informations de la Pharmacie ──
                        _buildSectionTitle(Icons.business_rounded, 'Détails de l\'établissement'),
                        const SizedBox(height: 12),
                        FadeInSlide(
                          index: 2,
                          child: _buildPharmacyDetailsCard(pharmacy),
                        ),
                        const SizedBox(height: 24),

                        // ── Localisation ──
                        _buildSectionTitle(Icons.map_rounded, 'Localisation'),
                        const SizedBox(height: 12),
                        FadeInSlide(
                          index: 3,
                          child: _buildLocationCard(context, viewModel),
                        ),
                        const SizedBox(height: 24),

                        // ── Paramètres & Compte ──
                        _buildSectionTitle(Icons.settings_rounded, 'Paramètres & Compte'),
                        const SizedBox(height: 12),
                        FadeInSlide(
                          index: 4,
                          child: _buildSettingsSection(context, viewModel),
                        ),
                        const SizedBox(height: 32),

                        // ── Déconnexion ──
                        _buildLogoutButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Header avec bannière et avatar Squircle
  Widget _buildPremiumHeader(
    BuildContext context, 
    PharmacyProfile? pharmacy, 
    ImageProvider? profileImage,
    String badgeLevel,
    int points,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Gradient with curved bottom
        Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryGreen, AppColors.accentBlue],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        // Abstract decorations
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),

        Column(
          children: [
            const SizedBox(height: 70),
            // Avatar with glass effect border
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: profileImage,
                      child: profileImage == null
                          ? const Icon(Icons.local_pharmacy_rounded, size: 40, color: AppColors.primaryGreen)
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: GestureDetector(
                    onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: _isUploadingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              pharmacy?.nomPharmacie ?? 'Ma Pharmacie',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Niveau ${badgeLevel.toUpperCase()}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid(PharmacyStats? stats, int points) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildMiniStatCard('Demandes', '${stats?.totalRequests ?? 0}', Icons.inbox_rounded, AppColors.softGreen),
        _buildMiniStatCard('Acceptées', '${stats?.acceptedRequests ?? 0}', Icons.check_circle_rounded, AppColors.primaryBlue),
        _buildMiniStatCard('Points', '$points', Icons.stars_rounded, Colors.orange),
        _buildMiniStatCard('Revenus', '${stats?.estimatedRevenue.toStringAsFixed(0) ?? 0} TND', Icons.payments_rounded, AppColors.lavender),
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Container(
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
        border: Border.all(color: color.withOpacity(0.05), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label, 
                  style: TextStyle(
                    fontSize: 10, 
                    color: AppColors.textSecondary.withOpacity(0.8), 
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w900, 
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyDetailsCard(PharmacyProfile? pharmacy) {
    if (pharmacy == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.person_rounded, 'Pharmacien', '${pharmacy.nom} ${pharmacy.prenom}'),
          const Divider(height: 24),
          _buildDetailRow(Icons.email_rounded, 'Email', pharmacy.email),
          const Divider(height: 24),
          _buildDetailRow(Icons.phone_rounded, 'Téléphone', pharmacy.displayTelephone),
          const Divider(height: 24),
          _buildDetailRow(Icons.badge_rounded, 'Numéro d\'ordre', pharmacy.numeroOrdre),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.backgroundPrimary, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.primaryGreen),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, PharmacyViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _settingsTile(
            Icons.notifications_active_rounded, 
            'Notifications', 
            AppColors.primaryBlue, 
            () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const NotificationsInboxScreen())
            )
          ),
          _settingsTile(
            Icons.history_rounded, 
            'Historique des demandes', 
            AppColors.softGreen, 
            () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const PharmacyRequestsScreen())
            )
          ),
          _settingsTile(
            Icons.manage_accounts_rounded, 
            'Paramètres du compte', 
            Colors.orange, 
            () {
              // Navigation vers paramètres avancés
            }
          ),
          _settingsTile(
            Icons.security_rounded, 
            'Sécurité & Confidentialité', 
            AppColors.lavender, 
            () {}
          ),
          _settingsTile(
            Icons.help_center_rounded, 
            'Centre d\'aide', 
            Colors.blueGrey, 
            () {}
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, Color iconColor, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final authVm = Provider.of<AuthViewModel>(context, listen: false);
          final pharmacyVm = Provider.of<PharmacyViewModel>(context, listen: false);
          await pharmacyVm.logout(clearAuthData: false);
          await authVm.logout();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        },
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Déconnexion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLocationCard(BuildContext context, PharmacyViewModel viewModel) {
    final profile = viewModel.pharmacyProfile;
    final lat = profile?.location?.latitude;
    final lng = profile?.location?.longitude;
    final hasLocation = lat != null && lng != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Localisation de la pharmacie',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasLocation ? 'Coordonnées configurées' : 'Non configuré',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasLocation ? AppColors.softGreen : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (hasLocation) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    'Lat: ${lat.toStringAsFixed(6)} • Lng: ${lng.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSavingLocation ? null : () => _openLocationOptions(viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSavingLocation
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_location_alt_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Configurer ma localisation',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ],
                    ),
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
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
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
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
                    borderRadius: BorderRadius.circular(AppColors.cardRadius),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
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
