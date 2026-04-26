import 'package:flutter/material.dart';

import 'app_radii.dart';
import 'app_typography.dart';

/// Premium Material 3 theme for the scientific calculator app.
abstract final class AppTheme {
  static ThemeData build(Brightness brightness, {bool highContrast = false}) {
    final seed = brightness == Brightness.dark
        ? highContrast
              ? const Color(0xFF00FFD1)
              : const Color(0xFF35D7BC)
        : highContrast
        ? const Color(0xFF006B5B)
        : const Color(0xFF0E9F8A);
    final colorScheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
          surface: brightness == Brightness.dark
              ? (highContrast
                    ? const Color(0xFF000B12)
                    : const Color(0xFF07131E))
              : (highContrast
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFFF8FBFF)),
          surfaceContainerLowest: brightness == Brightness.dark
              ? (highContrast
                    ? const Color(0xFF020F18)
                    : const Color(0xFF0B1622))
              : Colors.white,
          surfaceContainerLow: brightness == Brightness.dark
              ? (highContrast
                    ? const Color(0xFF071B2A)
                    : const Color(0xFF102131))
              : (highContrast
                    ? const Color(0xFFF7FAFC)
                    : const Color(0xFFF1F6FA)),
          surfaceContainer: brightness == Brightness.dark
              ? (highContrast
                    ? const Color(0xFF0B2436)
                    : const Color(0xFF132637))
              : (highContrast
                    ? const Color(0xFFEFF6FB)
                    : const Color(0xFFEAF2F8)),
          surfaceContainerHigh: brightness == Brightness.dark
              ? (highContrast
                    ? const Color(0xFF102D42)
                    : const Color(0xFF172C3F))
              : (highContrast
                    ? const Color(0xFFE4F0F7)
                    : const Color(0xFFE4EEF6)),
          surfaceContainerHighest: brightness == Brightness.dark
              ? (highContrast
                    ? const Color(0xFF173A54)
                    : const Color(0xFF1C354B))
              : (highContrast
                    ? const Color(0xFFD9EAF4)
                    : const Color(0xFFDCEAF3)),
          outline: highContrast
              ? (brightness == Brightness.dark ? Colors.white : Colors.black)
              : null,
          error: highContrast ? const Color(0xFFB00020) : null,
        );
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      focusColor: colorScheme.primary.withValues(alpha: 0.28),
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      textTheme: AppTypography.apply(baseTheme.textTheme, colorScheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest.withValues(alpha: 0.76),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: const OutlineInputBorder(borderRadius: AppRadii.control),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: highContrast ? 2.2 : 1.4,
          ),
        ),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.chip),
        side: BorderSide(
          color: highContrast
              ? colorScheme.outline
              : colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh.withValues(
          alpha: 0.72,
        ),
        indicatorColor: colorScheme.primaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh.withValues(
          alpha: 0.94,
        ),
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
      ),
    );
  }
}
