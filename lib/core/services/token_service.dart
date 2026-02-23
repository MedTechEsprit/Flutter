// Token Service for centralized JWT token management
// Location: lib/core/services/token_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for managing JWT tokens and user session data.
/// Use this service throughout the app to access authentication state.
class TokenService {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _userDataKey = 'user_data';

  // Singleton instance
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  // Cached values for quick access
  String? _cachedToken;
  String? _cachedUserId;
  String? _cachedUserRole;
  Map<String, dynamic>? _cachedUserData;

  /// Initialize the service - call this in main.dart before runApp
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    _cachedUserId = prefs.getString(_userIdKey);
    _cachedUserRole = prefs.getString(_userRoleKey);

    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      _cachedUserData = jsonDecode(userDataString);
    }
  }

  /// Get the current JWT token
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  /// Get token synchronously (only if already cached)
  String? get token => _cachedToken;

  /// Get the current user ID
  Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;

    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getString(_userIdKey);
    return _cachedUserId;
  }

  /// Get user ID synchronously (only if already cached)
  String? get userId => _cachedUserId;

  /// Get the current user role
  Future<String?> getUserRole() async {
    if (_cachedUserRole != null) return _cachedUserRole;

    final prefs = await SharedPreferences.getInstance();
    _cachedUserRole = prefs.getString(_userRoleKey);
    return _cachedUserRole;
  }

  /// Get user role synchronously (only if already cached)
  String? get userRole => _cachedUserRole;

  /// Get the full user data
  Future<Map<String, dynamic>?> getUserData() async {
    if (_cachedUserData != null) return _cachedUserData;

    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      _cachedUserData = jsonDecode(userDataString);
    }
    return _cachedUserData;
  }

  /// Get user data synchronously (only if already cached)
  Map<String, dynamic>? get userData => _cachedUserData;

  /// Save authentication data after login
  Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Extract user ID and role from userData
    final userId = userData['_id']?.toString() ?? userData['id']?.toString();
    final userRole = userData['role']?.toString();

    // Save to SharedPreferences
    await prefs.setString(_tokenKey, token);
    if (userId != null) await prefs.setString(_userIdKey, userId);
    if (userRole != null) await prefs.setString(_userRoleKey, userRole);
    await prefs.setString(_userDataKey, jsonEncode(userData));

    // Update cache
    _cachedToken = token;
    _cachedUserId = userId;
    _cachedUserRole = userRole;
    _cachedUserData = userData;
  }

  /// Clear all authentication data (logout)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userDataKey);

    // Clear cache
    _cachedToken = null;
    _cachedUserId = null;
    _cachedUserRole = null;
    _cachedUserData = null;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if user is logged in (synchronous, uses cache)
  bool get isLoggedInSync => _cachedToken != null && _cachedToken!.isNotEmpty;

  /// Get patient ID (helper for patient role)
  Future<String?> getPatientId() async {
    final data = await getUserData();
    // The patient ID might be stored differently depending on your backend
    return data?['patientId']?.toString() ??
           data?['_id']?.toString() ??
           data?['id']?.toString();
  }

  /// Get doctor ID (helper for doctor/medecin role)
  Future<String?> getDoctorId() async {
    final data = await getUserData();
    // The doctor ID might be stored differently depending on your backend
    return data?['medecinId']?.toString() ??
           data?['doctorId']?.toString() ??
           data?['_id']?.toString() ??
           data?['id']?.toString();
  }
}

