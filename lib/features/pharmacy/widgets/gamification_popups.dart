// 🎮 Gamification Pop-ups - 5 Variantes (Accepted, Unavailable, Declined, Rating, Penalty)
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────
// POP-UP PARENT
// ─────────────────────────────────────────────────────────────
enum GamificationPopupType {
  accepted,       // ✓ Médicament disponible
  unavailable,    // ⏸ Non disponible
  declined,       // ✕ Demande refusée
  rating,         // ⭐ Évaluation reçue
  penalty,        // ⚠️ Pénalité
}

class GamificationPopup extends StatefulWidget {
  final GamificationPopupType type;
  final int points;
  final List<String> breakdown;
  final String? description;
  final String? reason;
  final int? beforePoints;
  final int? afterPoints;
  final VoidCallback? onClose;

  const GamificationPopup({
    Key? key,
    required this.type,
    required this.points,
    required this.breakdown,
    this.description,
    this.reason,
    this.beforePoints,
    this.afterPoints,
    this.onClose,
  }) : super(key: key);

  @override
  State<GamificationPopup> createState() => _GamificationPopupState();

  // Factory constructors for each variant
  factory GamificationPopup.accepted({
    required int basePoints,
    required int bonusPoints,
    required String responseTime,
    required int beforePoints,
    required int afterPoints,
    required List<String> breakdown,
    VoidCallback? onClose,
  }) {
    return GamificationPopup(
      type: GamificationPopupType.accepted,
      points: basePoints + bonusPoints,
      breakdown: breakdown,
      description: 'Médicament Disponible',
      reason: 'Réponse rapide: $responseTime',
      beforePoints: beforePoints,
      afterPoints: afterPoints,
      onClose: onClose,
    );
  }

  factory GamificationPopup.unavailable({
    required int points,
    required int beforePoints,
    required int afterPoints,
    VoidCallback? onClose,
  }) {
    return GamificationPopup(
      type: GamificationPopupType.unavailable,
      points: points,
      breakdown: ['+$points (Réponse honnête et rapide)'],
      description: 'Non Disponible',
      beforePoints: beforePoints,
      afterPoints: afterPoints,
      onClose: onClose,
    );
  }

  factory GamificationPopup.declined({
    required int beforePoints,
    required int afterPoints,
    VoidCallback? onClose,
  }) {
    return GamificationPopup(
      type: GamificationPopupType.declined,
      points: 0,
      breakdown: ['Aucun point pour cette action'],
      description: 'Demande Refusée',
      beforePoints: beforePoints,
      afterPoints: afterPoints,
      onClose: onClose,
    );
  }

  factory GamificationPopup.rating({
    required int stars,
    required int points,
    required int beforePoints,
    required int afterPoints,
    VoidCallback? onClose,
  }) {
    final starDisplay = '⭐' * stars;
    return GamificationPopup(
      type: GamificationPopupType.rating,
      points: points,
      breakdown: ['$starDisplay: +$points points'],
      description: 'Évaluation Reçue',
      reason: '$stars ${stars == 1 ? 'étoile' : 'étoiles'}',
      beforePoints: beforePoints,
      afterPoints: afterPoints,
      onClose: onClose,
    );
  }

  factory GamificationPopup.penalty({
    required int penalty,
    required String reason,
    required int beforePoints,
    required int afterPoints,
    VoidCallback? onClose,
  }) {
    return GamificationPopup(
      type: GamificationPopupType.penalty,
      points: -penalty,
      breakdown: ['-$penalty (Pénalité)'],
      description: 'Pénalité Appliquée',
      reason: reason,
      beforePoints: beforePoints,
      afterPoints: afterPoints,
      onClose: onClose,
    );
  }
}

