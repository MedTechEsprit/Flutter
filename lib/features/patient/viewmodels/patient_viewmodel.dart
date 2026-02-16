import 'package:flutter/material.dart';
import 'package:diab_care/data/models/user_model.dart';
import 'package:diab_care/data/models/message_model.dart';
import 'package:diab_care/features/patient/services/patient_api_service.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';

class PatientViewModel extends ChangeNotifier {
  PatientModel? _patient;
  List<DoctorModel> _doctors = [];
  List<PharmacyUserModel> _pharmacies = [];
  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  String? _error;

  final PatientApiService _apiService = PatientApiService();
  final AuthService _authService = AuthService();

  PatientModel? get patient => _patient;
  List<DoctorModel> get doctors => _doctors;
  List<PharmacyUserModel> get pharmacies => _pharmacies;
  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charge toutes les données patient depuis l'API
  Future<void> loadPatientData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Charger le profil patient
      final profileResult = await _apiService.getProfile();
      if (profileResult['success'] == true && profileResult['data'] != null) {
        _patient = PatientModel.fromJson(profileResult['data']);
        debugPrint('✅ Profil patient chargé: ${_patient?.name}');
      } else {
        debugPrint('⚠️ Profil non chargé: ${profileResult['message']}');
      }

      // Charger les médecins
      final doctorsResult = await _apiService.getMedecins();
      if (doctorsResult['success'] == true && doctorsResult['data'] != null) {
        final List<dynamic> doctorsList = doctorsResult['data'] is List
            ? doctorsResult['data']
            : (doctorsResult['data']['data'] ?? []);
        _doctors = doctorsList
            .map((json) => DoctorModel.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ ${_doctors.length} médecins chargés');
      }

      // Charger les pharmacies
      final pharmaciesResult = await _apiService.getPharmacies();
      if (pharmaciesResult['success'] == true && pharmaciesResult['data'] != null) {
        final List<dynamic> pharmaciesList = pharmaciesResult['data'] is List
            ? pharmaciesResult['data']
            : (pharmaciesResult['data']['data'] ?? []);
        _pharmacies = pharmaciesList
            .map((json) => PharmacyUserModel.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ ${_pharmacies.length} pharmacies chargées');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur loadPatientData: $e');
      _error = 'Erreur de chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour le profil patient
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return false;

      final result = await _apiService.updatePatient(userId, data);
      if (result['success'] == true) {
        // Recharger le profil
        await loadPatientData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur updateProfile: $e');
      return false;
    }
  }

  List<MessageModel> getMessages(String conversationId) {
    // TODO: Implémenter avec API de messagerie quand disponible
    return [];
  }

  List<Map<String, dynamic>> getRecommendations(double glucose) {
    // Recommandations basées sur la valeur de glucose
    final List<Map<String, dynamic>> recommendations = [];

    if (glucose < 70) {
      recommendations.add({
        'title': 'Hypoglycémie détectée',
        'description': 'Prenez 15g de glucides rapides (jus de fruits, sucre).',
        'icon': Icons.warning,
        'color': Colors.red,
      });
    } else if (glucose > 180) {
      recommendations.add({
        'title': 'Glycémie élevée',
        'description': 'Buvez de l\'eau et faites une activité physique légère.',
        'icon': Icons.trending_up,
        'color': Colors.orange,
      });
    } else {
      recommendations.add({
        'title': 'Glycémie normale',
        'description': 'Continuez vos bonnes habitudes !',
        'icon': Icons.check_circle,
        'color': Colors.green,
      });
    }

    return recommendations;
  }

  void sendMessage(String conversationId, String content) {
    // TODO: Implémenter avec API de messagerie
    notifyListeners();
  }
}
