import 'package:flutter/material.dart';

/// Domain-specific color helpers for badges and panels.
abstract final class SemanticColors {
  static Color success(ColorScheme scheme) => const Color(0xFF059669);
  static Color warning(ColorScheme scheme) => const Color(0xFFD97706);
  static Color exact(ColorScheme scheme) => scheme.primary;
  static Color approximate(ColorScheme scheme) => scheme.tertiary;
  static Color symbolic(ColorScheme scheme) => const Color(0xFF7C3AED);
  static Color complex(ColorScheme scheme) => const Color(0xFF0891B2);
  static Color unit(ColorScheme scheme) => const Color(0xFF65A30D);
  static Color graph(ColorScheme scheme) => const Color(0xFF2563EB);
  static Color worksheet(ColorScheme scheme) => const Color(0xFFDB2777);
  static Color cas(ColorScheme scheme) => const Color(0xFFEA580C);

  static Color containerFor(Color color, Brightness brightness) {
    return Color.alphaBlend(
      color.withValues(alpha: brightness == Brightness.dark ? 0.24 : 0.14),
      brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
    );
  }
}
