import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/widgets/diab_care_bottom_nav.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'patients_list_screen.dart';
import 'appointments_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatViewModel>().loadConversations();
      }
    });
  }

  final List<Widget> _screens = const [
    DoctorDashboardScreen(),
    PatientsListScreen(),
    ConversationListScreen(isDoctor: true),
    AppointmentsScreen(),
    DoctorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: _screens[_currentIndex],
      extendBody: false,
      bottomNavigationBar: Consumer<ChatViewModel>(
        builder: (context, chatVM, _) {
          return DiabCareBottomNav(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const DiabCareNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Accueil',
              ),
              const DiabCareNavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people_rounded,
                label: 'Patients',
              ),
              DiabCareNavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Messages',
                badge: chatVM.totalUnread,
              ),
              const DiabCareNavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Agenda',
              ),
              const DiabCareNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }
}
