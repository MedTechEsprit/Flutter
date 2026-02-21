import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/data/models/pharmacy_models.dart';
import 'package:diab_care/features/pharmacy/widgets/request_widgets.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';

import 'package:diab_care/features/pharmacy/widgets/gamification_popups.dart';

class PharmacyRequestsScreen extends StatefulWidget {
  const PharmacyRequestsScreen({super.key});

  @override
  State<PharmacyRequestsScreen> createState() => _PharmacyRequestsScreenState();
}

class _PharmacyRequestsScreenState extends State<PharmacyRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<PharmacyViewModel>();
      if (viewModel.requestsState == LoadingState.initial) {
        viewModel.loadAllRequests();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyViewModel>(
      builder: (context, viewModel, child) {
        final requestsByStatus = viewModel.requestsByStatus;

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primaryGreen,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Demandes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 50),
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.mainGradient),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  isScrollable: false,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  tabs: [
                    Tab(text: 'En attente (${requestsByStatus['pending']?.length ?? 0})'),
                    Tab(text: 'Acceptées (${requestsByStatus['accepted']?.length ?? 0})'),
                    Tab(text: 'Refusées (${requestsByStatus['declined']?.length ?? 0})'),
                    Tab(text: 'Expirées (${requestsByStatus['expired']?.length ?? 0})'),
                  ],
                ),
              ),
              // État de chargement
              if (viewModel.requestsState == LoadingState.loading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primaryGreen),
                    ),
                  ),
                )
              // État d'erreur
              else if (viewModel.requestsState == LoadingState.error)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text('Erreur de chargement', style: AppTextStyles.header),
                          const SizedBox(height: 8),
                          Text(
                            viewModel.requestsError ?? 'Une erreur est survenue',
                            style: AppTextStyles.bodySecondary,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => viewModel.loadAllRequests(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              // Contenu des tabs
              else
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestList(requestsByStatus['pending'] ?? [], viewModel),
                      _buildRequestList(requestsByStatus['accepted'] ?? [], viewModel),
                      _buildRequestList(requestsByStatus['declined'] ?? [], viewModel),
                      _buildRequestList(requestsByStatus['expired'] ?? [], viewModel),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestList(List<MedicationRequest> requests, PharmacyViewModel viewModel) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Aucune demande', style: AppTextStyles.subheader),
            const SizedBox(height: 8),
            Text('Les demandes apparaîtront ici', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadAllRequests(),
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RequestCard(
              request: request,
              onAccept: request.status == RequestStatus.pending
                  ? () => _showAcceptDialog(request, viewModel)
                  : null,
              onDecline: request.status == RequestStatus.pending
                  ? () => _showDeclineDialog(request, viewModel)
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _showAcceptDialog(MedicationRequest request, PharmacyViewModel viewModel) {
    final priceController = TextEditingController();
    final messageController = TextEditingController();
    String selectedDelay = '30min';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Accepter la demande', style: AppTextStyles.header),
                const SizedBox(height: 20),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prix indicatif (TND)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDelay,
                  decoration: const InputDecoration(
                    labelText: 'Délai de préparation',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'immediate', child: Text('Immédiat')),
                    DropdownMenuItem(value: '30min', child: Text('30 minutes')),
                    DropdownMenuItem(value: '1h', child: Text('1 heure')),
                    DropdownMenuItem(value: '2h', child: Text('2 heures')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() => selectedDelay = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final price = double.tryParse(priceController.text);
                          if (price == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Prix invalide')),
                            );
                            return;
                          }

                          // Close the form dialog first
                          Navigator.pop(context);

                          try {
                            // 🎮 Call ViewModel to respond to request
                            final result = await viewModel.respondToMedicationRequest(
                              requestId: request.id,
                              status: 'accepted',
                              indicativePrice: price,
                              preparationDelay: selectedDelay,
                              pharmacyMessage: messageController.text,
                            );

                            print('🎮 RESULT: $result');

                            // Show points dialog immediately
                            if (mounted && result['success'] == true) {
                              // SUCCESS - Show points popup like in guide
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // TITRE
                                        const Text(
                                          '🎉 POINTS GAGNÉS! 🎉',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),

                                        const SizedBox(height: 24),

                                        // GROS NOMBRE POINTS
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          child: Text(
                                            '+${result['pointsAwarded'] ?? 0}',
                                            style: TextStyle(
                                              fontSize: 64,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[600],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // BREAKDOWN CARD
                                        if (result['basePoints'] != null) ...[
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Breakdown:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text('• Base Points: +${result['basePoints']}'),
                                                Text('• Bonus: +${result['bonusPoints'] ?? 0}'),
                                                const SizedBox(height: 12),
                                                Divider(color: Colors.grey[400]),
                                                const SizedBox(height: 12),
                                                if (result['reason'] != null)
                                                  Text(
                                                    result['reason'],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontStyle: FontStyle.italic,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 16),

                                        // PROGRESSION
                                        if (result['beforePoints'] != null && result['afterPoints'] != null) ...[
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                Column(
                                                  children: [
                                                    const Text('Avant', style: TextStyle(fontSize: 10)),
                                                    Text(
                                                      '${result['beforePoints']}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Icon(Icons.arrow_forward),
                                                Column(
                                                  children: [
                                                    const Text('Après', style: TextStyle(fontSize: 10)),
                                                    Text(
                                                      '${result['afterPoints']}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 24),

                                        // BOUTON FERMER
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            viewModel.refreshGamificationData();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text(
                                            '✓ FERMER',
                                            style: TextStyle(fontSize: 16, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );

                              // Refresh dashboard after closing
                              if (mounted) {
                                viewModel.loadDashboard();
                              }
                            } else if (mounted) {
                              // ERROR - show error dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Erreur'),
                                    ],
                                  ),
                                  content: Text(result['error'] ?? 'Une erreur est survenue'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            // Show error
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Erreur'),
                                  content: Text('Exception: $e'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accepter'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeclineDialog(MedicationRequest request, PharmacyViewModel viewModel) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du refus:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Raison',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez indiquer une raison')),
                );
                return;
              }

              Navigator.pop(context);

              await viewModel.declineRequest(
                request.id,
                message: reasonController.text,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demande refusée')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }
}

