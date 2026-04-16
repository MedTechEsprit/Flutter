import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';

class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = (media.size.width / 390).clamp(0.85, 1.05);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _Header(scale: scale),
              SizedBox(height: 12 * scale),
              _StepIndicator(scale: scale),
              SizedBox(height: 8 * scale),
              Text(
                'Sign up as a..',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 14 * scale),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12 * scale,
                  crossAxisSpacing: 12 * scale,
                  childAspectRatio: 1.5,
                  children: [
                    _RoleGridTile(
                      icon: Icons.personal_injury_rounded,
                      label: 'Patient',
                      onTap: () {
                        context.read<AuthViewModel>().selectRole(
                          UserRole.patient,
                        );
                        Navigator.pushNamed(context, '/register-patient');
                      },
                    ),
                    _RoleGridTile(
                      icon: Icons.medical_services_rounded,
                      label: 'Medecin',
                      onTap: () {
                        context.read<AuthViewModel>().selectRole(
                          UserRole.doctor,
                        );
                        Navigator.pushNamed(context, '/register-medecin');
                      },
                    ),
                    _RoleGridTile(
                      icon: Icons.local_pharmacy_rounded,
                      label: 'Pharmacien',
                      onTap: () {
                        context.read<AuthViewModel>().selectRole(
                          UserRole.pharmacy,
                        );
                        Navigator.pushNamed(context, '/register-pharmacien');
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16 * scale),
              _BottomPanel(scale: scale),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double scale;

  const _Header({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 10 * scale, 16, 16 * scale),
      decoration: const BoxDecoration(
        color: Color(0xFFB7E4E9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(140),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Image.asset('assets/logo/logo_withoutname.png', height: 68 * scale),
          SizedBox(height: 4 * scale),
          const _BrandTitle(),
          SizedBox(height: 2 * scale),
          Text(
            'Register for free',
            style: TextStyle(fontSize: 16 * scale, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

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

class _StepIndicator extends StatelessWidget {
  final double scale;

  const _StepIndicator({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Step',
          style: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.w600),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circle(1, true),
            Container(width: 58 * scale, height: 2, color: Colors.black),
            _circle(2, false),
          ],
        ),
      ],
    );
  }

  Widget _circle(int number, bool active) {
    return Container(
      width: 28 * scale,
      height: 28 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFB7E4E9) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Text('$number', style: TextStyle(fontSize: 13 * scale)),
    );
  }
}

class _RoleGridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoleGridTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB7E4E9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF118893)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoleTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFB7E4E9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF118893), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF0D6D77),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final double scale;

  const _BottomPanel({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20 * scale,
        18 * scale,
        20 * scale,
        16 * scale,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFB7E4E9),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(120)),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF5A6770), fontSize: 13),
              children: [
                const TextSpan(text: 'Already have an account? '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF2F66D3),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10 * scale),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFF5A6770))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OR',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFF5A6770))),
            ],
          ),
          SizedBox(height: 12 * scale),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                Icons.g_mobiledata_rounded,
                color: Color(0xFFEA4335),
                size: 32,
              ),
              Icon(Icons.facebook, color: Color(0xFF1877F2), size: 26),
              Icon(Icons.apple, color: Colors.black, size: 26),
            ],
          ),
        ],
      ),
    );
  }
}
