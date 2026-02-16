import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<PharmacyViewModel>();
      if (viewModel.dashboardData == null && viewModel.dashboardState != LoadingState.loading) {
        viewModel.loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyViewModel>(
      builder: (context, viewModel, child) {
        final pharmacy = viewModel.pharmacyProfile;
        final stats = viewModel.pharmacyStats;

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: CustomScrollView(
            slivers: [
              // App bar avec gradient
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.warmPeach,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.mainGradient),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.local_pharmacy_rounded, size: 48, color: AppColors.primaryGreen),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Nom
                          Text(
                            pharmacy?.nomPharmacie ?? 'Pharmacie',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          // Email
                          Text(
                            pharmacy?.email ?? '',
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Contenu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Stats rapides
                      if (stats != null) _buildQuickStats(stats),
                      const SizedBox(height: 24),
                      // Informations
                      _buildInfoSection(pharmacy),
                      const SizedBox(height: 24),
                      // Paramètres
                      _buildSettingsSection(context),
                      const SizedBox(height: 24),
                      // Déconnexion
                      _buildLogoutButton(context),
                      const SizedBox(height: 40),
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

  Widget _buildQuickStats(dynamic stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statistiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Demandes', '${stats.totalRequests}', Icons.inbox),
                _buildStatItem('Acceptées', '${stats.acceptedRequests}', Icons.check_circle),
                _buildStatItem('Clients', '${stats.newClients}', Icons.people),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInfoSection(dynamic pharmacy) {
    if (pharmacy == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucune information disponible'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Nom', '${pharmacy.nom} ${pharmacy.prenom}'),
            _buildInfoRow(Icons.email, 'Email', pharmacy.email),
            _buildInfoRow(Icons.phone, 'Téléphone', pharmacy.telephonePharmacie ?? 'N/A'),
            _buildInfoRow(Icons.location_on, 'Adresse', pharmacy.adressePharmacie ?? 'N/A'),
            _buildInfoRow(Icons.badge, 'Numéro d\'ordre', pharmacy.numeroOrdre ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Consumer<PharmacyViewModel>(
      builder: (context, viewModel, child) {
        final isOnline = viewModel.pharmacyProfile?.isOnDuty ?? true;

        return Card(
          child: Column(
            children: [
              // Mode Activité (En ligne / Hors ligne)
              ListTile(
                leading: Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline ? Colors.green : Colors.grey,
                ),
                title: const Text('Mode Activité'),
                subtitle: Text(
                  isOnline ? 'Vous êtes en ligne' : 'Vous êtes hors ligne',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
                trailing: Switch(
                  value: isOnline,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (value) async {
                    // Afficher un dialog de confirmation
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              value ? Icons.power_settings_new : Icons.power_off,
                              color: value ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(value ? 'Passer en ligne' : 'Passer hors ligne'),
                          ],
                        ),
                        content: Text(
                          value
                              ? 'En passant en ligne, vous recevrez des demandes de médicaments des patients à proximité.'
                              : 'En passant hors ligne, vous ne recevrez plus de nouvelles demandes jusqu\'à ce que vous vous reconnectiez.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: value ? AppColors.primaryGreen : Colors.grey,
                            ),
                            child: Text(value ? 'Passer en ligne' : 'Passer hors ligne'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      // Mettre à jour le statut
                      await viewModel.updateOnlineStatus(value);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? '✅ Vous êtes maintenant en ligne'
                                  : '🔴 Vous êtes maintenant hors ligne',
                            ),
                            backgroundColor: value ? Colors.green : Colors.grey,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications, color: AppColors.primaryGreen),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings, color: AppColors.primaryGreen),
                title: const Text('Paramètres'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help, color: AppColors.primaryGreen),
                title: const Text('Aide'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final authVm = Provider.of<AuthViewModel>(context, listen: false);
          final pharmacyVm = Provider.of<PharmacyViewModel>(context, listen: false);
          await pharmacyVm.logout();
          authVm.logout();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Déconnexion'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

