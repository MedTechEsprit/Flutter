import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/views/nutrition/nutrition_welcome_screen.dart';
import 'package:diab_care/features/patient/views/nutrition/meal_logging_screen.dart';
import 'package:diab_care/features/patient/views/nutrition/meal_history_screen.dart';
import 'package:diab_care/features/patient/views/nutrition/nutrition_analytics_screen.dart';
import 'package:diab_care/features/patient/views/nutrition/ai_meal_capture_screen.dart';
import 'package:diab_care/features/patient/views/nutrition/nutrition_goal_screen.dart';

/// Main Nutrition screen that provides navigation to all nutrition features
class NutritionMainScreen extends StatelessWidget {
  const NutritionMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintGreen,
      appBar: AppBar(
        title: const Text('Nutrition'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition Tracking',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your meals and track nutrition',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _NutritionCard(
                    icon: Icons.restaurant_rounded,
                    title: 'Log Meal',
                    subtitle: 'Add new meal',
                    color: AppColors.primaryGreen,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MealLoggingScreen()),
                    ),
                  ),
                  _NutritionCard(
                    icon: Icons.history_rounded,
                    title: 'History',
                    subtitle: 'View past meals',
                    color: AppColors.accentBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MealHistoryScreen()),
                    ),
                  ),
                  _NutritionCard(
                    icon: Icons.analytics_rounded,
                    title: 'Analytics',
                    subtitle: 'View insights',
                    color: AppColors.softOrange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NutritionAnalyticsScreen()),
                    ),
                  ),
                  _NutritionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'AI Capture',
                    subtitle: 'Photo analysis',
                    color: AppColors.warningOrange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AIMealCaptureScreen()),
                    ),
                  ),
                  _NutritionCard(
                    icon: Icons.track_changes_rounded,
                    title: 'Goals',
                    subtitle: 'Set targets',
                    color: AppColors.darkGreen,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NutritionGoalScreen()),
                    ),
                  ),
                  _NutritionCard(
                    icon: Icons.lightbulb_rounded,
                    title: 'Welcome',
                    subtitle: 'Getting started',
                    color: AppColors.lavender,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NutritionWelcomeScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NutritionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.shadowMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
