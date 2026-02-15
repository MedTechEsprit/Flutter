import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/models/meal_entry_model.dart';
import 'package:diab_care/features/patient/viewmodels/meal_viewmodel.dart';

/// AI meal capture: camera placeholder, capture → show editable AI predictions + confidence, Confirm & Save.
class AIMealCaptureScreen extends StatefulWidget {
  const AIMealCaptureScreen({super.key});

  @override
  State<AIMealCaptureScreen> createState() => _AIMealCaptureScreenState();
}

class _AIMealCaptureScreenState extends State<AIMealCaptureScreen> {
  bool _captured = false;
  bool _simulating = false;

  // Editable AI results (mock)
  final _carbsController = TextEditingController(text: '0');
  final _proteinController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  final _caloriesController = TextEditingController(text: '0');

  /// Mock confidence 0–100.
  int _confidence = 87;

  @override
  void dispose() {
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _onCapture() {
    setState(() => _simulating = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _simulating = false;
        _captured = true;
        _carbsController.text = '42';
        _proteinController.text = '18';
        _fatController.text = '12';
        _caloriesController.text = '285';
        _confidence = 87;
      });
    });
  }

  void _confirmAndSave() {
    final carbs = double.tryParse(_carbsController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());
    final calories = double.tryParse(_caloriesController.text.trim());
    if (carbs == null || protein == null || fat == null || carbs < 0 || protein < 0 || fat < 0) {
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
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('AI Meal Capture'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
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
                    child: _simulating
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppColors.primaryGreen),
                                SizedBox(height: 12),
                                Text('Analyzing...', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : Center(
                            child: Icon(
                              _captured ? Icons.done_all_rounded : Icons.camera_alt_rounded,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                          ),
                  ),
                  if (!_captured && !_simulating) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: FilledButton.icon(
                        onPressed: _onCapture,
                        icon: const Icon(Icons.camera_rounded),
                        label: const Text('Capture'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                  if (_captured) ...[
                    const SizedBox(height: 24),
                    // Confidence
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _confidenceColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.psychology_rounded, color: _confidenceColor(), size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'AI confidence: $_confidence%',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _confidenceColor()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Edit values if needed, then save.',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _EditableRow(label: 'Carbs (g)', controller: _carbsController),
                    _EditableRow(label: 'Protein (g)', controller: _proteinController),
                    _EditableRow(label: 'Fat (g)', controller: _fatController),
                    _EditableRow(label: 'Calories (kcal)', controller: _caloriesController),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _confirmAndSave,
                        icon: const Icon(Icons.check_rounded, size: 22),
                        label: const Text('Confirm & Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
