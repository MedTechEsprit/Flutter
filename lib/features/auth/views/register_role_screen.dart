import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';

/// Screen where users select their role BEFORE registration.
/// Login does NOT use this - login auto-detects role from backend.
class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Image.asset('assets/logo/logo_withoutname.png', height: 32),
                    const SizedBox(width: 10),
                    const Text(
                      'Créer un compte',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Je suis un(e) ...',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choisissez votre rôle pour créer votre compte',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _RoleCard(
                        icon: Icons.person,
                        title: 'Patient',
                        subtitle: 'Suivre ma glycémie et consulter mes médecins',
                        color: AppColors.softGreen,
                        onTap: () {
                          context.read<AuthViewModel>().selectRole(UserRole.patient);
                          Navigator.pushNamed(context, '/register-patient');
                        },
                      ),
                      const SizedBox(height: 14),
                      _RoleCard(
                        icon: Icons.medical_services,
                        title: 'Médecin',
                        subtitle: 'Gérer mes patients et suivre leurs données',
                        color: AppColors.lightBlue,
                        onTap: () {
                          context.read<AuthViewModel>().selectRole(UserRole.doctor);
                          Navigator.pushNamed(context, '/register-medecin');
                        },
                      ),
                      const SizedBox(height: 14),
                      _RoleCard(
                        icon: Icons.local_pharmacy,
                        title: 'Pharmacien',
                        subtitle: 'Gérer les demandes de médicaments',
                        color: AppColors.warmPeach,
                        onTap: () {
                          context.read<AuthViewModel>().selectRole(UserRole.pharmacy);
                          Navigator.pushNamed(context, '/register-pharmacien');
                        },
                      ),
                      const SizedBox(height: 32),
                      // Already have an account?
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/login');
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'Déjà un compte ? ',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                              children: const [
                                TextSpan(
                                  text: 'Se connecter',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}
