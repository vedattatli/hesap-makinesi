import 'symbolic_factor.dart';
import 'rational_value.dart';

/// Canonical symbolic term built from a rational coefficient and factors.
class SymbolicTerm {
  factory SymbolicTerm({
    required RationalValue coefficient,
    Iterable<SymbolicFactor> factors = const <SymbolicFactor>[],
    int maxFactorCount = 24,
  }) {
    return _normalize(
      coefficient: coefficient,
      factors: factors,
      maxFactorCount: maxFactorCount,
    );
  }

  const SymbolicTerm._({
    required this.coefficient,
    required this.factors,
    required this.piPower,
    required this.ePower,
    required this.radicalFactor,
  });

  final RationalValue coefficient;
  final List<SymbolicFactor> factors;
  final int piPower;
  final int ePower;
  final RadicalFactor? radicalFactor;

  bool get isRational => factors.isEmpty;

  bool get isZero => coefficient.numerator == BigInt.zero;

  String get factorKey {
    if (factors.isEmpty) {
      return '';
    }
    return factors.map((factor) => factor.key).join('*');
  }

  String get sortKey {
    if (isRational) {
      return '0:rational';
    }
    final radicalKey = radicalFactor?.key ?? '';
    return '1:$piPower:$ePower:$radicalKey';
  }

  bool hasOnlyConstant(SymbolicConstantKind constantKind, {int power = 1}) {
    if (radicalFactor != null) {
      return false;
    }

    return switch (constantKind) {
      SymbolicConstantKind.pi => piPower == power && ePower == 0,
      SymbolicConstantKind.e => ePower == power && piPower == 0,
    };
  }

  SymbolicTerm scale(RationalValue scalar, {int maxFactorCount = 24}) {
    return SymbolicTerm(
      coefficient: coefficient.multiply(scalar),
      factors: factors,
      maxFactorCount: maxFactorCount,
    );
  }

  SymbolicTerm negate({int maxFactorCount = 24}) {
    return scale(RationalValue.fromInt(-1), maxFactorCount: maxFactorCount);
  }

  SymbolicTerm multiply(SymbolicTerm other, {int maxFactorCount = 24}) {
    final combinedFactors = <SymbolicFactor>[...factors, ...other.factors];
    if (combinedFactors.length > maxFactorCount) {
      throw RangeError.range(
        combinedFactors.length,
        0,
        maxFactorCount,
        'factor count',
      );
    }

    return SymbolicTerm(
      coefficient: coefficient.multiply(other.coefficient),
      factors: combinedFactors,
      maxFactorCount: maxFactorCount,
    );
  }

  double toDouble() {
    var value = coefficient.toDouble();
    for (final factor in factors) {
      value *= factor.toDouble();
    }
    return value;
  }

  String toUnsignedDisplayString() {
    if (isRational) {
      return coefficient.abs().toFractionString();
    }

    final factorDisplay = _factorDisplay();
    final numerator = coefficient.numerator.abs();
    final denominator = coefficient.denominator;

    if (denominator == BigInt.one) {
      if (numerator == BigInt.one) {
        return factorDisplay;
      }
      return '$numerator$factorDisplay';
    }

    if (numerator == BigInt.one) {
      return '$factorDisplay/$denominator';
    }

    return '$numerator$factorDisplay/$denominator';
  }

  String toDisplayString({bool includeSign = true}) {
    final unsigned = toUnsignedDisplayString();
    if (!includeSign || coefficient.numerator >= BigInt.zero) {
      return unsigned;
    }
    return '-$unsigned';
  }

  String _factorDisplay() {
    final parts = <String>[];
    if (piPower > 0) {
      parts.add(_formatPower('π', piPower));
    }
    if (ePower > 0) {
      parts.add(_formatPower('e', ePower));
    }
    if (radicalFactor != null) {
      parts.add(radicalFactor!.displaySymbol);
    }
    return parts.join();
  }

  static String _formatPower(String symbol, int power) {
    if (power <= 1) {
      return symbol;
    }
    return '$symbol^$power';
  }

  static SymbolicTerm _normalize({
    required RationalValue coefficient,
    required Iterable<SymbolicFactor> factors,
    required int maxFactorCount,
  }) {
    if (coefficient.numerator == BigInt.zero) {
      return SymbolicTerm._(
        coefficient: RationalValue.zero,
        factors: const <SymbolicFactor>[],
        piPower: 0,
        ePower: 0,
        radicalFactor: null,
      );
    }

    var piPower = 0;
    var ePower = 0;
    var radicalProduct = BigInt.one;
    for (final factor in factors) {
      switch (factor) {
        case ConstantFactor(constantKind: SymbolicConstantKind.pi):
          piPower += 1;
        case ConstantFactor(constantKind: SymbolicConstantKind.e):
          ePower += 1;
        case RadicalFactor():
          radicalProduct *= factor.radicand;
      }
    }

    final normalizedFactors = <SymbolicFactor>[];
    var normalizedCoefficient = coefficient;
    if (radicalProduct > BigInt.one) {
      final decomposition = _extractSquareFree(radicalProduct);
      if (decomposition.outsideFactor > BigInt.one) {
        normalizedCoefficient = normalizedCoefficient.multiply(
          RationalValue(decomposition.outsideFactor, BigInt.one),
        );
      }
      if (decomposition.remainingFactor > BigInt.one) {
        normalizedFactors.add(RadicalFactor(decomposition.remainingFactor));
      }
    }

    for (var index = 0; index < piPower; index++) {
      normalizedFactors.add(symbolicPiFactor);
    }
    for (var index = 0; index < ePower; index++) {
      normalizedFactors.add(symbolicEFactor);
    }

    normalizedFactors.sort(_compareFactors);
    if (normalizedFactors.length > maxFactorCount) {
      throw RangeError.range(
        normalizedFactors.length,
        0,
        maxFactorCount,
        'factor count',
      );
    }

    RadicalFactor? radicalFactor;
    for (final factor in normalizedFactors) {
      if (factor is RadicalFactor) {
        radicalFactor = factor;
        break;
      }
    }

    return SymbolicTerm._(
      coefficient: normalizedCoefficient,
      factors: List<SymbolicFactor>.unmodifiable(normalizedFactors),
      piPower: piPower,
      ePower: ePower,
      radicalFactor: radicalFactor,
    );
  }

  static int _compareFactors(SymbolicFactor left, SymbolicFactor right) {
    final orderComparison = left.sortOrder.compareTo(right.sortOrder);
    if (orderComparison != 0) {
      return orderComparison;
    }
    return left.key.compareTo(right.key);
  }

  static _SquareFreeDecomposition _extractSquareFree(BigInt value) {
    if (value <= BigInt.one) {
      return _SquareFreeDecomposition(BigInt.one, BigInt.one);
    }

    // Guard: keep very large symbolic radicands exact without expensive
    // factorization. Phase 4 targets symbolic-lite, not full CAS factoring.
    if (value.toString().length > 18) {
      return _SquareFreeDecomposition(BigInt.one, value);
    }

    var remaining = value;
    var outside = BigInt.one;
    var factor = BigInt.two;

    while (factor * factor <= remaining) {
      final square = factor * factor;
      while (remaining.remainder(square) == BigInt.zero) {
        remaining ~/= square;
        outside *= factor;
      }
      factor = factor == BigInt.two ? BigInt.from(3) : factor + BigInt.two;
    }

    return _SquareFreeDecomposition(outside, remaining);
  }
}

class _SquareFreeDecomposition {
  const _SquareFreeDecomposition(this.outsideFactor, this.remainingFactor);

  final BigInt outsideFactor;
  final BigInt remainingFactor;
}
