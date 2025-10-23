import 'package:flutter/material.dart';
import 'theme_constants.dart';

/// OllieTheme provides light and dark ThemeData for the app
/// while preserving the custom styling of Ollie UI components
class OllieTheme {
  // Prevent instantiation
  OllieTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: ColorScheme.light(
        primary: OllieThemeConstants.lightPrimary,
        secondary: OllieThemeConstants.lightSecondary,
        error: OllieThemeConstants.lightDanger,
        surface: OllieThemeConstants.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: OllieThemeConstants.lightTextPrimary,
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: OllieThemeConstants.lightBackground,

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: OllieThemeConstants.lightSurface,
        foregroundColor: OllieThemeConstants.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: OllieThemeConstants.lightTextPrimary,
          fontSize: OllieThemeConstants.fontSizeLarge,
          fontWeight: OllieThemeConstants.fontWeightSemiBold,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: OllieThemeConstants.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            OllieThemeConstants.borderRadiusMedium,
          ),
          side: const BorderSide(
            color: OllieThemeConstants.lightBorder,
            width: 1,
          ),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: OllieThemeConstants.lightBorder,
        thickness: 1,
        space: 1,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: OllieThemeConstants.lightTextSecondary,
        size: 24,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: OllieThemeConstants.fontWeightBold,
          color: OllieThemeConstants.lightTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: OllieThemeConstants.fontWeightBold,
          color: OllieThemeConstants.lightTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: OllieThemeConstants.fontSizeXLarge,
          fontWeight: OllieThemeConstants.fontWeightSemiBold,
          color: OllieThemeConstants.lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: OllieThemeConstants.fontWeightSemiBold,
          color: OllieThemeConstants.lightTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: OllieThemeConstants.fontSizeLarge,
          fontWeight: OllieThemeConstants.fontWeightSemiBold,
          color: OllieThemeConstants.lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: OllieThemeConstants.fontSizeBody,
          fontWeight: OllieThemeConstants.fontWeightMedium,
          color: OllieThemeConstants.lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: OllieThemeConstants.fontSizeBody,
          fontWeight: OllieThemeConstants.fontWeightRegular,
          color: OllieThemeConstants.lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: OllieThemeConstants.fontSizeMedium,
          fontWeight: OllieThemeConstants.fontWeightRegular,
          color: OllieThemeConstants.lightTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: OllieThemeConstants.fontSizeMedium,
          fontWeight: OllieThemeConstants.fontWeightMedium,
          color: OllieThemeConstants.lightTextPrimary,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OllieThemeConstants.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            OllieThemeConstants.borderRadiusMedium,
          ),
          borderSide: const BorderSide(
            color: OllieThemeConstants.lightBorder,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            OllieThemeConstants.borderRadiusMedium,
          ),
          borderSide: const BorderSide(
            color: OllieThemeConstants.lightBorder,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            OllieThemeConstants.borderRadiusMedium,
          ),
          borderSide: const BorderSide(
            color: OllieThemeConstants.lightBorderFocus,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: OllieThemeConstants.darkPrimary,
        secondary: OllieThemeConstants.darkSecondary,
        error: OllieThemeConstants.darkDanger,
        surface: OllieThemeConstants.darkSurface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: OllieThemeConstants.darkTextPrimary,
        surfaceContainerHighest:
            OllieThemeConstants.darkSurfaceContainerHighest,
        surfaceContainerHigh: OllieThemeConstants.darkSurfaceContainerHigh,
        surfaceContainer: OllieThemeConstants.darkSurfaceContainer,
        surfaceContainerLow: OllieThemeConstants.darkSurfaceContainerLow,
        surfaceContainerLowest: OllieThemeConstants.darkSurfaceContainerLowest,
        onError: Colors.black,
      ),

      dividerColor: OllieThemeConstants.darkDivider,

      // Scaffold
      scaffoldBackgroundColor: OllieThemeConstants.darkBackground,

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: OllieThemeConstants.darkSurface,
        foregroundColor: OllieThemeConstants.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: OllieThemeConstants.darkTextPrimary,
          fontSize: OllieThemeConstants.fontSizeLarge,
          fontWeight: OllieThemeConstants.fontWeightSemiBold,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: OllieThemeConstants.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            OllieThemeConstants.borderRadiusMedium,
          ),
          side: const BorderSide(
            color: OllieThemeConstants.darkBorder,
            width: 1,
          ),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: OllieThemeConstants.darkBorder,
        thickness: 1,
        space: 1,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: OllieThemeConstants.darkTextSecondary,
        size: 24,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: OllieThemeConstants.fontWeightBold,
          color: OllieThemeConstants.darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: OllieThemeConstants.fontWeightBold,
          color: OllieThemeConstants.darkTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: OllieThemeConstants.fontSizeXLarge,
          fontWeight: OllieThemeConstants.fontWeightSemiBold,
          color: OllieThemeConstants.darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: OllieThemeConstants.fontWeightSemiBold,
          color: OllieThemeConstants.darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: OllieThemeConstants.fontSizeLarge,
          fontWeight: OllieThemeConstants.fontWeightSemiBold,
          color: OllieThemeConstants.darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: OllieThemeConstants.fontSizeBody,
          fontWeight: OllieThemeConstants.fontWeightMedium,
          color: OllieThemeConstants.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: OllieThemeConstants.fontSizeBody,
          fontWeight: OllieThemeConstants.fontWeightRegular,
          color: OllieThemeConstants.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: OllieThemeConstants.fontSizeMedium,
          fontWeight: OllieThemeConstants.fontWeightRegular,
          color: OllieThemeConstants.darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: OllieThemeConstants.fontSizeMedium,
          fontWeight: OllieThemeConstants.fontWeightMedium,
          color: OllieThemeConstants.darkTextPrimary,
        ),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: OllieThemeConstants.darkSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            OllieThemeConstants.borderRadiusMedium,
          ),
        ),
        iconColor: OllieThemeConstants.darkTextPrimary,
        textColor: OllieThemeConstants.darkTextPrimary,
      ),
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OllieThemeConstants.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            OllieThemeConstants.borderRadiusMedium,
          ),
          borderSide: const BorderSide(
            color: OllieThemeConstants.darkBorder,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            OllieThemeConstants.borderRadiusMedium,
          ),
          borderSide: const BorderSide(
            color: OllieThemeConstants.darkBorder,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            OllieThemeConstants.borderRadiusMedium,
          ),
          borderSide: const BorderSide(
            color: OllieThemeConstants.darkBorderFocus,
            width: 2,
          ),
        ),
      ),
    );
  }
}
