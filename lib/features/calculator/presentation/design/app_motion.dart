import 'package:flutter/widgets.dart';

/// Motion tokens. Callers pass [reduceMotion] to collapse transitions safely.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 1);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration expressive = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  static Duration duration(Duration duration, {required bool reduceMotion}) {
    return reduceMotion ? instant : duration;
  }
}
