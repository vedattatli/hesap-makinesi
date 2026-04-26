import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  const engine = CalculatorEngine();
  const approximate = CalculationContext(precision: 10);
  const exact = CalculationContext(
    numericMode: NumericMode.exact,
    preferExactResult: true,
    precision: 10,
  );

  group('Final QA deterministic fuzz tests', () {
    test('valid generated expressions parse and evaluate without crashes', () {
      final random = math.Random(1901);
      final lexer = CalculatorLexer();
      final parser = ExpressionParser();

      for (var i = 0; i < 80; i++) {
        final expression = _validExpression(random, depth: 3);

        final tokens = lexer.tokenize(expression);
        expect(
          () => parser.parse(tokens),
          returnsNormally,
          reason: 'Generated expression should parse: $expression',
        );

        late final CalculationOutcome outcome;
        expect(
          () => outcome = engine.evaluate(expression, context: approximate),
          returnsNormally,
          reason: 'Engine should not throw for: $expression',
        );
        expect(
          outcome.error?.type,
          isNot(CalculationErrorType.internalError),
          reason: 'Fuzz input should not surface internal errors: $expression',
        );
        final numericValue = outcome.result?.numericValue;
        if (numericValue != null) {
          expect(
            numericValue.isFinite,
            isTrue,
            reason: 'Finite expression should not format non-finite output.',
          );
        }
      }
    });

    test('malformed expressions fail safely without internal errors', () {
      final random = math.Random(2604);

      for (var i = 0; i < 60; i++) {
        final expression = _malformedExpression(random);
        late final CalculationOutcome outcome;
        expect(
          () => outcome = engine.evaluate(expression, context: approximate),
          returnsNormally,
          reason: 'Malformed input should be reported, not thrown.',
        );
        expect(
          outcome.error?.type,
          isNot(CalculationErrorType.internalError),
          reason:
              'Malformed input should not become internalError: $expression',
        );
      }
    });

    test('equation syntax remains scoped to equation-enabled parsing', () {
      final lexer = CalculatorLexer();
      final parser = ExpressionParser();
      final tokens = lexer.tokenize('x^2 = 4');

      expect(() => parser.parse(tokens), throwsA(anything));

      final equation = parser.parse(tokens, allowEquation: true);
      expect(equation, isA<EquationNode>());

      final badTokens = lexer.tokenize('a = b = c');
      expect(
        () => parser.parse(badTokens, allowEquation: true),
        throwsA(anything),
      );
    });
  });

  group('Final QA property tests', () {
    test('rational addition is commutative for a small exact domain', () {
      for (var a = -5; a <= 5; a++) {
        for (var b = -5; b <= 5; b++) {
          final left = engine.evaluate('$a + $b', context: exact);
          final right = engine.evaluate('$b + $a', context: exact);

          expect(left.error, isNull);
          expect(right.error, isNull);
          expect(left.result!.displayResult, right.result!.displayResult);
        }
      }
    });

    test('multiplication and division roundtrip when divisor is non-zero', () {
      for (var a = -4; a <= 4; a++) {
        for (var b = -4; b <= 4; b++) {
          if (b == 0) {
            continue;
          }
          final outcome = engine.evaluate('($a * $b) / $b', context: exact);

          expect(outcome.error, isNull);
          expect(outcome.result!.numericValue, closeTo(a, 1e-12));
        }
      }
    });

    test('matrix identity multiplication preserves matrix display', () {
      final outcome = engine.evaluate(
        'identity(2)*mat(2,2,1,2,3,4)',
        context: exact,
      );

      expect(outcome.error, isNull);
      expect(outcome.result!.matrixDisplayResult, '[[1, 2], [3, 4]]');
    });

    test('unit conversion roundtrip preserves target unit display', () {
      const units = CalculationContext(
        numericMode: NumericMode.exact,
        unitMode: UnitMode.enabled,
        precision: 10,
      );
      final outcome = engine.evaluate('to(to(100 cm, m), cm)', context: units);

      expect(outcome.error, isNull);
      expect(outcome.result!.displayResult, contains('cm'));
      expect(outcome.result!.unitDisplayResult, contains('cm'));
    });

    test('complex conjugate keeps magnitude invariant', () {
      const complex = CalculationContext(
        numericMode: NumericMode.exact,
        calculationDomain: CalculationDomain.complex,
        precision: 10,
      );
      final original = engine.evaluate('abs(3+4i)', context: complex);
      final conjugate = engine.evaluate('abs(conj(3+4i))', context: complex);

      expect(original.error, isNull);
      expect(conjugate.error, isNull);
      expect(original.result!.numericValue, closeTo(5, 1e-12));
      expect(conjugate.result!.numericValue, closeTo(5, 1e-12));
    });

    test('sin squared plus cos squared remains approximately one', () {
      const radians = CalculationContext(
        angleMode: AngleMode.radian,
        precision: 12,
      );
      for (final x in <String>['0', 'pi/6', 'pi/4', 'pi/3', 'pi/2']) {
        final outcome = engine.evaluate(
          'sin($x)^2 + cos($x)^2',
          context: radians,
        );

        expect(outcome.error, isNull);
        expect(outcome.result!.numericValue, closeTo(1, 1e-10));
      }
    });

    test('mean of repeated dataset values equals the repeated value', () {
      final outcome = engine.evaluate('mean(data(5,5,5,5))', context: exact);

      expect(outcome.error, isNull);
      expect(outcome.result!.numericValue, closeTo(5, 1e-12));
      expect(
        outcome.result!.statisticsDisplayResult?.toLowerCase(),
        contains('mean'),
      );
    });
  });
}

String _validExpression(math.Random random, {required int depth}) {
  if (depth == 0 || random.nextDouble() < 0.32) {
    return '${random.nextInt(9) + 1}';
  }

  final operators = <String>['+', '-', '*', '/', '^'];
  final operator = operators[random.nextInt(operators.length)];
  final left = _validExpression(random, depth: depth - 1);
  final right = switch (operator) {
    '/' => '${random.nextInt(9) + 1}',
    '^' => '${random.nextInt(3) + 1}',
    _ => _validExpression(random, depth: depth - 1),
  };
  return '($left $operator $right)';
}

String _malformedExpression(math.Random random) {
  const alphabet = '()+-*/^,=.abcxyz0123456789';
  final length = random.nextInt(18) + 1;
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(alphabet[random.nextInt(alphabet.length)]);
  }
  return buffer.toString();
}
