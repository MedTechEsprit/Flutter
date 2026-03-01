import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';
import 'package:diab_care/features/patient/views/marketplace_screen.dart';
import 'package:diab_care/features/patient/views/patient_orders_screen.dart';
import 'package:diab_care/features/patient/views/my_doctors_screen.dart';

class FindPharmaciesScreen extends StatefulWidget {
  const FindPharmaciesScreen({super.key});

  @override
  State<FindPharmaciesScreen> createState() => _FindPharmaciesScreenState();
}

class _FindPharmaciesScreenState extends State<FindPharmaciesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PatientViewModel>();
    final pharmacies = vm.pharmacies.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || p.address.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.greenGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pharmacies', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Trouvez une pharmacie près de vous', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            icon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                            hintText: 'Rechercher une pharmacie...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Quick access buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                _QuickBtn(icon: Icons.store, label: 'Marketplace', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()))),
                const SizedBox(width: 10),
                _QuickBtn(icon: Icons.receipt_long, label: 'Mes Commandes', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientOrdersScreen()))),
                const SizedBox(width: 10),
                _QuickBtn(icon: Icons.medical_services, label: 'Mes Médecins', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyDoctorsScreen()))),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: pharmacies.isEmpty
                ? const SliverFillRemaining(child: Center(child: Text('Aucune pharmacie trouvée', style: TextStyle(color: AppColors.textMuted))))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PharmacyCard(pharmacy: pharmacies[index]),
                      ),
                      childCount: pharmacies.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final dynamic pharmacy;

  const _PharmacyCard({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_pharmacy, color: AppColors.softGreen, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pharmacy.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: pharmacy.isOpen ? AppColors.statusGood : AppColors.statusCritical,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(pharmacy.isOpen ? 'Ouverte' : 'Fermée', style: TextStyle(fontSize: 12, color: pharmacy.isOpen ? AppColors.statusGood : AppColors.statusCritical, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${pharmacy.rating}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Address
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(child: Text(pharmacy.address ?? 'Adresse non disponible', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(pharmacy.phone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              Text('${pharmacy.totalReviews} avis', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final chatVm = context.read<ChatViewModel>();
                    final conv = await chatVm.startPharmacistConversation(pharmacy.id);
                    if (conv != null && context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: conv)));
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softGreen,
                    side: const BorderSide(color: AppColors.softGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                  icon: const Icon(Icons.shopping_cart, size: 16),
                  label: const Text('Commander'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppColors.softGreen, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    ));
  }
}
