import 'package:flutter/material.dart';

/// Elevation language for soft premium surfaces.
abstract final class AppShadows {
  static List<BoxShadow> panel(ColorScheme colorScheme) {
    return <BoxShadow>[
      BoxShadow(
        color: colorScheme.shadow.withValues(alpha: 0.16),
        blurRadius: 34,
        offset: const Offset(0, 20),
      ),
      BoxShadow(
        color: colorScheme.primary.withValues(alpha: 0.06),
        blurRadius: 56,
        offset: const Offset(0, 28),
      ),
    ];
  }

  static List<BoxShadow> control(ColorScheme colorScheme) {
    return <BoxShadow>[
      BoxShadow(
        color: colorScheme.shadow.withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
