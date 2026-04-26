import 'package:flutter/widgets.dart';

/// Radius tokens used by the premium calculator shell.
abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius panel = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius control = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
}
