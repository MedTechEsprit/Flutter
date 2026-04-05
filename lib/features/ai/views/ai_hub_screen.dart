import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'ai_chat_screen.dart';
import 'ai_food_analyzer_screen.dart';
import 'ai_prediction_screen.dart';
import 'ai_pattern_screen.dart';

/// AI Hub — Central screen listing all patient AI features
class AiHubScreen extends StatelessWidget {
  const AiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.secondaryGreen, AppColors.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Intelligence Artificielle',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Vos outils IA pour mieux gérer votre diabète',
                                  style: TextStyle(fontSize: 13, color: Colors.white70),
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
            ),
          ),

          // Feature cards
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // AI Chat
                _AiFeatureCard(
                  icon: Icons.smart_toy_rounded,
                  title: 'MediBot — Chat IA',
                  subtitle: 'Posez vos questions sur le diabète et la nutrition',
                  description: 'Un assistant intelligent qui analyse vos données de glycémie et repas pour vous donner des conseils personnalisés.',
                  gradient: const [AppColors.primaryGreen, AppColors.secondaryGreen],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
                ),
                const SizedBox(height: 14),

                // AI Food Analyzer
                _AiFeatureCard(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Analyse Alimentaire',
                  subtitle: 'Photographiez votre repas pour l\'analyser',
                  description: 'L\'IA identifie les aliments, estime les valeurs nutritionnelles et donne des conseils adaptés à votre profil.',
                  gradient: [AppColors.softOrange, AppColors.warmPeach],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiFoodAnalyzerScreen())),
                ),
                const SizedBox(height: 14),

                // AI Prediction
                _AiFeatureCard(
                  icon: Icons.auto_graph_rounded,
                  title: 'Prédiction Glycémique',
                  subtitle: 'Anticipez votre glycémie dans 2-4 heures',
                  description: 'Basé sur vos données récentes, l\'IA prédit la tendance de votre glycémie et vous alerte en cas de risque.',
                  gradient: const [AppColors.accentBlue, AppColors.primaryBlue],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPredictionScreen())),
                ),
                const SizedBox(height: 14),

                // AI Pattern
                _AiFeatureCard(
                  icon: Icons.insights_rounded,
                  title: 'Détection de Patterns',
                  subtitle: 'Analysez vos 30 derniers jours',
                  description: 'Détecte les hypoglycémies nocturnes, pics post-repas, fenêtres à risque et dégradation du contrôle glycémique.',
                  gradient: [AppColors.lavender, const Color(0xFFB794C6)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPatternScreen())),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _AiFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: gradient.first, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: gradient.first.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
