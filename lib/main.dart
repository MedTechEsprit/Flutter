import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_theme.dart';
import 'package:diab_care/core/theme/theme_provider.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';
import 'package:diab_care/features/patient/viewmodels/meal_viewmodel.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';
import 'package:diab_care/features/auth/views/role_selection_screen.dart';
import 'package:diab_care/features/auth/views/login_screen.dart';
import 'package:diab_care/features/auth/views/register_patient_screen.dart';
import 'package:diab_care/features/auth/views/register_medecin_screen.dart';
import 'package:diab_care/features/auth/views/register_pharmacien_screen.dart';
import 'package:diab_care/features/auth/views/register_role_screen.dart';
import 'package:diab_care/features/patient/views/patient_home_screen.dart';
import 'package:diab_care/features/doctor/views/doctor_home_screen.dart';
import 'package:diab_care/features/pharmacy/views/pharmacy_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize TokenService before app starts
  await TokenService().init();

  // Catch all errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack Trace: ${details.stack}');
  };

  runApp(const DiabCareApp());
}

class DiabCareApp extends StatelessWidget {
  const DiabCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) {
          final authVM = AuthViewModel();
          // Initialize auth state from storage
          authVM.init();
          return authVM;
        }),
        ChangeNotifierProvider(create: (_) => GlucoseViewModel()),
        ChangeNotifierProvider(create: (_) => PatientViewModel()),
        ChangeNotifierProvider(create: (_) => MealViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
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
            // Add error builder
            builder: (context, widget) {
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 80, color: Colors.red),
                          const SizedBox(height: 20),
                          const Text(
                            'Une erreur est survenue',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            errorDetails.exception.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Restart app
                            },
                            child: const Text('Redémarrer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              };
              return widget ?? const SizedBox();
            },
            routes: {
              '/': (context) => const RoleSelectionScreen(),
              '/login': (context) => const LoginScreen(),
              '/register-role': (context) => const RegisterRoleScreen(),
              '/register-patient': (context) => const RegisterPatientScreen(),
              '/register-medecin': (context) => const RegisterMedecinScreen(),
              '/register-pharmacien': (context) => const RegisterPharmacienScreen(),
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
