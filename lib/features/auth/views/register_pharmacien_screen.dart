import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';

/// Écran d'inscription pour les pharmaciens
/// POST /api/auth/register/pharmacien
class RegisterPharmacienScreen extends StatefulWidget {
  const RegisterPharmacienScreen({super.key});

  @override
  State<RegisterPharmacienScreen> createState() => _RegisterPharmacienScreenState();
}

class _RegisterPharmacienScreenState extends State<RegisterPharmacienScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nomPharmacieController = TextEditingController();
  final _numeroOrdreController = TextEditingController();
  final _telephonePharmacieController = TextEditingController();
  final _adressePharmacieController = TextEditingController();

  // State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomPharmacieController.dispose();
    _numeroOrdreController.dispose();
    _telephonePharmacieController.dispose();
    _adressePharmacieController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.registerPharmacien(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nomPharmacie: _nomPharmacieController.text.trim(),
      numeroOrdre: _numeroOrdreController.text.trim(),
      telephonePharmacie: _telephonePharmacieController.text.trim(),
      adressePharmacie: _adressePharmacieController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Compte créé avec succès! Vous pouvez maintenant vous connecter.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _errorMessage = result['message']);
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
              _buildAppBar(),
              Expanded(
                child: Container(
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
                          const SizedBox(height: 10),
                          _buildRoleIndicator(),
                          const SizedBox(height: 24),
                          const Text(
                            'Créer un compte',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Remplissez le formulaire pour vous inscrire',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),

                          if (_errorMessage != null) _buildErrorMessage(),

                          // Informations personnelles
                          _buildSectionTitle('Informations personnelles'),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(child: _buildTextField(_nomController, 'Nom', Icons.person)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField(_prenomController, 'Prénom', Icons.person_outline)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(_emailController, 'Email', Icons.email, isEmail: true),
                          const SizedBox(height: 24),

                          // Informations de la pharmacie
                          _buildSectionTitle('Informations de la pharmacie'),
                          const SizedBox(height: 16),

                          _buildTextField(_nomPharmacieController, 'Nom de la pharmacie', Icons.local_pharmacy),
                          const SizedBox(height: 16),

                          _buildTextField(_numeroOrdreController, 'Numéro d\'ordre', Icons.badge),
                          const SizedBox(height: 16),

                          _buildTextField(_telephonePharmacieController, 'Téléphone de la pharmacie', Icons.phone),
                          const SizedBox(height: 16),

                          _buildTextField(_adressePharmacieController, 'Adresse de la pharmacie', Icons.location_on),
                          const SizedBox(height: 24),

                          // Sécurité
                          _buildSectionTitle('Sécurité'),
                          const SizedBox(height: 16),

                          _buildPasswordField(_passwordController, 'Mot de passe', _obscurePassword, () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          }),
                          const SizedBox(height: 16),

                          _buildPasswordField(_confirmPasswordController, 'Confirmer le mot de passe', _obscureConfirmPassword, () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          }),
                          const SizedBox(height: 32),

                          _buildSubmitButton(),
                          const SizedBox(height: 16),

                          _buildLoginLink(),
                          const SizedBox(height: 24),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            'Inscription Pharmacien',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildRoleIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warmPeach.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_pharmacy, color: AppColors.warmPeach, size: 20),
          SizedBox(width: 8),
          Text('Pharmacien', style: TextStyle(color: AppColors.warmPeach, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isEmail = false,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.warmPeach, width: 2),
        ),
      ),
      validator: (value) {
        if (!isRequired) return null;
        if (value == null || value.isEmpty) return 'Ce champ est requis';
        if (isEmail && !value.contains('@')) return 'Email invalide';
        return null;
      },
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool obscure,
    VoidCallback toggle,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.warmPeach, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ce champ est requis';
        if (value.length < 6) return 'Minimum 6 caractères';
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmPeach,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text("S'inscrire", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Déjà un compte? ', style: TextStyle(color: AppColors.textSecondary)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Se connecter',
            style: TextStyle(color: AppColors.warmPeach, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

