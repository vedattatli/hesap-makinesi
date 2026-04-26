import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  group('Phase 13 CAS-lite transforms', () {
    const engine = CalculatorEngine();
    const exact = CalculationContext(numericMode: NumericMode.exact);

    test('simplify combines like polynomial terms and records steps', () {
      final outcome = engine.evaluate('simplify(x + x)', context: exact);

      expect(outcome.isSuccess, isTrue);
      expect(
        outcome.result!.valueKind,
        CalculatorValueKind.expressionTransform,
      );
      expect(outcome.result!.displayResult, '2 * x');
      expect(outcome.result!.summaryDisplayResult, 'simplify');
      expect(outcome.result!.alternativeResults['steps'], isNotNull);
    });

    test('expand supports guarded polynomial products and powers', () {
      final square = engine.evaluate('expand((x + 1)^2)', context: exact);
      final product = engine.evaluate(
        'expand((x - 2)*(x + 3))',
        context: exact,
      );

      expect(square.isSuccess, isTrue);
      expect(square.result!.displayResult, 'x ^ 2 + 2 * x + 1');
      expect(
        square.result!.alternativeResults['steps'],
        contains('polynomial'),
      );

      expect(product.isSuccess, isTrue);
      expect(product.result!.displayResult, 'x ^ 2 + x - 6');
    });

    test('factor handles common patterns and rational roots', () {
      final difference = engine.evaluate('factor(x^2 - 4)', context: exact);
      final perfectSquare = engine.evaluate(
        'factor(x^2 + 2*x + 1)',
        context: exact,
      );
      final cubic = engine.evaluate(
        'factor(x^3 - 6*x^2 + 11*x - 6)',
        context: exact,
      );

      expect(difference.isSuccess, isTrue);
      expect(difference.result!.displayResult, '(x - 2) * (x + 2)');

      expect(perfectSquare.isSuccess, isTrue);
      expect(perfectSquare.result!.displayResult, '(x + 1) ^ 2');

      expect(cubic.isSuccess, isTrue);
      expect(cubic.result!.displayResult, '(x - 1) * (x - 2) * (x - 3)');
      expect(
        cubic.result!.alternativeResults['steps'],
        contains('rational-root'),
      );
    });

    test('unsupported transforms return typed errors', () {
      final outcome = engine.evaluate('expand(sin(x))', context: exact);

      expect(outcome.isFailure, isTrue);
      expect(outcome.error!.type, CalculationErrorType.unsupportedCasTransform);
    });
  });

  group('Phase 13 systems solver', () {
    const engine = CalculatorEngine();
    const exact = CalculationContext(numericMode: NumericMode.exact);

    test('solveSystem solves small exact linear systems', () {
      final outcome = engine.evaluate(
        'solveSystem(eq(2*x + y, 5), eq(x - y, 1), vars(x,y))',
        context: exact,
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.valueKind, CalculatorValueKind.solveResult);
      expect(outcome.result!.displayResult, 'x = 2, y = 1');
      expect(outcome.result!.solveMethod, 'linearSystem');
      expect(
        outcome.result!.alternativeResults['steps'],
        contains('linear system'),
      );
    });

    test('linsolve reuses matrix/vector exact linear algebra', () {
      final outcome = engine.evaluate(
        'linsolve(mat(2,2,2,1,1,-1), vec(5,1))',
        context: exact,
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.valueKind, CalculatorValueKind.vector);
      expect(outcome.result!.displayResult, '[2, 1]');
    });

    test('solveSystem rejects nonlinear systems with typed error', () {
      final outcome = engine.evaluate(
        'solveSystem(eq(x^2 + y, 1), eq(x - y, 0), vars(x,y))',
        context: exact,
      );

      expect(outcome.isFailure, isTrue);
      expect(
        outcome.error!.type,
        CalculationErrorType.nonlinearSystemUnsupported,
      );
    });

    test(
      'existing vars(data) statistics alias remains eager stats behavior',
      () {
        final outcome = engine.evaluate('vars(data(1,2,3))', context: exact);

        expect(outcome.isSuccess, isTrue);
        expect(outcome.result!.displayResult, '1');
      },
    );
  });
}
