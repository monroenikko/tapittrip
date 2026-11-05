# TapItTrip brand colors

Sampled from the TapItTrip logo ([`../assets/tapittrip-logo.jpg`](../assets/tapittrip-logo.jpg)).
Branding is provisional (see `AGENTS.md`); change values here and in `app_colors.dart` together.

## Core palette

| Role | Name | Hex | Logo source |
| --- | --- | --- | --- |
| **Primary** | TapIt Navy | `#00376D` | "TapIt" wordmark |
| **Secondary** | Trip Orange | `#F76405` | "Trip" wordmark, map pin |
| Tertiary | Sky Blue | `#0166BE` | Suitcase gradient |
| Brand art only | Cyan `#02BCF5`, Teal `#15BBA3`, Sun `#FDD633` | — | Gradient, mountains, sun |

Brand-art colors are for illustrations, onboarding art, and the logo. Do not use them for text or controls.

## Material 3 color roles

| Role | Light | Dark |
| --- | --- | --- |
| `primary` | `#00376D` | `#A6C8FF` |
| `onPrimary` | `#FFFFFF` | `#00315F` |
| `primaryContainer` | `#D6E3FF` | `#004A8F` |
| `onPrimaryContainer` | `#001B3D` | `#D6E3FF` |
| `secondary` | `#F76405` | `#FF8A3D` |
| `onSecondary` | `#1F1000` | `#2E1300` |
| `secondaryContainer` | `#FFDBC8` | `#5C2000` |
| `onSecondaryContainer` | `#4A1C00` | `#FFDBC8` |
| `tertiary` | `#0166BE` | `#9ECBFF` |
| `onTertiary` | `#FFFFFF` | `#00315F` |
| `surface` | `#F7F9FC` | `#121417` |
| `onSurface` | `#1A1C1E` | `#E2E2E6` |
| `onSurfaceVariant` | `#43474E` | `#C3C6CF` |
| `error` | Material default | Material default |

Orange text on light surfaces: use `#B84A00` (≈5:1), not `#F76405` (3.1:1).

## Contrast (checked, WCAG)

| Pair | Ratio | OK for |
| --- | --- | --- |
| White on Navy `#00376D` | 11.9:1 | All text |
| `#1F1000` on Orange `#F76405` | 6.0:1 | All text |
| White on Orange `#F76405` | 3.1:1 | ❌ Large/bold ≥18 sp only — avoid |
| White on Sky `#0166BE` | 5.8:1 | All text |
| `#A6C8FF` on dark surface `#121417` | 10.8:1 | All text |
| `#FF8A3D` on `#2E1300` | 7.4:1 | All text |

## Usage rules
- **Navy = trust and structure**: app bar, primary `FilledButton`, headings, selected tab.
- **Orange = action and place**: FAB, "now/next" highlights, map pins, unread badges, progress. One orange focal point per screen.
- Do not place orange and navy text directly on each other (3.8:1).
- Status colors (success/warning/error) must not reuse orange; always pair color with an icon or text.
- In widgets read `Theme.of(context).colorScheme.primary` etc. Never write `Color(0xFF...)` outside the theme file.

## Implementation (copy into `client/lib/core/theme/`)

```dart
// app_colors.dart
import 'package:flutter/material.dart';

/// TapItTrip brand palette. Use only inside the theme layer.
abstract final class AppColors {
  static const navy = Color(0xFF00376D); // primary
  static const orange = Color(0xFFF76405); // secondary
  static const sky = Color(0xFF0166BE); // tertiary
  static const orangeText = Color(0xFFB84A00); // orange text on light bg
}
```

```dart
// app_theme.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD6E3FF),
      onPrimaryContainer: const Color(0xFF001B3D),
      secondary: AppColors.orange,
      onSecondary: const Color(0xFF1F1000),
      secondaryContainer: const Color(0xFFFFDBC8),
      onSecondaryContainer: const Color(0xFF4A1C00),
      tertiary: AppColors.sky,
      onTertiary: Colors.white,
      surface: const Color(0xFFF7F9FC),
      onSurface: const Color(0xFF1A1C1E),
      onSurfaceVariant: const Color(0xFF43474E),
    ),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.dark,
      primary: const Color(0xFFA6C8FF),
      onPrimary: const Color(0xFF00315F),
      primaryContainer: const Color(0xFF004A8F),
      onPrimaryContainer: const Color(0xFFD6E3FF),
      secondary: const Color(0xFFFF8A3D),
      onSecondary: const Color(0xFF2E1300),
      secondaryContainer: const Color(0xFF5C2000),
      onSecondaryContainer: const Color(0xFFFFDBC8),
      tertiary: const Color(0xFF9ECBFF),
      onTertiary: const Color(0xFF00315F),
      surface: const Color(0xFF121417),
      onSurface: const Color(0xFFE2E2E6),
      onSurfaceVariant: const Color(0xFFC3C6CF),
    ),
  );

  static ThemeData _build(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.secondary,
      foregroundColor: scheme.onSecondary,
    ),
  );
}
```

```dart
// main.dart
MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system,
  // ...
);
```

Add a widget test asserting `Theme.of(context).colorScheme.primary == AppColors.navy` and `secondary == AppColors.orange` so the brand cannot drift silently.
