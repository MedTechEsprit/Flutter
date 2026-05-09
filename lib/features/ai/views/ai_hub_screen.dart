import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/services/subscription_service.dart';
import 'ai_chat_screen.dart';
import 'ai_food_analyzer_screen.dart';
import 'ai_prediction_screen.dart';
import 'ai_pattern_screen.dart';
import 'premium_subscription_screen.dart';

/// AI Hub — Central screen listing all patient AI features
class AiHubScreen extends StatefulWidget {
  const AiHubScreen({super.key});

  @override
  State<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends State<AiHubScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _checkingSubscription = false;

  Future<void> _openFeature(Widget screen) async {
    if (_checkingSubscription) return;

    setState(() => _checkingSubscription = true);
    try {
      final status = await _subscriptionService.getMySubscription();
      if (!mounted) return;

      if (status.isActive) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => screen));
      } else {
        final unlocked = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()),
        );

        if (unlocked == true && mounted) {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => screen));
        }
      }
    } catch (e) {
      if (!mounted) return;
      final clean = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(clean)));
    } finally {
      if (mounted) setState(() => _checkingSubscription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.doctorBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(
                gradient: AppColors.doctorGradient,
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
                            child: const Icon(
                              Icons.show_chart_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Intelligence Artificielle',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'IA santé à portée de main pour tous les diabètes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
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
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'MediBot - Chat IA',
                  subtitle: '',
                  description: 'Posez des questions et obtenez des conseils personnalisés sur la nutrition',
                  gradient: const [
                    AppColors.primaryGreen,
                    AppColors.secondaryGreen,
                  ],
                  onTap: () => _openFeature(const AiChatScreen()),
                ),
                const SizedBox(height: 14),

                // AI Food Analyzer
                _AiFeatureCard(
                  icon: Icons.restaurant_rounded,
                  title: 'Analyse Alimentaire',
                  subtitle: '',
                  description: 'Téléchargez une photo de votre repas pour obtenir une évaluation de sa qualité nutritionnelle et de son impact sur la glycémie',
                  gradient: [AppColors.softOrange, AppColors.warmPeach],
                  onTap: () => _openFeature(const AiFoodAnalyzerScreen()),
                ),
                const SizedBox(height: 14),

                // AI Prediction
                _AiFeatureCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Prédiction Glycémique',
                  subtitle: '',
                  description: 'Anticipez votre glycémie future en fonction de vos habitudes alimentaires, de votre activité physique et...',
                  gradient: const [AppColors.accentBlue, AppColors.primaryBlue],
                  onTap: () => _openFeature(const AiPredictionScreen()),
                ),
                const SizedBox(height: 14),

                // AI Pattern
                _AiFeatureCard(
                  icon: Icons.insights_rounded,
                  title: 'Détection de Patterns',
                  subtitle: 'Analysez vos 30 derniers jours',
                  description:
                      'Détecte les hypoglycémies nocturnes, pics post-repas, fenêtres à risque et dégradation du contrôle glycémique.',
                  gradient: [AppColors.lavender, const Color(0xFFB794C6)],
                  onTap: () => _openFeature(const AiPatternScreen()),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _checkingSubscription
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Vérification de votre abonnement...'),
                ],
              ),
            )
          : null,
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradient.first.withOpacity(0.12),
              gradient.first.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: gradient.first.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
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
