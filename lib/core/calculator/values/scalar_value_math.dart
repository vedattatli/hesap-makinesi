import 'dart:math' as math;

import 'calculator_value.dart';
import 'double_value.dart';
import 'rational_value.dart';
import 'symbolic_simplifier.dart';
import 'symbolic_value.dart';

/// Shared scalar arithmetic helpers used by symbolic and complex values.
class ScalarValueMath {
  const ScalarValueMath._();

  static bool isExactScalar(CalculatorValue value) {
    return value is RationalValue || value is SymbolicValue;
  }

  static bool isZero(CalculatorValue value, {double epsilon = 1e-12}) {
    return switch (value) {
      RationalValue() => value.numerator == BigInt.zero,
      SymbolicValue() =>
        value.tryCollapseToRational()?.numerator == BigInt.zero,
      _ => value.toDouble().abs() < epsilon,
    };
  }

  static CalculatorValue collapse(CalculatorValue value) {
    if (value case final SymbolicValue symbolic) {
      return symbolic.tryCollapseToRational() ?? symbolic;
    }
    return value;
  }

  static CalculatorValue add(CalculatorValue left, CalculatorValue right) {
    if (isExactScalar(left) && isExactScalar(right)) {
      return collapse(SymbolicSimplifier.add(left, right));
    }
    return DoubleValue(left.toDouble() + right.toDouble());
  }

  static CalculatorValue subtract(CalculatorValue left, CalculatorValue right) {
    if (isExactScalar(left) && isExactScalar(right)) {
      return collapse(SymbolicSimplifier.subtract(left, right));
    }
    return DoubleValue(left.toDouble() - right.toDouble());
  }

  static CalculatorValue multiply(CalculatorValue left, CalculatorValue right) {
    if (isExactScalar(left) && isExactScalar(right)) {
      return collapse(SymbolicSimplifier.multiply(left, right));
    }
    return DoubleValue(left.toDouble() * right.toDouble());
  }

  static CalculatorValue divide(CalculatorValue left, CalculatorValue right) {
    if (isZero(right)) {
      throw ArgumentError.value(right, 'right', 'Division by zero.');
    }

    if (isExactScalar(left) && isExactScalar(right)) {
      return collapse(SymbolicSimplifier.divide(left, right));
    }

    return DoubleValue(left.toDouble() / right.toDouble());
  }

  static CalculatorValue negate(CalculatorValue value) {
    if (isExactScalar(value)) {
      return collapse(
        SymbolicSimplifier.multiply(RationalValue.fromInt(-1), value),
      );
    }
    return DoubleValue(-value.toDouble());
  }

  static CalculatorValue abs(CalculatorValue value) {
    if (value case final RationalValue rational) {
      return rational.abs();
    }

    if (value case final SymbolicValue symbolic) {
      return symbolic.toDouble() < 0 ? negate(symbolic) : symbolic;
    }

    return DoubleValue(value.toDouble().abs());
  }

  static CalculatorValue integerPower(CalculatorValue value, int exponent) {
    if (isExactScalar(value)) {
      return collapse(SymbolicSimplifier.integerPower(value, exponent));
    }
    return DoubleValue(math.pow(value.toDouble(), exponent).toDouble());
  }

  static CalculatorValue squareRoot(CalculatorValue value) {
    if (value case final RationalValue rational) {
      return collapse(SymbolicSimplifier.fromRadicalRational(rational));
    }
    return DoubleValue(math.sqrt(value.toDouble()));
  }

  static int compare(CalculatorValue left, CalculatorValue right) {
    if (left is RationalValue && right is RationalValue) {
      return left.compareTo(right);
    }
    return left.toDouble().compareTo(right.toDouble());
  }
}
