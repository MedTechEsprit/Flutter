import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/widgets/diab_care_bottom_nav.dart';
// ignore: unused_import
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'pharmacy_dashboard_screen.dart';
import 'pharmacy_requests_screen.dart';
import 'pharmacy_products_screen.dart';
import 'pharmacy_orders_screen.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';
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
    PharmacyProductsScreen(),
    PharmacyOrdersScreen(),
    ConversationListScreen(isDoctor: false),
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
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2_rounded,
            label: 'Produits',
          ),
          DiabCareNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Commandes',
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
