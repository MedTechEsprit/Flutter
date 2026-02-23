import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/models/meal_entry_model.dart';
import 'package:diab_care/features/patient/viewmodels/meal_viewmodel.dart';
import 'package:diab_care/features/patient/widgets/meal_card.dart';
import 'package:diab_care/features/patient/views/nutrition/meal_logging_screen.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  String _sort = 'Today'; // Today, This Week, This Month

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MealViewModel>();
    List<MealEntry> list;
    switch (_sort) {
      case 'Today':
        list = vm.mealsToday;
        break;
      case 'This Week':
        list = vm.mealsThisWeek;
        break;
      case 'This Month':
        list = vm.mealsThisMonth;
        break;
      default:
        list = vm.mealsToday;
    }
    final grouped = vm.getMealsGroupedByDate(list);

    return Scaffold(
      backgroundColor: AppColors.mintGreen,
      appBar: AppBar(
        title: const Text('Meal History'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Today', label: Text('Today')),
                ButtonSegment(value: 'This Week', label: Text('This Week')),
                ButtonSegment(value: 'This Month', label: Text('This Month')),
              ],
              selected: {_sort},
              onSelectionChanged: (s) => setState(() => _sort = s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_rounded, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No meals in this period',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final dateKey = grouped.keys.elementAt(index);
                      final meals = grouped[dateKey]!;
                      final dateLabel = DateFormat('EEEE, MMM d').format(dateKey);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...meals.map((e) => MealCard(
                                  entry: e,
                                  onEdit: () => _openEdit(context, e),
                                  onDelete: () => _confirmDelete(context, vm, e),
                                )),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context, MealEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealLoggingScreen(editingEntry: entry),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MealViewModel vm, MealEntry e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text('Remove "${e.mealType}" from history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              vm.deleteMeal(e.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
