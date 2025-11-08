import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/app_lifecycle_observer.dart';
import '../screens/auth_screen.dart';
import '../../../layout/main_app_layout.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../../config/theme/app_colors.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  Future<bool> _hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasCompletedOnboarding(),
      builder: (context, onboardingSnapshot) {
        // Show loading while checking onboarding status
        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.getBackground(true),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.getSecondary(true)),
            ),
          );
        }

        final hasCompletedOnboarding = onboardingSnapshot.data ?? false;

        // If onboarding not completed, show onboarding screen
        if (!hasCompletedOnboarding) {
          return const OnboardingScreen();
        }

        // Otherwise, proceed with auth flow
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            debugPrint('Auth Guard: ${snapshot.data}');
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: AppColors.getBackground(true),
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.getSecondary(true)),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              // User is logged in, wrap the MainAppLayout with our gatekeeper
              return AppLifecycleObserver(child: const MainAppLayout());
            }
            // User is not logged in
            return const AuthScreen();
          },
        );
      },
    );
  }
}
