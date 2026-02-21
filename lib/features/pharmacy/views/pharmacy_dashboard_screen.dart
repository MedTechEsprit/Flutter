import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';
import 'package:diab_care/features/pharmacy/widgets/boost_management_widget.dart';
import 'package:diab_care/data/models/pharmacy_models.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
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
        if (viewModel.dashboardState == LoadingState.loading && viewModel.dashboardData == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundPrimary,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryGreen),
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
        final requestsByStatus = viewModel.requestsByStatus;

        // Calculer les stats depuis les vraies données
        final pendingCount = requestsByStatus['pending']?.length ?? 0;
        final acceptedCount = requestsByStatus['accepted']?.length ?? 0;
        final declinedCount = requestsByStatus['declined']?.length ?? 0;
        final totalRequests = pendingCount + acceptedCount + declinedCount;

        // Points et autres infos
        final points = dashboardData?.pharmacy.points ?? profile?.points ?? 0;
        final badgeLevel = dashboardData?.pharmacy.badgeLevel ?? profile?.badgeLevel ?? 'bronze';
        final revenue = dashboardData?.stats.totalRevenue ?? profile?.totalRevenue ?? 0.0;
        final pharmacyName = dashboardData?.pharmacy.nomPharmacie ?? profile?.nomPharmacie ?? 'Ma Pharmacie';

        // Statut en ligne/hors ligne
        final isOnline = dashboardData?.pharmacy.isOnDuty ?? profile?.isOnDuty ?? true;

        // Calcul du taux d'acceptation
        final totalResponded = acceptedCount + declinedCount;
        final acceptanceRate = totalResponded > 0 ? (acceptedCount / totalResponded * 100).toInt() : 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: RefreshIndicator(
            onRefresh: () async {
              await viewModel.loadDashboard();
              await viewModel.loadAllRequests();
              await viewModel.loadActiveBoosts();
            },
            color: AppColors.primaryGreen,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                        const BoostManagementWidget(),
                        const SizedBox(height: 20),

                        // 📊 STATISTIQUES PRINCIPALES
                        _buildSectionTitle('📊', 'Vue d\'ensemble'),
                        const SizedBox(height: 12),
                        _buildMainStatsGrid(totalRequests, pendingCount, acceptedCount, declinedCount, points, revenue),
                        const SizedBox(height: 20),

                        // 📈 GRAPHIQUE DE PERFORMANCE
                        _buildSectionTitle('📈', 'Performance'),
                        const SizedBox(height: 12),
                        _buildPerformanceChart(acceptedCount, declinedCount, pendingCount, acceptanceRate),
                        const SizedBox(height: 20),

                        // 🏆 BADGE ET PROGRESSION
                        _buildSectionTitle('🏆', 'Votre Niveau'),
                        const SizedBox(height: 12),
                        _buildBadgeSection(badgeLevel, points, dashboardData?.badgeProgression),
                        const SizedBox(height: 20),

                        // 🎯 ANALYSE ACTIVITÉ
                        _buildSectionTitle('🎯', 'Analyse d\'activité'),
                        const SizedBox(height: 12),
                        _buildActivityAnalysis(viewModel, pendingCount, acceptedCount, declinedCount),
                        const SizedBox(height: 20),

                        // ⭐ AVIS CLIENTS
                        _buildSectionTitle('⭐', 'Avis Clients'),
                        const SizedBox(height: 12),
                        _buildReviewsSection(),
                        const SizedBox(height: 20),

                        // 💡 CONSEILS
                        _buildSectionTitle('💡', 'Conseils'),
                        const SizedBox(height: 12),
                        _buildTipsSection(acceptanceRate, pendingCount),

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
  Widget _buildModernAppBar(String pharmacyName, int points, String badgeLevel, bool isOnline) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF7DDAB9),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour,',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pharmacyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.white : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: isOnline ? Colors.green : Colors.grey,
                              size: 8,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnline ? 'En ligne' : 'Hors ligne',
                              style: TextStyle(
                                color: isOnline ? Colors.green.shade700 : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Titre de section
  Widget _buildSectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  // Grille de statistiques principales (style patient - couleurs pastels douces)
  Widget _buildMainStatsGrid(int total, int pending, int accepted, int declined, int points, double revenue) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('📥', '$total', 'Total', const Color(0xFFE0F7FA), const Color(0xFF00ACC1))),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('⏳', '$pending', 'En attente', const Color(0xFFFFF9E6), const Color(0xFFFFA726))),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('✅', '$accepted', 'Acceptées', const Color(0xFFE8F5E9), const Color(0xFF66BB6A))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard('❌', '$declined', 'Refusées', const Color(0xFFFFEBEE), const Color(0xFFEF5350))),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('🎯', '$points', 'Points', const Color(0xFFE1F5FE), const Color(0xFF29B6F6))),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('💰', '${revenue.toStringAsFixed(0)}', 'TND', const Color(0xFFF3E5F5), const Color(0xFFAB47BC))),
          ],
        ),
      ],
    );
  }

  // Carte de statistique (STYLE PATIENT - blanc avec ombre douce)
  Widget _buildStatCard(String emoji, String value, String label, Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: accentColor,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Graphique de performance
  Widget _buildPerformanceChart(int accepted, int declined, int pending, int acceptanceRate) {
    final total = accepted + declined + pending;
    final acceptedPercent = total > 0 ? accepted / total : 0.0;
    final declinedPercent = total > 0 ? declined / total : 0.0;
    final pendingPercent = total > 0 ? pending / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    _buildProgressBar('Acceptées', acceptedPercent, Colors.green, accepted),
                    const SizedBox(height: 12),
                    _buildProgressBar('Refusées', declinedPercent, Colors.red, declined),
                    const SizedBox(height: 12),
                    _buildProgressBar('En attente', pendingPercent, Colors.orange, pending),
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
                            acceptanceRate >= 70 ? Colors.green :
                            acceptanceRate >= 50 ? Colors.orange : Colors.red,
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

  Widget _buildProgressBar(String label, double percent, Color color, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
  Widget _buildBadgeSection(String badgeLevel, int points, dynamic badgeProgression) {
    final badgeInfo = _getBadgeFullInfo(badgeLevel);
    final nextLevelPoints = badgeProgression?.pointsToNextLevel ?? 50;
    final currentPoints = badgeProgression?.currentPoints ?? points;
    final totalForNext = currentPoints + nextLevelPoints;
    final progress = totalForNext > 0 ? currentPoints / totalForNext : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeInfo['color'] as Color, (badgeInfo['color'] as Color).withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
              Text(badgeInfo['emoji'] as String, style: const TextStyle(fontSize: 50)),
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
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Niv. ${badgeInfo['level']}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                  ),
                  Text(
                    '$currentPoints / $totalForNext pts',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                'Plus que $nextLevelPoints points! 🚀',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Analyse d'activité intelligente
  Widget _buildActivityAnalysis(PharmacyViewModel viewModel, int pending, int accepted, int declined) {
    final activities = <Map<String, dynamic>>[];

    // Générer des messages d'analyse
    if (accepted > 0) {
      activities.add({
        'icon': '✅',
        'color': Colors.green,
        'title': 'Demandes acceptées',
        'message': 'Vous avez accepté $accepted demande${accepted > 1 ? 's' : ''} de médicaments',
        'detail': '+${accepted * 10} points gagnés',
      });
    }

    if (declined > 0) {
      activities.add({
        'icon': '❌',
        'color': Colors.red,
        'title': 'Demandes refusées',
        'message': 'Vous avez refusé $declined demande${declined > 1 ? 's' : ''}',
        'detail': 'Raison: Non disponible en stock',
      });
    }

    if (pending > 0) {
      activities.add({
        'icon': '⏳',
        'color': Colors.orange,
        'title': 'Demandes en attente',
        'message': '$pending demande${pending > 1 ? 's' : ''} attendent votre réponse',
        'detail': 'Répondez vite pour gagner des points!',
      });
    }

    if (activities.isEmpty) {
      activities.add({
        'icon': '📭',
        'color': Colors.grey,
        'title': 'Aucune activité',
        'message': 'Vous n\'avez pas encore d\'activité',
        'detail': 'Les demandes des patients apparaîtront ici',
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                      child: Text(activity['icon'] as String, style: const TextStyle(fontSize: 20)),
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
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['detail'] as String,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
  Widget _buildReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                const Text('⭐', style: TextStyle(fontSize: 32)),
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
                        'Cette fonctionnalité arrive bientôt!',
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
              _buildReviewPlaceholder('⭐⭐⭐⭐⭐', '5.0', 'Note moyenne'),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _buildReviewPlaceholder('💬', '0', 'Avis reçus'),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _buildReviewPlaceholder('👍', '0%', 'Satisfaction'),
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
                    'Les patients pourront bientôt évaluer votre service après chaque retrait',
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

  Widget _buildReviewPlaceholder(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
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
        'icon': '⚡',
        'color': Colors.orange,
        'tip': 'Répondez aux $pending demande${pending > 1 ? 's' : ''} en attente pour augmenter votre score!',
      });
    }

    if (acceptanceRate < 50) {
      tips.add({
        'icon': '📈',
        'color': Colors.blue,
        'tip': 'Votre taux d\'acceptation est de $acceptanceRate%. Essayez d\'accepter plus de demandes!',
      });
    } else if (acceptanceRate >= 80) {
      tips.add({
        'icon': '🌟',
        'color': Colors.green,
        'tip': 'Excellent! Votre taux d\'acceptation de $acceptanceRate% est remarquable!',
      });
    }

    tips.add({
      'icon': '💎',
      'color': Colors.purple,
      'tip': 'Activez un boost pour apparaître en priorité dans les recherches!',
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: tips.map((tip) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(tip['icon'] as String, style: const TextStyle(fontSize: 20)),
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
  String _getBadgeEmoji(String badgeLevel) {
    switch (badgeLevel.toLowerCase()) {
      case 'silver': return '🥈';
      case 'gold': return '🥇';
      case 'platinum': return '💎';
      case 'diamond': return '👑';
      default: return '🥉';
    }
  }

  Map<String, dynamic> _getBadgeFullInfo(String badgeLevel) {
    switch (badgeLevel.toLowerCase()) {
      case 'silver':
        return {'emoji': '🥈', 'name': 'Partenaire Silver', 'color': Colors.blueGrey, 'level': 2};
      case 'gold':
        return {'emoji': '🥇', 'name': 'Partenaire Gold', 'color': Colors.amber.shade700, 'level': 3};
      case 'platinum':
        return {'emoji': '💎', 'name': 'Partenaire Platinum', 'color': Colors.indigo, 'level': 4};
      case 'diamond':
        return {'emoji': '👑', 'name': 'Partenaire Diamond', 'color': Colors.purple, 'level': 5};
      default:
        return {'emoji': '🥉', 'name': 'Partenaire Bronze', 'color': const Color(0xFFCD7F32), 'level': 1};
    }
  }
}

