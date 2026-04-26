import '../values/rational_value.dart';
import 'dimension_vector.dart';

/// Distinguishes regular units from affine absolute and delta temperatures.
enum UnitValueFlavor { regular, affineAbsolute, affineDelta }

/// Registry entry for a named unit symbol and its SI conversion metadata.
class UnitDefinition {
  UnitDefinition({
    required this.canonicalKey,
    required this.displaySymbol,
    required this.aliases,
    required this.dimension,
    required this.factorToBase,
    RationalValue? offsetToBase,
    this.flavor = UnitValueFlavor.regular,
  }) : offsetToBase = offsetToBase ?? RationalValue.zero;

  final String canonicalKey;
  final String displaySymbol;
  final List<String> aliases;
  final DimensionVector dimension;
  final RationalValue factorToBase;
  final RationalValue offsetToBase;
  final UnitValueFlavor flavor;

  bool get isAffine => flavor == UnitValueFlavor.affineAbsolute;

  bool get isDeltaUnit => flavor == UnitValueFlavor.affineDelta;

  bool get isRegular => flavor == UnitValueFlavor.regular;
}
