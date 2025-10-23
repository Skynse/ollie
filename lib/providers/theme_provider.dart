import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode state notifier
/// Manages the current theme mode and persists it to local storage
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadThemeMode();
    return ThemeMode.system;
  }

  /// Load theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey);

      if (themeModeString != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      // If loading fails, keep system default
      debugPrint('Failed to load theme mode: $e');
    }
  }

  /// Save theme mode to shared preferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toString());
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
    }
  }

  /// Set theme to light mode
  void setLightMode() {
    state = ThemeMode.light;
    _saveThemeMode(ThemeMode.light);
  }

  /// Set theme to dark mode
  void setDarkMode() {
    state = ThemeMode.dark;
    _saveThemeMode(ThemeMode.dark);
  }

  /// Set theme to system mode
  void setSystemMode() {
    state = ThemeMode.system;
    _saveThemeMode(ThemeMode.system);
  }

  /// Toggle between light and dark mode
  void toggleTheme(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final currentBrightness = state == ThemeMode.system
        ? brightness
        : (state == ThemeMode.light ? Brightness.light : Brightness.dark);

    if (currentBrightness == Brightness.light) {
      setDarkMode();
    } else {
      setLightMode();
    }
  }

  /// Get the effective brightness based on current theme mode
  Brightness getEffectiveBrightness(BuildContext context) {
    if (state == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness;
    }
    return state == ThemeMode.light ? Brightness.light : Brightness.dark;
  }

  /// Check if dark mode is currently active
  bool isDarkMode(BuildContext context) {
    return getEffectiveBrightness(context) == Brightness.dark;
  }
}

/// Provider for theme mode
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});
