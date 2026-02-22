// 🎮 Points Reward Popup - Clean, reusable popup for points display
import 'package:flutter/material.dart';

/// Type of reward popup to display
enum RewardPopupType {
  accepted,     // ✓ Médicament disponible - Green
  unavailable,  // ⏸ Non disponible - Orange
  declined,     // ✕ Refusé - Grey (no points)
  rating,       // ⭐ Évaluation reçue - Amber
  penalty,      // ⚠️ Pénalité - Red
}

/// Shows a centered points reward popup
/// Returns when the popup is dismissed
Future<void> showPointsRewardPopup({
  required BuildContext context,
  required RewardPopupType type,
  required int pointsAwarded,
  int? basePoints,
  int? bonusPoints,
  String? reason,
  int? beforePoints,
  int? afterPoints,
  List<String>? breakdown,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) => PointsRewardPopup(
      type: type,
      pointsAwarded: pointsAwarded,
      basePoints: basePoints,
      bonusPoints: bonusPoints,
      reason: reason,
      beforePoints: beforePoints,
      afterPoints: afterPoints,
      breakdown: breakdown,
    ),
  );
}

class PointsRewardPopup extends StatefulWidget {
  final RewardPopupType type;
  final int pointsAwarded;
  final int? basePoints;
  final int? bonusPoints;
  final String? reason;
  final int? beforePoints;
  final int? afterPoints;
  final List<String>? breakdown;

  const PointsRewardPopup({
    super.key,
    required this.type,
    required this.pointsAwarded,
    this.basePoints,
    this.bonusPoints,
    this.reason,
    this.beforePoints,
    this.afterPoints,
    this.breakdown,
  });

  @override
  State<PointsRewardPopup> createState() => _PointsRewardPopupState();
}

class _PointsRewardPopupState extends State<PointsRewardPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig();

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: config.color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: config.color.withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  _buildHeader(config),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Points Display
                        _buildPointsDisplay(config),

                        const SizedBox(height: 16),

                        // Breakdown (if available)
                        if (widget.breakdown != null && widget.breakdown!.isNotEmpty)
                          _buildBreakdown(config),

                        // Progression
                        if (widget.beforePoints != null && widget.afterPoints != null) ...[
                          const SizedBox(height: 16),
                          _buildProgression(config),
                        ],

                        const SizedBox(height: 20),

                        // OK Button
                        _buildOkButton(config),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_TypeConfig config) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 8, 16),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
      ),
      child: Row(
        children: [
          Text(
            config.emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              config.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: config.color,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.grey[600],
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsDisplay(_TypeConfig config) {
    final isNegative = widget.pointsAwarded < 0;
    final displayPoints = widget.pointsAwarded.abs();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            '${isNegative ? '-' : '+'}$displayPoints',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: config.color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'POINTS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: config.color.withOpacity(0.7),
              letterSpacing: 2,
            ),
          ),
          if (widget.reason != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.reason!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdown(_TypeConfig config) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détail:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...widget.breakdown!.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: config.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildProgression(_TypeConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(
                'Avant',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.beforePoints}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_rounded,
            color: config.color,
            size: 24,
          ),
          Column(
            children: [
              Text(
                'Après',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.afterPoints}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: config.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOkButton(_TypeConfig config) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: config.color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'OK',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  _TypeConfig _getTypeConfig() {
    switch (widget.type) {
      case RewardPopupType.accepted:
        return _TypeConfig(
          emoji: '🎉',
          title: 'POINTS GAGNÉS!',
          color: const Color(0xFF4CAF50), // Green
        );
      case RewardPopupType.unavailable:
        return _TypeConfig(
          emoji: '✅',
          title: 'POINTS GAGNÉS',
          color: const Color(0xFFFF9800), // Orange
        );
      case RewardPopupType.declined:
        return _TypeConfig(
          emoji: '✕',
          title: 'DEMANDE REFUSÉE',
          color: const Color(0xFF9E9E9E), // Grey
        );
      case RewardPopupType.rating:
        return _TypeConfig(
          emoji: '⭐',
          title: 'ÉVALUATION REÇUE',
          color: const Color(0xFFFFC107), // Amber
        );
      case RewardPopupType.penalty:
        return _TypeConfig(
          emoji: '⚠️',
          title: 'PÉNALITÉ',
          color: const Color(0xFFF44336), // Red
        );
    }
  }
}

class _TypeConfig {
  final String emoji;
  final String title;
  final Color color;

  _TypeConfig({
    required this.emoji,
    required this.title,
    required this.color,
  });
}

