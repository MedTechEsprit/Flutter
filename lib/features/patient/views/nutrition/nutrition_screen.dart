import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/views/meals_screen.dart';

/// Nutrition page for patients: upload/take food photo, view AI analysis (mock).
/// Mobile-first, DiabCare design system.
enum _NutritionState { empty, loading, result, error }

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with TickerProviderStateMixin {
  _NutritionState _state = _NutritionState.empty;
  XFile? _pickedFile;
  File? _imageFile;
  String? _errorMessage;

  // Mock AI result (frontend-only simulation)
  double _carbs = 0;
  double _sugar = 0;
  int _calories = 0;
  int _glycemicIndex = 0;
  String _riskLevel = 'Low';
  Color _riskColor = AppColors.statusGood;
  String _recommendation = '';

  static const double _cardRadius = 20;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() {
        _pickedFile = file;
        _imageFile = File(file.path);
        _errorMessage = null;
        _state = _NutritionState.loading;
      });
      _simulateAnalysis();
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _NutritionState.error;
          _errorMessage = 'Impossible d\'accéder à l\'image. Vérifiez les autorisations.';
        });
      }
    }
  }

  void _simulateAnalysis() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    setState(() {
      _carbs = 42;
      _sugar = 12;
      _calories = 285;
      _glycemicIndex = 55;
      _riskLevel = 'Medium';
      _riskColor = AppColors.warningOrange;
      _recommendation =
          'Ce repas a un index glycémique modéré. Privilégiez une portion raisonnable et accompagnez avec des fibres (légumes) pour limiter le pic de glycémie.';
      _state = _NutritionState.result;
    });
  }

  void _reset() {
    setState(() {
      _state = _NutritionState.empty;
      _pickedFile = null;
      _imageFile = null;
      _errorMessage = null;
    });
  }

  void _saveMeal() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Repas enregistré dans votre journal'),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _NavChip(
                  label: 'Meals',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealsScreen())),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_state == _NutritionState.empty || _state == _NutritionState.error) ...[
                      _buildUploadCard(),
                      if (_state == _NutritionState.error) _buildErrorCard(),
                    ],
                    if (_state == _NutritionState.loading && _imageFile != null) ...[
                      _buildImagePreview(showLoading: true),
                      _buildLoadingCard(),
                    ],
                    if (_state == _NutritionState.result && _imageFile != null) ...[
                      _buildImagePreview(showLoading: false),
                      _buildResultsCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textPrimary,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.backgroundPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nutrition',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Analyze your meal with AI',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 48,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add a photo of your meal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Take a picture or choose from your gallery for instant analysis.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _UploadButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UploadButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Upload from Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview({required bool showLoading}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : const SizedBox(),
              ),
              if (showLoading)
                Container(
                  color: Colors.black38,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.primaryGreen,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing your meal...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI is estimating nutrients and impact.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.statusErrorBg,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _errorMessage ?? 'An error occurred.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: _reset,
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _riskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _riskLevel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _riskColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.grain_rounded,
                    label: 'Carbohydrates',
                    value: '${_carbs.toInt()}',
                    unit: 'g',
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.cake_rounded,
                    label: 'Sugar',
                    value: '${_sugar.toInt()}',
                    unit: 'g',
                    color: AppColors.softOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Calories',
                    value: '$_calories',
                    unit: 'kcal',
                    color: AppColors.warmPeach,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.trending_up_rounded,
                    label: 'Glycemic Index',
                    value: '$_glycemicIndex',
                    unit: '',
                    color: AppColors.accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: AppColors.darkGreen, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _recommendation,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveMeal,
                icon: const Icon(Icons.save_rounded, size: 22),
                label: const Text('Save Meal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _reset,
                child: Text(
                  'Analyze another meal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends State<_UploadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.35)),
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: AppColors.primaryGreen, size: 28),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  State<_MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<_MetricTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 22, color: widget.color),
          const SizedBox(height: 10),
          _AnimatedCounter(
            value: widget.value,
            unit: widget.unit,
            color: widget.color,
          ),
          const SizedBox(height: 2),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animates from 0 to [value] when first built.
class _AnimatedCounter extends StatefulWidget {
  final String value;
  final String unit;
  final Color color;

  const _AnimatedCounter({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final end = double.tryParse(widget.value) ?? 0;
    _animation = Tween<double>(begin: 0, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final display = widget.value.contains('.')
            ? _animation.value.toStringAsFixed(1)
            : _animation.value.toInt().toString();
        return Text(
          '$display${widget.unit}',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mintGreen.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGreen)),
        ),
      ),
    );
  }
}
