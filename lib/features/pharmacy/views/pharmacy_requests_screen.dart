import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/data/models/pharmacy_models.dart';
import 'package:diab_care/features/pharmacy/widgets/request_widgets.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';
import 'package:diab_care/features/pharmacy/widgets/points_reward_popup.dart';

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
              onUnavailable: request.status == RequestStatus.pending
                  ? () => _showUnavailableDialog(request, viewModel)
                  : null,
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ACCEPT DIALOG - Shows form then points popup
  // ─────────────────────────────────────────────────────────────
  void _showAcceptDialog(MedicationRequest request, PharmacyViewModel viewModel) {
    final priceController = TextEditingController();
    final messageController = TextEditingController();
    String selectedDelay = '30min';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Accepter la demande', style: AppTextStyles.header),
                  ],
                ),
                const SizedBox(height: 24),

                // Price field
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Prix indicatif (TND)',
                    hintText: 'Ex: 25.50',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Delay dropdown
                DropdownButtonFormField<String>(
                  value: selectedDelay,
                  decoration: InputDecoration(
                    labelText: 'Délai de préparation',
                    prefixIcon: const Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

                // Message field
                TextField(
                  controller: messageController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Message (optionnel)',
                    hintText: 'Information complémentaire...',
                    prefixIcon: const Icon(Icons.message_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAccept(
                          context,
                          request,
                          viewModel,
                          priceController.text,
                          selectedDelay,
                          messageController.text,
                        ),
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Accepter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAccept(
    BuildContext dialogContext,
    MedicationRequest request,
    PharmacyViewModel viewModel,
    String priceText,
    String delay,
    String message,
  ) async {
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un prix valide'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Close the form
    Navigator.pop(dialogContext);

    // Show loading indicator
    _showLoadingDialog();

    try {
      final result = await viewModel.respondToMedicationRequest(
        requestId: request.id,
        status: 'accepted',
        indicativePrice: price,
        preparationDelay: delay,
        pharmacyMessage: message.isNotEmpty ? message : null,
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      if (mounted && result['success'] == true) {
        // Show points reward popup
        await showPointsRewardPopup(
          context: context,
          type: RewardPopupType.accepted,
          pointsAwarded: result['pointsAwarded'] ?? 0,
          basePoints: result['basePoints'],
          bonusPoints: result['bonusPoints'],
          reason: result['reason'],
          beforePoints: result['beforePoints'],
          afterPoints: result['afterPoints'],
          breakdown: _buildBreakdownList(result),
        );

        // Refresh data
        if (mounted) {
          viewModel.loadDashboard();
          viewModel.refreshGamificationData();
        }
      } else if (mounted) {
        _showErrorDialog(result['error'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) _showErrorDialog('Exception: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UNAVAILABLE DIALOG - Mark as not available (+5 points)
  // ─────────────────────────────────────────────────────────────
  void _showUnavailableDialog(MedicationRequest request, PharmacyViewModel viewModel) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text('Non disponible'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indiquez que ce médicament n\'est pas disponible.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous gagnerez +5 points pour votre réponse honnête!',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Message (optionnel)',
                hintText: 'Ex: Rupture de stock temporaire',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            onPressed: () => _handleUnavailable(ctx, request, viewModel, messageController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUnavailable(
    BuildContext dialogContext,
    MedicationRequest request,
    PharmacyViewModel viewModel,
    String message,
  ) async {
    Navigator.pop(dialogContext);
    _showLoadingDialog();

    try {
      final result = await viewModel.respondToMedicationRequest(
        requestId: request.id,
        status: 'unavailable',
        pharmacyMessage: message.isNotEmpty ? message : null,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (mounted && result['success'] == true) {
        await showPointsRewardPopup(
          context: context,
          type: RewardPopupType.unavailable,
          pointsAwarded: result['pointsAwarded'] ?? 5,
          reason: 'Réponse honnête et rapide',
          beforePoints: result['beforePoints'],
          afterPoints: result['afterPoints'],
          breakdown: ['+5 points (réponse honnête)'],
        );

        if (mounted) {
          viewModel.loadDashboard();
          viewModel.refreshGamificationData();
        }
      } else if (mounted) {
        _showErrorDialog(result['error'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) _showErrorDialog('Exception: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DECLINE DIALOG - Reject request (0 points)
  // ─────────────────────────────────────────────────────────────
  void _showDeclineDialog(MedicationRequest request, PharmacyViewModel viewModel) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel_outlined, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Refuser la demande'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veuillez indiquer la raison du refus:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aucun point pour cette action',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Raison du refus *',
                hintText: 'Ex: Ordonnance invalide, produit contrôlé...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            onPressed: () => _handleDecline(ctx, request, viewModel, reasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDecline(
    BuildContext dialogContext,
    MedicationRequest request,
    PharmacyViewModel viewModel,
    String reason,
  ) async {
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer une raison'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(dialogContext);
    _showLoadingDialog();

    try {
      final result = await viewModel.respondToMedicationRequest(
        requestId: request.id,
        status: 'declined',
        pharmacyMessage: reason,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (mounted && result['success'] == true) {
        await showPointsRewardPopup(
          context: context,
          type: RewardPopupType.declined,
          pointsAwarded: 0,
          reason: 'Aucun point pour les refus',
          beforePoints: result['beforePoints'],
          afterPoints: result['afterPoints'],
          breakdown: ['0 points'],
        );

        if (mounted) {
          viewModel.loadDashboard();
          viewModel.refreshGamificationData();
        }
      } else if (mounted) {
        _showErrorDialog(result['error'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) _showErrorDialog('Exception: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────────
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<String> _buildBreakdownList(Map<String, dynamic> result) {
    final list = <String>[];
    if (result['basePoints'] != null) {
      list.add('Base: +${result['basePoints']} points');
    }
    if (result['bonusPoints'] != null && result['bonusPoints'] > 0) {
      list.add('Bonus rapidité: +${result['bonusPoints']} points');
    }
    return list;
  }
}
