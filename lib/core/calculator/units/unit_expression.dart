import 'dart:collection';

import '../values/rational_value.dart';
import 'dimension_vector.dart';
import 'unit_definition.dart';

/// Canonical display-oriented unit expression such as `km/h` or `m^2`.
class UnitExpression {
  factory UnitExpression({
    required Map<String, int> exponents,
    required Map<String, String> displaySymbols,
    required DimensionVector dimension,
    required RationalValue factorToBase,
    RationalValue? offsetToBase,
    UnitValueFlavor flavor = UnitValueFlavor.regular,
  }) {
    final normalizedExponents = <String, int>{};
    final normalizedDisplaySymbols = <String, String>{};

    for (final entry in exponents.entries) {
      if (entry.value == 0) {
        continue;
      }
      normalizedExponents[entry.key] = entry.value;
      normalizedDisplaySymbols[entry.key] =
          displaySymbols[entry.key] ?? entry.key;
    }

    if (normalizedExponents.isEmpty) {
      return UnitExpression.dimensionless();
    }

    return UnitExpression._(
      exponents: Map<String, int>.unmodifiable(normalizedExponents),
      displaySymbols: Map<String, String>.unmodifiable(normalizedDisplaySymbols),
      dimension: dimension,
      factorToBase: factorToBase,
      offsetToBase: offsetToBase ?? RationalValue.zero,
      flavor: flavor,
    );
  }

  factory UnitExpression.fromDefinition(UnitDefinition definition) {
    return UnitExpression(
      exponents: <String, int>{definition.canonicalKey: 1},
      displaySymbols: <String, String>{
        definition.canonicalKey: definition.displaySymbol,
      },
      dimension: definition.dimension,
      factorToBase: definition.factorToBase,
      offsetToBase: definition.offsetToBase,
      flavor: definition.flavor,
    );
  }

  factory UnitExpression.dimensionless() {
    return UnitExpression._(
      exponents: const <String, int>{},
      displaySymbols: const <String, String>{},
      dimension: DimensionVector.dimensionless,
      factorToBase: RationalValue.one,
      offsetToBase: RationalValue.zero,
      flavor: UnitValueFlavor.regular,
    );
  }

  UnitExpression._({
    required this.exponents,
    required this.displaySymbols,
    required this.dimension,
    required this.factorToBase,
    required this.offsetToBase,
    required this.flavor,
  });

  final Map<String, int> exponents;
  final Map<String, String> displaySymbols;
  final DimensionVector dimension;
  final RationalValue factorToBase;
  final RationalValue offsetToBase;
  final UnitValueFlavor flavor;

  bool get isDimensionless => dimension.isDimensionless || exponents.isEmpty;

  bool get isAffineAbsolute => flavor == UnitValueFlavor.affineAbsolute;

  bool get isAffineDelta => flavor == UnitValueFlavor.affineDelta;

  bool get isSingleUnit =>
      exponents.length == 1 && exponents.values.single == 1;

  String? get singleCanonicalKey => isSingleUnit ? exponents.keys.single : null;

  int get factorCount => exponents.length;

