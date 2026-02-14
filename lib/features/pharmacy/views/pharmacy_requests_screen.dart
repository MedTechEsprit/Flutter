import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/data/mock/mock_pharmacy_data.dart';
import 'package:diab_care/data/models/pharmacy_models.dart';
import 'package:diab_care/features/pharmacy/widgets/request_widgets.dart';

class PharmacyRequestsScreen extends StatefulWidget {
  const PharmacyRequestsScreen({super.key});

  @override
  State<PharmacyRequestsScreen> createState() => _PharmacyRequestsScreenState();
}

class _PharmacyRequestsScreenState extends State<PharmacyRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<MedicationRequest>> _requestsByStatus = MockPharmacyData.requestsByStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180, floating: true, pinned: true, snap: true,
            backgroundColor: Colors.transparent, elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.mixedGradient),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Demandes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Gérez les demandes de médicaments', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                  const SizedBox(height: 16),
                  _buildSummaryRow(),
                ]),
              ),
            ),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(50), child: Container(
              color: AppColors.background,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryGreen,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primaryGreen,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'En attente (${_requestsByStatus['pending']?.length ?? 0})'),
                  Tab(text: 'Acceptées (${_requestsByStatus['accepted']?.length ?? 0})'),
                  Tab(text: 'Refusées (${_requestsByStatus['declined']?.length ?? 0})'),
                  Tab(text: 'Expirées (${_requestsByStatus['expired']?.length ?? 0})'),
                ],
              ),
            )),
          ),
        ],
        body: TabBarView(controller: _tabController, children: [
          _buildRequestList(_requestsByStatus['pending'] ?? []),
          _buildRequestList(_requestsByStatus['accepted'] ?? []),
          _buildRequestList(_requestsByStatus['declined'] ?? []),
          _buildRequestList(_requestsByStatus['expired'] ?? []),
        ]),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final pending = _requestsByStatus['pending']?.length ?? 0;
    final urgent = _requestsByStatus['pending']?.where((r) => r.isUrgent).length ?? 0;
    return Row(children: [
      _summaryChip('⏳', '$pending en attente', Colors.white.withOpacity(0.25)),
      const SizedBox(width: 8),
      if (urgent > 0) _summaryChip('⚡', '$urgent urgentes', Colors.red.withOpacity(0.3)),
    ]);
  }

  Widget _summaryChip(String icon, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(icon, style: const TextStyle(fontSize: 14)), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))]),
    );
  }

  Widget _buildRequestList(List<MedicationRequest> requests) {
    if (requests.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: AppColors.greenGradient, shape: BoxShape.circle), child: const Icon(Icons.inbox_rounded, size: 48, color: AppColors.darkGreen)),
        const SizedBox(height: 16),
        Text('Aucune demande', style: AppTextStyles.subheader),
        const SizedBox(height: 8),
        Text('Les demandes apparaîtront ici', style: AppTextStyles.bodySecondary),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return RequestCard(
          request: req,
          onAccept: req.status == RequestStatus.pending ? () => _showAcceptDialog(req) : null,
          onDecline: req.status == RequestStatus.pending ? () => _showDeclineDialog(req) : null,
          onIgnore: req.status == RequestStatus.pending ? () {} : null,
        );
      },
    );
  }

  void _showAcceptDialog(MedicationRequest request) {
    final priceController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Accepter la demande', style: AppTextStyles.header),
          const SizedBox(height: 8),
          Text(request.medicationName, style: AppTextStyles.subheader.copyWith(color: AppColors.primaryGreen)),
          const SizedBox(height: 20),
          TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Prix (TND)', prefixIcon: const Icon(Icons.payments_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: AppColors.secondaryBackground)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Demande acceptée!'), backgroundColor: AppColors.primaryGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Confirmer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
        ]),
      ),
    );
  }

  void _showDeclineDialog(MedicationRequest request) {
    final reasons = ['Rupture de stock', 'Ordonnance requise', 'Hors catalogue', 'Autre'];
    String? selectedReason;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Refuser la demande', style: AppTextStyles.header),
          const SizedBox(height: 16),
          ...reasons.map((r) => GestureDetector(
            onTap: () => setModalState(() => selectedReason = r),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: selectedReason == r ? AppColors.mintGreen : AppColors.secondaryBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: selectedReason == r ? AppColors.primaryGreen : AppColors.border)),
              child: Text(r, style: TextStyle(fontWeight: selectedReason == r ? FontWeight.w600 : FontWeight.w400, color: AppColors.textPrimary)),
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: selectedReason != null ? () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Demande refusée'), backgroundColor: AppColors.textSecondary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); } : null, style: ElevatedButton.styleFrom(backgroundColor: AppColors.textSecondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Confirmer le refus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
        ]),
      )),
    );
  }
}
