import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'pharmacy_dashboard_screen.dart';
import 'pharmacy_requests_screen.dart';
import 'pharmacy_profile_screen.dart';

class PharmacyHomeScreen extends StatefulWidget {
  const PharmacyHomeScreen({super.key});

  @override
  State<PharmacyHomeScreen> createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PharmacyDashboardScreen(),
    PharmacyRequestsScreen(),
    PharmacyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: AppColors.primaryGreen,
            unselectedItemColor: AppColors.textMuted,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            iconSize: 26,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), activeIcon: Icon(Icons.dashboard_rounded), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), activeIcon: Icon(Icons.list_alt_rounded), label: 'Demandes'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}
