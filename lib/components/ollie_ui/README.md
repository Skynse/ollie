THIS IS A TEMPORARY FILE FOR MY REFERENCE


# Ollie UI - Dark Theme Implementation

Your Ollie UI component library now fully supports dark theme! 🌙

## What's Been Implemented

### 1. **Theme Constants** (`theme_constants.dart`)
- Comprehensive color palette for light and dark modes
- Shared constants for spacing, font sizes, border radius, and shadows
- Helper methods to get theme-aware colors based on brightness

### 2. **Theme Class** (`theme.dart`)
- Complete light and dark ThemeData configurations
- Material 3 support
- Consistent styling across the entire app

### 3. **Theme Provider** (`providers/theme_provider.dart`)
- State management for theme mode (Light, Dark, System)
- Persistent theme selection using SharedPreferences
- Easy theme toggling and switching

### 4. **Updated Components**
- **OllieButton**: Now supports dark theme with proper color adaptation
- **OllieTextfield**: Fully themed for both light and dark modes

### 5. **Theme Toggle Widgets** (`theme_toggle.dart`)
Three different theme switcher components:
- **ThemeToggle**: Simple icon button toggle
- **ThemeModeSelector**: Full selector with Light/Dark/System options
- **ThemeSwitch**: Toggle switch style

## How to Use

### Quick Start

The theme is already integrated into your app! It will:
- Default to system theme (follows device settings)
- Remember user's preference
- Automatically update all Ollie UI components

### Adding a Theme Switcher

**Option 1: Simple Icon Toggle**
```dart
import 'package:ollie/components/ollie_ui/theme_toggle.dart';

// In your AppBar or settings
AppBar(
  actions: [
    ThemeToggle(), // Simple sun/moon icon
  ],
)
```

**Option 2: Full Mode Selector (Recommended)**
```dart
import 'package:ollie/components/ollie_ui/theme_toggle.dart';

// In your settings page
ThemeModeSelector(
  showIcons: true,
  direction: Axis.horizontal, // or Axis.vertical
)
```

**Option 3: Switch Style**
```dart
import 'package:ollie/components/ollie_ui/theme_toggle.dart';

ThemeSwitch(showLabels: true)
```

### Programmatic Theme Control

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/providers/theme_provider.dart';

// In a ConsumerWidget
final notifier = ref.read(themeModeProvider.notifier);

// Set specific theme
notifier.setLightMode();
notifier.setDarkMode();
notifier.setSystemMode();

// Toggle between light and dark
notifier.toggleTheme(context);

// Check current mode
final isDark = notifier.isDarkMode(context);
```

### Using Theme Colors in Custom Widgets

```dart
import 'package:ollie/components/ollie_ui/theme_constants.dart';

Widget build(BuildContext context) {
  final brightness = Theme.of(context).brightness;

  return Container(
    color: OllieThemeConstants.getSurfaceColor(brightness),
    child: Text(
      'Hello',
      style: TextStyle(
        color: OllieThemeConstants.getTextColor(brightness),
        fontSize: OllieThemeConstants.fontSizeBody,
      ),
    ),
  );
}
```

## Color Palette

### Light Theme
- **Primary**: Blue (#2196F3)
- **Background**: Light Grey (#FAFAFA)
- **Surface**: White
- **Text Primary**: Dark Grey (#212121)
- **Text Secondary**: Grey (#757575)

### Dark Theme
- **Primary**: Light Blue (#42A5F5)
- **Background**: Dark (#121212)
- **Surface**: Dark Grey (#1E1E1E)
- **Text Primary**: Light Grey (#E0E0E0)
- **Text Secondary**: Medium Grey (#B0B0B0)

## Example: Adding Theme Toggle to HomePage

```dart
// In lib/screens/home/homepage.dart
import 'package:ollie/components/ollie_ui/theme_toggle.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ollie'),
        actions: [
          ThemeToggle(), // Add this!
        ],
      ),
      body: YourContent(),
    );
  }
}
```

## Theme Persistence

The theme preference is automatically saved using SharedPreferences and will persist across app restarts. Users will see their preferred theme every time they open the app.

## Notes

- All Ollie UI components (OllieButton, OllieTextfield, etc.) automatically adapt to the current theme
- The rest of your app will use the theme defined in `theme.dart`
- To add theme support to other custom components, use the helper methods in `OllieThemeConstants`
- The system theme option will automatically follow the device's dark mode setting

## What's Not Affected

Your custom Ollie UI components maintain their unique styling and behavior - only the colors adapt to light/dark mode. The overall look and feel of your buttons, text fields, and other components remains consistent with the Ollie UI design system.
