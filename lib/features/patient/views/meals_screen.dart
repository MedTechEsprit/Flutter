import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/views/meal_logging_screen.dart';
import 'package:diab_care/features/patient/views/meal_history_screen.dart';
import 'package:diab_care/features/patient/views/nutrition_analytics_screen.dart';
import 'package:diab_care/features/patient/views/ai_meal_capture_screen.dart';

/// Meals hub: Log meal, History, Analytics, AI Capture.
class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Meals'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HubCard(
            icon: Icons.restaurant_menu_rounded,
            title: 'meals',
            subtitle: 'Manually enter a meal',
            color: AppColors.primaryGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MealLoggingScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.history_rounded,
            title: 'History',
            subtitle: 'View past meals',
            color: AppColors.accentBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MealHistoryScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.analytics_rounded,
            title: 'Analytics',
            subtitle: 'Daily summary & charts',
            color: AppColors.lavender,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NutritionAnalyticsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.camera_alt_rounded,
            title: 'AI Capture',
            subtitle: 'Capture meal with AI',
            color: AppColors.softOrange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIMealCaptureScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
