import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/app_lifecycle_observer.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/repositories/auth_repository.dart';
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

  /// Ensure Firebase token is stored for API requests
  /// This is called when user is already authenticated (e.g., app restart)
  Future<void> _ensureTokenStored(User firebaseUser) async {
    try {
      final authRepository = locator<AuthRepository>();

      // Check if token already exists
      final hasToken = await authRepository.hasValidToken();
      if (hasToken) {
        debugPrint('✅ Token already stored');
        return;
      }

      // Store Firebase token
      debugPrint('📝 Storing Firebase token for authenticated user');
      await authRepository.verifyFirebaseToken(firebaseUser);
      debugPrint('✅ Firebase token stored successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to store Firebase token: $e');
      // Don't block the UI, just log the error
    }
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
              // User is logged in - ensure Firebase token is stored before showing app
              return FutureBuilder<void>(
                future: _ensureTokenStored(snapshot.data!),
                builder: (context, tokenSnapshot) {
                  if (tokenSnapshot.connectionState == ConnectionState.waiting) {
                    // Show loading while storing token
                    return Scaffold(
                      backgroundColor: AppColors.getBackground(true),
                      body: Center(
                        child: CircularProgressIndicator(color: AppColors.getSecondary(true)),
                      ),
                    );
                  }
                  // Token is stored, show the main app
                  return AppLifecycleObserver(child: const MainAppLayout());
                },
              );
            }
            // User is not logged in
            return const AuthScreen();
          },
        );
      },
    );
  }
}
