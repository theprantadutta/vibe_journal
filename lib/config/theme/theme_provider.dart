// lib/config/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.dark; // Default to dark

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isLightMode => _themeMode == ThemeMode.light;

  bool get isSystemMode => _themeMode == ThemeMode.system;

  // Toggle between light and dark
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    await _saveThemePreference();
    notifyListeners();
  }

  // Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _saveThemePreference();
    notifyListeners();
  }

  // Set to dark mode
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }

  // Set to light mode
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }

  // Set to system mode
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themePreferenceKey);

      if (themeModeString != null) {
        _themeMode = _themeModeFromString(themeModeString);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, _themeMode.toString());
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  // Convert string to ThemeMode
  ThemeMode _themeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  // Get current theme brightness (useful for conditional rendering)
  Brightness getCurrentBrightness(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness;
    }
    return _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  // Check if using dark theme (accounting for system setting)
  bool isDark(BuildContext context) {
    return getCurrentBrightness(context) == Brightness.dark;
  }
}
