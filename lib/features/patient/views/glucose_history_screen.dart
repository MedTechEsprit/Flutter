import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';
import 'package:diab_care/features/patient/widgets/glucose_card.dart';
import 'package:intl/intl.dart';

class GlucoseHistoryScreen extends StatelessWidget {
  const GlucoseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final glucoseVM = context.watch<GlucoseViewModel>();
    final grouped = glucoseVM.readingsGroupedByDate;
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.mainGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Historique', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('${glucoseVM.readings.length} mesures enregistrées', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _FilterChip(label: 'Tout', isSelected: glucoseVM.filterType == 'all', onTap: () => glucoseVM.setFilter('all')),
                  _FilterChip(label: 'À jeun', isSelected: glucoseVM.filterType == 'fasting', onTap: () => glucoseVM.setFilter('fasting')),
                  _FilterChip(label: 'Avant repas', isSelected: glucoseVM.filterType == 'before_meal', onTap: () => glucoseVM.setFilter('before_meal')),
                  _FilterChip(label: 'Après repas', isSelected: glucoseVM.filterType == 'after_meal', onTap: () => glucoseVM.setFilter('after_meal')),
                  _FilterChip(label: 'Coucher', isSelected: glucoseVM.filterType == 'bedtime', onTap: () => glucoseVM.setFilter('bedtime')),
                ],
              ),
            ),
          ),

          // Grouped by date
          ...sortedDates.map((dateStr) {
            final readings = grouped[dateStr]!;
            final date = DateTime.parse(dateStr);
            final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
            final isYesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1))) == dateStr;

            String dateLabel;
            if (isToday) {
              dateLabel = "Aujourd'hui";
            } else if (isYesterday) {
              dateLabel = 'Hier';
            } else {
              dateLabel = DateFormat('EEEE d MMMM', 'fr_FR').format(date);
            }

            // Filter readings based on current filter
            final filteredReadings = glucoseVM.filterType == 'all'
                ? readings
                : readings.where((r) => r.type == glucoseVM.filterType).toList();

            if (filteredReadings.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Text(dateLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          Text('${filteredReadings.length} mesures', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    ...filteredReadings.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlucoseCard(reading: r, displayUnit: glucoseVM.preferredUnit),
                    )),
                  ],
                ),
              ),
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.softGreen : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.softGreen : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
