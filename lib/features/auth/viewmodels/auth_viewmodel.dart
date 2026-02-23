import 'package:flutter/material.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';

enum UserRole { patient, doctor, pharmacy }

class AuthViewModel extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final AuthService _authService = AuthService();

  UserRole? _selectedRole;
  bool _isLoggedIn = false;
  String _userName = '';
  String? _userId;
  String? _errorMessage;
  bool _isLoading = false;

  UserRole? get selectedRole => _selectedRole;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  /// Initialize the ViewModel - call this on app start
  Future<void> init() async {
    await _tokenService.init();

    if (_tokenService.isLoggedInSync) {
      _isLoggedIn = true;
      final userData = _tokenService.userData;
      if (userData != null) {
        _userName = _extractUserName(userData);
        _userId = userData['_id']?.toString() ?? userData['id']?.toString();
        _selectedRole = _parseRole(userData['role']?.toString());
      }
      notifyListeners();
    }
  }

  void selectRole(UserRole role) {
    _selectedRole = role;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);

      if (response.success && response.token != null && response.userData != null) {
        // Save token and user data
        await _tokenService.saveAuthData(
          token: response.token!,
          userData: response.userData!,
        );

        _isLoggedIn = true;
        _userName = _extractUserName(response.userData!);
        _userId = response.userData!['_id']?.toString() ??
                  response.userData!['id']?.toString();
        // Auto-detect role from backend response
        _selectedRole = _parseRole(response.userData!['role']?.toString());
        _errorMessage = null;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.errorMessage ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenService.clearAuthData();
    _isLoggedIn = false;
    _selectedRole = null;
    _userName = '';
    _userId = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Get current user's patient ID (for patient role)
  Future<String?> getPatientId() async {
    return await _tokenService.getPatientId();
  }

  /// Get current user's doctor ID (for doctor role)
  Future<String?> getDoctorId() async {
    return await _tokenService.getDoctorId();
  }

  /// Get current JWT token
  Future<String?> getToken() async {
    return await _tokenService.getToken();
  }

  String _extractUserName(Map<String, dynamic> userData) {
    // Try different field combinations based on your backend response
    final nom = userData['nom'] ?? '';
    final prenom = userData['prenom'] ?? '';
    final name = userData['name'] ?? '';
    final fullName = userData['fullName'] ?? '';

    if (fullName.isNotEmpty) return fullName;
    if (name.isNotEmpty) return name;
    if (nom.isNotEmpty || prenom.isNotEmpty) return '$prenom $nom'.trim();
    return userData['email'] ?? 'User';
  }

  UserRole? _parseRole(String? role) {
    if (role == null) return null;
    switch (role.toLowerCase()) {
      case 'patient':
        return UserRole.patient;
      case 'medecin':
      case 'doctor':
        return UserRole.doctor;
      case 'pharmacien':
      case 'pharmacy':
        return UserRole.pharmacy;
      default:
        return null;
    }
  }
}
