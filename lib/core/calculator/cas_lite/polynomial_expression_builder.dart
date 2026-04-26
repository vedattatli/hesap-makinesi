import '../ast_nodes.dart';
import '../solve/expression_transformer.dart';
import '../solve/polynomial.dart';
import '../values/calculator_value.dart';
import '../values/rational_value.dart';
import '../values/scalar_value_math.dart';

class PolynomialExpressionBuilder {
  const PolynomialExpressionBuilder();

  ExpressionNode build(Polynomial polynomial) {
    if (polynomial.isZero) {
      return ExpressionTransformer.zero();
    }

    ExpressionNode? expression;
    final degrees = polynomial.coefficients.keys.toList(growable: false)
      ..sort((left, right) => right.compareTo(left));
    for (final degree in degrees) {
      final coefficient = polynomial.coefficientOf(degree);
      if (ScalarValueMath.isZero(coefficient)) {
        continue;
      }
      final term = _term(
        polynomial.variableName,
        degree,
        ScalarValueMath.abs(coefficient),
      );
      final isNegative = coefficient.toDouble() < -1e-12;
      if (expression == null) {
        expression = isNegative ? ExpressionTransformer.negate(term) : term;
      } else {
        expression = isNegative
            ? ExpressionTransformer.subtract(expression, term)
            : ExpressionTransformer.add(expression, term);
      }
    }
    return expression ?? ExpressionTransformer.zero();
  }

  ExpressionNode _term(
    String variableName,
    int degree,
    CalculatorValue coefficient,
  ) {
    final coefficientNode = _valueToNode(coefficient);
    if (degree == 0) {
      return coefficientNode;
    }

    final variableNode = degree == 1
        ? ConstantNode(name: variableName, position: 0)
        : ExpressionTransformer.power(
            ConstantNode(name: variableName, position: 0),
            ExpressionTransformer.integer(degree),
          );
    if (_isOne(coefficient)) {
      return variableNode;
    }
    return ExpressionTransformer.multiply(coefficientNode, variableNode);
  }

  ExpressionNode _valueToNode(CalculatorValue value) {
    if (value case final RationalValue rational) {
      final numerator = rational.numerator.toInt();
      if (rational.denominator == BigInt.one) {
        return ExpressionTransformer.integer(numerator);
      }
      return ExpressionTransformer.divide(
        ExpressionTransformer.integer(numerator),
        ExpressionTransformer.integer(rational.denominator.toInt()),
      );
    }
    final numeric = value.toDouble();
    if (numeric.isFinite && numeric == numeric.roundToDouble()) {
      return ExpressionTransformer.integer(numeric.round());
    }
    return NumberNode(
      rawValue: numeric.toString(),
      value: numeric,
      position: 0,
    );
  }

  bool _isOne(CalculatorValue value) {
    if (value case final RationalValue rational) {
      return rational.numerator == BigInt.one &&
          rational.denominator == BigInt.one;
    }
    return (value.toDouble() - 1).abs() < 1e-12;
  }
}
