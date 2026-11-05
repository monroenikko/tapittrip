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
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      color: scheme.surface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.secondary,
      foregroundColor: scheme.onSecondary,
    ),
  );
}
