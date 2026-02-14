import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/data/mock/mock_pharmacy_data.dart';
import 'package:diab_care/data/models/pharmacy_models.dart';
import 'package:diab_care/features/pharmacy/widgets/dashboard_widgets.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedPeriod = '7j';

  @override
  Widget build(BuildContext context) {
    final stats = MockPharmacyData.pharmacyStats;
    final badges = MockPharmacyData.badges;
    final performance = MockPharmacyData.performanceMetrics;
    final activity = MockPharmacyData.activityEvents;
    final reviews = MockPharmacyData.reviews;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 8),
              WelcomeBanner(messages: const ['🎉 Bienvenue! Consultez vos stats.', '💰 Nouveau bonus débloqué!', '🏆 Objectif presque atteint!']),
              const SizedBox(height: 20),
              _buildPeriodSelector(),
              const SizedBox(height: 20),
              _buildStatsGrid(stats),
              const SizedBox(height: 28),
              _buildChartsSection(stats),
              const SizedBox(height: 28),
              _buildBadgesSection(badges),
              const SizedBox(height: 28),
              _buildPerformanceSection(performance),
              const SizedBox(height: 28),
              _buildActivitySection(activity),
              const SizedBox(height: 28),
              _buildReviewsSection(reviews),
              const SizedBox(height: 100),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false, pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.mixedGradient),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pharmacie', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                const Text('Tableau de Bord', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['24h', '7j', '30j', '90j'];
    return Row(children: periods.map((p) => Expanded(
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: () => setState(() => _selectedPeriod = p),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: _selectedPeriod == p ? AppColors.mainGradient : null,
              color: _selectedPeriod != p ? AppColors.secondaryBackground : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(p, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _selectedPeriod == p ? Colors.white : AppColors.textSecondary))),
          ),
        ),
      ),
    )).toList());
  }

  Widget _buildStatsGrid(PharmacyStats stats) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.0,
      children: [
        StatCard(icon: '📋', number: '${stats.totalRequests}', label: 'Total Demandes', cardColor: AppColors.mintGreen),
        StatCard(icon: '✅', number: '${stats.acceptedRequests}', label: 'Acceptées', badge: '${stats.acceptanceRate.toStringAsFixed(0)}%', cardColor: AppColors.lightBlue),
        StatCard(icon: '⏳', number: '${stats.pendingRequests}', label: 'En Attente', cardColor: const Color(0xFFFFF9E6)),
        StatCard(icon: '⭐', number: stats.averageRating.toStringAsFixed(1), label: 'Note Moyenne', badge: '${stats.totalReviews} avis', cardColor: const Color(0xFFFFF0E6)),
      ],
    );
  }

  Widget _buildChartsSection(PharmacyStats stats) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('📊 Évolution', style: AppTextStyles.header),
      const SizedBox(height: 14),
      StatCardWithChart(title: 'Demandes traitées', value: '${stats.acceptedRequests}', subtitle: '+12%', chartData: [5, 8, 6, 12, 10, 14, 11], primaryColor: AppColors.primaryGreen, chartColor: Colors.white),
      const SizedBox(height: 12),
      StatCardWithChart(title: 'Temps de réponse', value: '${stats.responseTimeMinutes}min', subtitle: 'Moyen', chartData: [30, 25, 28, 20, 22, 18, 15], primaryColor: AppColors.accentBlue, chartColor: Colors.white),
    ]);
  }

  Widget _buildBadgesSection(List<BadgeLevel> badges) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('🏆 Badges & Niveaux', style: AppTextStyles.header),
      const SizedBox(height: 14),
      ...badges.map((b) => Padding(padding: const EdgeInsets.only(bottom: 14), child: BadgeDisplay(icon: b.icon, name: b.name, currentPoints: b.currentPoints, maxPoints: b.maxPoints))),
    ]);
  }

  Widget _buildPerformanceSection(List<PerformanceMetric> metrics) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('📈 Performance', style: AppTextStyles.header),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.75,
        children: metrics.map((m) => PerformanceCard(label: m.label, value: m.value, stars: m.stars, benchmark: m.benchmark, badge: m.badge)).toList(),
      ),
    ]);
  }

  Widget _buildActivitySection(List<ActivityEvent> events) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('📝 Activité Récente', style: AppTextStyles.header),
      const SizedBox(height: 14),
      ...events.map((e) => ActivityEventCard(icon: e.icon, description: e.description, timestamp: e.timestamp, value: e.value)),
    ]);
  }

  Widget _buildReviewsSection(List<Review> reviews) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('💬 Derniers Avis', style: AppTextStyles.header),
      const SizedBox(height: 14),
      ...reviews.map((r) => ReviewCard(patientName: r.patientName, rating: r.rating, comment: r.comment, timestamp: r.timestamp)),
    ]);
  }
}
