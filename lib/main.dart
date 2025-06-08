import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/theme/app_colors.dart';
import 'core/services/service_locator.dart';
import 'features/auth/presentation/widgets/auth_guard.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupLocator();
  runApp(const VibeJournalApp());
}

class VibeJournalApp extends StatelessWidget {
  const VibeJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeJournal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.background,
        dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),

        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          onPrimary: AppColors.onPrimary,
          onSecondary: AppColors.onSecondary,
          onSurface: AppColors.onSurface,
          error: AppColors.error,
          onError: AppColors.onError,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBarBackground,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            // fontFamily: 'YourPreferredFont' // Example
          ),
        ),

        textTheme: TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w300,
            fontSize: 96,
          ),
          displayMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w300,
            fontSize: 60,
          ),
          displaySmall: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
            fontSize: 48,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
            fontSize: 34,
          ),
          headlineSmall: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
            fontSize: 24,
          ), // Often used for AppBar titles if not overridden
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ), // Often used for ListTile titles
          titleMedium: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
          titleSmall: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ), // Default text style
          bodySmall: TextStyle(
            color: AppColors.textHint,
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          labelLarge: TextStyle(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ), // For buttons
          labelSmall: TextStyle(
            color: AppColors.textHint,
            fontWeight: FontWeight.w400,
            fontSize: 10,
          ),
        ),

        iconTheme: IconThemeData(color: AppColors.textSecondary, size: 24.0),
        primaryIconTheme: IconThemeData(color: AppColors.onPrimary, size: 24.0),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: BorderSide(
              color: AppColors.textSecondary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),

        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill,
          hintStyle: const TextStyle(color: AppColors.textHint),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(
              color: AppColors.inputFocusBorder,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: AppColors.error.withOpacity(0.8),
              width: 1.0,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: AppColors.error, width: 2.0),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.onSecondary,
          elevation: 4.0,
        ),

        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 0.5,
          space: 1,
        ),

        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.switchActive;
            }
            return AppColors.switchInactiveThumb;
          }),
          trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.switchActive.withOpacity(0.5);
            }
            return AppColors.switchInactiveTrack;
          }),
          trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.switchActive.withOpacity(0.2);
            }
            return Colors.transparent;
          }),
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors
              .appBarBackground, // Or AppColors.surface for slight difference
          selectedItemColor: AppColors.bottomNavSelected,
          unselectedItemColor: AppColors.bottomNavUnselected,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        splashColor: Colors.white.withOpacity(0.12),
        highlightColor: Colors.white.withOpacity(0.10),
      ),
      home: const AuthGuard(),
    );
  }
}
