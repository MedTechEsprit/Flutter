import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/patient/views/meal_logging_screen.dart';
import 'package:diab_care/features/patient/views/meal_history_screen.dart';
import 'package:diab_care/features/patient/views/nutrition_analytics_screen.dart';
import 'package:diab_care/features/patient/views/ai_meal_capture_screen.dart';

/// Welcome screen for Nutrition module matching the Figma design
class NutritionWelcomeScreen extends StatelessWidget {
  const NutritionWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
              
              // Main content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Vegetables illustration area
                    Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.mintGreen.withOpacity(0.3),
                            AppColors.lightGreen.withOpacity(0.2),
                          ],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pot illustration
                          Positioned(
                            bottom: 40,
                            child: Container(
                              width: 120,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.darkGreen.withOpacity(0.8),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(60),
                                  topRight: Radius.circular(60),
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          // Pot lid
                          Positioned(
                            bottom: 110,
                            child: Container(
                              width: 100,
                              height: 15,
                              decoration: BoxDecoration(
                                color: AppColors.darkGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          // Vegetables falling
                          Positioned(
                            top: 60,
                            left: 80,
                            child: Icon(Icons.eco, size: 40, color: AppColors.primaryGreen),
                          ),
                          Positioned(
                            top: 80,
                            right: 70,
                            child: Icon(Icons.eco, size: 35, color: AppColors.secondaryGreen),
                          ),
                          Positioned(
                            top: 120,
                            left: 60,
                            child: Icon(Icons.eco, size: 30, color: AppColors.lightGreen),
                          ),
                          Positioned(
                            top: 100,
                            right: 90,
                            child: Icon(Icons.eco, size: 25, color: AppColors.darkGreen),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Title
                    Text(
                      'Nutrients',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Subtitle
                    Text(
                      'Personalized nutrition for every motivation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom section with decorative elements and button
              Column(
                children: [
                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () => _showNutritionOptions(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Decorative elements
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left decorative vegetable
                      Icon(Icons.eco, size: 24, color: AppColors.primaryGreen.withOpacity(0.6)),
                      
                      // Right decorative fruit
                      Icon(Icons.circle, size: 24, color: AppColors.softOrange.withOpacity(0.6)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNutritionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nutrition Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20),
            _OptionTile(
              icon: Icons.add_circle_outline,
              title: 'Log Meal',
              subtitle: 'Add a new meal entry',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MealLoggingScreen()),
                );
              },
            ),
            _OptionTile(
              icon: Icons.history,
              title: 'Meal History',
              subtitle: 'View past meals',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MealHistoryScreen()),
                );
              },
            ),
            _OptionTile(
              icon: Icons.analytics_outlined,
              title: 'Analytics',
              subtitle: 'View nutrition analytics',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NutritionAnalyticsScreen()),
                );
              },
            ),
            _OptionTile(
              icon: Icons.camera_alt_outlined,
              title: 'AI Meal Capture',
              subtitle: 'Capture and analyze meals',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AIMealCaptureScreen()),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
