// lib/config/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // This class is not meant to be instantiated.
  AppColors._();

  // ============================================================
  // DARK MODE COLORS (Enhanced & Refined)
  // ============================================================

  // --- Core Brand Colors ---
  static const Color darkPrimary = Color(0xFF9D4EDD); // Vibey Purple
  static const Color darkPrimaryVariant = Color(0xFF7B2CBF); // Deeper Purple
  static const Color darkSecondary = Color(0xFFF72585); // Neon Pink/Magenta
  static const Color darkSecondaryVariant = Color(0xFFD60270); // Deeper Pink

  // --- Background & Surfaces ---
  static const Color darkBackground = Color(0xFF000000); // True black AMOLED
  static const Color darkSurface = Color(0xFF1C1C1E); // Cards, sheets
  static const Color darkSurfaceElevated = Color(
    0xFF2C2C2E,
  ); // Higher elevation
  static const Color darkAppBar = Color(0xFF000000);

  // --- Text Colors ---
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Headlines, titles
  static const Color darkTextSecondary = Color(0xDEFFFFFF); // 87% - Body text
  static const Color darkTextTertiary = Color(
    0x99FFFFFF,
  ); // 60% - Hints, captions
  static const Color darkTextDisabled = Color(0x61FFFFFF); // 38% - Disabled

  // --- Component Colors ---
  static const Color darkInputFill = Color(0xFF2A2A2E);
  static const Color darkInputBorder = Color(0xFF3A3A3E);
  static const Color darkInputFocusBorder = darkPrimary;
  static const Color darkDivider = Color(0x1FFFFFFF); // 12% white
  static const Color darkRipple = Color(0x1FFFFFFF); // 12% white

  // --- On Colors (Text/icons on backgrounds) ---
  static const Color darkOnPrimary = Colors.white;
  static const Color darkOnSecondary = Colors.white;
  static const Color darkOnBackground = Colors.white;
  static const Color darkOnSurface = darkTextSecondary;
  static const Color darkOnError = Colors.black;

  // ============================================================
  // LIGHT MODE COLORS (New, Sophisticated & Clean)
  // ============================================================

  // --- Core Brand Colors ---
  static const Color lightPrimary = Color(0xFF8B3DCC); // Slightly darker purple
  static const Color lightPrimaryVariant = Color(0xFF6A1B9A); // Deep purple
  static const Color lightSecondary = Color(0xFFE91E63); // Pink
  static const Color lightSecondaryVariant = Color(0xFFC2185B); // Deep pink

  // --- Background & Surfaces ---
  static const Color lightBackground = Color(0xFFFAFAFA); // Soft white
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white cards
  static const Color lightSurfaceElevated = Color(0xFFF5F5F5); // Subtle grey
  static const Color lightAppBar = Color(0xFFFFFFFF);

  // --- Text Colors ---
  static const Color lightTextPrimary = Color(0xFF1A1A1A); // Almost black
  static const Color lightTextSecondary = Color(0xFF4A4A4A); // Dark grey
  static const Color lightTextTertiary = Color(0xFF757575); // Medium grey
  static const Color lightTextDisabled = Color(0xFFBDBDBD); // Light grey

  // --- Component Colors ---
  static const Color lightInputFill = Color(0xFFF5F5F5);
  static const Color lightInputBorder = Color(0xFFE0E0E0);
  static const Color lightInputFocusBorder = lightPrimary;
  static const Color lightDivider = Color(0x1F000000); // 12% black
  static const Color lightRipple = Color(0x1F000000); // 12% black

  // --- On Colors (Text/icons on backgrounds) ---
  static const Color lightOnPrimary = Colors.white;
  static const Color lightOnSecondary = Colors.white;
  static const Color lightOnBackground = lightTextPrimary;
  static const Color lightOnSurface = lightTextSecondary;
  static const Color lightOnError = Colors.white;

  // ============================================================
  // SEMANTIC COLORS (Work for both themes)
  // ============================================================

  // --- Success ---
  static const Color successDark = Color(0xFF4ADE80); // Vibrant green
  static const Color successLight = Color(0xFF2E7D32); // Forest green

  // --- Error/Danger ---
  static const Color errorDark = Color(0xFFEF4444); // Bright red
  static const Color errorLight = Color(0xFFC62828); // Deep red

  // --- Warning ---
  static const Color warningDark = Color(0xFFFBBF24); // Amber
  static const Color warningLight = Color(0xFFF57C00); // Orange

  // --- Info ---
  static const Color infoDark = Color(0xFF3B82F6); // Blue
  static const Color infoLight = Color(0xFF1976D2); // Deep blue

  // ============================================================
  // MOOD COLORS (Enhanced)
  // ============================================================

  static const Map<String, Color> moodColorsDark = {
    'positive': Color(0xFF4ADE80), // Vibrant green
    'negative': Color(0xFF60A5FA), // Calm blue
    'neutral': Color(0xFF94A3B8), // Slate grey
    'unknown': Color(0xFF475569), // Dark grey
  };

  static const Map<String, Color> moodColorsLight = {
    'positive': Color(0xFF22C55E), // Green
    'negative': Color(0xFF3B82F6), // Blue
    'neutral': Color(0xFF64748B), // Slate
    'unknown': Color(0xFF94A3B8), // Light grey
  };

  // Helper to get mood color based on theme
  static Color getMoodColor(String mood, bool isDark) {
    final colors = isDark ? moodColorsDark : moodColorsLight;
    return colors[mood] ??
        (isDark ? moodColorsDark['unknown']! : moodColorsLight['unknown']!);
  }

  // ============================================================
  // GRADIENT PRESETS
  // ============================================================

  // --- Brand Gradients ---
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFF7B2CBF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFF72585), Color(0xFFD60270)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient vibeyGradient = LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFFF72585)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Mood Gradients ---
  static const Gradient positiveGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient negativeGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient neutralGradient = LinearGradient(
    colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Subtle Background Gradients ---
  static const Gradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient lightBackgroundGradient = LinearGradient(
    colors: [Color(0xFFFAFAFA), Color(0xFFF0F0F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- Special Effect Gradients ---
  static const Gradient shimmerGradient = LinearGradient(
    colors: [Color(0xFF2A2A2E), Color(0xFF3A3A3E), Color(0xFF2A2A2E)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, 0.0),
    end: Alignment(2.0, 0.0),
  );

  static const Gradient glassGradient = LinearGradient(
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Radial Gradients (for the recording orb) ---
  static Gradient orbGradient({Color? centerColor}) {
    return RadialGradient(
      colors: [
        centerColor ?? const Color(0xFF9D4EDD),
        const Color(0xFF7B2CBF),
        const Color(0xFF5A1E8C),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
  }

  static const Gradient orbGlowGradient = RadialGradient(
    colors: [
      Color(0x809D4EDD), // 50% opacity purple
      Color(0x00000000), // Transparent
    ],
    stops: [0.0, 1.0],
  );

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  // Get primary color based on theme
  static Color getPrimary(bool isDark) => isDark ? darkPrimary : lightPrimary;

  // Get secondary color based on theme
  static Color getSecondary(bool isDark) =>
      isDark ? darkSecondary : lightSecondary;

  // Get background color based on theme
  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  // Get surface color based on theme
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;

  // Get text primary color based on theme
  static Color getTextPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;

  // Get text secondary color based on theme
  static Color getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;

  // Get success color based on theme
  static Color getSuccess(bool isDark) => isDark ? successDark : successLight;

  // Get error color based on theme
  static Color getError(bool isDark) => isDark ? errorDark : errorLight;

  // Get warning color based on theme
  static Color getWarning(bool isDark) => isDark ? warningDark : warningLight;

  // Get info color based on theme
  static Color getInfo(bool isDark) => isDark ? infoDark : infoLight;

  // Get text hint color (tertiary text)
  static Color getTextHint(bool isDark) =>
      isDark ? darkTextTertiary : lightTextTertiary;

  // Get text disabled color
  static Color getTextDisabled(bool isDark) =>
      isDark ? darkTextDisabled : lightTextDisabled;

  // Get onPrimary color (text on primary background)
  static Color getOnPrimary(bool isDark) =>
      isDark ? darkOnPrimary : lightOnPrimary;

  // Get onSecondary color (text on secondary background)
  static Color getOnSecondary(bool isDark) =>
      isDark ? darkOnSecondary : lightOnSecondary;

  // Get input fill color
  static Color getInputFill(bool isDark) =>
      isDark ? darkInputFill : lightInputFill;

  // Get surface elevated color
  static Color getSurfaceElevated(bool isDark) =>
      isDark ? darkSurfaceElevated : lightSurfaceElevated;
}
