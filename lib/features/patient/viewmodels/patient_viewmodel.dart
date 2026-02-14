import 'package:flutter/material.dart';
import 'package:diab_care/data/models/user_model.dart';
import 'package:diab_care/data/models/message_model.dart';
import 'package:diab_care/data/mock/mock_patient_data.dart';

class PatientViewModel extends ChangeNotifier {
  PatientModel? _patient;
  List<DoctorModel> _doctors = [];
  List<PharmacyUserModel> _pharmacies = [];
  List<ConversationModel> _conversations = [];
  bool _isLoading = false;

  PatientModel? get patient => _patient;
  List<DoctorModel> get doctors => _doctors;
  List<PharmacyUserModel> get pharmacies => _pharmacies;
  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;

  void loadPatientData() {
    _isLoading = true;
    notifyListeners();

    _patient = MockPatientData.getCurrentPatient();
    _doctors = MockPatientData.getAvailableDoctors();
    _pharmacies = MockPatientData.getAvailablePharmacies();
    _conversations = MockPatientData.getConversations();

    _isLoading = false;
    notifyListeners();
  }

  List<MessageModel> getMessages(String conversationId) {
    return MockPatientData.getMessages(conversationId);
  }

  List<Map<String, dynamic>> getRecommendations(double glucose) {
    return MockPatientData.getRecommendations(glucose);
  }

  void sendMessage(String conversationId, String content) {
    // Mock send
    notifyListeners();
  }
}
