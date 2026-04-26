import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  final engine = const CalculatorEngine();
  final lexer = const CalculatorLexer();
  final parser = const ExpressionParser();

  ExpressionNode parse(String expression) {
    return parser.parse(lexer.tokenize(expression));
  }

  group('Worksheet scoped evaluator', () {
    test('default evaluation keeps unknown variables undefined', () {
      final outcome = engine.evaluate('a + 1');

      expect(outcome.isFailure, isTrue);
      expect(outcome.error?.type, CalculationErrorType.unknownConstant);
    });

    test('scoped variable evaluation resolves worksheet symbols only when provided', () {
      final outcome = engine.evaluate(
        'a + 1',
        context: const CalculationContext(numericMode: NumericMode.exact),
        scope: EvaluationScope(
          variables: <String, CalculatorValue>{'a': RationalValue.fromInt(2)},
        ),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result?.displayResult, '3');
    });

    test('default evaluation keeps unknown worksheet functions unsupported', () {
      final outcome = engine.evaluate('f(3)');

      expect(outcome.isFailure, isTrue);
      expect(outcome.error?.type, CalculationErrorType.unknownFunction);
    });

    test('scoped function evaluation resolves worksheet-defined functions', () {
      final function = ScopedFunctionDefinition(
        name: 'f',
        parameters: const <String>['x'],
        bodyExpression: 'x^2',
        normalizedBodyExpression: 'x ^ 2',
        bodyAst: parse('x^2'),
        sourceId: 'function-block',
      );
      final outcome = engine.evaluate(
        'f(3)',
        context: const CalculationContext(numericMode: NumericMode.exact),
        scope: EvaluationScope(
          functions: <String, ScopedFunctionDefinition>{'f': function},
        ),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result?.displayResult, '9');
    });

    test('function parameters shadow worksheet variables', () {
      final function = ScopedFunctionDefinition(
        name: 'f',
        parameters: const <String>['x'],
        bodyExpression: 'x + 1',
        normalizedBodyExpression: 'x + 1',
        bodyAst: parse('x + 1'),
        sourceId: 'function-block',
      );
      final outcome = engine.evaluate(
        'f(2)',
        context: const CalculationContext(numericMode: NumericMode.exact),
        scope: EvaluationScope(
          variables: <String, CalculatorValue>{'x': RationalValue.fromInt(10)},
          functions: <String, ScopedFunctionDefinition>{'f': function},
        ),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result?.displayResult, '3');
    });

    test('built-in functions cannot be overridden by scope functions', () {
      final fakeSin = ScopedFunctionDefinition(
        name: 'sin',
        parameters: const <String>['x'],
        bodyExpression: '42',
        normalizedBodyExpression: '42',
        bodyAst: parse('42'),
        sourceId: 'fake-sin',
      );
      final outcome = engine.evaluate(
        'sin(0)',
        scope: EvaluationScope(
          functions: <String, ScopedFunctionDefinition>{'sin': fakeSin},
        ),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result?.displayResult, '0');
    });
  });
}
