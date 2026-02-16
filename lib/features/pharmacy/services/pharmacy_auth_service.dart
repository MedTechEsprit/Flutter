import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/features/pharmacy/models/pharmacy_api_models.dart';

/// Service d'authentification pour la pharmacie
/// Utilise SharedPreferences (plus fiable sur émulateur) au lieu de FlutterSecureStorage
class PharmacyAuthService {
  // Storage keys
  static const String _tokenKey = 'pharmacy_token';
  static const String _pharmacyIdKey = 'pharmacy_id';
  static const String _pharmacyDataKey = 'pharmacy_data';

  /// Login pharmacy user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.login}';

    debugPrint('🔐 ========== TENTATIVE DE CONNEXION PHARMACIE ==========');
    debugPrint('📍 URL: $url');
    debugPrint('📧 Email: $email');
    debugPrint('🔑 Password length: ${password.length}');

    try {
      final requestBody = jsonEncode({
        'email': email,
        'password': password,
      });
      debugPrint('📤 Request body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
        body: requestBody,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏰ TIMEOUT: Le serveur ne répond pas après 15 secondes');
          throw Exception('Timeout');
        },
      );

      debugPrint('📥 Status code: ${response.statusCode}');
      // Ne pas printer le body complet car il est trop long
      debugPrint('📥 Response body length: ${response.body.length} chars');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        debugPrint('🔍 Clés dans la réponse: ${data.keys.toList()}');

        // Extract token and pharmacy ID - IMPORTANT: c'est 'accessToken' pas 'access_token'
        final token = data['accessToken'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        debugPrint('🔑 Token extrait: ${token != null ? "OUI" : "NON"}');
        if (token != null) {
          debugPrint('🔑 Token length: ${token.length} chars');
          debugPrint('🔑 Token start: ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
        }
        debugPrint('👤 User extrait: ${user != null ? "OUI" : "NON"}');

        if (token == null || token.isEmpty) {
          debugPrint('❌ ERREUR CRITIQUE: Token est null ou vide!');
          return {
            'success': false,
            'message': 'Token non reçu du serveur',
          };
        }

        if (user == null) {
          debugPrint('❌ ERREUR CRITIQUE: User est null!');
          return {
            'success': false,
            'message': 'Données utilisateur non reçues',
          };
        }

        final pharmacyId = user['_id'] as String?;

        debugPrint('✅ CONNEXION RÉUSSIE! Pharmacy ID: $pharmacyId');

        // Store using SharedPreferences (plus fiable sur émulateur)
        debugPrint('💾💾💾 DÉBUT DU STOCKAGE 💾💾💾');
        try {
          debugPrint('💾 [1/4] Obtention de SharedPreferences...');
          final prefs = await SharedPreferences.getInstance();
          debugPrint('💾 [1/4] ✅ SharedPreferences obtenu');

          debugPrint('💾 [2/4] Stockage du TOKEN (key: $_tokenKey, length: ${token.length})...');
          final resultToken = await prefs.setString(_tokenKey, token);
          debugPrint('💾 [2/4] ${resultToken ? "✅" : "❌"} Token stocké: $resultToken');

          debugPrint('💾 [3/4] Stockage de l\'ID (key: $_pharmacyIdKey, value: $pharmacyId)...');
          final resultId = await prefs.setString(_pharmacyIdKey, pharmacyId ?? '');
          debugPrint('💾 [3/4] ${resultId ? "✅" : "❌"} ID stocké: $resultId');

          debugPrint('💾 [4/4] Stockage des données user...');
          final resultUser = await prefs.setString(_pharmacyDataKey, jsonEncode(user));
          debugPrint('💾 [4/4] ${resultUser ? "✅" : "❌"} User stocké: $resultUser');

          debugPrint('💾💾💾 FIN DU STOCKAGE 💾💾💾');
        } catch (storageError, stackTrace) {
          debugPrint('❌❌❌ ERREUR STOCKAGE: $storageError');
          debugPrint('❌ Stack: $stackTrace');
          return {
            'success': false,
            'message': 'Erreur de stockage: $storageError',
          };
        }

        // Vérification immédiate
        debugPrint('🔍🔍🔍 VÉRIFICATION IMMÉDIATE 🔍🔍🔍');
        try {
          final prefs = await SharedPreferences.getInstance();
          final storedToken = prefs.getString(_tokenKey);
          final storedId = prefs.getString(_pharmacyIdKey);

          debugPrint('🔍 Token stocké? ${storedToken != null ? "OUI" : "NON"}');
          if (storedToken != null) {
            debugPrint('🔍 Token length: ${storedToken.length} chars');
            debugPrint('🔍 Token identique? ${storedToken == token}');
          }

          debugPrint('🔍 ID stocké? ${storedId != null ? "OUI" : "NON"}');
          if (storedId != null) {
            debugPrint('🔍 ID value: $storedId');
            debugPrint('🔍 ID identique? ${storedId == pharmacyId}');
          }
        } catch (e) {
          debugPrint('❌ Erreur lors de la vérification: $e');
        }

        return {
          'success': true,
          'token': token,
          'pharmacyId': pharmacyId,
          'user': PharmacyProfile.fromJson(user),
        };
      } else if (response.statusCode == 401) {
        debugPrint('❌ ERREUR 401: Identifiants incorrects');
        return {
          'success': false,
          'message': 'Email ou mot de passe incorrect',
        };
      } else {
        debugPrint('❌ ERREUR SERVEUR: ${response.statusCode}');
        final error = jsonDecode(response.body);
        String message = 'Erreur de connexion';
        if (error['message'] is List) {
          message = (error['message'] as List).join(', ');
        } else if (error['message'] is String) {
          message = error['message'];
        }
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION: $e');
      debugPrint('📚 Stack trace: $stackTrace');

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

  /// Logout user - clears all stored data
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_pharmacyIdKey);
    await prefs.remove(_pharmacyDataKey);
    debugPrint('🚪 Déconnexion effectuée');
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final isLogged = token != null && token.isNotEmpty;
    debugPrint('🔐 isLoggedIn check: $isLogged (token: ${token != null ? "${token.length} chars" : "null"})');
    return isLogged;
  }

  /// Get stored JWT token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    debugPrint('🔑 getToken called: ${token != null ? "FOUND (${token.length} chars)" : "NULL"}');
    return token;
  }

  /// Get stored pharmacy ID
  Future<String?> getPharmacyId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_pharmacyIdKey);
    debugPrint('🆔 getPharmacyId called: ${id ?? "NULL"}');
    return id;
  }

  /// Get stored pharmacy profile
  Future<PharmacyProfile?> getStoredProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_pharmacyDataKey);
    if (data != null && data.isNotEmpty) {
      try {
        return PharmacyProfile.fromJson(jsonDecode(data));
      } catch (e) {
        debugPrint('Erreur parsing profil: $e');
        return null;
      }
    }
    return null;
  }

  /// Update stored pharmacy profile
  Future<void> updateStoredProfile(PharmacyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pharmacyDataKey,
      jsonEncode({
        '_id': profile.id,
        'nom': profile.nom,
        'prenom': profile.prenom,
        'email': profile.email,
        'role': profile.role,
        'nomPharmacie': profile.nomPharmacie,
        'numeroOrdre': profile.numeroOrdre,
        'telephonePharmacie': profile.telephonePharmacie,
        'adressePharmacie': profile.adressePharmacie,
        'statutCompte': profile.statutCompte,
      }),
    );
  }
}

