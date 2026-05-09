import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/widgets/diab_care_bottom_nav.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';
import 'package:diab_care/core/services/walkthrough_service.dart';
import 'package:diab_care/core/widgets/role_walkthrough_dialog.dart';
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
  final _walkthroughService = WalkthroughService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHome();
    });
  }

  Future<void> _initializeHome() async {
    if (!mounted) return;
    context.read<ChatViewModel>().loadConversations();
    await _showWalkthroughIfNeeded();
  }

  Future<void> _showWalkthroughIfNeeded() async {
    if (!mounted) return;

    final shouldShow = await _walkthroughService
        .consumePendingAfterRegistration(AppUserRole.doctor);
    if (!shouldShow || !mounted) return;

    final steps = _walkthroughService.stepsForRole(AppUserRole.doctor);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RoleWalkthroughDialog(
        roleTitle: _walkthroughService.roleTitle(AppUserRole.doctor),
        steps: steps,
        onCompleted: () {},
      ),
    );
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
                label: 'Home',
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
                label: 'Schedule',
              ),
              const DiabCareNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
