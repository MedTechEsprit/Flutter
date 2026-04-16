import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() =>
      _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  SubscriptionStatus? _status;
  bool _loading = true;
  bool _paymentLoading = false;
  bool _verifyLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final status = await _subscriptionService.getMySubscription();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startCheckout() async {
    setState(() => _paymentLoading = true);
    try {
      final session = await _subscriptionService.createCheckoutSession();
      final uri = Uri.parse(session.checkoutUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showError('Impossible d\'ouvrir Stripe Checkout');
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _paymentLoading = false);
    }
  }

  Future<void> _verifyPayment() async {
    setState(() => _verifyLoading = true);
    try {
      final status = await _subscriptionService.verifyLatestPayment();
      if (!mounted) return;
      setState(() => _status = status);

      if (status.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abonnement Premium activé ✅')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Paiement non confirmé pour le moment. Réessayez dans quelques secondes.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _verifyLoading = false);
    }
  }

  void _showError(String message) {
    final clean = message.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(clean)));
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final isActive = status?.isActive == true;
    final amount = status?.amount ?? 20;
    final currency = (status?.currency ?? 'eur').toUpperCase();
    final currencyLabel = currency == 'EUR' ? '€' : currency;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Abonnement Premium'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.elevatedShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'DiabCare Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isActive
                              ? 'Votre abonnement est actif.'
                              : 'Débloquez toutes les fonctionnalités IA patient.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '$amount $currencyLabel / mois',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoTile(Icons.auto_awesome_rounded, 'AI Chat personnalisé'),
                  _infoTile(
                    Icons.restaurant_menu_rounded,
                    'Analyse alimentaire IA',
                  ),
                  _infoTile(
                    Icons.auto_graph_rounded,
                    'Prédiction glycémique avancée',
                  ),
                  _infoTile(
                    Icons.insights_rounded,
                    'Détection intelligente de patterns',
                  ),
                  const SizedBox(height: 20),
                  if (isActive)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Continuer vers les outils IA'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _paymentLoading ? null : _startCheckout,
                      icon: _paymentLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_open_rounded),
                      label: Text(
                        _paymentLoading
                            ? 'Ouverture du paiement...'
                            : 'Souscrire maintenant',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _verifyLoading ? null : _verifyPayment,
                      icon: _verifyLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_rounded),
                      label: Text(
                        _verifyLoading
                            ? 'Vérification...'
                            : 'J\'ai payé, vérifier mon abonnement',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _infoTile(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
