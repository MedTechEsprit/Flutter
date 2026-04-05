import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';

class AddGlucoseScreen extends StatefulWidget {
  const AddGlucoseScreen({super.key});

  @override
  State<AddGlucoseScreen> createState() => _AddGlucoseScreenState();
}

class _AddGlucoseScreenState extends State<AddGlucoseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _valueController = TextEditingController();
  String _selectedType = 'fasting';
  String _selectedUnit = 'mg/dL';
  bool _isSaving = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  double? _glucometerValue;
  final _noteController = TextEditingController();

  final _types = [
    {'key': 'fasting', 'label': 'À jeun', 'icon': Icons.wb_sunny_outlined},
    {'key': 'before_meal', 'label': 'Avant repas', 'icon': Icons.restaurant_outlined},
    {'key': 'after_meal', 'label': 'Après repas', 'icon': Icons.restaurant},
    {'key': 'bedtime', 'label': 'Coucher', 'icon': Icons.nightlight_outlined},
    {'key': 'random', 'label': 'Aléatoire', 'icon': Icons.access_time},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Use the preferred unit from viewmodel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<GlucoseViewModel>();
      setState(() => _selectedUnit = vm.preferredUnit);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveManualReading() async {
    final value = double.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer une valeur valide')));
      return;
    }

    setState(() => _isSaving = true);
    final vm = context.read<GlucoseViewModel>();
    final success = await vm.addReadingToApi(
      value: value,
      period: _selectedType,
      unit: _selectedUnit,
      note: _noteController.text,
    );
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Mesure enregistrée avec succès'), backgroundColor: AppColors.statusGood, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erreur lors de l\'enregistrement'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  Future<void> _saveGlucometerReading() async {
    if (_glucometerValue == null) return;

    setState(() => _isSaving = true);
    final vm = context.read<GlucoseViewModel>();
    final success = await vm.addReadingToApi(
      value: _glucometerValue!,
      period: _selectedType,
      unit: _selectedUnit,
      note: 'Glucomètre',
    );
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Mesure du glucomètre enregistrée'), backgroundColor: AppColors.statusGood, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erreur lors de l\'enregistrement'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  Future<void> _simulateGlucometerConnection() async {
    setState(() => _isConnecting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isConnecting = false;
      _isConnected = true;
      _glucometerValue = 95 + (DateTime.now().millisecond % 60).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Ajouter une mesure'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.softGreen,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.softGreen,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Manuel'),
            Tab(icon: Icon(Icons.bluetooth), text: 'Glucomètre'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualTab(),
          _buildGlucometerTab(),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value Input
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                const Text('Valeur de glycémie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _valueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: '---',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 48),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Unit Selector
                    _buildUnitSelector(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Type Selection
          const Text('Type de mesure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _types.map((t) {
              final isSelected = _selectedType == t['key'];
              return InkWell(
                onTap: () => setState(() => _selectedType = t['key'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.softGreen.withOpacity(0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.softGreen : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t['icon'] as IconData, size: 18, color: isSelected ? AppColors.softGreen : AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        t['label'] as String,
                        style: TextStyle(
                          color: isSelected ? AppColors.softGreen : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Note field
          const Text('Note (optionnel)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ajouter une note...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.softGreen)),
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveManualReading,
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.softGreen.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          isDense: true,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.softGreen),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.softGreen, size: 20),
          items: const [
            DropdownMenuItem(value: 'mg/dL', child: Text('mg/dL')),
            DropdownMenuItem(value: 'mmol/L', child: Text('mmol/L')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedUnit = val);
              // Also update preferred unit in viewmodel
              context.read<GlucoseViewModel>().setPreferredUnit(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildGlucometerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Bluetooth visual
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isConnected ? AppColors.softGreen.withOpacity(0.1) : AppColors.lightBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: _isConnecting
                      ? const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(color: AppColors.lightBlue))
                      : Icon(
                          _isConnected ? Icons.check_circle : Icons.bluetooth_searching,
                          size: 60,
                          color: _isConnected ? AppColors.softGreen : AppColors.lightBlue,
                        ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isConnecting
                      ? 'Recherche en cours...'
                      : _isConnected
                          ? 'Glucomètre connecté'
                          : 'Connecter le glucomètre',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _isConnected ? AppColors.softGreen : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isConnecting
                      ? 'Vérifiez que votre glucomètre est allumé'
                      : _isConnected
                          ? 'Valeur détectée automatiquement'
                          : 'Assurez-vous que le Bluetooth est activé',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                if (_isConnected && _glucometerValue != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    '${_glucometerValue!.toInt()} $_selectedUnit',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.softGreen),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (!_isConnected)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _simulateGlucometerConnection,
                icon: const Icon(Icons.bluetooth),
                label: Text(_isConnecting ? 'Connexion...' : 'Connecter', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

          if (_isConnected) ...[
            // Type Selection
            const SizedBox(height: 8),
            const Align(alignment: Alignment.centerLeft, child: Text('Type de mesure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _types.map((t) {
                final isSelected = _selectedType == t['key'];
                return InkWell(
                  onTap: () => setState(() => _selectedType = t['key'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.softGreen.withOpacity(0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.softGreen : Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t['icon'] as IconData, size: 18, color: isSelected ? AppColors.softGreen : AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(t['label'] as String, style: TextStyle(color: isSelected ? AppColors.softGreen : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveGlucometerReading,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer la mesure', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
