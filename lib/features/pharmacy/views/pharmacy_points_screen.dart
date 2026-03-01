import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';

class PharmacyPointsScreen extends StatefulWidget {
  const PharmacyPointsScreen({super.key});
  @override
  State<PharmacyPointsScreen> createState() => _PharmacyPointsScreenState();
}

class _PharmacyPointsScreenState extends State<PharmacyPointsScreen> {
  final _tokenService = TokenService();
  bool _loading = true;
  int _points = 0;
  String _badge = 'bronze';
  Map<String, dynamic> _config = {};
  Map<String, dynamic> _stats = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pharmId = _tokenService.userId ?? await _tokenService.getUserId();
    final token = await AuthService().getToken();
    final headers = {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
    final base = '${AuthService.baseUrl}/api';

    try {
      // Load points config, stats, and pharmacist info in parallel
      final results = await Future.wait([
        http.get(Uri.parse('$base/orders/points/config'), headers: headers),
        http.get(Uri.parse('$base/orders/pharmacist/$pharmId/stats'), headers: headers),
        http.get(Uri.parse('$base/pharmaciens/$pharmId'), headers: headers),
      ]);

      if (results[0].statusCode == 200) _config = jsonDecode(results[0].body);
      if (results[1].statusCode == 200) _stats = jsonDecode(results[1].body);
      if (results[2].statusCode == 200) {
        final data = jsonDecode(results[2].body);
        _points = (data['points'] as num?)?.toInt() ?? 0;
        _badge = data['badgeLevel'] ?? 'bronze';
      }
    } catch (e) { debugPrint('❌ Points: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pointsRules = (_config['POINTS'] as Map?)?.cast<String, dynamic>() ?? {};
    final badgeThresholds = (_config['BADGE_THRESHOLDS'] as Map?)?.cast<String, dynamic>() ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Mes Points', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.softGreen))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Points header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.softGreen, Color(0xFF1B8A6B)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.softGreen.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Column(children: [
                      Icon(_badgeIcon(_badge), size: 48, color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(height: 8),
                      Text('$_points', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text('points', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('Badge ${_badge.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Stats
                  Row(children: [
                    _statCard('Commandes', '${_stats['totalOrders'] ?? 0}', Icons.receipt_long),
                    const SizedBox(width: 12),
                    _statCard('Terminées', '${_stats['completedOrders'] ?? 0}', Icons.check_circle),
                    const SizedBox(width: 12),
                    _statCard('Revenus', '${((_stats['totalRevenue'] as num?)?.toInt() ?? 0)} DA', Icons.attach_money),
                  ]),
                  const SizedBox(height: 24),

                  // Badge progression
                  const Text('Progression des Badges', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...['bronze', 'silver', 'gold', 'platinum', 'diamond'].map((b) {
                    final threshold = (badgeThresholds[b] as num?)?.toInt() ?? 0;
                    final isCurrent = b == _badge;
                    final isUnlocked = _points >= threshold;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.softGreen.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrent ? Border.all(color: AppColors.softGreen, width: 2) : null,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
                      ),
                      child: Row(children: [
                        Icon(_badgeIcon(b), size: 28, color: isUnlocked ? _badgeColor(b) : Colors.grey.shade300),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(b[0].toUpperCase() + b.substring(1), style: TextStyle(fontWeight: FontWeight.w600, color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted)),
                          Text('$threshold points requis', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ])),
                        if (isUnlocked)
                          const Icon(Icons.check_circle, color: AppColors.softGreen, size: 22)
                        else
                          Text('${threshold - _points}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      ]),
                    );
                  }),
                  const SizedBox(height: 24),

                  // How to earn points
                  const Text('Comment gagner des points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _pointRule('Confirmer une commande', pointsRules['ORDER_CONFIRMED'] ?? 10, Icons.check),
                  _pointRule('Commande prête', pointsRules['ORDER_READY'] ?? 5, Icons.inventory),
                  _pointRule('Commande récupérée', pointsRules['ORDER_PICKED_UP'] ?? 15, Icons.shopping_bag),
                  _pointRule('Par article vendu', pointsRules['PER_ITEM_SOLD'] ?? 5, Icons.medication),
                  _pointRule('Confirmation rapide (<5min)', pointsRules['FAST_CONFIRM_BONUS'] ?? 3, Icons.flash_on),
                  _pointRule('Première commande du jour', pointsRules['FIRST_ORDER_OF_DAY'] ?? 5, Icons.wb_sunny),
                  _pointRule('Milestone 10 commandes', pointsRules['MILESTONE_10_ORDERS'] ?? 50, Icons.emoji_events),
                  _pointRule('Milestone 50 commandes', pointsRules['MILESTONE_50_ORDERS'] ?? 150, Icons.emoji_events),
                  _pointRule('Milestone 100 commandes', pointsRules['MILESTONE_100_ORDERS'] ?? 300, Icons.emoji_events),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(children: [
        Icon(icon, color: AppColors.softGreen, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ]),
    ));
  }

  Widget _pointRule(String label, dynamic pts, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, color: AppColors.softGreen, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text('+$pts', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ]),
    );
  }

  IconData _badgeIcon(String badge) => switch(badge) {
    'bronze' => Icons.shield_outlined,
    'silver' => Icons.shield,
    'gold' => Icons.workspace_premium,
    'platinum' => Icons.diamond_outlined,
    'diamond' => Icons.diamond,
    _ => Icons.shield_outlined,
  };

  Color _badgeColor(String badge) => switch(badge) {
    'bronze' => const Color(0xFFCD7F32),
    'silver' => const Color(0xFFC0C0C0),
    'gold' => const Color(0xFFFFD700),
    'platinum' => const Color(0xFFE5E4E2),
    'diamond' => const Color(0xFFB9F2FF),
    _ => Colors.grey,
  };
}
