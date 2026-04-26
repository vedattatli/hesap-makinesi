import 'package:flutter/widgets.dart';

/// Shared spacing scale for calculator presentation surfaces.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  static const EdgeInsets screen = EdgeInsets.all(lg);
  static const EdgeInsets card = EdgeInsets.all(xl);
  static const EdgeInsets compactCard = EdgeInsets.all(md);
}
