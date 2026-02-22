import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/models/meal_entry_model.dart';
import 'package:diab_care/features/patient/viewmodels/meal_viewmodel.dart';
import 'package:diab_care/features/patient/views/nutrition_analytics_screen.dart';

class MealLoggingScreen extends StatefulWidget {
  final MealEntry? editingEntry;

  const MealLoggingScreen({super.key, this.editingEntry});

  @override
  State<MealLoggingScreen> createState() => _MealLoggingScreenState();
}

class _MealLoggingScreenState extends State<MealLoggingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();

  late String _mealType;
  late DateTime _mealTime;
  final List<String> _composition = [];

  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  static const _compositionOptions = [
    'Chicken', 'Meat', 'Eggs', 'Salad', 'Rice', 'Pasta', 'Bread',
    'Vegetables', 'Fish', 'Cheese', 'Fruits', 'Legumes', 'Dairy', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.editingEntry;
    if (e != null) {
      _mealType = e.mealType;
      _mealTime = e.time;
      if (e.composition != null) _composition.addAll(e.composition!);
      _carbsController.text = e.carbs.toString();
      _proteinController.text = e.protein.toString();
      _fatController.text = e.fat.toString();
      if (e.calories != null) _caloriesController.text = e.calories.toString();
      if (e.notes != null) _notesController.text = e.notes!;
    } else {
      _mealType = 'Breakfast';
      _mealTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_mealTime),
    );
    if (picked != null) {
      setState(() {
        _mealTime = DateTime(
          _mealTime.year,
          _mealTime.month,
          _mealTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveMeal() {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<MealViewModel>();
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0;
    final protein = double.tryParse(_proteinController.text.trim()) ?? 0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0;
    final calories = double.tryParse(_caloriesController.text.trim());
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    final compositionList = _composition.isEmpty ? null : List<String>.from(_composition);

    if (widget.editingEntry != null) {
      final entry = widget.editingEntry!.copyWith(
        mealType: _mealType,
        carbs: carbs,
        protein: protein,
        fat: fat,
        calories: calories,
        notes: notes,
        time: _mealTime,
        composition: compositionList,
      );
      vm.updateMeal(entry);
    } else {
      final entry = vm.createEntry(
        mealType: _mealType,
        carbs: carbs,
        protein: protein,
        fat: fat,
        calories: calories,
        notes: notes,
        time: _mealTime,
        composition: compositionList,
      );
      vm.addMeal(entry);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.editingEntry != null ? 'Meal updated' : 'Meal saved successfully'),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
    if (widget.editingEntry == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NutritionAnalyticsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintGreen,
      appBar: AppBar(
        title: Text(widget.editingEntry != null ? 'Edit Meal' : 'Log Meal'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Meal type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _mealType,
                    decoration: _inputDecoration(),
                    items: _mealTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _mealType = v ?? _mealType),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What is the meal composed of?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _compositionOptions.map((option) {
                      final selected = _composition.contains(option);
                      return FilterChip(
                        label: Text(option),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) _composition.add(option);
                            else _composition.remove(option);
                          });
                        },
                        selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                        checkmarkColor: AppColors.primaryGreen,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Macros (grams)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(hint: 'Carbs'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(hint: 'Protein'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(hint: 'Fat'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(hint: 'Calories (optional)'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim());
                      if (n != null && n < 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: _inputDecoration(hint: 'Add notes...'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: AppColors.primaryGreen),
                      const SizedBox(width: 12),
                      const Text('Time of meal ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const Spacer(),
                      Text(
                        '${_mealTime.hour.toString().padLeft(2, '0')}:${_mealTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saveMeal,
                icon: const Icon(Icons.save_rounded, size: 22),
                label: const Text('Save Meal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: BorderSide(color: AppColors.border)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: BorderSide(color: AppColors.border)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2)
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: AppColors.errorRed)
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
