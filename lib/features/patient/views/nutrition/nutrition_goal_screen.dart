import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';

/// Goal & Profile screen matching the Figma design with weight loss motivation options
class NutritionGoalScreen extends StatefulWidget {
  const NutritionGoalScreen({super.key});

  @override
  State<NutritionGoalScreen> createState() => _NutritionGoalScreenState();
}

class _NutritionGoalScreenState extends State<NutritionGoalScreen> {
  final List<String> _selectedGoals = [];
  
  final List<String> _availableGoals = [
    'Feel better in my body',
    'Be healthier',
    'Get in shape',
    'Health Conditions',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Goal & Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Question
              const Text(
                'We all have different reasons to lose weight, what are yours?',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Goals list
              Expanded(
                child: ListView.builder(
                  itemCount: _availableGoals.length,
                  itemBuilder: (context, index) {
                    final goal = _availableGoals[index];
                    final isSelected = _selectedGoals.contains(goal);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedGoals.remove(goal);
                            } else {
                              _selectedGoals.add(goal);
                            }
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.softOrange.withOpacity(0.2)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? AppColors.softOrange
                                  : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Checkbox
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected 
                                      ? AppColors.softOrange
                                      : AppColors.white,
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppColors.softOrange
                                        : AppColors.border,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: AppColors.white,
                                      )
                                    : null,
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Goal text
                              Expanded(
                                child: Text(
                                  goal,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected 
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Next button
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _selectedGoals.isNotEmpty 
                      ? () {
                          // Handle next action
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Goals saved: ${_selectedGoals.join(", ")}'),
                              backgroundColor: AppColors.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: AppColors.textMuted,
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
