import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/models/meal_entry_model.dart';
import 'package:diab_care/data/services/ai_food_analyzer_service.dart';

class MealAiDetailScreen extends StatefulWidget {
  final MealEntry meal;

  const MealAiDetailScreen({super.key, required this.meal});

  @override
  State<MealAiDetailScreen> createState() => _MealAiDetailScreenState();
}

class _MealAiDetailScreenState extends State<MealAiDetailScreen> {
  final AiFoodAnalyzerService _service = AiFoodAnalyzerService();
  Future<AiFoodAnalysisDetail?>? _future;

  @override
  void initState() {
    super.initState();
    final mealId = widget.meal.id;
    if (mealId != null && mealId.isNotEmpty) {
      _future = _service.getAnalysisByMeal(mealId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Meal AI Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _future == null
          ? _buildMessage('This meal has no valid ID. Cannot load AI details.')
          : FutureBuilder<AiFoodAnalysisDetail?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  );
                }

                if (snapshot.hasError) {
                  return _buildMessage('Failed to load AI details: ${snapshot.error}');
                }

                final detail = snapshot.data;
                if (detail == null) {
                  return _buildMessage('No AI analysis found for this meal.\nThis is usually a manual meal entry.');
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (detail.imageUrl != null && detail.imageUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            detail.imageUrl!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildImageFallback(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _sectionCard(
                        title: 'Meal Summary',
                        child: Text(
                          detail.summary.isNotEmpty
                              ? detail.summary
                              : 'No summary available.',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Nutrition',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _metricChip('Calories', '${detail.analysisResult['calories'] ?? widget.meal.calories?.round() ?? 0}'),
                            _metricChip('Carbs', '${detail.analysisResult['carbs'] ?? widget.meal.carbs.round()} g'),
                            _metricChip('Protein', '${detail.analysisResult['protein'] ?? widget.meal.protein.round()} g'),
                            _metricChip('Fat', '${detail.analysisResult['fat'] ?? widget.meal.fat.round()} g'),
                            if ((detail.analysisResult['glycemicIndex']?.toString().isNotEmpty ?? false))
                              _metricChip('GI', detail.analysisResult['glycemicIndex'].toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Recommendations',
                        child: detail.recommendations.isEmpty
                            ? const Text('No recommendations available.', style: TextStyle(color: AppColors.textSecondary))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: detail.recommendations
                                    .map((r) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Text('• $r', style: const TextStyle(color: AppColors.textPrimary, height: 1.4)),
                                        ))
                                    .toList(),
                              ),
                      ),
                      if (detail.warnings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _sectionCard(
                          title: 'Warnings',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: detail.warnings
                                .map((w) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text('• $w', style: const TextStyle(color: AppColors.textPrimary, height: 1.4)),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 220,
      width: double.infinity,
      color: AppColors.secondaryBackground,
      alignment: Alignment.center,
      child: const Text('Image unavailable', style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  Widget _buildMessage(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ),
    );
  }
}
