import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/patient/viewmodels/meal_viewmodel.dart';
import 'package:diab_care/data/services/ai_food_analyzer_service.dart';
import 'package:diab_care/data/services/cloudinary_service.dart';

/// AI meal capture: camera/gallery → real AI analysis via backend → show editable results → Confirm & Save.
class AIMealCaptureScreen extends StatefulWidget {
  const AIMealCaptureScreen({super.key});

  @override
  State<AIMealCaptureScreen> createState() => _AIMealCaptureScreenState();
}

class _AIMealCaptureScreenState extends State<AIMealCaptureScreen> {
  bool _captured = false;
  bool _analyzing = false;
  final ImagePicker _picker = ImagePicker();
  final AiFoodAnalyzerService _aiService = AiFoodAnalyzerService();
  final TokenService _tokenService = TokenService();

  // Editable AI results
  final _carbsController = TextEditingController(text: '0');
  final _proteinController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  final _caloriesController = TextEditingController(text: '0');

  /// AI confidence 0–100.
  int _confidence = 0;
  String _mealName = '';
  String? _aiAdvice;
  String? _error;

  @override
  void dispose() {
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      setState(() {
        _analyzing = true;
        _captured = true;
        _error = null;
      });

      // Try real AI analysis
      try {
        final patientId = await _tokenService.getUserId();
        if (patientId == null) throw Exception('Patient non connecté');

        // Read image bytes from XFile (works reliably on all platforms)
        final imageBytes = await file.readAsBytes();
        final fileName = file.name.isNotEmpty ? file.name : 'photo.jpg';
        debugPrint(
          '📷 [MealCapture] Image: ${imageBytes.length} bytes, name: $fileName',
        );

        // Upload to Cloudinary
        final imageUrl = await CloudinaryService.uploadImageBytes(
          Uint8List.fromList(imageBytes),
          fileName: fileName,
          folder: 'diabcare/meals',
        );
        debugPrint('✅ [MealCapture] Cloudinary URL: $imageUrl');

        final result = await _aiService.analyzeFood(imageUrl: imageUrl);

        if (!mounted) return;
        setState(() {
          _analyzing = false;
          _mealName = result.mealName;
          _carbsController.text = '${result.carbs.round()}';
          _proteinController.text = '${result.protein.round()}';
          _fatController.text = '${result.fat.round()}';
          _caloriesController.text = '${result.calories.round()}';
          _confidence = result.confidence > 0 ? result.confidence : 80;
          _aiAdvice = result.aiAdvice;
        });
      } catch (e) {
        // Fallback to mock if backend fails
        if (!mounted) return;
        setState(() {
          _error = 'IA indisponible, valeurs estimées. ($e)';
          _analyzing = false;
          _mealName = 'Repas détecté';
          _carbsController.text = '42';
          _proteinController.text = '18';
          _fatController.text = '12';
          _caloriesController.text = '285';
          _confidence = 50;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de capture: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        setState(() => _analyzing = false);
      }
    }
  }

  void _onCapture() {
    _pickImage(ImageSource.camera);
  }

  void _onUpload() {
    _pickImage(ImageSource.gallery);
  }

  void _confirmAndSave() {
    final carbs = double.tryParse(_carbsController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());
    final calories = double.tryParse(_caloriesController.text.trim());
    if (carbs == null ||
        protein == null ||
        fat == null ||
        carbs < 0 ||
        protein < 0 ||
        fat < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid Carbs, Protein, and Fat'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final vm = context.read<MealViewModel>();
    final entry = vm.createEntry(
      mealType: 'Lunch',
      carbs: carbs,
      protein: protein,
      fat: fat,
      calories: calories,
      time: DateTime.now(),
    );
    vm.addMeal(entry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Meal saved'),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  Color _confidenceColor() {
    if (_confidence >= 70) return AppColors.statusGood;
    if (_confidence >= 40) return AppColors.warningOrange;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintGreen,
      appBar: AppBar(
        title: const Text('AI Meal Capture'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Camera preview placeholder
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _analyzing
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: AppColors.primaryGreen,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Analyse IA en cours...',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Icon(
                              _captured
                                  ? Icons.done_all_rounded
                                  : Icons.camera_alt_rounded,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                          ),
                  ),
                  if (!_captured && !_analyzing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _onCapture,
                            icon: const Icon(Icons.camera_rounded),
                            label: const Text('Capture'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _onUpload,
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text('Upload'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryGreen,
                              side: BorderSide(color: AppColors.primaryGreen),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_captured && !_analyzing) ...[
                    const SizedBox(height: 24),
                    // Meal name (if AI detected)
                    if (_mealName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.fastfood_rounded,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _mealName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Error message
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.warningOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.warningOrange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Confidence
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _confidenceColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_rounded,
                            color: _confidenceColor(),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'AI confidence: $_confidence%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _confidenceColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Edit values if needed, then save.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EditableRow(
                      label: 'Carbs (g)',
                      controller: _carbsController,
                    ),
                    _EditableRow(
                      label: 'Protein (g)',
                      controller: _proteinController,
                    ),
                    _EditableRow(label: 'Fat (g)', controller: _fatController),
                    _EditableRow(
                      label: 'Calories (kcal)',
                      controller: _caloriesController,
                    ),
                    // AI advice
                    if (_aiAdvice != null && _aiAdvice!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.mintGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_rounded,
                              color: AppColors.primaryGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _aiAdvice!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _confirmAndSave,
                        icon: const Icon(Icons.check_rounded, size: 22),
                        label: const Text(
                          'Confirm & Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _EditableRow({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
