import 'package:flutter/material.dart';

enum UserRole { patient, doctor, pharmacy }

class AuthViewModel extends ChangeNotifier {
  UserRole? _selectedRole;
  bool _isLoggedIn = false;
  String _userName = '';

  UserRole? get selectedRole => _selectedRole;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;

  void selectRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _isLoggedIn = true;
    switch (_selectedRole) {
      case UserRole.patient:
        _userName = 'Ahmed Benali';
        break;
      case UserRole.doctor:
        _userName = 'Dr. Sarah Johnson';
        break;
      case UserRole.pharmacy:
        _userName = 'Pharmacie Centrale';
        break;
      default:
        _userName = 'Utilisateur';
    }
    notifyListeners();
    return true;
  }

  void logout() {
    _isLoggedIn = false;
    _selectedRole = null;
    _userName = '';
    notifyListeners();
  }
}
