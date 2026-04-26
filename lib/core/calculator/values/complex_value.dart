import 'dart:math' as math;

import '../angle_mode.dart';
import 'calculator_value.dart';
import 'double_value.dart';
import 'rational_value.dart';
import 'scalar_value_math.dart';

/// Complex value represented in rectangular form.
class ComplexValue extends CalculatorValue {
  factory ComplexValue({
    required CalculatorValue realPart,
    required CalculatorValue imaginaryPart,
  }) {
    if (realPart is ComplexValue || imaginaryPart is ComplexValue) {
      throw ArgumentError(
        'ComplexValue parts must be scalar calculator values.',
      );
    }

    return ComplexValue._(
      realPart: ScalarValueMath.collapse(realPart),
      imaginaryPart: ScalarValueMath.collapse(imaginaryPart),
    );
  }

  const ComplexValue._({
    required this.realPart,
    required this.imaginaryPart,
  });

  final CalculatorValue realPart;
  final CalculatorValue imaginaryPart;

  static ComplexValue get imaginaryUnit =>
      ComplexValue(realPart: RationalValue.zero, imaginaryPart: RationalValue.one);

  static ComplexValue fromScalar(CalculatorValue value) =>
      ComplexValue(realPart: value, imaginaryPart: RationalValue.zero);

  static ComplexValue promote(CalculatorValue value) {
    return value is ComplexValue ? value : ComplexValue.fromScalar(value);
  }

  @override
  CalculatorValueKind get kind => CalculatorValueKind.complex;

  @override
  bool get isExact => realPart.isExact && imaginaryPart.isExact;

  bool get isReal => ScalarValueMath.isZero(imaginaryPart);

  bool get isPureImaginary =>
      ScalarValueMath.isZero(realPart) && !ScalarValueMath.isZero(imaginaryPart);

  @override
  double toDouble() => magnitude().toDouble();

  CalculatorValue simplify() {
    if (isReal) {
      return ScalarValueMath.collapse(realPart);
    }
    return this;
  }

  ComplexValue conjugate() {
    return ComplexValue(
      realPart: realPart,
      imaginaryPart: ScalarValueMath.negate(imaginaryPart),
    );
  }

  CalculatorValue magnitude() {
    final sumOfSquares = ScalarValueMath.add(
      ScalarValueMath.multiply(realPart, realPart),
      ScalarValueMath.multiply(imaginaryPart, imaginaryPart),
    );

    if (sumOfSquares is RationalValue && sumOfSquares.numerator >= BigInt.zero) {
      return ScalarValueMath.squareRoot(sumOfSquares);
    }

    return DoubleValue(math.sqrt(sumOfSquares.toDouble()));
  }

  double argumentRadiansApproximate() {
    return math.atan2(imaginaryPart.toDouble(), realPart.toDouble());
  }

  double argument(AngleMode angleMode) {
    final radians = argumentRadiansApproximate();
    return switch (angleMode) {
      AngleMode.degree => radians * 180 / math.pi,
      AngleMode.radian => radians,
      AngleMode.gradian => radians * 200 / math.pi,
    };
  }

  CalculatorValue addValue(CalculatorValue other) {
    final right = ComplexValue.promote(other);
    return ComplexValue(
      realPart: ScalarValueMath.add(realPart, right.realPart),
      imaginaryPart: ScalarValueMath.add(imaginaryPart, right.imaginaryPart),
    ).simplify();
  }

  CalculatorValue subtractValue(CalculatorValue other) {
    final right = ComplexValue.promote(other);
    return ComplexValue(
      realPart: ScalarValueMath.subtract(realPart, right.realPart),
      imaginaryPart: ScalarValueMath.subtract(
        imaginaryPart,
        right.imaginaryPart,
      ),
    ).simplify();
  }

  CalculatorValue multiplyValue(CalculatorValue other) {
    final right = ComplexValue.promote(other);
    final ac = ScalarValueMath.multiply(realPart, right.realPart);
    final bd = ScalarValueMath.multiply(imaginaryPart, right.imaginaryPart);
    final ad = ScalarValueMath.multiply(realPart, right.imaginaryPart);
    final bc = ScalarValueMath.multiply(imaginaryPart, right.realPart);
    return ComplexValue(
      realPart: ScalarValueMath.subtract(ac, bd),
      imaginaryPart: ScalarValueMath.add(ad, bc),
    ).simplify();
  }

  CalculatorValue divideValue(CalculatorValue other) {
    final right = ComplexValue.promote(other);
    final denominator = ScalarValueMath.add(
      ScalarValueMath.multiply(right.realPart, right.realPart),
      ScalarValueMath.multiply(right.imaginaryPart, right.imaginaryPart),
    );
    if (ScalarValueMath.isZero(denominator)) {
      throw ArgumentError.value(other, 'other', 'Division by zero.');
    }

    final ac = ScalarValueMath.multiply(realPart, right.realPart);
    final bd = ScalarValueMath.multiply(imaginaryPart, right.imaginaryPart);
    final bc = ScalarValueMath.multiply(imaginaryPart, right.realPart);
    final ad = ScalarValueMath.multiply(realPart, right.imaginaryPart);

    return ComplexValue(
      realPart: ScalarValueMath.divide(
        ScalarValueMath.add(ac, bd),
        denominator,
      ),
      imaginaryPart: ScalarValueMath.divide(
        ScalarValueMath.subtract(bc, ad),
        denominator,
      ),
    ).simplify();
  }

  CalculatorValue negateValue() {
    return ComplexValue(
      realPart: ScalarValueMath.negate(realPart),
      imaginaryPart: ScalarValueMath.negate(imaginaryPart),
    ).simplify();
  }

  CalculatorValue reciprocal() {
    return ComplexValue.fromScalar(RationalValue.one).divideValue(this);
  }

  CalculatorValue integerPower(int exponent) {
    if (exponent == 0) {
      return RationalValue.one;
    }

    if (exponent < 0) {
      final reciprocalValue = reciprocal();
      if (reciprocalValue case final ComplexValue complex) {
        return complex.integerPower(-exponent);
      }
      return ScalarValueMath.integerPower(reciprocalValue, -exponent);
    }

    CalculatorValue result = RationalValue.one;
    CalculatorValue base = this;
    var remaining = exponent;
    while (remaining > 0) {
      if (remaining.isOdd) {
        result = ComplexValue.promote(result).multiplyValue(base);
      }
      remaining ~/= 2;
      if (remaining > 0) {
        base = ComplexValue.promote(base).multiplyValue(base);
      }
    }

    return result is ComplexValue ? result.simplify() : result;
  }
}
