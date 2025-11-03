import 'package:flutter/material.dart';

/// Theme constants for Ollie UI components
/// Provides colors and styles that adapt to light/dark mode
class OllieThemeConstants {
  // Prevent instantiation
  OllieThemeConstants._();

  // ========== LIGHT THEME COLORS ==========

  static const Color lightPrimary = Color(0xFF2196F3); // Blue
  static const Color lightSecondary = Color(0xFF424242); // Grey 800
  static const Color lightDanger = Color(0xFFE53935); // Red
  static const Color lightSuccess = Color(0xFF43A047); // Green

  // Backgrounds
  static const Color lightBackground = Color(0xFFFAFAFA); // Grey 50
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5); // Grey 100

  // Text colors
  static const Color lightTextPrimary = Color(0xFF212121); // Grey 900
  static const Color lightTextSecondary = Color(0xFF757575); // Grey 600
  static const Color lightTextDisabled = Color(0xFFBDBDBD); // Grey 400

  // Border colors
  static const Color lightBorder = Color(0xFFE0E0E0); // Grey 300
  static const Color lightBorderFocus = lightPrimary;

  // State colors
  static const Color lightHover = Color(0xFFF5F5F5);
  static const Color lightPressed = Color(0xFFEEEEEE);
  static const Color lightDisabled = Color(0xFFE0E0E0);

  // ========== DARK THEME COLORS ==========

  static const Color darkPrimary = Color(0xFF42A5F5); // Light Blue (accent)
  static const Color darkSecondary = Color(
    0xFF8B9198,
  ); // Light Gray (for secondary elements)
  static const Color darkDanger = Color(0xFFEF5350); // Lighter red
  static const Color darkSuccess = Color(0xFF66BB6A); // Lighter green

  // divider
  static const Color darkDivider = Color(0xFF2d2d2d); // Softer divider
  // Backgrounds - Softer dark gray theme
  static const Color darkBackground = Color(
    0xFF1a1a1a,
  ); // Softer dark gray (main bg)
  static const Color darkSurface = Color(0xFF242424); // Cards/surfaces
  static const Color darkSurfaceVariant = Color(
    0xFF2d2d2d,
  ); // Elevated surfaces

  // Text colors
  static const Color darkTextPrimary = Color(0xFFe5e5e5); // Light gray text
  static const Color darkTextSecondary = Color(0xFF9ca3af); // Medium gray text
  static const Color darkTextDisabled = Color(0xFF6b7280); // Dimmed text

  // Border colors
  static const Color darkBorder = Color(0xFF404040); // Visible borders
  static const Color darkBorderFocus = darkPrimary;

  // State colors
  static const Color darkHover = Color(0xFF2a2a2a); // Slightly lighter on hover
  static const Color darkPressed = Color(
    0xFF303030,
  ); // Slightly more elevation when pressed
  static const Color darkDisabled = Color(0xFF383838); // Disabled state

  // ========== SHARED CONSTANTS ==========

  // Border radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 24.0;

  // Font weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  static List<BoxShadow> lightShadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      offset: const Offset(2, 2),
      blurRadius: 6,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.8),
      offset: const Offset(-2, -2),
      blurRadius: 6,
    ),
  ];

  static List<BoxShadow> lightShadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      offset: const Offset(4, 4),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.7),
      offset: const Offset(-4, -4),
      blurRadius: 12,
    ),
  ];

  static List<BoxShadow> darkShadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> darkShadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static const Color darkSurfaceContainerHighest = Color(
    0xFF4D5150,
  ); // Davys Gray

  static const Color darkSurfaceContainerHigh = Color(
    0xFF3A4241,
  ); // Outer Space

  static const Color darkSurfaceContainer = Color(0xFF273332); // Gunmetal 2

  static const Color darkSurfaceContainerLow = Color(0xFF1F2B2A);

  static const Color darkSurfaceContainerLowest = Color(0xFF142423); // Gunmetal

  // ========== HELPER METHODS ==========

  /// Get primary color based on brightness
  static Color getPrimaryColor(Brightness brightness) {
    return brightness == Brightness.light ? lightPrimary : darkPrimary;
  }

  /// Get text color based on brightness
  static Color getTextColor(Brightness brightness) {
    return brightness == Brightness.light ? lightTextPrimary : darkTextPrimary;
  }

  /// Get secondary text color based on brightness
  static Color getSecondaryTextColor(Brightness brightness) {
    return brightness == Brightness.light
        ? lightTextSecondary
        : darkTextSecondary;
  }

  /// Get background color based on brightness
  static Color getBackgroundColor(Brightness brightness) {
    return brightness == Brightness.light ? lightBackground : darkBackground;
  }

  /// Get surface color based on brightness
  static Color getSurfaceColor(Brightness brightness) {
    return brightness == Brightness.light ? lightSurface : darkSurface;
  }

  /// Get border color based on brightness
  static Color getBorderColor(Brightness brightness) {
    return brightness == Brightness.light ? lightBorder : darkBorder;
  }

  /// Get shadow based on brightness and size
  static List<BoxShadow> getShadow(
    Brightness brightness, {
    bool medium = false,
  }) {
    if (brightness == Brightness.light) {
      return medium ? lightShadowMedium : lightShadowSmall;
    } else {
      return medium ? darkShadowMedium : darkShadowSmall;
    }
  }
}
