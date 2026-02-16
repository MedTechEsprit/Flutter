import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service d'authentification unifié pour tous les rôles
/// Gère le stockage SharedPreferences pour Patient, Médecin et Pharmacien
///
/// Endpoints:
/// - POST /api/auth/register/patient
/// - POST /api/auth/register/medecin
/// - POST /api/auth/register/pharmacien
/// - POST /api/auth/login
class AuthService {
  // Base URL - 10.0.2.2 pour l'émulateur Android (pointe vers localhost)
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _userDataKey = 'user_data';

  // Headers par défaut
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers avec authentification
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ═══════════════════════════════════════════════════════════════
  // LOGIN UNIFIÉ
  // ═══════════════════════════════════════════════════════════════

  /// POST /api/auth/login
  /// Login unifié pour tous les rôles
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = '$baseUrl/auth/login';

    debugPrint('🔐 ========== TENTATIVE DE CONNEXION ==========');
    debugPrint('📍 URL: $url');
    debugPrint('📧 Email: $email');
    debugPrint('🔑 Password length: ${password.length}');

    try {
      final requestBody = jsonEncode({
        'email': email,
        'motDePasse': password,
      });
      debugPrint('📤 Request body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: requestBody,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏰ TIMEOUT: Le serveur ne répond pas après 15 secondes');
          throw Exception('Timeout');
        },
      );

      debugPrint('📥 Status code: ${response.statusCode}');
      debugPrint('📥 Response body length: ${response.body.length} chars');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('🔍 Clés dans la réponse: ${data.keys.toList()}');

        // Extract token and user - supporte 'accessToken' ou 'token'
        final token = (data['accessToken'] ?? data['token']) as String?;
        final user = data['user'] as Map<String, dynamic>?;

        debugPrint('🔑 Token extrait: ${token != null ? "OUI (${token.length} chars)" : "NON"}');
        debugPrint('👤 User extrait: ${user != null ? "OUI" : "NON"}');

        if (token == null || token.isEmpty) {
          debugPrint('❌ ERREUR: Token est null ou vide!');
          return {
            'success': false,
            'message': 'Token non reçu du serveur',
          };
        }

        if (user == null) {
          debugPrint('❌ ERREUR: User est null!');
          return {
            'success': false,
            'message': 'Données utilisateur non reçues',
          };
        }

        final userId = user['_id'] as String?;
        final userRole = user['role'] as String? ?? 'patient';

        debugPrint('✅ CONNEXION RÉUSSIE!');
        debugPrint('👤 User ID: $userId');
        debugPrint('🎭 Role: $userRole');

        // Stockage dans SharedPreferences
        await _storeAuthData(
          token: token,
          userId: userId ?? '',
          role: userRole,
          userData: user,
        );

        return {
          'success': true,
          'token': token,
          'userId': userId,
          'role': userRole,
          'user': user,
          'message': 'Connexion réussie',
        };
      } else if (response.statusCode == 401) {
        debugPrint('❌ ERREUR 401: Identifiants incorrects');
        return {
          'success': false,
          'message': 'Email ou mot de passe incorrect',
        };
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      return _handleException(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // INSCRIPTION PATIENT
  // ═══════════════════════════════════════════════════════════════

  /// POST /api/auth/register/patient
  Future<Map<String, dynamic>> registerPatient({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String dateNaissance,
    required String sexe,
    String? telephone,
    String? adresse,
    String? typeDiabete,
    String? medecinTraitantId,
  }) async {
    debugPrint('📝 ========== REGISTER PATIENT ==========');
    final url = '$baseUrl/auth/register/patient';
    debugPrint('🌐 URL: $url');

    // Mapper le sexe en majuscules comme attendu par l'API
    final sexeAPI = sexe.toUpperCase() == 'HOMME' ? 'HOMME' :
                    sexe.toUpperCase() == 'FEMME' ? 'FEMME' : 'HOMME';

    // Mapper le type de diabète
    String? typeDiabeteAPI;
    if (typeDiabete != null && typeDiabete.isNotEmpty) {
      if (typeDiabete.toLowerCase().contains('type 1')) {
        typeDiabeteAPI = 'TYPE_1';
      } else if (typeDiabete.toLowerCase().contains('type 2')) {
        typeDiabeteAPI = 'TYPE_2';
      } else if (typeDiabete.toLowerCase().contains('gestationnel')) {
        typeDiabeteAPI = 'GESTATIONNEL';
      }
    }

    final body = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': password,
      'dateNaissance': dateNaissance,
      'sexe': sexeAPI,
      if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
      if (typeDiabeteAPI != null) 'typeDiabete': typeDiabeteAPI,
      // Note: adresse n'existe pas dans l'API patient, on l'ignore
    };

    return _performRegistration(url, body, 'patient');
  }

  // ═══════════════════════════════════════════════════════════════
  // INSCRIPTION MÉDECIN
  // ═══════════════════════════════════════════════════════════════

  /// POST /api/auth/register/medecin
  Future<Map<String, dynamic>> registerMedecin({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String specialite,
    required String numeroOrdre,
    String? telephone,
    String? adresseCabinet,
    String? hopital,
  }) async {
    debugPrint('📝 ========== REGISTER MEDECIN ==========');
    final url = '$baseUrl/auth/register/medecin';
    debugPrint('🌐 URL: $url');

    final body = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': password,
      'specialite': specialite,
      'numeroOrdre': numeroOrdre,
      if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
      if (adresseCabinet != null && adresseCabinet.isNotEmpty) 'adresseCabinet': adresseCabinet,
      // Note: hopital n'existe pas dans l'API, on utilise 'clinique' à la place
      if (hopital != null && hopital.isNotEmpty) 'clinique': hopital,
    };

    return _performRegistration(url, body, 'medecin');
  }

  // ═══════════════════════════════════════════════════════════════
  // INSCRIPTION PHARMACIEN
  // ═══════════════════════════════════════════════════════════════

  /// POST /api/auth/register/pharmacien
  Future<Map<String, dynamic>> registerPharmacien({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String nomPharmacie,
    required String numeroOrdre,
    required String telephonePharmacie,
    required String adressePharmacie,
    double? latitude,
    double? longitude,
  }) async {
    debugPrint('📝 ========== REGISTER PHARMACIEN ==========');
    final url = '$baseUrl/auth/register/pharmacien';
    debugPrint('🌐 URL: $url');

    final body = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': password,
      'nomPharmacie': nomPharmacie,
      'numeroOrdre': numeroOrdre,
      'telephonePharmacie': telephonePharmacie,
      'adressePharmacie': adressePharmacie,
      // Note: location peut être géré séparément par le backend via géocodage
      // On n'envoie pas de coordonnées dans l'inscription initiale
    };

    return _performRegistration(url, body, 'pharmacien');
  }

  // ═══════════════════════════════════════════════════════════════
  // GESTION DU STOCKAGE
  // ═══════════════════════════════════════════════════════════════

  /// Stocke les données d'authentification
  Future<void> _storeAuthData({
    required String token,
    required String userId,
    required String role,
    required Map<String, dynamic> userData,
  }) async {
    debugPrint('💾 ========== STOCKAGE AUTH DATA ==========');
    try {
      final prefs = await SharedPreferences.getInstance();

      debugPrint('💾 [1/4] Stockage du TOKEN...');
      await prefs.setString(_tokenKey, token);
      debugPrint('💾 [1/4] ✅ Token stocké');

      debugPrint('💾 [2/4] Stockage de l\'USER ID...');
      await prefs.setString(_userIdKey, userId);
      debugPrint('💾 [2/4] ✅ User ID stocké: $userId');

      debugPrint('💾 [3/4] Stockage du ROLE...');
      await prefs.setString(_userRoleKey, role);
      debugPrint('💾 [3/4] ✅ Role stocké: $role');

      debugPrint('💾 [4/4] Stockage des USER DATA...');
      await prefs.setString(_userDataKey, jsonEncode(userData));
      debugPrint('💾 [4/4] ✅ User data stocké');

      debugPrint('💾 ========== STOCKAGE TERMINÉ ==========');

      // Vérification immédiate
      await _verifyStoredData();
    } catch (e) {
      debugPrint('❌ Erreur de stockage: $e');
      rethrow;
    }
  }

  /// Vérifie que les données sont bien stockées
  Future<void> _verifyStoredData() async {
    debugPrint('🔍 ========== VÉRIFICATION STOCKAGE ==========');
    final prefs = await SharedPreferences.getInstance();

    final storedToken = prefs.getString(_tokenKey);
    final storedId = prefs.getString(_userIdKey);
    final storedRole = prefs.getString(_userRoleKey);

    debugPrint('🔍 Token stocké: ${storedToken != null ? "✅ (${storedToken.length} chars)" : "❌ NULL"}');
    debugPrint('🔍 User ID stocké: ${storedId != null ? "✅ ($storedId)" : "❌ NULL"}');
    debugPrint('🔍 Role stocké: ${storedRole != null ? "✅ ($storedRole)" : "❌ NULL"}');
  }

  /// Déconnexion - efface toutes les données stockées
  Future<void> logout() async {
    debugPrint('🚪 ========== DÉCONNEXION ==========');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userDataKey);
    debugPrint('🚪 ✅ Toutes les données effacées');
  }

  /// Vérifie si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final isLogged = token != null && token.isNotEmpty;
    debugPrint('🔐 isLoggedIn: $isLogged');
    return isLogged;
  }

  /// Récupère le token stocké
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    debugPrint('🔑 getToken: ${token != null ? "FOUND (${token.length} chars)" : "NULL"}');
    return token;
  }

  /// Récupère l'ID utilisateur stocké
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_userIdKey);
    debugPrint('🆔 getUserId: ${id ?? "NULL"}');
    return id;
  }

  /// Récupère le rôle stocké
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_userRoleKey);
    debugPrint('🎭 getRole: ${role ?? "NULL"}');
    return role;
  }

  /// Récupère les données utilisateur stockées
  Future<Map<String, dynamic>?> getStoredUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userDataKey);
    if (data != null && data.isNotEmpty) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('❌ Erreur parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  /// Met à jour les données utilisateur stockées
  Future<void> updateStoredUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
    debugPrint('💾 User data mis à jour');
  }

  // ═══════════════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES
  // ═══════════════════════════════════════════════════════════════

  /// Exécute une inscription
  Future<Map<String, dynamic>> _performRegistration(
    String url,
    Map<String, dynamic> body,
    String role,
  ) async {
    try {
      debugPrint('📤 Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏰ TIMEOUT');
          throw Exception('Timeout');
        },
      );

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Inscription $role réussie!');

        // Si le backend retourne un token et user, stocker automatiquement
        final token = (data['accessToken'] ?? data['token']) as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (token != null && user != null) {
          await _storeAuthData(
            token: token,
            userId: user['_id'] ?? '',
            role: role,
            userData: user,
          );
        }

        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Inscription réussie',
        };
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      debugPrint('❌ Register $role error: $e');
      return _handleException(e);
    }
  }

  /// Gère les réponses d'erreur
  Map<String, dynamic> _handleErrorResponse(http.Response response) {
    debugPrint('�� ERREUR ${response.statusCode}');

    try {
      final body = jsonDecode(response.body);
      String message = 'Une erreur est survenue';

      if (body['message'] is List) {
        message = (body['message'] as List).join(', ');
      } else if (body['message'] is String) {
        message = body['message'];
      }

      switch (response.statusCode) {
        case 400:
          return {'success': false, 'message': message, 'errors': body['errors']};
        case 401:
          return {'success': false, 'message': 'Email ou mot de passe incorrect'};
        case 409:
          return {'success': false, 'message': message.isNotEmpty ? message : 'Cet email est déjà utilisé'};
        case 500:
          return {'success': false, 'message': 'Erreur serveur. Veuillez réessayer plus tard.'};
        default:
          return {'success': false, 'message': message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de communication avec le serveur'};
    }
  }

  /// Gère les exceptions
  Map<String, dynamic> _handleException(dynamic e) {
    String errorMessage;

    if (e.toString().contains('SocketException') ||
        e.toString().contains('Connection refused')) {
      errorMessage = 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré.';
    } else if (e.toString().contains('Timeout')) {
      errorMessage = 'Le serveur ne répond pas (timeout).';
    } else {
      errorMessage = 'Erreur réseau: ${e.toString()}';
    }

    return {
      'success': false,
      'message': errorMessage,
    };
  }
}

