import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';

class AuthResponse {
  final bool success;
  final String? token;
  final Map<String, dynamic>? userData;
  final String? errorMessage;

  AuthResponse({
    required this.success,
    this.token,
    this.userData,
    this.errorMessage,
  });
}

class AuthService {
  // Android Emulator: 10.0.2.2 = host machine's localhost
  // Change port to match your NestJS backend port
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const Duration _timeout = Duration(seconds: 10);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'motDePasse': password, // Backend expects French field name
          // Note: role is not sent - backend determines it from user data
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AuthResponse(
          success: true,
          token: data['accessToken'] ?? data['token'] ?? data['access_token'],
          userData: data['user'] ?? data['data'],
        );
      } else if (response.statusCode == 401) {
        return AuthResponse(
          success: false,
          errorMessage: 'Email ou mot de passe incorrect',
        );
      } else {
        final data = jsonDecode(response.body);
        return AuthResponse(
          success: false,
          errorMessage: _extractErrorMessage(data),
        );
      }
    } on SocketException {
      return AuthResponse(
        success: false,
        errorMessage: 'Serveur inaccessible. Vérifiez que le backend tourne sur le port 3000.',
      );
    } on TimeoutException {
      return AuthResponse(
        success: false,
        errorMessage: 'Délai dépassé. Le serveur ne répond pas.',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        errorMessage: 'Erreur: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> registerPatient(Map<String, dynamic> data) async {
    return _register('patient', data);
  }

  Future<AuthResponse> registerMedecin(Map<String, dynamic> data) async {
    return _register('medecin', data);
  }

  Future<AuthResponse> registerPharmacien(Map<String, dynamic> data) async {
    return _register('pharmacien', data);
  }

  Future<AuthResponse> _register(String role, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register/$role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return AuthResponse(
          success: true,
          token: responseData['accessToken'] ?? responseData['token'] ?? responseData['access_token'],
          userData: responseData['user'] ?? responseData['data'],
        );
      } else {
        final responseData = jsonDecode(response.body);
        return AuthResponse(
          success: false,
          errorMessage: _extractErrorMessage(responseData),
        );
      }
    } on SocketException {
      return AuthResponse(
        success: false,
        errorMessage: 'Serveur inaccessible. Vérifiez que le backend tourne sur le port 3000.',
      );
    } on TimeoutException {
      return AuthResponse(
        success: false,
        errorMessage: 'Délai dépassé (10s). Le serveur ne répond pas.',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        errorMessage: 'Erreur: ${e.toString()}',
      );
    }
  }

  final TokenService _tokenService = TokenService();

  /// Get the stored JWT token
  Future<String?> getToken() async {
    return await _tokenService.getToken();
  }

  /// Update stored user data after profile update
  Future<void> updateStoredUserData(Map<String, dynamic> updatedData) async {
    final token = await _tokenService.getToken();
    if (token != null) {
      await _tokenService.saveAuthData(token: token, userData: updatedData);
    }
  }

  /// Extract error message from NestJS response (handles both String and List<String>)
  String _extractErrorMessage(Map<String, dynamic> responseData) {
    final message = responseData['message'];
    final error = responseData['error'];

    // NestJS validation errors return message as List<String>
    if (message is List) {
      return message.join(', ');
    } else if (message is String) {
      return message;
    } else if (error is String) {
      return error;
    }
    return 'Erreur lors de l\'opération';
  }

  // ignore: unused_element
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return 'patient';
      case UserRole.doctor:
        return 'medecin';
      case UserRole.pharmacy:
        return 'pharmacien';
    }
  }
}

