import 'package:flutter/material.dart';
import 'theme_constants.dart';

/// Extension on BuildContext to easily access theme-aware colors
extension ThemeExtension on BuildContext {
  /// Get current brightness
  Brightness get brightness => Theme.of(this).brightness;

  /// Check if dark mode is active
  bool get isDarkMode => brightness == Brightness.dark;

  /// Get primary color
  Color get primaryColor => OllieThemeConstants.getPrimaryColor(brightness);

  /// Get text color
  Color get textColor => OllieThemeConstants.getTextColor(brightness);

  /// Get secondary text color
  Color get secondaryTextColor =>
      OllieThemeConstants.getSecondaryTextColor(brightness);

  /// Get background color
  Color get backgroundColor =>
      OllieThemeConstants.getBackgroundColor(brightness);

  /// Get surface color
  Color get surfaceColor => OllieThemeConstants.getSurfaceColor(brightness);

  /// Get surface variant color
  Color get surfaceVariantColor => isDarkMode
      ? OllieThemeConstants.darkBackground
      : OllieThemeConstants.lightSurfaceVariant;

  /// Get border color
  Color get borderColor => OllieThemeConstants.getBorderColor(brightness);

  /// Get hover color
  Color get hoverColor => isDarkMode
      ? OllieThemeConstants.darkHover
      : OllieThemeConstants.lightHover;

  /// Get pressed color
  Color get pressedColor => isDarkMode
      ? OllieThemeConstants.darkPressed
      : OllieThemeConstants.lightPressed;

  /// Get disabled color
  Color get disabledColor => isDarkMode
      ? OllieThemeConstants.darkDisabled
      : OllieThemeConstants.lightDisabled;

  /// Get text disabled color
  Color get textDisabledColor => isDarkMode
      ? OllieThemeConstants.darkTextDisabled
      : OllieThemeConstants.lightTextDisabled;

  /// Get danger color
  Color get dangerColor => isDarkMode
      ? OllieThemeConstants.darkDanger
      : OllieThemeConstants.lightDanger;

  /// Get success color
  Color get successColor => isDarkMode
      ? OllieThemeConstants.darkSuccess
      : OllieThemeConstants.lightSuccess;

  /// Get secondary color
  Color get secondaryColor => isDarkMode
      ? OllieThemeConstants.darkSecondary
      : OllieThemeConstants.lightSecondary;

  /// Get shadow
  List<BoxShadow> getShadow({bool medium = false}) {
    return OllieThemeConstants.getShadow(brightness, medium: medium);
  }

  /// Get small shadow
  List<BoxShadow> get shadowSmall => OllieThemeConstants.getShadow(brightness);

  /// Get medium shadow
  List<BoxShadow> get shadowMedium =>
      OllieThemeConstants.getShadow(brightness, medium: true);
}

/// Helper to get theme-aware colors without BuildContext
class ThemeColors {
  final Brightness brightness;

  const ThemeColors(this.brightness);

  factory ThemeColors.light() => const ThemeColors(Brightness.light);
  factory ThemeColors.dark() => const ThemeColors(Brightness.dark);

  Color get primary => OllieThemeConstants.getPrimaryColor(brightness);
  Color get text => OllieThemeConstants.getTextColor(brightness);
  Color get secondaryText =>
      OllieThemeConstants.getSecondaryTextColor(brightness);
  Color get background => OllieThemeConstants.getBackgroundColor(brightness);
  Color get surface => OllieThemeConstants.getSurfaceColor(brightness);
  Color get border => OllieThemeConstants.getBorderColor(brightness);

  Color get surfaceVariant => brightness == Brightness.dark
      ? OllieThemeConstants.darkSurfaceVariant
      : OllieThemeConstants.lightSurfaceVariant;

  Color get danger => brightness == Brightness.dark
      ? OllieThemeConstants.darkDanger
      : OllieThemeConstants.lightDanger;

  Color get success => brightness == Brightness.dark
      ? OllieThemeConstants.darkSuccess
      : OllieThemeConstants.lightSuccess;
}
