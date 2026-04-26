import 'calculator_value.dart';
import 'double_value.dart';
import 'rational_value.dart';
import 'symbolic_factor.dart';
import 'symbolic_term.dart';
import 'symbolic_value.dart';

/// Symbolic-lite helpers for radicals, constants and exact term arithmetic.
class SymbolicSimplifier {
  const SymbolicSimplifier._();

  static const maxTermCount = 100;
  static const maxFactorCount = 24;

  static CalculatorValue fromPi() {
    return SymbolicValue.fromFactor(
      symbolicPiFactor,
      maxTermCount: maxTermCount,
      maxFactorCount: maxFactorCount,
    );
  }

  static CalculatorValue fromE() {
    return SymbolicValue.fromFactor(
      symbolicEFactor,
      maxTermCount: maxTermCount,
      maxFactorCount: maxFactorCount,
    );
  }

  static CalculatorValue fromRadicalRational(RationalValue value) {
    if (value.numerator.isNegative) {
      throw ArgumentError.value(value, 'value', 'Radicand must be non-negative.');
    }

    final exactRoot = value.tryExactSquareRoot();
    if (exactRoot != null) {
      return exactRoot;
    }

    final numeratorParts = _extractSquareParts(value.numerator);
    final denominatorParts = _extractSquareParts(value.denominator);
    var coefficient = RationalValue(
      numeratorParts.outsideFactor,
      denominatorParts.outsideFactor,
    );

    BigInt radicand;
    if (denominatorParts.remainingFactor == BigInt.one) {
      radicand = numeratorParts.remainingFactor;
    } else {
      coefficient = coefficient.divide(
        RationalValue(denominatorParts.remainingFactor, BigInt.one),
      );
      radicand =
          numeratorParts.remainingFactor * denominatorParts.remainingFactor;
    }

    if (radicand == BigInt.one) {
      return coefficient;
    }

    return SymbolicValue(
      [
        SymbolicTerm(
          coefficient: coefficient,
          factors: [RadicalFactor(radicand)],
          maxFactorCount: maxFactorCount,
        ),
      ],
      maxTermCount: maxTermCount,
      maxFactorCount: maxFactorCount,
    );
  }

  static CalculatorValue add(CalculatorValue left, CalculatorValue right) {
    if (left is RationalValue && right is RationalValue) {
      return left.add(right);
    }
    return _collapse(
      SymbolicValue(
        [..._toTerms(left), ..._toTerms(right)],
        maxTermCount: maxTermCount,
        maxFactorCount: maxFactorCount,
      ),
    );
  }

  static CalculatorValue subtract(CalculatorValue left, CalculatorValue right) {
    if (left is RationalValue && right is RationalValue) {
      return left.subtract(right);
    }
    final negatedTerms = _toTerms(right)
        .map((term) => term.negate(maxFactorCount: maxFactorCount));
    return _collapse(
      SymbolicValue(
        [..._toTerms(left), ...negatedTerms],
        maxTermCount: maxTermCount,
        maxFactorCount: maxFactorCount,
      ),
    );
  }

  static CalculatorValue multiply(CalculatorValue left, CalculatorValue right) {
    if (left is RationalValue && right is RationalValue) {
      return left.multiply(right);
    }

    final leftTerms = _toTerms(left);
    final rightTerms = _toTerms(right);
    final multipliedTerms = <SymbolicTerm>[];
    for (final leftTerm in leftTerms) {
      for (final rightTerm in rightTerms) {
        multipliedTerms.add(
          leftTerm.multiply(rightTerm, maxFactorCount: maxFactorCount),
        );
      }
    }

    return _collapse(
      SymbolicValue(
        multipliedTerms,
        maxTermCount: maxTermCount,
        maxFactorCount: maxFactorCount,
      ),
    );
  }

  static CalculatorValue divide(CalculatorValue left, CalculatorValue right) {
    if (right is RationalValue && right.numerator == BigInt.zero) {
      throw ArgumentError.value(right, 'right', 'Division by zero.');
    }
    if (right is DoubleValue && right.value == 0) {
      throw ArgumentError.value(right, 'right', 'Division by zero.');
    }

    if (left is RationalValue && right is RationalValue) {
      return left.divide(right);
    }

    if (right is RationalValue) {
      final scaledTerms = _toTerms(left)
          .map(
            (term) => term.scale(
              right.reciprocal(),
              maxFactorCount: maxFactorCount,
            ),
          )
          .toList(growable: false);
      return _collapse(
        SymbolicValue(
          scaledTerms,
          maxTermCount: maxTermCount,
          maxFactorCount: maxFactorCount,
        ),
      );
    }

    final leftSymbolic = _toSymbolicValue(left);
    final rightSymbolic = _toSymbolicValue(right);
    if (!leftSymbolic.isSingleTerm || !rightSymbolic.isSingleTerm) {
      throw UnsupportedError(
        'General symbolic division is not supported in phase 4.',
      );
    }

    return _divideTerms(leftSymbolic.singleTerm!, rightSymbolic.singleTerm!);
  }

