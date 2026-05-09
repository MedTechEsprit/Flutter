import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/services/ai_prediction_service.dart';

/// AI Prediction screen — Patient views glucose trend predictions (2-4h)
class AiPredictionScreen extends StatefulWidget {
  const AiPredictionScreen({super.key});

  @override
  State<AiPredictionScreen> createState() => _AiPredictionScreenState();
}

class _AiPredictionScreenState extends State<AiPredictionScreen> {
  final _service = AiPredictionService();
  AiPrediction? _prediction;
  List<AiPrediction> _history = [];
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _requestPrediction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prediction = await _service.predict();
      if (mounted) {
        setState(() {
          _prediction = prediction;
          _isLoading = false;
        });
        _loadHistory(); // refresh history
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _service.getHistory(limit: 10);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
          // Set latest prediction if we don't have one yet
          if (_prediction == null && history.isNotEmpty) {
            _prediction = history.first;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.trending_up_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Prédiction Glycémique', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prediction action card
            _buildPredictCard(),
            const SizedBox(height: 16),

            // Error
            if (_error != null) _buildErrorCard(),

            // Current prediction result
            if (_prediction != null) ...[
              _buildPredictionResult(),
              const SizedBox(height: 16),
              if (_prediction!.recommendations.isNotEmpty) _buildRecommendations(),
              const SizedBox(height: 16),
            ],

            // History
            _buildHistorySection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Prédiction IA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Prédisez votre glycémie pour les 2-4 prochaines heures basé sur vos données récentes.',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _requestPrediction,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_isLoading ? 'Analyse en cours...' : 'Lancer la prédiction'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionResult() {
    final p = _prediction!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Résultat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              if (p.isFallback)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Estimation locale', style: TextStyle(fontSize: 10, color: AppColors.warningOrange, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Main prediction value
          Center(
            child: Column(
              children: [
                Text(
                  '${p.predictedValue.round()}',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: _riskColor(p.riskLevel),
                  ),
                ),
                const Text('mg/dL', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('estimation dans 2h', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (p.estimatedValue4h != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '→ ${p.estimatedValue4h!.round()} mg/dL dans 4h',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _buildStatChip(Icons.trending_up_rounded, p.trendLabel, _trendColor(p.trend)),
              const SizedBox(width: 8),
              _buildStatChip(Icons.shield_rounded, p.riskLevelLabel, _riskColor(p.riskLevel)),
              const SizedBox(width: 8),
              _buildStatChip(Icons.speed_rounded, '${p.confidence}%', AppColors.accentBlue),
            ],
          ),
          const SizedBox(height: 16),

          // Summary
          if (p.summary.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(p.summary, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
            ),

          // Explanation
          if (p.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.explanation, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4))),
                ],
              ),
            ),
          ],

          // Alerts
          if (p.alerts.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...p.alerts.map((alert) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statusErrorBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.critical),
                  const SizedBox(width: 8),
                  Expanded(child: Text(alert, style: const TextStyle(fontSize: 12, color: AppColors.critical, fontWeight: FontWeight.w500))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates_rounded, color: AppColors.accentGold),
              SizedBox(width: 8),
              Text('Recommandations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ..._prediction!.recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•', style: TextStyle(fontSize: 16, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rec, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historique des prédictions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (_isLoadingHistory)
          const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
        else if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('Aucune prédiction encore', style: TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          ..._history.map((p) => _buildHistoryTile(p)),
      ],
    );
  }

  Widget _buildHistoryTile(AiPrediction p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _riskColor(p.riskLevel).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${p.predictedValue.round()}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _riskColor(p.riskLevel)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.trendLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(
                  p.createdAt != null ? _formatDate(p.createdAt!) : '',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _riskColor(p.riskLevel).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              p.riskLevelLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _riskColor(p.riskLevel)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusErrorBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.critical, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'critical':
        return const Color(0xFFE53E3E);
      case 'high':
        return AppColors.critical;
      case 'moderate':
        return AppColors.warningOrange;
      default:
        return AppColors.statusGood;
    }
  }

  Color _trendColor(String trend) {
    switch (trend) {
      case 'increase':
      case 'worsening':
      case 'rising':
        return AppColors.softOrange;
      case 'decrease':
      case 'improving':
      case 'falling':
        return AppColors.primaryBlue;
      default:
        return AppColors.statusGood;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
