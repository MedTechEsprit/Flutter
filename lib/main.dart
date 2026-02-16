import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_theme.dart';
import 'package:diab_care/core/theme/theme_provider.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';
import 'package:diab_care/features/auth/views/role_selection_screen.dart';
import 'package:diab_care/features/auth/views/login_screen.dart';
import 'package:diab_care/features/patient/views/patient_home_screen.dart';
import 'package:diab_care/features/doctor/views/doctor_home_screen.dart';
import 'package:diab_care/features/pharmacy/views/pharmacy_home_screen.dart';

void main() {
  runApp(const DiabCareApp());
}

class DiabCareApp extends StatelessWidget {
  const DiabCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => GlucoseViewModel()),
        ChangeNotifierProvider(create: (_) => PatientViewModel()),
        ChangeNotifierProvider(create: (_) => PharmacyViewModel()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'DiabCare',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (context) => const RoleSelectionScreen(),
              '/login': (context) => const LoginScreen(),
              '/patient-home': (context) => const PatientHomeScreen(),
              '/doctor-home': (context) => const DoctorHomeScreen(),
              '/pharmacy-home': (context) => const PharmacyHomeScreen(),
            },
          );
        },
      ),
    );
  }
}

