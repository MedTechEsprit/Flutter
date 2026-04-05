import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/widgets/diab_care_bottom_nav.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/meal_viewmodel.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/patient_request_service.dart';
import 'package:diab_care/features/patient/views/glucose_dashboard_screen.dart';
// ignore: unused_import
import 'package:diab_care/features/patient/views/glucose_history_screen.dart';
import 'package:diab_care/features/patient/views/find_doctors_screen.dart';
import 'package:diab_care/features/patient/views/find_pharmacies_screen.dart';
import 'package:diab_care/features/patient/views/patient_profile_screen.dart';
import 'package:diab_care/features/patient/views/nutrition/nutrition_main_screen.dart';
import 'package:diab_care/features/ai/views/ai_hub_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;
  final _tokenService = TokenService();
  final _patientRequestService = PatientRequestService();
  bool _checkingAccessRequests = false;

  final List<Widget> _screens = const [
    GlucoseDashboardScreen(),
    NutritionMainScreen(),
    AiHubScreen(),
    FindDoctorsScreen(),
    FindPharmaciesScreen(),
    PatientProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GlucoseViewModel>().loadReadings();
      context.read<PatientViewModel>().loadPatientData();
      context.read<MealViewModel>().loadMeals();
      context.read<ChatViewModel>().loadConversations();
      _checkPendingDoctorAccessRequests();
    });
  }

  Future<void> _checkPendingDoctorAccessRequests() async {
    if (_checkingAccessRequests || !mounted) return;

    _checkingAccessRequests = true;
    try {
      final patientId = _tokenService.userId ?? await _tokenService.getUserId();
      if (patientId == null || !mounted) return;

      final requests = await _patientRequestService.getPendingDoctorAccessRequests(patientId);
      if (requests.isEmpty || !mounted) return;

      final request = requests.first;
      final doctor = (request['doctorId'] as Map<String, dynamic>?) ?? {};
      final doctorName = 'Dr. ${doctor['prenom'] ?? ''} ${doctor['nom'] ?? ''}'.trim();

      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Demande d\'autorisation'),
          content: Text(
            '$doctorName souhaite accéder à vos informations médicales.\n\nAutoriser cet accès ?',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Refuser'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.softGreen, foregroundColor: Colors.white),
              child: const Text('Autoriser'),
            ),
          ],
        ),
      );

      if (accepted == null) return;

      await _patientRequestService.respondDoctorAccessRequest(
        patientId: patientId,
        requestId: request['_id'].toString(),
        accept: accepted,
        declineReason: accepted ? null : 'Refusé par le patient',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted
                ? 'Accès accordé au médecin. Il peut désormais consulter vos informations.'
                : 'Demande refusée.',
          ),
          backgroundColor: accepted ? AppColors.softGreen : const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(milliseconds: 400), _checkPendingDoctorAccessRequests);
    } catch (_) {
      // Ignore popup failures silently to avoid blocking home screen
    } finally {
      _checkingAccessRequests = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: _screens[_currentIndex],
      extendBody: false,
      bottomNavigationBar: DiabCareBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          DiabCareNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Accueil',
          ),
          DiabCareNavItem(
            icon: Icons.restaurant_outlined,
            activeIcon: Icons.restaurant_rounded,
            label: 'Nutrition',
          ),
          DiabCareNavItem(
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome_rounded,
            label: 'IA',
          ),
          DiabCareNavItem(
            icon: Icons.medical_services_outlined,
            activeIcon: Icons.medical_services_rounded,
            label: 'Médecins',
          ),
          DiabCareNavItem(
            icon: Icons.local_pharmacy_outlined,
            activeIcon: Icons.local_pharmacy_rounded,
            label: 'Pharmacies',
          ),
          DiabCareNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
