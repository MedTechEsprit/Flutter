import 'package:flutter/material.dart';
import 'package:diab_care/features/pharmacy/services/pharmacy_auth_service.dart';
import 'package:diab_care/features/pharmacy/models/pharmacy_api_models.dart';

enum UserRole { patient, doctor, pharmacy }

class AuthViewModel extends ChangeNotifier {
  UserRole? _selectedRole;
  bool _isLoggedIn = false;
  String _userName = '';
  String? _loginError;
  bool _isLoading = false;

  // Service d'authentification pharmacie
  final PharmacyAuthService _pharmacyAuthService = PharmacyAuthService();
  PharmacyProfile? _pharmacyProfile;

  // Getters
  UserRole? get selectedRole => _selectedRole;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String? get loginError => _loginError;
  bool get isLoading => _isLoading;
  PharmacyProfile? get pharmacyProfile => _pharmacyProfile;

  void selectRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _loginError = null;
    notifyListeners();

    // Si le rôle est pharmacie, utiliser l'API réelle
    if (_selectedRole == UserRole.pharmacy) {
      final result = await _pharmacyAuthService.login(
        email: email,
        password: password,
      );

      _isLoading = false;

      if (result['success'] == true) {
        _isLoggedIn = true;
        _pharmacyProfile = result['user'] as PharmacyProfile?;
        _userName = _pharmacyProfile?.nomPharmacie ?? 'Pharmacie';
        _loginError = null;
        notifyListeners();
        return true;
      } else {
        _loginError = result['message'] as String?;
        notifyListeners();
        return false;
      }
    }

    // Pour les autres rôles (patient, doctor), garder le comportement mock existant
    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;

    // Mock login - accepter n'importe quel email/password pour demo
    if (email.isNotEmpty && password.isNotEmpty) {
      _isLoggedIn = true;
      switch (_selectedRole) {
        case UserRole.patient:
          _userName = 'Ahmed Benali';
          break;
        case UserRole.doctor:
          _userName = 'Dr. Sarah Martin';
          break;
        case UserRole.pharmacy:
          _userName = 'Pharmacie Centrale';
          break;
        default:
          _userName = 'Utilisateur';
      }
      notifyListeners();
      return true;
    } else {
      _loginError = 'Email ou mot de passe incorrect';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isLoggedIn = false;
    _userName = '';
    _selectedRole = null;
    _pharmacyProfile = null;
    notifyListeners();
  }

  void clearError() {
    _loginError = null;
    notifyListeners();
  }
}

