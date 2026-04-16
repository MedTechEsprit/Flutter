import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';

class RegisterPharmacienScreen extends StatefulWidget {
  const RegisterPharmacienScreen({super.key});

  @override
  State<RegisterPharmacienScreen> createState() =>
      _RegisterPharmacienScreenState();
}

class _RegisterPharmacienScreenState extends State<RegisterPharmacienScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pharmacyNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  bool _obscurePassword = true;
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _pharmacyNameController.dispose();
    _licenseController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez scanner la localisation de la pharmacie avant de continuer.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Split full name into first and last name
    final nameParts = _nameController.text.trim().split(' ');
    final prenom = nameParts.isNotEmpty ? nameParts.first : '';
    final nom = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final response = await _authService.registerPharmacien({
      'nom': nom.isEmpty ? _nameController.text.trim() : nom,
      'prenom': prenom,
      'email': _emailController.text.trim(),
      'telephone': _phoneController.text.trim(),
      'motDePasse': _passwordController.text,
      'nomPharmacie': _pharmacyNameController.text.trim(),
      'numeroOrdre': _licenseController.text.trim(),
      'adressePharmacie': _addressController.text.trim(),
      // Optional fields with default values
      'photoProfil': '',
      'horaires': {
        'lundi': '08:00-19:00',
        'mardi': '08:00-19:00',
        'mercredi': '08:00-19:00',
        'jeudi': '08:00-19:00',
        'vendredi': '08:00-19:00',
        'samedi': '09:00-13:00',
      },
      'telephonePharmacie': _phoneController.text.trim(),
      'servicesProposes': ['Conseil en diabétologie'],
      'listeMedicamentsDisponibles': [],
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
          context.read<AuthViewModel>().selectRole(UserRole.pharmacy);
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
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/pharmacy-home',
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.errorMessage ?? 'Erreur lors de l\'inscription',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _scanPharmacyLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez activer la localisation sur votre appareil.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission de localisation refusée. Autorisez-la puis réessayez.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 12));
      } on TimeoutException {
        // Fallback for devices where fresh GPS fix takes too long.
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d\'obtenir la localisation rapidement. Vérifiez GPS/réseau et réessayez.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _latitude = position!.latitude;
        _longitude = position.longitude;
      });

      await _fillAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Localisation capturée avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de localisation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
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
      if (address.isEmpty) return;

      if (!mounted) return;
      setState(() {
        _addressController.text = address;
      });
    } catch (_) {
      // If reverse geocoding fails, keep manual entry.
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
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Inscription Pharmacien',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
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
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Requis' : null,
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
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          // Password
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
                              if (v?.isEmpty ?? true) return 'Requis';
                              if (v!.length < 6) return 'Minimum 6 caractères';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Pharmacy Name
                          _buildTextField(
                            controller: _pharmacyNameController,
                            label: 'Nom de la pharmacie',
                            icon: Icons.local_pharmacy,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          // License
                          _buildTextField(
                            controller: _licenseController,
                            label: 'Numéro de licence',
                            icon: Icons.card_membership,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          // Address
                          _buildTextField(
                            controller: _addressController,
                            label: 'Adresse',
                            icon: Icons.location_on,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Requis' : null,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLocating
                                  ? null
                                  : _scanPharmacyLocation,
                              icon: _isLocating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _latitude != null && _longitude != null
                                          ? Icons.check_circle_outline
                                          : Icons.my_location,
                                    ),
                              label: Text(
                                _latitude != null && _longitude != null
                                    ? 'Localisation capturée (${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)})'
                                    : 'Scanner la localisation de la pharmacie',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warmPeach,
                                side: const BorderSide(
                                  color: AppColors.warmPeach,
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
                          const SizedBox(height: 32),
                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warmPeach,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
        prefixIcon: Icon(icon, color: AppColors.warmPeach),
        suffixIcon: suffixIcon,
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
    );
  }
}
