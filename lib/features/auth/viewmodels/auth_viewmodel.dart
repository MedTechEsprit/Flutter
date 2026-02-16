import 'package:flutter/material.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';
import 'package:diab_care/features/pharmacy/models/pharmacy_api_models.dart';

enum UserRole { patient, doctor, pharmacy }

/// ViewModel d'authentification unifié pour tous les rôles
/// Utilise AuthService avec stockage SharedPreferences
class AuthViewModel extends ChangeNotifier {
  UserRole? _selectedRole;
  bool _isLoggedIn = false;
  String _userName = '';
  String? _userId;
  String? _loginError;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  // Service d'authentification unifié
  final AuthService _authService = AuthService();

  // Profil pharmacie (pour compatibilité avec PharmacyViewModel)
  PharmacyProfile? _pharmacyProfile;

  // Getters
  UserRole? get selectedRole => _selectedRole;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String? get userId => _userId;
  String? get loginError => _loginError;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;
  PharmacyProfile? get pharmacyProfile => _pharmacyProfile;
  AuthService get authService => _authService;

  /// Sélectionne le rôle utilisateur
  void selectRole(UserRole role) {
    _selectedRole = role;
    debugPrint('🎭 Role sélectionné: $role');
    notifyListeners();
  }

  /// Initialise le ViewModel depuis les données stockées
  Future<bool> initialize() async {
    debugPrint('🔄 ========== INITIALISATION AUTH ==========');

    final isLogged = await _authService.isLoggedIn();
    if (!isLogged) {
      debugPrint('❌ Pas de session stockée');
      return false;
    }

    // Récupérer les données stockées
    final storedRole = await _authService.getRole();
    final storedUserId = await _authService.getUserId();
    final storedUserData = await _authService.getStoredUserData();

    if (storedRole != null && storedUserData != null) {
      _isLoggedIn = true;
      _userId = storedUserId;
      _userData = storedUserData;

      // Restaurer le rôle
      switch (storedRole) {
        case 'patient':
          _selectedRole = UserRole.patient;
          break;
        case 'medecin':
        case 'doctor':
          _selectedRole = UserRole.doctor;
          break;
        case 'pharmacien':
        case 'pharmacy':
          _selectedRole = UserRole.pharmacy;
          _pharmacyProfile = PharmacyProfile.fromJson(storedUserData);
          break;
      }

      // Extraire le nom
      _userName = _extractUserName(storedUserData, _selectedRole);

      debugPrint('✅ Session restaurée: $_userName (${_selectedRole?.name})');
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Connexion utilisateur
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _loginError = null;
    notifyListeners();

    debugPrint('🔐 Login avec role: $_selectedRole');

    final result = await _authService.login(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (result['success'] == true) {
      _isLoggedIn = true;
      _userId = result['userId'];
      _userData = result['user'];

      // Extraire le nom utilisateur
      if (_userData != null) {
        _userName = _extractUserName(_userData!, _selectedRole);

        // Si pharmacien, créer le profil pharmacie
        if (_selectedRole == UserRole.pharmacy) {
          _pharmacyProfile = PharmacyProfile.fromJson(_userData!);
        }
      }

      debugPrint('✅ Connexion réussie: $_userName');
      _loginError = null;
      notifyListeners();
      return true;
    } else {
      _loginError = result['message'] as String?;
      debugPrint('❌ Erreur login: $_loginError');
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    debugPrint('🚪 Déconnexion...');
    await _authService.logout();

    _isLoggedIn = false;
    _userName = '';
    _userId = null;
    _selectedRole = null;
    _userData = null;
    _pharmacyProfile = null;
    _loginError = null;

    notifyListeners();
    debugPrint('✅ Déconnexion effectuée');
  }

  /// Efface les erreurs
  void clearError() {
    _loginError = null;
    notifyListeners();
  }

  /// Extrait le nom utilisateur depuis les données
  String _extractUserName(Map<String, dynamic> data, UserRole? role) {
    final prenom = data['prenom'] ?? '';
    final nom = data['nom'] ?? '';

    switch (role) {
      case UserRole.patient:
        final name = '$prenom $nom'.trim();
        return name.isNotEmpty ? name : 'Patient';
      case UserRole.doctor:
        final name = '$prenom $nom'.trim();
        return name.isNotEmpty ? 'Dr. $name' : 'Médecin';
      case UserRole.pharmacy:
        final nomPharmacie = data['nomPharmacie'] ?? '';
        return nomPharmacie.isNotEmpty ? nomPharmacie : 'Pharmacie';
      default:
        return '$prenom $nom'.trim();
    }
  }

  /// Récupère le token (pour les appels API)
  Future<String?> getToken() async {
    return await _authService.getToken();
  }

  /// Récupère l'ID utilisateur
  Future<String?> getUserId() async {
    return await _authService.getUserId();
  }
}