  UnitExpression multiply(UnitExpression other) {
    if (isAffineAbsolute || other.isAffineAbsolute) {
      throw UnsupportedError(
        'Affine absolute units cannot be multiplied into compound expressions.',
      );
    }

    final nextExponents = LinkedHashMap<String, int>.from(exponents);
    final nextDisplaySymbols = LinkedHashMap<String, String>.from(displaySymbols);
    for (final entry in other.exponents.entries) {
      nextExponents.update(
        entry.key,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
      nextDisplaySymbols.putIfAbsent(
        entry.key,
        () => other.displaySymbols[entry.key] ?? entry.key,
      );
      if (nextExponents[entry.key] == 0) {
        nextExponents.remove(entry.key);
        nextDisplaySymbols.remove(entry.key);
      }
    }

    final nextFlavor = isDimensionless
        ? other.flavor
        : other.isDimensionless
        ? flavor
        : UnitValueFlavor.regular;

    return UnitExpression(
      exponents: nextExponents,
      displaySymbols: nextDisplaySymbols,
      dimension: dimension.add(other.dimension),
      factorToBase: factorToBase.multiply(other.factorToBase),
      flavor: nextFlavor,
    );
  }

  UnitExpression divide(UnitExpression other) {
    if (isAffineAbsolute || other.isAffineAbsolute) {
      throw UnsupportedError(
        'Affine absolute units cannot be divided into compound expressions.',
      );
    }

    final nextExponents = LinkedHashMap<String, int>.from(exponents);
    final nextDisplaySymbols = LinkedHashMap<String, String>.from(displaySymbols);
    for (final entry in other.exponents.entries) {
      nextExponents.update(
        entry.key,
        (value) => value - entry.value,
        ifAbsent: () => -entry.value,
      );
      nextDisplaySymbols.putIfAbsent(
        entry.key,
        () => other.displaySymbols[entry.key] ?? entry.key,
      );
      if (nextExponents[entry.key] == 0) {
        nextExponents.remove(entry.key);
        nextDisplaySymbols.remove(entry.key);
      }
    }

    final nextFlavor = isDimensionless
        ? other.flavor == UnitValueFlavor.affineDelta
              ? UnitValueFlavor.affineDelta
              : UnitValueFlavor.regular
        : UnitValueFlavor.regular;

    return UnitExpression(
      exponents: nextExponents,
      displaySymbols: nextDisplaySymbols,
      dimension: dimension.subtract(other.dimension),
      factorToBase: factorToBase.divide(other.factorToBase),
      flavor: nextFlavor,
    );
  }

  UnitExpression integerPower(int exponent) {
    if (exponent == 0) {
      return UnitExpression.dimensionless();
    }
    if (isAffineAbsolute && exponent != 1) {
      throw UnsupportedError(
        'Affine absolute units do not support non-trivial powers.',
      );
    }

    final nextExponents = <String, int>{};
    for (final entry in exponents.entries) {
      nextExponents[entry.key] = entry.value * exponent;
    }

    final nextFactor = exponent > 0
        ? factorToBase.powInteger(exponent)
        : factorToBase.reciprocal().powInteger(-exponent);

    return UnitExpression(
      exponents: nextExponents,
      displaySymbols: displaySymbols,
      dimension: dimension.multiplyByExponent(exponent),
      factorToBase: nextFactor,
      flavor: exponent == 1 ? flavor : UnitValueFlavor.regular,
    );
  }

  UnitExpression? squareRoot() {
    if (isAffineAbsolute) {
      return null;
    }
    if (exponents.values.any((value) => value.isOdd)) {
      return null;
    }

    final dimensionParts = <int>[
      dimension.length,
      dimension.mass,
      dimension.time,
      dimension.electricCurrent,
      dimension.thermodynamicTemperature,
      dimension.amountOfSubstance,
      dimension.luminousIntensity,
    ];
    if (dimensionParts.any((value) => value.isOdd)) {
      return null;
    }

    final factorRoot = factorToBase.tryExactSquareRoot();
    if (factorRoot == null) {
      return null;
    }

    final nextExponents = <String, int>{};
    for (final entry in exponents.entries) {
      nextExponents[entry.key] = entry.value ~/ 2;
    }

    return UnitExpression(
      exponents: nextExponents,
      displaySymbols: displaySymbols,
      dimension: dimension.divideByExponent(2),
      factorToBase: factorRoot,
      flavor: isAffineDelta ? UnitValueFlavor.affineDelta : UnitValueFlavor.regular,
    );
  }

  String toDisplayString() {
    if (isDimensionless) {
      return '1';
    }

    final numerator = <String>[];
    final denominator = <String>[];

    for (final entry in exponents.entries) {
      final symbol = displaySymbols[entry.key] ?? entry.key;
      if (entry.value > 0) {
        numerator.add(_formatUnitSymbol(symbol, entry.value));
      } else {
        denominator.add(_formatUnitSymbol(symbol, -entry.value));
      }
    }

    final numeratorText = numerator.isEmpty ? '1' : numerator.join('*');
    if (denominator.isEmpty) {
      return numeratorText;
    }
    return '$numeratorText/${denominator.join('*')}';
  }

  @override
  String toString() => toDisplayString();

  @override
  bool operator ==(Object other) {
    return other is UnitExpression &&
        _mapEquals(exponents, other.exponents) &&
        _mapEquals(displaySymbols, other.displaySymbols) &&
        dimension == other.dimension &&
        factorToBase.compareTo(other.factorToBase) == 0 &&
        offsetToBase.compareTo(other.offsetToBase) == 0 &&
        flavor == other.flavor;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(exponents.entries.map((entry) => Object.hash(entry.key, entry.value))),
    Object.hashAll(
      displaySymbols.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    dimension,
    factorToBase.numerator,
    factorToBase.denominator,
    offsetToBase.numerator,
    offsetToBase.denominator,
    flavor,
  );

  static bool _mapEquals<T>(Map<String, T> left, Map<String, T> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  static String _formatUnitSymbol(String symbol, int exponent) {
    if (exponent == 1) {
      return symbol;
    }
    return '$symbol${_superscript(exponent)}';
  }

  static String _superscript(int exponent) {
    const digits = <String, String>{
      '-': '⁻',
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
    };
    return exponent
        .toString()
        .split('')
        .map((character) => digits[character] ?? character)
        .join();
  }
}
