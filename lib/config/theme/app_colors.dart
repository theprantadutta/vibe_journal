// lib/config/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // This class is not meant to be instantiated.
  AppColors._();

  // --- Core Dark Mode Palette ---
  static const Color primary = Color(0xFF9D4EDD); // Vibey Purple
  static const Color secondary = Color(0xFFF72585); // Neon Pink/Magenta Accent

  static const Color background = Colors.black; // True black for AMOLED
  static const Color surface = Color(
    0xFF1C1C1E,
  ); // Slightly off-black for cards, elevated surfaces
  static const Color appBarBackground = Colors.black;

  // --- Text Colors ---
  static const Color textPrimary = Colors.white; // For headlines, titles
  static const Color textSecondary = Color(
    0xDEFFFFFF,
  ); // 87% white for body text, subtitles
  static const Color textDisabled = Color(
    0x61FFFFFF,
  ); // 38% white for disabled text/icons
  static const Color textHint = Color(0x99FFFFFF); // 60% white for hints

  // --- Component Specific Colors ---
  static const Color inputFill = Color(
    0xFF2A2A2E,
  ); // Background for text fields
  static const Color inputFocusBorder = primary;
  static const Color error = Color(0xFFCF6679); // Standard Material dark error

  static const Color onPrimary =
      Colors.white; // Text/icon on primary background
  static const Color onSecondary =
      Colors.white; // Text/icon on secondary background
  static const Color onBackground =
      Colors.white; // Text/icon on main background
  static const Color onSurface =
      textSecondary; // Text/icon on surface background (cards)
  static const Color onError = Colors.black; // Text/icon on error background

  // --- UI Elements ---
  static const Color divider = Color(0x33FFFFFF); // White with 20% opacity

  static const Color switchActive = secondary;
  static const Color switchInactiveThumb = Color(
    0xFFBDBDBD,
  ); // Grey for inactive thumb
  static const Color switchInactiveTrack = Color(
    0x52FFFFFF,
  ); // White with 32% opacity for inactive track

  static const Color bottomNavSelected = secondary;
  static const Color bottomNavUnselected = Color(0xFF757575); // Grey 600

  // You can add mood-specific colors here later:
  // static const Color moodHappy = Color(0xFF69F0AE); // Greenish
  // static const Color moodCalm = Color(0xFF4FC3F7); // Bluish
  // static const Color moodEnergetic = Color(0xFFFFD740); // Yellowish
}
