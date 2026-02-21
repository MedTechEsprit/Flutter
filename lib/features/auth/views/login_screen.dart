import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  final UserRole? role;

  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authVM = context.read<AuthViewModel>();
    final success = await authVM.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
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
          route = '/';
      }
      Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? 'Erreur de connexion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final roleInfo = _getRoleInfo(authVM.selectedRole);

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
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // Role indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: roleInfo['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(roleInfo['icon'], color: roleInfo['color'], size: 20),
                                const SizedBox(width: 8),
                                Text(roleInfo['label'], style: TextStyle(color: roleInfo['color'], fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('Connexion', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          const Text('Entrez vos identifiants pour continuer', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          const SizedBox(height: 32),
                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'exemple@email.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.softGreen, width: 2),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Email requis' : null,
                          ),
                          const SizedBox(height: 16),
                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.softGreen, width: 2),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Mot de passe requis' : null,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Mot de passe oublié ?', style: TextStyle(color: AppColors.softGreen)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.softGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Separator
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade300)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('ou', style: TextStyle(color: Colors.grey.shade500)),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade300)),
                            ],
                          ),
                          const SizedBox(height: 24),
                        // Register
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              final selectedRole = widget.role ?? authVM.selectedRole;
                              switch (selectedRole) {
                                case UserRole.patient:
                                  Navigator.pushNamed(context, '/register-patient');
                                  break;
                                case UserRole.doctor:
                                  Navigator.pushNamed(context, '/register-medecin');
                                  break;
                                case UserRole.pharmacy:
                                  Navigator.pushNamed(context, '/register-pharmacien');
                                  break;
                                default:
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Veuillez sélectionner un rôle')),
                                  );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Créer un compte', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                          ),
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
      ),
    );
  }

  Map<String, dynamic> _getRoleInfo(UserRole? role) {
    switch (role) {
      case UserRole.patient:
        return {'icon': Icons.person, 'label': 'Patient', 'color': AppColors.softGreen};
      case UserRole.doctor:
        return {'icon': Icons.medical_services, 'label': 'Médecin', 'color': AppColors.lightBlue};
      case UserRole.pharmacy:
        return {'icon': Icons.local_pharmacy, 'label': 'Pharmacien', 'color': AppColors.warmPeach};
      default:
        return {'icon': Icons.person, 'label': 'Utilisateur', 'color': AppColors.softGreen};
    }
  }
}
