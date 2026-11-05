import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import 'theme_constants.dart';

/// Theme toggle button that allows users to switch between light and dark mode
class ThemeToggle extends ConsumerWidget {
  final IconData? lightIcon;
  final IconData? darkIcon;
  final bool showLabel;
  final double? iconSize;

  const ThemeToggle({
    super.key,
    this.lightIcon = Icons.light_mode,
    this.darkIcon = Icons.dark_mode,
    this.showLabel = false,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return IconButton(
      icon: Icon(isDark ? lightIcon : darkIcon, size: iconSize),
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggleTheme(context);
      },
    );
  }
}

/// Theme mode selector with three options: Light, Dark, System
class ThemeModeSelector extends ConsumerWidget {
  final bool showIcons;
  final Axis direction;

  const ThemeModeSelector({
    super.key,
    this.showIcons = true,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final notifier = ref.read(themeModeProvider.notifier);

    final options = [
      _ThemeModeOption(
        mode: ThemeMode.light,
        label: 'Light',
        icon: Icons.light_mode,
      ),
      _ThemeModeOption(
        mode: ThemeMode.dark,
        label: 'Dark',
        icon: Icons.dark_mode,
      ),
      _ThemeModeOption(
        mode: ThemeMode.system,
        label: 'System',
        icon: Icons.brightness_auto,
      ),
    ];

    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          return _buildOption(
            context,
            option,
            themeMode.value ?? ThemeMode.system,
            brightness,
            notifier,
          );
        }).toList(),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        return _buildOption(
          context,
          option,
          themeMode.value ?? ThemeMode.system,
          brightness,
          notifier,
        );
      }).toList(),
    );
  }

  Widget _buildOption(
    BuildContext context,
    _ThemeModeOption option,
    ThemeMode currentMode,
    Brightness brightness,
    ThemeModeNotifier notifier,
  ) {
    final isSelected = currentMode == option.mode;
    final primaryColor = OllieThemeConstants.getPrimaryColor(brightness);
    final textColor = OllieThemeConstants.getTextColor(brightness);
    final borderColor = OllieThemeConstants.getBorderColor(brightness);

    return Padding(
      padding: const EdgeInsets.all(OllieThemeConstants.spacingXSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            switch (option.mode) {
              case ThemeMode.light:
                notifier.setLightMode();
                break;
              case ThemeMode.dark:
                notifier.setDarkMode();
                break;
              case ThemeMode.system:
                notifier.setSystemMode();
                break;
            }
          },
          borderRadius: BorderRadius.circular(
            OllieThemeConstants.borderRadiusSmall,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: OllieThemeConstants.spacingMedium,
              vertical: OllieThemeConstants.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? primaryColor : borderColor,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(
                OllieThemeConstants.borderRadiusSmall,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcons) ...[
                  Icon(
                    option.icon,
                    size: 20,
                    color: isSelected ? primaryColor : textColor,
                  ),
                  const SizedBox(width: OllieThemeConstants.spacingSmall),
                ],
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: OllieThemeConstants.fontSizeMedium,
                    fontWeight: isSelected
                        ? OllieThemeConstants.fontWeightSemiBold
                        : OllieThemeConstants.fontWeightRegular,
                    color: isSelected ? primaryColor : textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeModeOption {
  final ThemeMode mode;
  final String label;
  final IconData icon;

  const _ThemeModeOption({
    required this.mode,
    required this.label,
    required this.icon,
  });
}

/// Simple toggle switch for theme
class ThemeSwitch extends ConsumerWidget {
  final bool showLabels;

  const ThemeSwitch({super.key, this.showLabels = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textColor = OllieThemeConstants.getSecondaryTextColor(brightness);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels) ...[
          Icon(Icons.light_mode, size: 18, color: textColor),
          const SizedBox(width: OllieThemeConstants.spacingSmall),
        ],
        Switch(
          value: isDark,
          onChanged: (_) {
            ref.read(themeModeProvider.notifier).toggleTheme(context);
          },
          activeThumbColor: OllieThemeConstants.getPrimaryColor(brightness),
        ),
        if (showLabels) ...[
          const SizedBox(width: OllieThemeConstants.spacingSmall),
          Icon(Icons.dark_mode, size: 18, color: textColor),
        ],
      ],
    );
  }
}
