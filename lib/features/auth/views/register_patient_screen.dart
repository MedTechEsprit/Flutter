import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:diab_care/features/pharmacy/views/pharmacy_location_picker_screen.dart';
import 'package:diab_care/core/services/walkthrough_service.dart';
import 'package:diab_care/features/auth/views/widgets/auth_form_styles.dart';

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
  final _locationController = TextEditingController();

  DateTime? _dateNaissance;
  String? _selectedTypeDiabete;
  String? _selectedGroupeSanguin;
  double? _latitude;
  double? _longitude;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLocating = false;
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
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.softGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
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
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
      if (_latitude != null && _longitude != null)
        'location': {
          'type': 'Point',
          'coordinates': [_longitude, _latitude],
        },
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
          await WalkthroughService.instance.markPendingAfterRegistration(
            AppUserRole.patient,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription réussie! Bienvenue!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/medical-profile',
        (route) => false,
      );
    } else {
      _showError(response.errorMessage ?? 'Erreur lors de l\'inscription');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _choosePatientLocation() async {
    if (_isLocating) return;

    final initial = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(36.8065, 10.1815);

    final picked = await Navigator.push<PharmacyLocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PharmacyLocationPickerScreen(
          initialLocation: initial,
          title: 'Choisir votre position',
          showAutoButton: false,
          confirmButtonLabel: 'Valider ma position',
          markerTitle: 'Votre position',
          positionLabel: 'Lat',
        ),
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _latitude = picked.latitude;
      _longitude = picked.longitude;
    });

    await _fillAddressFromCoordinates(
      latitude: picked.latitude,
      longitude: picked.longitude,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Position patient enregistrée.'),
        backgroundColor: AppColors.softGreen,
      ),
    );
  }

  Future<void> _fillAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 8));
      if (placemarks.isEmpty) return;

      final place = placemarks.first;
      final parts = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
        place.country,
      ].where((p) => p != null && p!.trim().isNotEmpty).map((p) => p!.trim());

      final address = parts.join(', ');
      if (address.isEmpty || !mounted) return;

      setState(() {
        _locationController.text = address;
      });
    } catch (_) {
      // Manual selection still works without reverse geocoding.
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
              AuthFormStyles.header(context, 'Inscription Patient'),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: AuthFormStyles.sheetDecoration,
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
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Le nom est requis'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Prénom ─────────────────────────────
                          _buildTextField(
                            controller: _prenomController,
                            label: 'Prénom',
                            icon: Icons.person,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Le prénom est requis'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Email ──────────────────────────────
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'L\'email est requis';
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
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Le mot de passe est requis';
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
                                decoration: AuthFormStyles.inputDecoration(
                                  label: 'Date de naissance',
                                  icon: Icons.cake,
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    color: AppColors.softGreen,
                                  ),
                                  hintText: _dateNaissance != null
                                      ? DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_dateNaissance!)
                                      : 'Sélectionner une date',
                                ),
                                controller: TextEditingController(
                                  text: _dateNaissance != null
                                      ? DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_dateNaissance!)
                                      : '',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Type de diabète (dropdown) ─────────
                          DropdownButtonFormField<String>(
                            value: _selectedTypeDiabete,
                            decoration: AuthFormStyles.inputDecoration(
                              label: 'Type de diabète',
                              icon: Icons.medical_information,
                            ),
                            items: _typeDiabeteOptions.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedTypeDiabete = v),
                            validator: (v) => v == null ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Groupe sanguin (dropdown) ──────────
                          DropdownButtonFormField<String>(
                            value: _selectedGroupeSanguin,
                            decoration: AuthFormStyles.inputDecoration(
                              label: 'Groupe sanguin',
                              icon: Icons.water_drop,
                            ),
                            items: _groupeSanguinOptions
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedGroupeSanguin = v),
                            validator: (v) => v == null ? 'Requis' : null,
                          ),
                          const SizedBox(height: 32),

                          _buildTextField(
                            controller: _locationController,
                            label: 'Localisation',
                            icon: Icons.location_on,
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.softGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.softGreen.withOpacity(0.18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Votre position de proximité',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Choisissez votre position manuellement sur la carte.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLocating
                                        ? null
                                        : _choosePatientLocation,
                                    icon: const Icon(Icons.map_rounded),
                                    label: const Text('Choisir sur la carte'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.softGreen,
                                      side: const BorderSide(
                                        color: AppColors.softGreen,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _latitude != null && _longitude != null
                                      ? 'Position enregistrée (${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)})'
                                      : 'Position non définie pour le moment.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Register Button ────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: AuthFormStyles.primaryButtonStyle,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'S\'inscrire',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      obscureText: obscureText,
      validator: validator,
      decoration: AuthFormStyles.inputDecoration(
        label: label,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
