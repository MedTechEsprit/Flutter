import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/services/ai_pattern_service.dart';

/// AI Pattern screen — 30-day glucose pattern analysis
class AiPatternScreen extends StatefulWidget {
  const AiPatternScreen({super.key});

  @override
  State<AiPatternScreen> createState() => _AiPatternScreenState();
}

class _AiPatternScreenState extends State<AiPatternScreen> {
  final _service = AiPatternService();
  AiPatternAnalysis? _analysis;
  List<AiPatternAnalysis> _history = [];
  bool _isAnalyzing = false;
  bool _isLoadingHistory = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLatest();
    _loadHistory();
  }

  Future<void> _loadLatest() async {
    try {
      final latest = await _service.getLatest();
      if (mounted && latest != null) {
        setState(() => _analysis = latest);
      }
    } catch (_) {}
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final result = await _service.analyzePatterns();
      if (mounted) {
        setState(() {
          _analysis = result;
          _isAnalyzing = false;
        });
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _service.getHistory(limit: 10);
      if (mounted) setState(() { _history = history; _isLoadingHistory = false; });
    } catch (_) {
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
            Icon(Icons.pattern_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Analyse de Patterns', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action card
            _buildAnalyzeCard(),
            const SizedBox(height: 16),

            if (_error != null) _buildErrorCard(),

            // Results
            if (_analysis != null) ...[
              _buildOverallAssessment(),
              const SizedBox(height: 16),
              _buildPatternCards(),
              const SizedBox(height: 16),
            ],

            _buildHistorySection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentBlue, AppColors.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Détection de Patterns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              if (_analysis != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_analysis!.detectedCount}/4',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Analyse vos 30 derniers jours pour détecter les patterns dangereux : hypoglycémies nocturnes, pics post-repas, fenêtres à risque et dégradation du contrôle.',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isAnalyzing ? null : _runAnalysis,
              icon: _isAnalyzing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.primaryBlue, strokeWidth: 2))
                  : const Icon(Icons.search_rounded),
              label: Text(_isAnalyzing ? 'Analyse en cours...' : 'Lancer l\'analyse'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accentBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallAssessment() {
    final assessment = _analysis!.overallAssessment;
    if (assessment == null) return const SizedBox.shrink();

    final urgencyColor = _urgencyColor(assessment.urgencyLevel);

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
            children: [
              const Icon(Icons.assessment_rounded, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Évaluation globale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  assessment.urgencyLevel.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: urgencyColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Control level
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: urgencyColor),
                const SizedBox(width: 8),
                Text('Niveau de contrôle: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(assessment.controlLevel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: urgencyColor)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Summary
          if (assessment.summary.isNotEmpty)
            Text(assessment.summary, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),

          // Doctor consultation needed
          if (assessment.doctorConsultationNeeded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusErrorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.medical_services_rounded, color: AppColors.critical, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consultation médicale recommandée',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.critical),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Top priorities
          if (assessment.topPriorities.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Priorités:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            ...assessment.topPriorities.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(p, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                    ],
                  ),
                )),
          ],

          if (_analysis!.isFallback) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('⚠️ Estimation locale (IA indisponible)', style: TextStyle(fontSize: 11, color: AppColors.warningOrange)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatternCards() {
    return Column(
      children: [
        if (_analysis!.nocturnalHypoglycemia != null)
          _buildPatternCard(
            'Hypoglycémies Nocturnes',
            Icons.nightlight_round,
            _analysis!.nocturnalHypoglycemia!,
            AppColors.lavender,
          ),
        if (_analysis!.postMealSpikes != null)
          _buildPatternCard(
            'Pics Post-Repas',
            Icons.restaurant_rounded,
            _analysis!.postMealSpikes!,
            AppColors.softOrange,
          ),
        if (_analysis!.riskTimeWindows != null)
          _buildPatternCard(
            'Fenêtres à Risque',
            Icons.schedule_rounded,
            _analysis!.riskTimeWindows!,
            AppColors.primaryBlue,
          ),
        if (_analysis!.glycemicControlDegradation != null)
          _buildPatternCard(
            'Dégradation du Contrôle',
            Icons.trending_down_rounded,
            _analysis!.glycemicControlDegradation!,
            AppColors.critical,
          ),
      ],
    );
  }

  Widget _buildPatternCard(String title, IconData icon, PatternDetection pattern, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pattern.detected ? color.withOpacity(0.3) : AppColors.border,
          width: pattern.detected ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pattern.detected
                      ? _riskLevelColor(pattern.riskLevel).withOpacity(0.12)
                      : AppColors.statusSuccessBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pattern.detected ? (pattern.riskLevel ?? 'Détecté').toUpperCase() : 'OK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: pattern.detected ? _riskLevelColor(pattern.riskLevel) : AppColors.statusGood,
                  ),
                ),
              ),
            ],
          ),
          if (pattern.detected && pattern.recommendation != null) ...[
            const SizedBox(height: 10),
            Text(pattern.recommendation!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historique', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (_isLoadingHistory)
          const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
        else if (_history.isEmpty)
          const Center(child: Text('Aucune analyse effectuée', style: TextStyle(color: AppColors.textMuted)))
        else
          ..._history.map((a) => _buildHistoryTile(a)),
      ],
    );
  }

  Widget _buildHistoryTile(AiPatternAnalysis a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('${a.detectedCount}/4', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.overallAssessment?.controlLevel ?? 'Analyse',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  a.createdAt != null ? _formatDate(a.createdAt!) : '',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (a.triggerType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: a.triggerType == 'cron' ? AppColors.lightBlue : AppColors.mintGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                a.triggerType == 'cron' ? 'Auto' : 'Manuel',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: a.triggerType == 'cron' ? AppColors.accentBlue : AppColors.primaryGreen,
                ),
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

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'critical': return const Color(0xFFE53E3E);
      case 'high': return AppColors.critical;
      case 'moderate': return AppColors.warningOrange;
      default: return AppColors.statusGood;
    }
  }

  Color _riskLevelColor(String? risk) {
    switch (risk) {
      case 'critical': return const Color(0xFFE53E3E);
      case 'high': return AppColors.critical;
      case 'moderate': return AppColors.warningOrange;
      default: return AppColors.statusGood;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
