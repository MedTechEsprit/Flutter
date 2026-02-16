import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/data/models/pharmacy_models.dart';
import 'package:diab_care/features/pharmacy/widgets/request_widgets.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';

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

                          Navigator.pop(context);
                          await viewModel.acceptRequest(
                            requestId: request.id,
                            price: price,
                            preparationDelay: selectedDelay,
                            message: messageController.text,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Demande acceptée')),
                            );
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

