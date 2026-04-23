import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:diab_care/core/widgets/animations.dart';

/// Welcome screen - entry point of the app.
/// Auto-redirects logged-in users based on their role.
/// Otherwise shows: "Se connecter" (login) or "Créer un compte" (register with role choice).
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  bool _checked = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
            return;
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
        child: Stack(
          children: [
            // Decorative circles
            Positioned(top: -30, right: -30, child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
            )),
            Positioned(top: 60, right: 40, child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)),
            )),
            Positioned(bottom: 100, left: -40, child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)),
            )),
            Positioned(bottom: 200, right: -20, child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.03)),
            )),
            Positioned(top: 200, left: -20, child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
            )),

            SafeArea(
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
                            // Pulsing logo container
                            FadeInSlide(
                              index: 0,
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.12),
                                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, spreadRadius: 5),
                                    ],
                                  ),
                                  child: Image.asset('assets/logo/logo_withname.png', height: 150),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            FadeInSlide(
                              index: 1,
                              child: Text(
                                'Votre partenaire santé',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.95),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeInSlide(
                              index: 2,
                              child: Text(
                                'Gérez votre diabète en toute simplicité',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ── Middle section: Buttons ──
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(
                            children: [
                              // Se connecter — glassmorphic white button
                              FadeInSlide(
                                index: 3,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pushNamed(context, '/login'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primaryGreen,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
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
                              ),
                              const SizedBox(height: 14),
                              // Créer un compte — outlined with glow
                              FadeInSlide(
                                index: 4,
                                child: Container(
                                  width: double.infinity,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 16, spreadRadius: -2)],
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pushNamed(context, '/register-role'),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.white.withOpacity(0.6), width: 2),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                              ),
                            ],
                          ),
                        ),

                        // ── Bottom section: Features + version ──
                        Column(
                          children: [
                            // Divider
                            Container(
                              width: 60,
                              height: 2,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.0)]),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            // Features
                            FadeInSlide(
                              index: 5,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: const [
                                  _FeatureIcon(icon: Icons.bloodtype_rounded, label: 'Glycémie'),
                                  _FeatureIcon(icon: Icons.restaurant_rounded, label: 'Nutrition'),
                                  _FeatureIcon(icon: Icons.medical_services_rounded, label: 'Médecins'),
                                  _FeatureIcon(icon: Icons.local_pharmacy_rounded, label: 'Pharmacies'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'v1.0.0 — DiabCare © 2025',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
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
          ],
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500)),
      ],
    );
  }
}
