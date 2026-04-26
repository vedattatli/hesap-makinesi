import '../values/calculator_value.dart';
import '../values/rational_value.dart';
import '../values/scalar_value_math.dart';

class Polynomial {
  Polynomial({
    required this.variableName,
    required Map<int, CalculatorValue> coefficients,
  }) : coefficients = Map<int, CalculatorValue>.unmodifiable(
         coefficients
             .map((degree, value) => MapEntry(degree, ScalarValueMath.collapse(value)))
             .cast<int, CalculatorValue>()
           ..removeWhere((_, value) => ScalarValueMath.isZero(value)),
       );

  final String variableName;
  final Map<int, CalculatorValue> coefficients;

  int get degree =>
      coefficients.isEmpty ? 0 : coefficients.keys.reduce((a, b) => a > b ? a : b);

  bool get isZero => coefficients.isEmpty;

  bool get isExact => coefficients.values.every((value) => value.isExact);

  CalculatorValue coefficientOf(int degree) =>
      coefficients[degree] ?? RationalValue.zero;

  Iterable<int> get orderedDegrees =>
      coefficients.keys.toList(growable: false)..sort((a, b) => a.compareTo(b));

  Polynomial add(Polynomial other) {
    final result = <int, CalculatorValue>{...coefficients};
    for (final entry in other.coefficients.entries) {
      result.update(
        entry.key,
        (current) => ScalarValueMath.add(current, entry.value),
        ifAbsent: () => entry.value,
      );
    }
    return Polynomial(variableName: variableName, coefficients: result);
  }

  Polynomial subtract(Polynomial other) {
    final result = <int, CalculatorValue>{...coefficients};
    for (final entry in other.coefficients.entries) {
      result.update(
        entry.key,
        (current) => ScalarValueMath.subtract(current, entry.value),
        ifAbsent: () => ScalarValueMath.negate(entry.value),
      );
    }
    return Polynomial(variableName: variableName, coefficients: result);
  }

  Polynomial multiply(Polynomial other) {
    final result = <int, CalculatorValue>{};
    for (final left in coefficients.entries) {
      for (final right in other.coefficients.entries) {
        final degree = left.key + right.key;
        final value = ScalarValueMath.multiply(left.value, right.value);
        result.update(
          degree,
          (current) => ScalarValueMath.add(current, value),
          ifAbsent: () => value,
        );
      }
    }
    return Polynomial(variableName: variableName, coefficients: result);
  }

  Polynomial scale(CalculatorValue scalar) {
    final result = <int, CalculatorValue>{};
    for (final entry in coefficients.entries) {
      result[entry.key] = ScalarValueMath.multiply(entry.value, scalar);
    }
    return Polynomial(variableName: variableName, coefficients: result);
  }

  Polynomial divideByScalar(CalculatorValue scalar) {
    final result = <int, CalculatorValue>{};
    for (final entry in coefficients.entries) {
      result[entry.key] = ScalarValueMath.divide(entry.value, scalar);
    }
    return Polynomial(variableName: variableName, coefficients: result);
  }

  CalculatorValue evaluate(CalculatorValue x) {
    CalculatorValue total = RationalValue.zero;
    for (final degree in orderedDegrees) {
      final coefficient = coefficientOf(degree);
      final power = degree == 0
          ? RationalValue.one
          : ScalarValueMath.integerPower(x, degree);
      total = ScalarValueMath.add(
        total,
        ScalarValueMath.multiply(coefficient, power),
      );
    }
    return total;
  }

  List<RationalValue>? rationalCoefficientsDescending() {
    final coefficients = <RationalValue>[];
    for (var degree = this.degree; degree >= 0; degree--) {
      final coefficient = coefficientOf(degree);
      if (coefficient is RationalValue) {
        coefficients.add(coefficient);
      } else {
        return null;
      }
    }
    return List<RationalValue>.unmodifiable(coefficients);
  }
}

