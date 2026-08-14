import 'package:flutter/material.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/splash/splash_screen.dart';
import 'app_routes.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/prescriptions/history/prescription_history_screen.dart';
import '../../screens/profile/patient_profile_screen.dart';
import '../../screens/prescriptions/upload/upload_screen.dart';
import '../../screens/prescriptions/details/prescription_details_screen.dart';
import '../../screens/prescriptions/verification/verification_screen.dart';
import '../../widgets/auth_guard.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            child: DashboardScreen(),
          ),
        );

      case AppRoutes.patientProfile:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            child: PatientProfileScreen(),
          ),
        );

      case AppRoutes.uploadPrescription:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            child: UploadScreen(),
          ),
        );

      case AppRoutes.verification:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            child: VerificationScreen(),
          ),
        );

      case AppRoutes.prescriptionDetails:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            child: PrescriptionDetailsScreen(),
          ),
        );

      case AppRoutes.prescriptionHistory:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            child: PrescriptionHistoryScreen(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page Not Found'),
            ),
          ),
        );
    }
  }
}