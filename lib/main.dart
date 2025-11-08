import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'config/theme/app_theme.dart';
import 'config/theme/theme_provider.dart';
import 'core/services/haptic_service.dart';
import 'core/services/service_locator.dart';
import 'core/services/sound_service.dart';
import 'features/auth/presentation/widgets/auth_guard.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup service locator
  setupLocator();

  // Initialize services
  await HapticService().initialize();
  await SoundService().initialize();

  runApp(const VibeJournalApp());
}

class VibeJournalApp extends StatefulWidget {
  const VibeJournalApp({super.key});

  @override
  State<VibeJournalApp> createState() => _VibeJournalAppState();
}

class _VibeJournalAppState extends State<VibeJournalApp> {
  @override
  void initState() {
    super.initState();
    // Remove splash screen after first frame to prevent performTraversals warnings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'VibeJournal',
            debugShowCheckedModeBanner: false,

            // Use the new theme system
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Theme animation
            themeAnimationDuration: const Duration(milliseconds: 300),
            themeAnimationCurve: Curves.easeInOut,

            home: const AuthGuard(),
          );
        },
      ),
    );
  }
}
