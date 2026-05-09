import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/ai_food_analyzer_service.dart';
import 'package:diab_care/data/services/cloudinary_service.dart';
import 'package:flutter/foundation.dart';

/// AI Food Analyzer — Patient captures a food image, AI analyzes it
class AiFoodAnalyzerScreen extends StatefulWidget {
  const AiFoodAnalyzerScreen({super.key});

  @override
  State<AiFoodAnalyzerScreen> createState() => _AiFoodAnalyzerScreenState();
}

class _AiFoodAnalyzerScreenState extends State<AiFoodAnalyzerScreen> {
  final _service = AiFoodAnalyzerService();
  final _tokenService = TokenService();
  final _picker = ImagePicker();

  XFile? _imageFile;
  bool _isAnalyzing = false;
  AiFoodAnalysisResponse? _result;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      setState(() {
        _imageFile = file;
        _result = null;
        _error = null;
      });

      await _analyzeImage(file);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erreur lors de la capture: $e');
      }
    }
  }

  Future<void> _analyzeImage(XFile file) async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final patientId = await _tokenService.getUserId();
      if (patientId == null) throw Exception('Patient non connecté');

      // Read image bytes from XFile (works on all platforms)
      final imageBytes = await file.readAsBytes();
      final fileName = file.name.isNotEmpty ? file.name : 'photo.jpg';
      debugPrint('📷 [FoodAnalyzer] Image: ${imageBytes.length} bytes, name: $fileName');

      // Upload to Cloudinary
      final imageUrl = await CloudinaryService.uploadImageBytes(
        Uint8List.fromList(imageBytes),
        fileName: fileName,
        folder: 'diabcare/meals',
      );
      debugPrint('✅ [FoodAnalyzer] Cloudinary URL: $imageUrl');

      final result = await _service.analyzeFood(
        imageUrl: imageUrl,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });
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
            Icon(Icons.restaurant_menu_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Analyse Alimentaire IA', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview / capture area
            _buildImageArea(),
            const SizedBox(height: 16),

            // Capture buttons (only if no result yet)
            if (_result == null && !_isAnalyzing) _buildCaptureButtons(),

            // Loading indicator
            if (_isAnalyzing) _buildLoadingCard(),

            // Error message
            if (_error != null) _buildErrorCard(),

            // Results
            if (_result != null) ...[
              _buildNutritionCard(),
              const SizedBox(height: 16),
              if (_result!.detailedAdvice != null && _result!.detailedAdvice!.hasContent) _buildAdviceCard(),
              if (_result!.healthNote != null && _result!.healthNote!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildHealthNoteCard(),
              ],
              const SizedBox(height: 16),
              _buildRetryButton(),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _imageFile != null
            ? Image.file(File(_imageFile!.path), fit: BoxFit.cover, width: double.infinity)
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'Prenez une photo de votre repas',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'L\'IA analysera sa composition nutritionnelle',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCaptureButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_rounded, size: 20),
              label: const Text('Prendre une photo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded, size: 20),
              label: const Text('Galerie'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: AppColors.primaryGreen),
          SizedBox(height: 16),
          Text('Analyse en cours...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Text(
            'L\'IA identifie les aliments et calcule les valeurs nutritionnelles',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
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

  Widget _buildNutritionCard() {
    final r = _result!;
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
              const Icon(Icons.fastfood_rounded, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.mealName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text('IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryGreen)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildNutrientTile('Calories', '${r.calories.round()}', 'kcal', AppColors.softOrange),
              _buildNutrientTile('Glucides', '${r.carbs.round()}', 'g', AppColors.primaryBlue),
              _buildNutrientTile('Protéines', '${r.protein.round()}', 'g', AppColors.primaryGreen),
              _buildNutrientTile('Lipides', '${r.fat.round()}', 'g', AppColors.lavender),
            ],
          ),
          if (r.aiAdvice != null && r.aiAdvice!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AppColors.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(r.aiAdvice!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrientTile(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(unit, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    final advice = _result!.detailedAdvice!;
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
              Icon(Icons.psychology_rounded, color: AppColors.accentBlue),
              SizedBox(width: 8),
              Text('Conseils détaillés', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (advice.glucoseImpact.isNotEmpty) _buildAdviceRow(Icons.show_chart_rounded, 'Impact glycémique', advice.glucoseImpact, AppColors.softOrange),
          if (advice.expectedGlucoseRise.isNotEmpty) _buildAdviceRow(Icons.trending_up_rounded, 'Hausse attendue', advice.expectedGlucoseRise, AppColors.warningOrange),
          if (advice.riskLevel.isNotEmpty) _buildAdviceRow(Icons.shield_rounded, 'Niveau de risque', advice.riskLevel, _riskAdviceColor(advice.riskLevel)),
          if (advice.personalizedRisk.isNotEmpty) _buildAdviceRow(Icons.person_rounded, 'Risque personnalisé', advice.personalizedRisk, AppColors.critical),
          if (advice.portionAdvice.isNotEmpty) _buildAdviceRow(Icons.straighten_rounded, 'Conseil portion', advice.portionAdvice, AppColors.primaryGreen),
          if (advice.timingAdvice.isNotEmpty) _buildAdviceRow(Icons.schedule_rounded, 'Timing', advice.timingAdvice, AppColors.accentBlue),
          if (advice.exerciseRecommendation.isNotEmpty) _buildAdviceRow(Icons.fitness_center_rounded, 'Exercice', advice.exerciseRecommendation, AppColors.primaryGreen),
          if (advice.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Recommandations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            ...advice.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(rec, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3))),
                ],
              ),
            )),
          ],
          if (advice.alternativeSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Alternatives', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            ...advice.alternativeSuggestions.map((alt) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.lavender),
                  const SizedBox(width: 6),
                  Expanded(child: Text(alt, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Color _riskAdviceColor(String risk) {
    final lower = risk.toLowerCase();
    if (lower.contains('high') || lower.contains('élevé')) return AppColors.critical;
    if (lower.contains('moderate') || lower.contains('modéré')) return AppColors.warningOrange;
    return AppColors.statusGood;
  }

  Widget _buildHealthNoteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.health_and_safety_rounded, color: AppColors.primaryGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_result!.healthNote!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceRow(IconData icon, String title, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _imageFile = null;
          _result = null;
          _error = null;
        });
      },
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Analyser un autre repas'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        side: const BorderSide(color: AppColors.primaryGreen),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

}
