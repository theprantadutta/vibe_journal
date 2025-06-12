import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/widgets/app_lifecycle_observer.dart';
import '../screens/auth_screen.dart';
import '../../../layout/main_app_layout.dart';
import '../../../../config/theme/app_colors.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint('Auth Guard: ${snapshot.data}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
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
  }
}