  static CalculatorValue integerPower(CalculatorValue base, int exponent) {
    if (exponent == 0) {
      return RationalValue.one;
    }
    if (base is RationalValue) {
      return base.powInteger(exponent);
    }

    if (exponent < 0) {
      final positive = integerPower(base, -exponent);
      return divide(RationalValue.one, positive);
    }

    var result = CalculatorValueHolder(RationalValue.one);
    for (var count = 0; count < exponent; count++) {
      result = CalculatorValueHolder(multiply(result.value, base));
    }
    return result.value;
  }

  static CalculatorValue halfPower(CalculatorValue base) {
    if (base is! RationalValue) {
      throw UnsupportedError('Half power requires a rational base.');
    }
    return fromRadicalRational(base);
  }

  static CalculatorValue negativeHalfPower(CalculatorValue base) {
    final root = halfPower(base);
    return divide(RationalValue.one, root);
  }

  static List<SymbolicTerm> _toTerms(CalculatorValue value) {
    return switch (value) {
      RationalValue() => <SymbolicTerm>[
        SymbolicTerm(
          coefficient: value,
          maxFactorCount: maxFactorCount,
        ),
      ],
      SymbolicValue() => value.terms,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Only exact rational/symbolic values can be converted to symbolic terms.',
      ),
    };
  }

  static SymbolicValue _toSymbolicValue(CalculatorValue value) {
    return switch (value) {
      SymbolicValue() => value,
      RationalValue() => SymbolicValue.fromRational(
        value,
        maxTermCount: maxTermCount,
        maxFactorCount: maxFactorCount,
      ),
      _ => throw ArgumentError.value(value, 'value', 'Unsupported symbolic value.'),
    };
  }

  static CalculatorValue _collapse(SymbolicValue value) {
    final rational = value.tryCollapseToRational();
    return rational ?? value;
  }

  static CalculatorValue _divideTerms(SymbolicTerm numerator, SymbolicTerm denominator) {
    if (denominator.coefficient.numerator == BigInt.zero) {
      throw ArgumentError.value(
        denominator,
        'denominator',
        'Division by zero.',
      );
    }

    var coefficient = numerator.coefficient.divide(denominator.coefficient);
    var piDifference = numerator.piPower - denominator.piPower;
    var eDifference = numerator.ePower - denominator.ePower;

    if (piDifference < 0 || eDifference < 0) {
      throw UnsupportedError(
        'Symbolic constants in the denominator are not supported in phase 4.',
      );
    }

    var value = _collapse(
      SymbolicValue(
        [
          SymbolicTerm(
            coefficient: coefficient,
            factors: [
              for (var index = 0; index < piDifference; index++) symbolicPiFactor,
              for (var index = 0; index < eDifference; index++) symbolicEFactor,
            ],
            maxFactorCount: maxFactorCount,
          ),
        ],
        maxTermCount: maxTermCount,
        maxFactorCount: maxFactorCount,
      ),
    );

    final numeratorRadical = numerator.radicalFactor;
    final denominatorRadical = denominator.radicalFactor;
    if (numeratorRadical == null && denominatorRadical == null) {
      return value;
    }

    if (numeratorRadical != null && denominatorRadical != null) {
      final radicalQuotient = fromRadicalRational(
        RationalValue(numeratorRadical.radicand, denominatorRadical.radicand),
      );
      return multiply(value, radicalQuotient);
    }

    if (numeratorRadical != null) {
      final radicalValue = SymbolicValue.fromFactor(
        numeratorRadical,
        maxTermCount: maxTermCount,
        maxFactorCount: maxFactorCount,
      );
      return multiply(value, radicalValue);
    }

    final radicalValue = fromRadicalRational(
      RationalValue(BigInt.one, denominatorRadical!.radicand),
    );
    return multiply(value, radicalValue);
  }

  static _SquareParts _extractSquareParts(BigInt value) {
    if (value <= BigInt.one) {
      return _SquareParts(BigInt.one, BigInt.one);
    }

    if (value.toString().length > 18) {
      return _SquareParts(BigInt.one, value);
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

    return _SquareParts(outside, remaining);
  }
}

class CalculatorValueHolder {
  const CalculatorValueHolder(this.value);

  final CalculatorValue value;
}

class _SquareParts {
  const _SquareParts(this.outsideFactor, this.remainingFactor);

  final BigInt outsideFactor;
  final BigInt remainingFactor;
}
