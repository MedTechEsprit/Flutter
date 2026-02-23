import 'package:flutter/material.dart';
import 'package:diab_care/data/models/user_model.dart';
import 'package:diab_care/data/mock/mock_patient_data.dart';
import 'package:diab_care/features/patient/services/patient_api_service.dart';

class PatientViewModel extends ChangeNotifier {
  final PatientApiService _api = PatientApiService();

  PatientModel? _patient;
  List<DoctorModel> _doctors = [];
  List<PharmacyUserModel> _pharmacies = [];
  bool _isLoading = false;
  String? _error;

  PatientModel? get patient => _patient;
  List<DoctorModel> get doctors => _doctors;
  List<PharmacyUserModel> get pharmacies => _pharmacies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatientData() async {
    _isLoading = true;
    notifyListeners();

    // Load mock patient profile (profile comes from auth)
    _patient = MockPatientData.getCurrentPatient();

    // Load real data from backend (await both in parallel)
    await Future.wait([
      _loadDoctorsFromApi(),
      _loadPharmaciesFromApi(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch real doctors list from backend GET /api/medecins
  Future<void> _loadDoctorsFromApi() async {
    try {
      final result = await _api.getMedecins(page: 1, limit: 50);
      if (result['success'] == true) {
        final data = result['data'];
        List rawList;
        if (data is Map && data.containsKey('data')) {
          rawList = data['data'] as List;
        } else if (data is List) {
          rawList = data;
        } else {
          rawList = [];
        }

        _doctors = rawList.map((json) {
          final map = json as Map<String, dynamic>;
          final nom = map['nom']?.toString() ?? '';
          final prenom = map['prenom']?.toString() ?? '';
          final fullName = '$prenom $nom'.trim();

          return DoctorModel(
            id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
            name: fullName.isNotEmpty ? fullName : 'Dr. Inconnu',
            email: map['email']?.toString() ?? '',
            phone: map['telephone']?.toString() ?? '',
            specialty: map['specialite']?.toString() ?? 'Généraliste',
            license: map['numeroOrdre']?.toString() ?? '',
            hospital: map['clinique']?.toString() ?? '',
            isAvailable: map['statutCompte']?.toString().toLowerCase() == 'actif',
            totalPatients: (map['listePatients'] as List?)?.length ?? 0,
            satisfactionRate: ((map['noteMoyenne'] ?? 0) as num).toDouble() * 20, // 0-5 → 0-100
            yearsExperience: ((map['anneesExperience'] ?? 0) as num).toInt(),
          );
        }).toList();
        notifyListeners();
      } else {
        debugPrint('⚠️ Failed to load doctors: ${result['message']}');
        // Fallback to mock data
        _doctors = MockPatientData.getAvailableDoctors();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading doctors: $e');
      _doctors = MockPatientData.getAvailableDoctors();
      notifyListeners();
    }
  }

  /// Fetch real pharmacies list from backend GET /api/pharmaciens
  Future<void> _loadPharmaciesFromApi() async {
    try {
      final result = await _api.getPharmacies(page: 1, limit: 50);
      if (result['success'] == true) {
        final data = result['data'];
        List rawList;
        if (data is Map && data.containsKey('data')) {
          rawList = data['data'] as List;
        } else if (data is List) {
          rawList = data;
        } else {
          rawList = [];
        }

        _pharmacies = rawList.map((json) {
          final map = json as Map<String, dynamic>;
          final nomPharmacie = map['nomPharmacie']?.toString() ?? '';
          final nom = map['nom']?.toString() ?? '';
          final prenom = map['prenom']?.toString() ?? '';
          final displayName = nomPharmacie.isNotEmpty
              ? nomPharmacie
              : '$prenom $nom'.trim();

          return PharmacyUserModel(
            id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
            name: displayName.isNotEmpty ? displayName : 'Pharmacie',
            email: map['email']?.toString() ?? '',
            phone: map['telephonePharmacie']?.toString() ?? map['telephone']?.toString() ?? '',
            address: map['adressePharmacie']?.toString() ?? '',
            license: map['numeroOrdre']?.toString() ?? '',
            isOpen: map['statutCompte']?.toString().toLowerCase() == 'actif',
            rating: ((map['noteMoyenne'] ?? map['averageRating'] ?? 0) as num).toDouble(),
            totalReviews: ((map['totalRequestsReceived'] ?? 0) as num).toInt(),
          );
        }).toList();
        notifyListeners();
      } else {
        debugPrint('⚠️ Failed to load pharmacies: ${result['message']}');
        _pharmacies = MockPatientData.getAvailablePharmacies();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading pharmacies: $e');
      _pharmacies = MockPatientData.getAvailablePharmacies();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getRecommendations(double glucose) {
    return MockPatientData.getRecommendations(glucose);
  }
}
