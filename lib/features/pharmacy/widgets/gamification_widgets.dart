// 🎮 Gamification Widgets - PointsEarnedDialog, BadgeProgressBar, etc.
import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/data/models/gamification_models.dart';

// ─────────────────────────────────────────────────────────────
// 1️⃣ POINTS EARNED DIALOG
// ─────────────────────────────────────────────────────────────
class PointsEarnedDialog extends StatefulWidget {
  final String action;
  final int basePoints;
  final int bonusPoints;
  final int totalPoints;
  final int beforePoints;
  final int afterPoints;
  final List<String> breakdown;
  final String? reason;
  final bool isPenalty;
  final VoidCallback? onClose;

  const PointsEarnedDialog({
    Key? key,
    required this.action,
    required this.basePoints,
    required this.bonusPoints,
    required this.totalPoints,
    required this.beforePoints,
    required this.afterPoints,
    required this.breakdown,
    this.reason,
    this.isPenalty = false,
    this.onClose,
  }) : super(key: key);

  @override
  State<PointsEarnedDialog> createState() => _PointsEarnedDialogState();
}

class _PointsEarnedDialogState extends State<PointsEarnedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Auto-close après 4 secondes
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onClose?.call();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNegative = widget.totalPoints < 0;
    final accentColor = widget.isPenalty ? Colors.red : AppColors.primaryGreen;
    final icon = widget.isPenalty ? '⚠️' : '🎉';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🎉 Header
                Text(
                  icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isPenalty ? '⚠️ PÉNALITÉ APPLIQUÉE' : '🎉 POINTS GAGNÉS! 🎉',
                  style: AppTextStyles.header.copyWith(
                    color: accentColor,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 📝 Action description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Action: ${widget.action}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.reason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Raison: ${widget.reason}',
                          style: AppTextStyles.bodyMuted.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 💎 Points Breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détail des Points:',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.breakdown.asMap().entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.value,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${isNegative ? '-' : '+'}${widget.totalPoints.abs()} points ${isNegative ? '❌' : '✨'}',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 📊 Points Progression
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progression des Points:',
                        style: AppTextStyles.bodyMuted.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Avant: ${widget.beforePoints}',
                              style: AppTextStyles.bodyMuted,
                            ),
                          ),
                          const Text('→'),
                          Expanded(
                            child: Text(
                              'Après: ${widget.afterPoints} ⭐',
                              style: AppTextStyles.bodyMuted.copyWith(
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ✓ Close Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClose?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '✓ FERMER',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2️⃣ BADGE PROGRESS BAR
// ─────────────────────────────────────────────────────────────
class BadgeProgressBar extends StatelessWidget {
  final int currentPoints;
  final BadgeThreshold? currentBadge;
  final BadgeThreshold? nextBadge;
  final int progress; // 0-100
  final int pointsNeeded;

  const BadgeProgressBar({
    Key? key,
    required this.currentPoints,
    required this.currentBadge,
    required this.nextBadge,
    required this.progress,
    required this.pointsNeeded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Badge
          if (currentBadge != null)
            Row(
              children: [
                Text(
                  currentBadge!.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentBadge!.badge.toUpperCase(),
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${currentBadge!.minPoints}-${currentBadge!.maxPoints} points',
                        style: AppTextStyles.bodyMuted.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression',
                    style: AppTextStyles.bodyMuted.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$progress%',
                    style: AppTextStyles.bodyMuted.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 100 ? Colors.orange : AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Next Badge
          if (nextBadge != null && pointsNeeded > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    nextBadge!.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prochain Badge: ${nextBadge!.badge.toUpperCase()}',
                          style: AppTextStyles.bodyMuted.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$pointsNeeded points nécessaires',
                          style: AppTextStyles.bodyMuted.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3️⃣ POINTS AND BADGES SECTION
// ─────────────────────────────────────────────────────────────
class PointsAndBadgesSection extends StatelessWidget {
  final PointsStatsResponse stats;

  const PointsAndBadgesSection({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📊 Header
          Text(
            '📊 POINTS & BADGES',
            style: AppTextStyles.header.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),

          // 💎 Current Points
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen.withOpacity(0.1),
                  AppColors.primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Points Actuels',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.currentPoints}',
                      style: AppTextStyles.header.copyWith(
                        fontSize: 32,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Text(
                  '💎',
                  style: AppTextStyles.header.copyWith(fontSize: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 🏆 Current Badge
          if (stats.badge.name.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    stats.badge.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Badge Actuel',
                          style: AppTextStyles.bodyMuted.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${stats.badge.name.toUpperCase()} - ${stats.badge.description}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // 📈 Today's Earnings
          if (stats.today.pointsEarned > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Points Gagnés Aujourd'hui",
                        style: AppTextStyles.bodyMuted.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '+${stats.today.pointsEarned} pts',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${stats.today.activitiesCount} action${stats.today.activitiesCount > 1 ? 's' : ''}',
                    style: AppTextStyles.bodyMuted.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 4️⃣ UNLOCKED BADGES DISPLAY
// ─────────────────────────────────────────────────────────────
class UnlockedBadgesDisplay extends StatelessWidget {
  final List<BadgeThreshold> allBadges;
  final List<String> unlockedBadges;

  const UnlockedBadgesDisplay({
    Key? key,
    required this.allBadges,
    required this.unlockedBadges,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏅 BADGES DÉBLOQUÉS',
            style: AppTextStyles.header.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final isUnlocked = unlockedBadges.contains(badge.badge);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.amber[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked
                        ? Colors.amber.withOpacity(0.5)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isUnlocked ? badge.emoji : '🔒',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.badge.toUpperCase(),
                      style: AppTextStyles.bodyMuted.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked ? Colors.black87 : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${badge.minPoints}-${badge.maxPoints}',
                      style: AppTextStyles.bodyMuted.copyWith(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isUnlocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 16,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 5️⃣ RANKING CARD
// ─────────────────────────────────────────────────────────────
class RankingCard extends StatelessWidget {
  final RankingResponse ranking;
  final Statistics stats;

  const RankingCard({
    Key? key,
    required this.ranking,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 RANKING & PERFORMANCE',
            style: AppTextStyles.header.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),

          // 🥇 Rank
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[50]!,
                  Colors.blue[100]!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre Classement',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${ranking.rank} / ${ranking.totalPharmacies}',
                      style: AppTextStyles.header.copyWith(
                        fontSize: 24,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Percentile',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Top ${ranking.percentile}%',
                      style: AppTextStyles.header.copyWith(
                        fontSize: 20,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 📊 Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                'Taux d\'Acceptation',
                '${stats.acceptanceRate}%',
                Colors.green,
              ),
              _buildStatCard(
                'Temps Moyen',
                '${stats.averageResponseTime} min',
                Colors.blue,
              ),
              _buildStatCard(
                'Note Moyenne',
                '⭐ ${stats.averageRating}',
                Colors.orange,
              ),
              _buildStatCard(
                'Total Clients',
                '${stats.totalClients}',
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMuted.copyWith(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

