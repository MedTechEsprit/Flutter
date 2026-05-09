import 'package:flutter/material.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/ai/views/ai_prediction_screen.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';
import 'package:diab_care/features/doctor/views/appointments_screen.dart';
import 'package:diab_care/features/doctor/views/patient_detail_view_screen.dart';
import 'package:diab_care/features/doctor/views/patient_requests_screen.dart';
import 'package:diab_care/features/patient/views/find_doctors_screen.dart';
import 'package:diab_care/features/patient/views/find_pharmacies_screen.dart';
import 'package:diab_care/features/patient/views/glucose_history_screen.dart';
import 'package:diab_care/features/patient/views/patient_appointments_screen.dart';
import 'package:diab_care/features/patient/views/patient_medication_requests_screen.dart';
import 'package:diab_care/features/patient/views/nutrition/meal_history_screen.dart';
import 'package:diab_care/features/patient/views/patient_orders_screen.dart';
import 'package:diab_care/features/pharmacy/views/pharmacy_orders_screen.dart';
import 'package:diab_care/features/pharmacy/views/pharmacy_requests_screen.dart';

class NotificationNavigationService {
  NotificationNavigationService._();
  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final TokenService _tokenService = TokenService();

  Future<void> openInbox() async {
    final state = navigatorKey.currentState;
    if (state == null) return;
    state.pushNamed('/notifications-inbox');
  }

  Future<void> navigateFromNotificationData(
    Map<String, dynamic> data, {
    bool fallbackToInbox = true,
  }) async {
    final state = navigatorKey.currentState;
    if (state == null) return;

    final role = (await _tokenService.getUserRole())?.toLowerCase();

    final conversationId = _read(data, 'conversationId');
    final appointmentId = _read(data, 'appointmentId');
    final requestId = _read(data, 'requestId');
    final orderId = _read(data, 'orderId');
    final measurementId = _read(data, 'measurementId');
    final predictionId = _read(data, 'predictionId');
    final mealId = _read(data, 'mealId');
    final patientId = _read(data, 'patientId');
    final doctorId = _read(data, 'doctorId');
    final pharmacyId = _read(data, 'pharmacyId');
    final status = _read(data, 'status')?.toLowerCase();
    final triggerType = _read(data, 'triggerType')?.toLowerCase();

    try {
      if (conversationId != null || _read(data, 'messageId') != null) {
        state.push(
          MaterialPageRoute(
            builder: (_) => ConversationListScreen(
              isDoctor: role == 'medecin' || role == 'doctor',
              isPharmacist: role == 'pharmacien' || role == 'pharmacy',
            ),
          ),
        );
        return;
      }

      if (appointmentId != null) {
        if (role == 'medecin' || role == 'doctor') {
          state.push(
            MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
          );
          return;
        }

        state.push(
          MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen()),
        );
        return;
      }

      if (requestId != null) {
        if (role == 'medecin' || role == 'doctor') {
          state.push(
            MaterialPageRoute(builder: (_) => const PatientRequestsScreen()),
          );
          return;
        }

        if (role == 'pharmacien' || role == 'pharmacy') {
          state.push(
            MaterialPageRoute(builder: (_) => const PharmacyRequestsScreen()),
          );
          return;
        }

        state.push(
          MaterialPageRoute(
            builder: (_) => const PatientMedicationRequestsScreen(),
          ),
        );
        return;
      }

      if (orderId != null) {
        if (role == 'pharmacien' || role == 'pharmacy') {
          state.push(
            MaterialPageRoute(builder: (_) => const PharmacyOrdersScreen()),
          );
          return;
        }

        state.push(MaterialPageRoute(builder: (_) => const PatientOrdersScreen()));
        return;
      }

      if (measurementId != null) {
        state.push(
          MaterialPageRoute(builder: (_) => const GlucoseHistoryScreen()),
        );
        return;
      }

      if (predictionId != null) {
        state.push(MaterialPageRoute(builder: (_) => const AiPredictionScreen()));
        return;
      }

      if (mealId != null) {
        state.push(MaterialPageRoute(builder: (_) => const MealHistoryScreen()));
        return;
      }

      if (patientId != null && (role == 'medecin' || role == 'doctor')) {
        state.push(
          MaterialPageRoute(
            builder: (_) => PatientDetailViewScreen(
              patientId: patientId,
              patientName: 'Patient',
            ),
          ),
        );
        return;
      }

      if (doctorId != null && role == 'patient') {
        state.push(MaterialPageRoute(builder: (_) => const FindDoctorsScreen()));
        return;
      }

      if (pharmacyId != null && role == 'patient') {
        state.push(
          MaterialPageRoute(builder: (_) => const FindPharmaciesScreen()),
        );
        return;
      }

      if (triggerType != null && triggerType.contains('message')) {
        state.push(
          MaterialPageRoute(
            builder: (_) => ConversationListScreen(
              isDoctor: role == 'medecin' || role == 'doctor',
              isPharmacist: role == 'pharmacien' || role == 'pharmacy',
            ),
          ),
        );
        return;
      }

      if (status != null &&
          (status.contains('order') ||
              status.contains('confirmed') ||
              status.contains('cancelled'))) {
        if (role == 'pharmacien' || role == 'pharmacy') {
          state.push(
            MaterialPageRoute(builder: (_) => const PharmacyOrdersScreen()),
          );
        } else {
          state.push(
            MaterialPageRoute(builder: (_) => const PatientOrdersScreen()),
          );
        }
        return;
      }

      if (fallbackToInbox) {
        await openInbox();
      }
    } catch (_) {
      if (fallbackToInbox) {
        await openInbox();
      }
    }
  }

  String? _read(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
