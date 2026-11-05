import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode state notifier
/// Manages the current theme mode and persists it to local storage
class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    // Load saved theme mode from storage
    return await _loadThemeMode();
  }

  /// Load theme mode from shared preferences
  Future<ThemeMode> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey);

      if (themeModeString != null) {
        return ThemeMode.values.firstWhere(
          (mode) =>
              mode.name == themeModeString ||
              mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      // If loading fails, use system default
      debugPrint('Failed to load theme mode: $e');
    }
    return ThemeMode.system;
  }

  /// Save theme mode to shared preferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
    }
  }

  /// Set theme to light mode
  Future<void> setLightMode() async {
    state = const AsyncValue.data(ThemeMode.light);
    await _saveThemeMode(ThemeMode.light);
  }

  /// Set theme to dark mode
  Future<void> setDarkMode() async {
    state = const AsyncValue.data(ThemeMode.dark);
    await _saveThemeMode(ThemeMode.dark);
  }

  /// Set theme to system mode
  Future<void> setSystemMode() async {
    state = const AsyncValue.data(ThemeMode.system);
    await _saveThemeMode(ThemeMode.system);
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme(BuildContext context) async {
    final currentMode = state.value ?? ThemeMode.system;
    final brightness = MediaQuery.of(context).platformBrightness;
    final currentBrightness = currentMode == ThemeMode.system
        ? brightness
        : (currentMode == ThemeMode.light ? Brightness.light : Brightness.dark);

    if (currentBrightness == Brightness.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }

  /// Get the effective brightness based on current theme mode
  Brightness getEffectiveBrightness(BuildContext context) {
    final currentMode = state.value ?? ThemeMode.system;
    if (currentMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness;
    }
    return currentMode == ThemeMode.light ? Brightness.light : Brightness.dark;
  }

  /// Check if dark mode is currently active
  bool isDarkMode(BuildContext context) {
    return getEffectiveBrightness(context) == Brightness.dark;
  }
}

/// Provider for theme mode
final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  () {
    return ThemeModeNotifier();
  },
);
