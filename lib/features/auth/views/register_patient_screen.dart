import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _dateNaissance;
  String? _selectedTypeDiabete;
  String? _selectedGroupeSanguin;

  bool _obscurePassword = true;
  bool _isLoading = false;
  final _authService = AuthService();

  // ── Options ───────────────────────────────────────────────────
  static const _typeDiabeteOptions = {
    'TYPE_1': 'Type 1',
    'TYPE_2': 'Type 2',
    'GESTATIONNEL': 'Gestationnel',
    'PRE_DIABETE': 'Pré-diabète',
    'AUTRE': 'Autre',
  };

  static const _groupeSanguinOptions = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDateNaissance() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(now.year - 30),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.softGreen, onPrimary: Colors.white, surface: Colors.white, onSurface: AppColors.textPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate dropdowns
    if (_selectedTypeDiabete == null) {
      _showError('Veuillez sélectionner le type de diabète');
      return;
    }
    if (_selectedGroupeSanguin == null) {
      _showError('Veuillez sélectionner le groupe sanguin');
      return;
    }
    if (_dateNaissance == null) {
      _showError('Veuillez sélectionner la date de naissance');
      return;
    }

    setState(() => _isLoading = true);

    final body = <String, dynamic>{
      'nom': _nomController.text.trim(),
      'prenom': _prenomController.text.trim(),
      'email': _emailController.text.trim(),
      'motDePasse': _passwordController.text,
      'telephone': _telephoneController.text.trim(),
      'dateNaissance': _dateNaissance!.toIso8601String(),
      'typeDiabete': _selectedTypeDiabete,
      'groupeSanguin': _selectedGroupeSanguin,
    };

    debugPrint('📤 REGISTER BODY: $body');

    final response = await _authService.registerPatient(body);

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
        const SnackBar(content: Text('Inscription réussie! Bienvenue!'), backgroundColor: Colors.green),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/medical-profile', (route) => false);
    } else {
      _showError(response.errorMessage ?? 'Erreur lors de l\'inscription');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
                    const Text('Inscription Patient', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // ── Nom ────────────────────────────────
                          _buildTextField(
                            controller: _nomController,
                            label: 'Nom',
                            icon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Prénom ─────────────────────────────
                          _buildTextField(
                            controller: _prenomController,
                            label: 'Prénom',
                            icon: Icons.person,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Le prénom est requis' : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Email ──────────────────────────────
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'L\'email est requis';
                              if (!v.contains('@')) return 'Email invalide';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Téléphone ──────────────────────────
                          _buildTextField(
                            controller: _telephoneController,
                            label: 'Téléphone',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          // ── Mot de passe ───────────────────────
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
                              if (v == null || v.isEmpty) return 'Le mot de passe est requis';
                              if (v.length < 6) return 'Minimum 6 caractères';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Date de naissance ──────────────────
                          GestureDetector(
                            onTap: _pickDateNaissance,
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Date de naissance',
                                  prefixIcon: const Icon(Icons.cake, color: AppColors.softGreen),
                                  suffixIcon: const Icon(Icons.calendar_today, color: AppColors.softGreen),
                                  hintText: _dateNaissance != null
                                      ? DateFormat('dd/MM/yyyy').format(_dateNaissance!)
                                      : 'Sélectionner une date',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.softGreen, width: 2)),
                                ),
                                controller: TextEditingController(
                                  text: _dateNaissance != null ? DateFormat('dd/MM/yyyy').format(_dateNaissance!) : '',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Type de diabète (dropdown) ─────────
                          DropdownButtonFormField<String>(
                            value: _selectedTypeDiabete,
                            decoration: InputDecoration(
                              labelText: 'Type de diabète',
                              prefixIcon: const Icon(Icons.medical_information, color: AppColors.softGreen),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.softGreen, width: 2)),
                            ),
                            items: _typeDiabeteOptions.entries
                                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedTypeDiabete = v),
                            validator: (v) => v == null ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Groupe sanguin (dropdown) ──────────
                          DropdownButtonFormField<String>(
                            value: _selectedGroupeSanguin,
                            decoration: InputDecoration(
                              labelText: 'Groupe sanguin',
                              prefixIcon: const Icon(Icons.water_drop, color: AppColors.softGreen),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.softGreen, width: 2)),
                            ),
                            items: _groupeSanguinOptions
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedGroupeSanguin = v),
                            validator: (v) => v == null ? 'Requis' : null,
                          ),
                          const SizedBox(height: 32),

                          // ── Register Button ────────────────────
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
                          const SizedBox(height: 20),
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

