import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';

class BoostManagementWidget extends StatefulWidget {
  const BoostManagementWidget({super.key});

  @override
  State<BoostManagementWidget> createState() => _BoostManagementWidgetState();
}

class _BoostManagementWidgetState extends State<BoostManagementWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacyViewModel>().loadActiveBoosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyViewModel>(
      builder: (context, viewModel, child) {
        final activeBoosts = viewModel.activeBoosts;
        final hasActiveBoost = activeBoosts.isNotEmpty;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasActiveBoost
                    ? [Colors.amber.shade50, Colors.orange.shade50]
                    : [Colors.grey.shade50, Colors.grey.shade100],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasActiveBoost ? Colors.amber : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasActiveBoost ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasActiveBoost ? '⚡ Boost Actif' : '⚡ Boost de Visibilité',
                            style: AppTextStyles.header.copyWith(
                              color: hasActiveBoost ? Colors.amber.shade900 : Colors.grey.shade700,
                              fontSize: 18,
                            ),
                          ),
                          if (hasActiveBoost)
                            Text(
                              activeBoosts.first.remainingTimeText,
                              style: AppTextStyles.bodySecondary.copyWith(
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!hasActiveBoost)
                      ElevatedButton.icon(
                        onPressed: () => _showBoostDialog(context, viewModel),
                        icon: const Icon(Icons.flash_on, size: 18),
                        label: const Text('Activer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (hasActiveBoost)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Votre pharmacie apparaît en priorité dans un rayon de ${activeBoosts.first.radiusKm} km',
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Augmentez votre visibilité et recevez plus de demandes de patients à proximité.',
                    style: AppTextStyles.bodySecondary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBoostDialog(BuildContext context, PharmacyViewModel viewModel) {
    String selectedType = '24h';
    int radiusKm = 10;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              const Text('Activer un Boost'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type de boost',
                style: AppTextStyles.subheader,
              ),
              const SizedBox(height: 8),
              _buildBoostOption('24h', '24 Heures', '🚀', selectedType, (value) {
                setState(() => selectedType = value);
              }),
              _buildBoostOption('week', '1 Semaine', '⚡', selectedType, (value) {
                setState(() => selectedType = value);
              }),
              _buildBoostOption('month', '1 Mois', '💎', selectedType, (value) {
                setState(() => selectedType = value);
              }),
              const SizedBox(height: 20),
              Text(
                'Rayon de visibilité',
                style: AppTextStyles.subheader,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: radiusKm.toDouble(),
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: '$radiusKm km',
                      activeColor: AppColors.primaryGreen,
                      onChanged: (value) {
                        setState(() => radiusKm = value.toInt());
                      },
                    ),
                  ),
                  Text(
                    '$radiusKm km',
                    style: AppTextStyles.header.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Votre pharmacie sera mise en avant auprès des patients dans la zone sélectionnée.',
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: Colors.blue.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final result = await viewModel.activateBoost(
                  boostType: selectedType,
                  radiusKm: radiusKm,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['success'] == true
                            ? '✅ Boost activé avec succès!'
                            : '❌ ${result['message'] ?? 'Erreur'}',
                      ),
                      backgroundColor: result['success'] == true
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('Activer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoostOption(
    String value,
    String label,
    String emoji,
    String selectedValue,
    Function(String) onChanged,
  ) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primaryGreen : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }
}

