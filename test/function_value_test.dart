import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  ExpressionNode parseExpression(String source) {
    const lexer = CalculatorLexer();
    const parser = ExpressionParser();
    return parser.parse(lexer.tokenize(source));
  }

  group('FunctionValue and scoped graph evaluation', () {
    test('creates function value with normalized display data', () {
      final expression = FunctionExpression(
        originalExpression: 'x^2',
        expressionAst: parseExpression('x^2'),
      );
      final value = FunctionValue(function: expression);

      expect(value.kind, CalculatorValueKind.function);
      expect(value.variableName, 'x');
      expect(value.normalizedExpression, 'x ^ 2');
    });

    test('graph scope evaluates x + 1 with x = 2', () {
      final analysis = const GraphAnalysis();
      final expression = FunctionExpression(
        originalExpression: 'x + 1',
        expressionAst: parseExpression('x + 1'),
      );

      final result = analysis.evalAt(
        expression,
        RationalValue(BigInt.from(2), BigInt.one),
        const CalculationContext(numericMode: NumericMode.exact),
      );

      expect(result.toDouble(), 3);
    });

    test('sin(x) evaluates at pi/2 inside graph scope', () {
      final analysis = const GraphAnalysis();
      final expression = FunctionExpression(
        originalExpression: 'sin(x)',
        expressionAst: parseExpression('sin(x)'),
      );

      final result = analysis.evalAt(
        expression,
        DoubleValue(math.pi / 2),
        const CalculationContext(angleMode: AngleMode.radian),
      );

      expect(result.toDouble(), closeTo(1, 1e-10));
    });
  });
}
