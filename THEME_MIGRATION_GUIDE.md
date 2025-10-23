# Theme Migration Guide - Removing Hardcoded Colors

This guide helps you update components to support dark theme by replacing hardcoded colors with theme-aware alternatives.

## Files Needing Updates

**Priority 1 - Core Kanban Components:**
- `lib/components/kanban_column.dart`
- `lib/components/kanban_card.dart`
- `lib/components/enhanced_column_header.dart`
- `lib/components/enhanced_card_content.dart`
- `lib/components/enhanced_drop_zone.dart`

**Priority 2 - Dialogs:**
- `lib/components/add_card_dialog.dart`
- `lib/components/add_column_dialog.dart`
- `lib/components/edit_card_dialog.dart`
- `lib/components/edit_column_dialog.dart`
- `lib/components/manage_columns_dialog.dart`

**Priority 3 - All Other Dialogs** (27 files total)

## Quick Reference - Color Replacements

### Using BuildContext Extension (Easiest Method)

First, import the extension:
```dart
import 'package:ollie/components/ollie_ui/theme_extensions.dart';
```

Then use the context extension:

| Old Code | New Code |
|----------|----------|
| `Colors.white` | `context.surfaceColor` |
| `Colors.black` | `context.textColor` |
| `Colors.grey.shade200` | `context.borderColor` |
| `Colors.grey.shade50` | `context.surfaceVariantColor` |
| `Colors.grey.shade700` | `context.secondaryTextColor` |
| `Colors.blue` | `context.primaryColor` |
| `Colors.red` | `context.dangerColor` |
| `Colors.green` | `context.successColor` |

### Example Migration

**Before:**
```dart
Container(
  color: Colors.white,
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.black),
  ),
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
      ),
    ],
  ),
)
```

**After:**
```dart
import 'package:ollie/components/ollie_ui/theme_extensions.dart';

Container(
  color: context.surfaceColor,
  child: Text(
    'Hello',
    style: TextStyle(color: context.textColor),
  ),
  decoration: BoxDecoration(
    border: Border.all(color: context.borderColor),
    boxShadow: context.shadowSmall,
  ),
)
```

## Common Patterns

### 1. Surface/Background Colors

```dart
// Card backgrounds
Container(
  color: context.surfaceColor,  // White in light, dark grey in dark
)

// Page backgrounds
Scaffold(
  backgroundColor: context.backgroundColor,  // Off-white in light, black in dark
)

// Elevated surfaces
Container(
  color: context.surfaceVariantColor,  // Light grey in light, darker grey in dark
)
```

### 2. Text Colors

```dart
// Primary text
Text('Title', style: TextStyle(color: context.textColor))

// Secondary text (labels, hints)
Text('Subtitle', style: TextStyle(color: context.secondaryTextColor))

// Disabled text
Text('Disabled', style: TextStyle(color: context.textDisabledColor))
```

### 3. Borders and Dividers

```dart
// Borders
border: Border.all(color: context.borderColor)

// Dividers
Divider(color: context.borderColor)
```

### 4. Shadows

```dart
// Small shadow
boxShadow: context.shadowSmall

// Medium shadow
boxShadow: context.shadowMedium
```

### 5. Interactive States

```dart
// Hover state
onHover: (hovering) {
  setState(() {
    _color = hovering ? context.hoverColor : context.surfaceColor;
  });
}

// Pressed state
color: _isPressed ? context.pressedColor : context.surfaceColor
```

### 6. Semantic Colors

```dart
// Error/Danger
color: context.dangerColor  // Red (lighter in dark mode)

// Success
color: context.successColor  // Green (lighter in dark mode)

// Primary action
color: context.primaryColor  // Blue (lighter in dark mode)
```

## Step-by-Step Migration Process

### For Each Component:

1. **Add the import:**
   ```dart
   import 'package:ollie/components/ollie_ui/theme_extensions.dart';
   ```

2. **Find hardcoded colors:**
   - Search for `Colors.white`, `Colors.black`, `Colors.grey`, etc.
   - Search for `Color(0xFF...)` hex colors

3. **Replace with theme-aware colors:**
   - Use the table above as a reference
   - Consider the semantic meaning (is it a background? border? text?)

4. **Test in both themes:**
   - Run the app
   - Toggle between light and dark mode using `ThemeToggle()`
   - Verify colors look correct in both modes

## Example: Migrating kanban_column.dart

**Before:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.withOpacity(0.2),
        blurRadius: 10,
      ),
    ],
  ),
)
```

**After:**
```dart
import 'package:ollie/components/ollie_ui/theme_extensions.dart';

Container(
  decoration: BoxDecoration(
    color: context.surfaceColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: context.borderColor),
    boxShadow: _isActive ? context.shadowMedium : context.shadowSmall,
  ),
)
```

## Special Cases

### When Context is Not Available

If you're in a class that doesn't have access to `BuildContext`, use `ThemeData`:

```dart
class MyData {
  Color getColor(BuildContext context) {
    return context.primaryColor;
  }
}
```

### Fixed Colors (Don't Change These)

Some colors should remain hardcoded:
- **Status indicators with specific meanings** (e.g., priority colors that are part of your data model)
- **Brand colors** (if you have specific brand requirements)
- **Chart colors** (if they represent specific data categories)

### Conditional Logic

For complex conditional colors:

```dart
Color getStatusColor(String status) {
  switch (status) {
    case 'active':
      return context.successColor;
    case 'error':
      return context.dangerColor;
    default:
      return context.secondaryTextColor;
  }
}
```

## Testing Checklist

After migrating a component:
- [ ] Component renders in light mode
- [ ] Component renders in dark mode
- [ ] Text is readable in both modes
- [ ] Borders are visible in both modes
- [ ] Interactive states (hover, press) work in both modes
- [ ] No visual glitches when switching themes

## Quick Start Script

To find all files with hardcoded colors in your components:

```bash
# Windows PowerShell
Get-ChildItem -Path "lib\components" -Recurse -Filter "*.dart" | Select-String -Pattern "Colors\.(white|black|grey|blue|red)" | Group-Object Path | Select-Object Name

# Or use the analyzer
flutter analyze | findstr "Colors\."
```

## Priority Order

1. **Start with visible components:** kanban_column, kanban_card
2. **Then dialogs:** Users see these frequently
3. **Finally, utility components:** Less visible but still important

## Need Help?

- Check `lib/components/ollie_ui/ollie_button.dart` - Already migrated ✅
- Check `lib/components/ollie_ui/ollie_textfield.dart` - Already migrated ✅
- Look at `theme_extensions.dart` for all available color helpers
- Look at `theme_constants.dart` for the complete color palette

## Summary

The migration is straightforward:
1. Import `theme_extensions.dart`
2. Replace `Colors.X` with `context.X`
3. Test in both themes
4. Done! ✨
