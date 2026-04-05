import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';
import 'package:diab_care/features/pharmacy/widgets/boost_management_widget.dart';
import 'package:diab_care/features/pharmacy/views/pharmacy_points_screen.dart';
import 'package:diab_care/core/widgets/animations.dart';
import 'package:diab_care/features/pharmacy/models/pharmacy_api_models.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() =>
      _PharmacyDashboardScreenState();
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

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
  }

  void _loadDataIfNeeded(PharmacyViewModel viewModel) {
    if (!_hasLoadedData && viewModel.isLoggedIn) {
      _hasLoadedData = true;
      viewModel.loadDashboard();
      viewModel.loadAllRequests();
      viewModel.loadActiveBoosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyViewModel>(
      builder: (context, viewModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadDataIfNeeded(viewModel);
        });

        // État de chargement initial
        if (viewModel.dashboardState == LoadingState.loading &&
            viewModel.dashboardData == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundPrimary,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 16),
                  Text('Chargement du dashboard...', style: AppTextStyles.body),
                ],
              ),
            ),
          );
        }

        // Récupérer les données
        final dashboardData = viewModel.dashboardData;
        final profile = viewModel.pharmacyProfile;
        final stats = dashboardData?.stats;

        // Calculer les stats depuis le dashboard (orders)
        final pendingCount = dashboardData?.pendingRequestsCount ?? 0;
        final acceptedCount = stats?.totalRequestsAccepted ?? 0;
        final declinedCount = stats?.totalRequestsDeclined ?? 0;
        final totalRequests =
            stats?.totalRequestsReceived ??
            (pendingCount + acceptedCount + declinedCount);

        // Points et autres infos
        final points = dashboardData?.pharmacy.points ?? profile?.points ?? 0;
        final badgeLevel =
            dashboardData?.pharmacy.badgeLevel ??
            profile?.badgeLevel ??
            'bronze';
        final revenue =
            dashboardData?.stats.totalRevenue ?? profile?.totalRevenue ?? 0.0;
        final pharmacyName =
            dashboardData?.pharmacy.nomPharmacie ??
            profile?.nomPharmacie ??
            'Ma Pharmacie';

        // Statut en ligne/hors ligne
        final isOnline =
            dashboardData?.pharmacy.isOnDuty ?? profile?.isOnDuty ?? true;

        // Calcul du taux d'acceptation
        final totalResponded = acceptedCount + declinedCount;
        final acceptanceRate = totalResponded > 0
            ? (acceptedCount / totalResponded * 100).toInt()
            : 0;

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: RefreshIndicator(
            onRefresh: () async {
              await viewModel.loadDashboard();
              await viewModel.loadAllRequests();
              await viewModel.loadActiveBoosts();
            },
            color: AppColors.primaryGreen,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // App Bar Moderne
                _buildModernAppBar(pharmacyName, points, badgeLevel, isOnline),

                // Contenu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // 🚀 SECTION BOOST
                        FadeInSlide(
                          index: 0,
                          child: const BoostManagementWidget(),
                        ),
                        const SizedBox(height: 20),

                        // STATISTIQUES PRINCIPALES
                        FadeInSlide(
                          index: 1,
                          child: _buildSectionTitle(
                            Icons.bar_chart_rounded,
                            'Vue d\'ensemble',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInSlide(
                          index: 1,
                          child: _buildMainStatsGrid(
                            totalRequests,
                            pendingCount,
                            acceptedCount,
                            declinedCount,
                            points,
                            revenue,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // GRAPHIQUE DE PERFORMANCE
                        FadeInSlide(
                          index: 2,
                          child: _buildSectionTitle(
                            Icons.insights_rounded,
                            'Performance',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInSlide(
                          index: 2,
                          child: _buildPerformanceChart(
                            acceptedCount,
                            declinedCount,
                            pendingCount,
                            acceptanceRate,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // BADGE ET PROGRESSION
                        FadeInSlide(
                          index: 3,
                          child: _buildSectionTitle(
                            Icons.workspace_premium_rounded,
                            'Votre Niveau',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInSlide(
                          index: 3,
                          child: _buildBadgeSection(
                            badgeLevel,
                            points,
                            dashboardData?.badgeProgression,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ANALYSE ACTIVITE
                        FadeInSlide(
                          index: 4,
                          child: _buildSectionTitle(
                            Icons.track_changes_rounded,
                            'Analyse d\'activité',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInSlide(
                          index: 4,
                          child: _buildActivityAnalysis(
                            viewModel,
                            pendingCount,
                            acceptedCount,
                            declinedCount,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // AVIS CLIENTS
                        FadeInSlide(
                          index: 5,
                          child: _buildSectionTitle(
                            Icons.star_rounded,
                            'Avis Clients',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInSlide(
                          index: 5,
                          child: _buildReviewsSection(stats),
                        ),
                        const SizedBox(height: 20),

                        // CONSEILS
                        FadeInSlide(
                          index: 6,
                          child: _buildSectionTitle(
                            Icons.lightbulb_outline_rounded,
                            'Conseils',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInSlide(
                          index: 6,
                          child: _buildTipsSection(
                            acceptanceRate,
                            pendingCount,
                          ),
                        ),

                        const SizedBox(height: 100),
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

  // App Bar Moderne avec gradient (EXACT COMME PATIENT!)
  Widget _buildModernAppBar(
    String pharmacyName,
    int points,
    String badgeLevel,
    bool isOnline,
  ) {
    final badgeText = badgeLevel.isEmpty
        ? 'Bronze'
        : '${badgeLevel[0].toUpperCase()}${badgeLevel.substring(1)}';

    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.local_pharmacy_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour 👋',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pharmacyName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: isOnline
                                    ? AppColors.softGreen
                                    : Colors.white70,
                                size: 8,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? 'En ligne' : 'Hors ligne',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Niveau $badgeText',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '$points',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.softGreen.withOpacity(
                                      0.85,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Points cumulés',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PharmacyPointsScreen(),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
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
          Positioned(
            top: -20,
            right: -30,
            child: _DecorativeCircle(size: 100, opacity: 0.06),
          ),
          Positioned(
            top: 60,
            right: 40,
            child: _DecorativeCircle(size: 50, opacity: 0.04),
          ),
          Positioned(
            bottom: 40,
            left: -20,
            child: _DecorativeCircle(size: 70, opacity: 0.05),
          ),
        ],
      ),
    );
  }

  // Titre de section
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.accentBlue),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Grille de statistiques principales (style patient - couleurs pastels douces)
  Widget _buildMainStatsGrid(
    int total,
    int pending,
    int accepted,
    int declined,
    int points,
    double revenue,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                Icons.inventory_2_rounded,
                '$total',
                'Total',
                AppColors.accentBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                Icons.hourglass_top_rounded,
                '$pending',
                'En attente',
                AppColors.softOrange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                Icons.check_circle_rounded,
                '$accepted',
                'Acceptées',
                AppColors.stable,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                Icons.cancel_rounded,
                '$declined',
                'Refusées',
                AppColors.warmPeach,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PharmacyPointsScreen(),
                  ),
                ),
                child: _buildStatCard(
                  Icons.track_changes_rounded,
                  '$points',
                  'Points',
                  AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                Icons.payments_rounded,
                '${revenue.toStringAsFixed(0)}',
                'TND',
                AppColors.lavender,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Carte de statistique (STYLE PATIENT - blanc avec ombre douce)
  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Graphique de performance
  Widget _buildPerformanceChart(
    int accepted,
    int declined,
    int pending,
    int acceptanceRate,
  ) {
    final total = accepted + declined + pending;
    final acceptedPercent = total > 0 ? accepted / total : 0.0;
    final declinedPercent = total > 0 ? declined / total : 0.0;
    final pendingPercent = total > 0 ? pending / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Barres de progression
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBar(
                      'Acceptées',
                      acceptedPercent,
                      Colors.green,
                      accepted,
                    ),
                    const SizedBox(height: 12),
                    _buildProgressBar(
                      'Refusées',
                      declinedPercent,
                      Colors.red,
                      declined,
                    ),
                    const SizedBox(height: 12),
                    _buildProgressBar(
                      'En attente',
                      pendingPercent,
                      Colors.orange,
                      pending,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Cercle de taux d'acceptation
              Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: acceptanceRate / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            acceptanceRate >= 70
                                ? AppColors.stable
                                : acceptanceRate >= 50
                                ? AppColors.attention
                                : AppColors.warmPeach,
                          ),
                        ),
                        Center(
                          child: Text(
                            '$acceptanceRate%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Taux\nd\'acceptation',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    double percent,
    Color color,
    int count,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // Section Badge
  Widget _buildBadgeSection(
    String badgeLevel,
    int points,
    dynamic badgeProgression,
  ) {
    final badgeInfo = _getBadgeFullInfo(badgeLevel);
    final nextLevelPoints = badgeProgression?.pointsToNextLevel ?? 50;
    final currentPoints = badgeProgression?.currentPoints ?? points;
    final totalForNext = currentPoints + nextLevelPoints;
    final progress = totalForNext > 0 ? currentPoints / totalForNext : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeInfo['color'] as Color,
            (badgeInfo['color'] as Color).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: (badgeInfo['color'] as Color).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                badgeInfo['icon'] as IconData,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badgeInfo['name'] as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$currentPoints points accumulés',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Niv. ${badgeInfo['level']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de progression
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prochain niveau',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$currentPoints / $totalForNext pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Plus que $nextLevelPoints points avant le prochain niveau.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Analyse d'activité intelligente
  Widget _buildActivityAnalysis(
    PharmacyViewModel viewModel,
    int pending,
    int accepted,
    int declined,
  ) {
    final activities = <Map<String, dynamic>>[];

    // Générer des messages d'analyse
    if (accepted > 0) {
      activities.add({
        'icon': Icons.check_circle_rounded,
        'color': AppColors.stable,
        'title': 'Demandes acceptées',
        'message':
            'Vous avez accepté $accepted demande${accepted > 1 ? 's' : ''} de médicaments',
        'detail': '+${accepted * 10} points gagnés',
      });
    }

    if (declined > 0) {
      activities.add({
        'icon': Icons.cancel_rounded,
        'color': AppColors.warmPeach,
        'title': 'Demandes refusées',
        'message':
            'Vous avez refusé $declined demande${declined > 1 ? 's' : ''}',
        'detail': 'Raison: Non disponible en stock',
      });
    }

    if (pending > 0) {
      activities.add({
        'icon': Icons.hourglass_top_rounded,
        'color': AppColors.softOrange,
        'title': 'Demandes en attente',
        'message':
            '$pending demande${pending > 1 ? 's' : ''} attendent votre réponse',
        'detail': 'Répondez vite pour gagner des points!',
      });
    }

    if (activities.isEmpty) {
      activities.add({
        'icon': Icons.inbox_outlined,
        'color': AppColors.textSecondary,
        'title': 'Aucune activité',
        'message': 'Vous n\'avez pas encore d\'activité',
        'detail': 'Les demandes des patients apparaîtront ici',
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          final isLast = index == activities.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (activity['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        size: 20,
                        color: activity['color'] as Color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: activity['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity['message'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['detail'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Section Avis Clients
  Widget _buildReviewsSection(DashboardStats? stats) {
    final averageRating = stats?.averageRating ?? 0;
    final totalReviews = stats?.totalReviews ?? 0;
    final satisfaction = averageRating > 0
        ? ((averageRating / 5) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 32,
                  color: AppColors.accentGold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avis Clients',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        totalReviews == 0
                            ? 'Aucun avis pour le moment'
                            : '$totalReviews avis recu(s)',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildReviewPlaceholder(
                Icons.star_rate_rounded,
                averageRating.toStringAsFixed(1),
                'Note moyenne',
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _buildReviewPlaceholder(
                Icons.reviews_rounded,
                '$totalReviews',
                'Avis recus',
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _buildReviewPlaceholder(
                Icons.thumb_up_rounded,
                '$satisfaction%',
                'Satisfaction',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les evaluations patients mettent a jour vos statistiques automatiquement.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPlaceholder(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // Section Conseils
  Widget _buildTipsSection(int acceptanceRate, int pending) {
    final tips = <Map<String, dynamic>>[];

    if (pending > 0) {
      tips.add({
        'icon': Icons.bolt_rounded,
        'color': AppColors.softOrange,
        'tip':
            'Répondez aux $pending demande${pending > 1 ? 's' : ''} en attente pour augmenter votre score!',
      });
    }

    if (acceptanceRate < 50) {
      tips.add({
        'icon': Icons.trending_up_rounded,
        'color': AppColors.accentBlue,
        'tip':
            'Votre taux d\'acceptation est de $acceptanceRate%. Essayez d\'accepter plus de demandes!',
      });
    } else if (acceptanceRate >= 80) {
      tips.add({
        'icon': Icons.auto_awesome_rounded,
        'color': AppColors.stable,
        'tip':
            'Excellent! Votre taux d\'acceptation de $acceptanceRate% est remarquable!',
      });
    }

    tips.add({
      'icon': Icons.flash_on_rounded,
      'color': AppColors.lavender,
      'tip':
          'Activez un boost pour apparaître en priorité dans les recherches!',
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blueGradient.colors[1],
            AppColors.greenGradient.colors[1],
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: Column(
        children: tips.map((tip) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  tip['icon'] as IconData,
                  size: 20,
                  color: tip['color'] as Color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip['tip'] as String,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helpers
  // ignore: unused_element
  String _getBadgeEmoji(String badgeLevel) {
    switch (badgeLevel.toLowerCase()) {
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      case 'platinum':
        return '💎';
      case 'diamond':
        return '👑';
      default:
        return '🥉';
    }
  }

  Map<String, dynamic> _getBadgeFullInfo(String badgeLevel) {
    switch (badgeLevel.toLowerCase()) {
      case 'silver':
        return {
          'icon': Icons.workspace_premium_rounded,
          'name': 'Partenaire Silver',
          'color': AppColors.textSecondary,
          'level': 2,
        };
      case 'gold':
        return {
          'icon': Icons.emoji_events_rounded,
          'name': 'Partenaire Gold',
          'color': AppColors.accentGold,
          'level': 3,
        };
      case 'platinum':
        return {
          'icon': Icons.diamond_rounded,
          'name': 'Partenaire Platinum',
          'color': AppColors.primaryBlue,
          'level': 4,
        };
      case 'diamond':
        return {
          'icon': Icons.military_tech_rounded,
          'name': 'Partenaire Diamond',
          'color': AppColors.lavender,
          'level': 5,
        };
      default:
        return {
          'icon': Icons.workspace_premium_rounded,
          'name': 'Partenaire Bronze',
          'color': AppColors.softOrange,
          'level': 1,
        };
    }
  }
}
