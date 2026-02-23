import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';

/// Welcome screen - entry point of the app.
/// Auto-redirects logged-in users based on their role.
/// Otherwise shows: "Se connecter" (login) or "Créer un compte" (register with role choice).
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked) {
      _checked = true;
      _autoRedirectIfLoggedIn();
    }
  }

  void _autoRedirectIfLoggedIn() {
    final authVM = context.read<AuthViewModel>();
    if (authVM.isLoggedIn && authVM.selectedRole != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        String route;
        switch (authVM.selectedRole) {
          case UserRole.patient:
            route = '/patient-home';
            break;
          case UserRole.doctor:
            route = '/doctor-home';
            break;
          case UserRole.pharmacy:
            route = '/pharmacy-home';
            break;
          default:
            return; // unknown role, stay on welcome
        }
        Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final safeHeight = screenHeight - topPadding - bottomPadding;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: safeHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ── Top section: Logo + tagline ──
                    Column(
                      children: [
                        SizedBox(height: safeHeight * 0.06),
                        // Decorative circle behind logo
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Image.asset(
                            'assets/logo/logo_withname.png',
                            height: 160,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Votre partenaire santé',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Gérez votre diabète en toute simplicité',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),

                    // ── Middle section: Buttons ──
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          // Se connecter button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 6,
                                shadowColor: Colors.black.withValues(alpha: 0.25),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login_rounded, size: 22),
                                  SizedBox(width: 10),
                                  Text('Se connecter', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Créer un compte button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(context, '/register-role'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white, width: 2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_add_alt_1_rounded, size: 22),
                                  SizedBox(width: 10),
                                  Text('Créer un compte', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Bottom section: Features + version ──
                    Column(
                      children: [
                        // Divider line
                        Container(
                          width: 60,
                          height: 1.5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        // Features preview
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            _FeatureIcon(icon: Icons.bloodtype_rounded, label: 'Glycémie'),
                            _FeatureIcon(icon: Icons.restaurant_rounded, label: 'Nutrition'),
                            _FeatureIcon(icon: Icons.medical_services_rounded, label: 'Médecins'),
                            _FeatureIcon(icon: Icons.local_pharmacy_rounded, label: 'Pharmacies'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'v1.0.0 — DiabCare © 2025',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }
}
