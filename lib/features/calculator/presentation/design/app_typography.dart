import 'package:flutter/material.dart';

/// Typography tuning for a crisp scientific-product feel.
abstract final class AppTypography {
  static TextTheme apply(TextTheme base, ColorScheme colorScheme) {
    return base
        .apply(
          fontFamily: 'Aptos',
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        )
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.45,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.25,
          ),
        );
  }
}
