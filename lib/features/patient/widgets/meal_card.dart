import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/models/meal_entry_model.dart';

/// Expandable meal card: summary line, expand for full details + Edit / Delete.
class MealCard extends StatefulWidget {
  final MealEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MealCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final timeStr = DateFormat('HH:mm').format(e.time);
    final notePreview = (e.notes == null || e.notes!.isEmpty)
        ? null
        : (e.notes!.length > 60 ? '${e.notes!.substring(0, 60)}...' : e.notes);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.mealType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _Chip(label: 'Carbs', value: '${e.carbs.toInt()}g', color: AppColors.primaryGreen),
                  _Chip(label: 'Protein', value: '${e.protein.toInt()}g', color: AppColors.accentBlue),
                  _Chip(label: 'Fat', value: '${e.fat.toInt()}g', color: AppColors.softOrange),
                  if (e.calories != null)
                    _Chip(label: 'Cal', value: '${e.calories!.toInt()}', color: AppColors.warmPeach)
                  else
                    _Chip(label: 'Cal', value: '${e.effectiveCalories.toInt()}', color: AppColors.textMuted),
                ],
              ),
              if (notePreview != null) ...[
                const SizedBox(height: 8),
                Text(
                  notePreview,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (_expanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (e.composition != null && e.composition!.isNotEmpty) ...[
                  const Text('Composition', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: e.composition!.map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (e.notes != null && e.notes!.isNotEmpty) ...[
                  const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(e.notes!, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primaryGreen),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.critical),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}
