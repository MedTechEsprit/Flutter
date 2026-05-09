import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/widgets/diab_care_bottom_nav.dart';
// ignore: unused_import
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'pharmacy_dashboard_screen.dart';
import 'pharmacy_requests_screen.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';
import 'package:diab_care/core/services/walkthrough_service.dart';
import 'package:diab_care/core/widgets/role_walkthrough_dialog.dart';
import 'pharmacy_profile_screen.dart';

class PharmacyHomeScreen extends StatefulWidget {
  const PharmacyHomeScreen({super.key});

  @override
  State<PharmacyHomeScreen> createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> {
  int _currentIndex = 0;
  final _walkthroughService = WalkthroughService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWalkthroughIfNeeded();
    });
  }

  Future<void> _showWalkthroughIfNeeded() async {
    if (!mounted) return;

    final shouldShow = await _walkthroughService
        .consumePendingAfterRegistration(AppUserRole.pharmacy);
    if (!shouldShow || !mounted) return;

    final steps = _walkthroughService.stepsForRole(AppUserRole.pharmacy);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RoleWalkthroughDialog(
        roleTitle: _walkthroughService.roleTitle(AppUserRole.pharmacy),
        steps: steps,
        onCompleted: () {},
      ),
    );
  }

  final List<Widget> _screens = const [
    PharmacyDashboardScreen(),
    PharmacyRequestsScreen(),
    ConversationListScreen(isDoctor: false, isPharmacist: true),
    PharmacyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: IndexedStack(index: _currentIndex, children: _screens),
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
            icon: Icons.list_alt_outlined,
            activeIcon: Icons.list_alt_rounded,
            label: 'Demandes',
          ),
          DiabCareNavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble_rounded,
            label: 'Chat',
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
