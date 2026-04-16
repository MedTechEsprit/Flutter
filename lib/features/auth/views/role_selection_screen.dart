import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    const brand = Color(0xFF1C3FE8);
    const secondary = Color(0xFF50C2CA);
    final size = MediaQuery.of(context).size;
    final scale = (size.width / 390).clamp(0.86, 1.04);
    final headerHeight = (size.height * 0.36).clamp(230.0, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: headerHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFB7E4E9),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(58),
                    bottomRight: Radius.circular(160),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 30 * scale,
                  vertical: 14 * scale,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeInSlide(
                      index: 0,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/logo/logo_withoutname.png',
                              height: 86 * scale,
                            ),
                            SizedBox(height: 8 * scale),
                            const _GradientBrandTitle(),
                            SizedBox(height: 6 * scale),
                            Text(
                              'GIVING THE BEST ONLINE CARE SERVICE',
                              style: TextStyle(
                                color: const Color(0xFF464646),
                                fontSize: 11 * scale,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 26 * scale),
                    FadeInSlide(
                      index: 1,
                      child: SizedBox(
                        width: double.infinity,
                        height: 50 * scale,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register-role'),
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 18,
                          ),
                          label: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondary,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: Colors.black.withValues(alpha: 0.16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    FadeInSlide(
                      index: 2,
                      child: SizedBox(
                        width: double.infinity,
                        height: 50 * scale,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: secondary,
                              width: 1.6,
                            ),
                            foregroundColor: secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientBrandTitle extends StatelessWidget {
  const _GradientBrandTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'DiabCare',
      style: TextStyle(
        fontSize: 30,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w800,
        color: Color(0xFF50C2CA),
        shadows: [
          Shadow(color: Color(0x33000000), offset: Offset(0, 2), blurRadius: 6),
        ],
      ),
    );
  }
}