class _GamificationPopupState extends State<GamificationPopup>
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

    // Auto-close after 4 seconds
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return switch (widget.type) {
      GamificationPopupType.accepted => _buildAcceptedVariant(),
      GamificationPopupType.unavailable => _buildUnavailableVariant(),
      GamificationPopupType.declined => _buildDeclinedVariant(),
      GamificationPopupType.rating => _buildRatingVariant(),
      GamificationPopupType.penalty => _buildPenaltyVariant(),
    };
  }

  // ─────────────────────────────────────────────────────────────
  // VARIANTE 1️⃣: ACCEPTED (Médicament Disponible)
  // ─────────────────────────────────────────────────────────────
  Widget _buildAcceptedVariant() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            '🎉',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'POINTS GAGNÉS! 🎉',
            style: AppTextStyles.header.copyWith(
              color: Colors.green,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Action info
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
                  '✓ ${widget.description}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.reason!,
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Points breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Détail des Points:',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.breakdown.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $item',
                    style: AppTextStyles.body.copyWith(fontSize: 14),
                  ),
                )),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '+${widget.points} points ✨',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Points progression
          if (widget.beforePoints != null && widget.afterPoints != null)
            _buildProgressionDisplay(Colors.green),

          const SizedBox(height: 24),

          // Close button
          _buildCloseButton(Colors.green),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // VARIANTE 2️⃣: UNAVAILABLE (Non Disponible)
  // ─────────────────────────────────────────────────────────────
  Widget _buildUnavailableVariant() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✅',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'POINTS GAGNÉS ✅',
            style: AppTextStyles.header.copyWith(
              color: Colors.orange[700],
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '⏸ ${widget.description}\nRéponse honnête et rapide',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Points Gagnés',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '+${widget.points} pts',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (widget.beforePoints != null && widget.afterPoints != null)
            _buildProgressionDisplay(Colors.orange),

          const SizedBox(height: 24),
          _buildCloseButton(Colors.orange),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // VARIANTE 3️⃣: DECLINED (Demande Refusée)
  // ─────────────────────────────────────────────────────────────
  Widget _buildDeclinedVariant() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✕',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'DEMANDE REFUSÉE',
            style: AppTextStyles.header.copyWith(
              color: Colors.grey[700],
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Aucun point pour cette action',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          if (widget.beforePoints != null && widget.afterPoints != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Avant: ${widget.beforePoints}',
                    style: AppTextStyles.bodyMuted,
                  ),
                  const Text('→'),
                  Text(
                    'Après: ${widget.afterPoints}',
                    style: AppTextStyles.bodyMuted.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          _buildCloseButton(Colors.grey),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // VARIANTE 4️⃣: RATING (Évaluation Reçue)
  // ─────────────────────────────────────────────────────────────
  Widget _buildRatingVariant() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '⭐',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'ÉVALUATION REÇUE',
            style: AppTextStyles.header.copyWith(
              color: Colors.amber[700],
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.reason ?? 'Merci pour votre service!',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bonus Points',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '+${widget.points} pts 💎',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (widget.beforePoints != null && widget.afterPoints != null)
            _buildProgressionDisplay(Colors.amber),

          const SizedBox(height: 24),
          _buildCloseButton(Colors.amber),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // VARIANTE 5️⃣: PENALTY (Pénalité)
  // ─────────────────────────────────────────────────────────────
  Widget _buildPenaltyVariant() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '⚠️',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            '⚠️ PÉNALITÉ APPLIQUÉE',
            style: AppTextStyles.header.copyWith(
              color: Colors.red,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Raison:',
                  style: AppTextStyles.bodyMuted.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.reason ?? 'Comportement non conforme',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Points Perdus',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '-${widget.points.abs()} pts ❌',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (widget.beforePoints != null && widget.afterPoints != null)
            _buildProgressionDisplay(Colors.red),

          const SizedBox(height: 24),
          _buildCloseButton(Colors.red),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _buildProgressionDisplay(Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Avant: ${widget.beforePoints}',
            style: AppTextStyles.bodyMuted,
          ),
          const Icon(Icons.arrow_forward_ios, size: 12),
          Text(
            'Après: ${widget.afterPoints}',
            style: AppTextStyles.bodyMuted.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(Color color) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
        widget.onClose?.call();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
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
    );
  }
}

