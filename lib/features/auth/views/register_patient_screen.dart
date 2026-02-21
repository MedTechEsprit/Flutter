import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _diabetesTypeController = TextEditingController();
  final _bloodTypeController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _diabetesTypeController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await _authService.registerPatient({
      'nom': _nameController.text.split(' ').last,
      'prenom': _nameController.text.split(' ').first,
      'name': _nameController.text,
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
      'diabetesType': _diabetesTypeController.text.trim(),
      'bloodType': _bloodTypeController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      if (response.token != null && response.userData != null) {
        await TokenService().saveAuthData(
          token: response.token!,
          userData: response.userData!,
        );
        if (mounted) {
          context.read<AuthViewModel>().selectRole(UserRole.patient);
          await context.read<AuthViewModel>().init();
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription réussie! Bienvenue!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/patient-home', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.errorMessage ?? 'Erreur lors de l\'inscription'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                    const Text(
                      'Inscription Patient',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
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
                          // Name
                          _buildTextField(
                            controller: _nameController,
                            label: 'Nom complet',
                            icon: Icons.person,
                            validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          // Email
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Requis';
                              if (!v!.contains('@')) return 'Email invalide';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Phone
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Téléphone',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          // Password
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Mot de passe',
                            icon: Icons.lock,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Requis';
                              if (v!.length < 6) return 'Minimum 6 caractères';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Age
                          _buildTextField(
                            controller: _ageController,
                            label: 'Âge',
                            icon: Icons.cake,
                            keyboardType: TextInputType.number,
                            validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          // Diabetes Type
                          _buildTextField(
                            controller: _diabetesTypeController,
                            label: 'Type de diabète',
                            icon: Icons.medical_information,
                            validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          // Blood Type
                          _buildTextField(
                            controller: _bloodTypeController,
                            label: 'Groupe sanguin',
                            icon: Icons.water_drop,
                            validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                          ),
                          const SizedBox(height: 32),
                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.softGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('S\'inscrire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.softGreen),
        suffixIcon: suffixIcon,
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
    );
  }
}

