import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  group('CalculatorEngine CAS-lite solving', () {
    const engine = CalculatorEngine();
    const exact = CalculationContext(numericMode: NumericMode.exact);
    const exactRad = CalculationContext(
      numericMode: NumericMode.exact,
      angleMode: AngleMode.radian,
    );
    const complexExact = CalculationContext(
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.complex,
    );

    test('solves exact linear equations and expression equals zero form', () {
      final equation = engine.evaluate('solve(2*x + 3 = 7, x)', context: exact);
      final expression = engine.evaluate('solve(2*x + 3, x)', context: exact);

      expect(equation.isSuccess, isTrue);
      expect(equation.result!.displayResult, 'x = 2');
      expect(equation.result!.solveMethod, 'exactLinear');
      expect(equation.result!.solutionCount, 1);

      expect(expression.isSuccess, isTrue);
      expect(expression.result!.displayResult, 'x = -3/2');
      expect(expression.result!.equationDisplayResult, '2 * x + 3 = 0');
    });

    test('solves scoped linear equations with worksheet-style variables', () {
      final outcome = engine.evaluate(
        'solve(a*x + 4 = 0, x)',
        context: exact,
        scope: EvaluationScope(
          variables: <String, CalculatorValue>{'a': RationalValue.fromInt(2)},
        ),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.displayResult, 'x = -2');
    });

    test('solves exact quadratic equations in real and complex domains', () {
      final quadratic = engine.evaluate('solve(x^2 - 4 = 0, x)', context: exact);
      final repeated = engine.evaluate(
        'solve(x^2 + 2*x + 1 = 0, x)',
        context: exact,
      );
      final irrational = engine.evaluate(
        'solve(x^2 - 2 = 0, x)',
        context: exact,
      );
      final realNone = engine.evaluate('solve(x^2 + 1 = 0, x)', context: exact);
      final complexRoots = engine.evaluate(
        'solve(x^2 + 1 = 0, x)',
        context: complexExact,
      );

      expect(quadratic.isSuccess, isTrue);
      expect(quadratic.result!.displayResult, 'x = {-2, 2}');
      expect(quadratic.result!.solveMethod, 'exactQuadratic');

      expect(repeated.isSuccess, isTrue);
      expect(repeated.result!.displayResult, 'x = -1');

      expect(irrational.isSuccess, isTrue);
      expect(irrational.result!.displayResult, contains('\u221A2'));
      expect(irrational.result!.solutionCount, 2);

      expect(realNone.isSuccess, isTrue);
      expect(realNone.result!.displayResult, 'No solution');
      expect(realNone.result!.solveDomain, 'real');

      expect(complexRoots.isSuccess, isTrue);
      expect(complexRoots.result!.displayResult, contains('i'));
      expect(complexRoots.result!.solveDomain, 'complex');
    });

    test('solves rational-root polynomials exactly', () {
      final outcome = engine.evaluate(
        'solve(x^3 - 6*x^2 + 11*x - 6 = 0, x)',
        context: exact,
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.displayResult, 'x = {1, 2, 3}');
      expect(outcome.result!.solveMethod, 'rationalRootPolynomial');
      expect(outcome.result!.solutionCount, 3);
    });

    test('numeric solve reuses interval-based graph solving behavior', () {
      final solveSin = engine.evaluate(
        'solve(sin(x)=0, x, -pi, pi)',
        context: exactRad,
      );
      final nsolve = engine.evaluate(
        'nsolve(cos(x)-x, x, 0, 1)',
        context: exactRad,
      );

      expect(
        solveSin.isSuccess,
        isTrue,
        reason: '${solveSin.error?.type} ${solveSin.error?.message}',
      );
      expect(solveSin.result!.isApproximate, isTrue);
      expect(solveSin.result!.solveMethod, 'graphRootReuse');
      expect(solveSin.result!.solutionCount, 3);
      expect(solveSin.result!.displayResult, contains('0'));

      expect(
        nsolve.isSuccess,
        isTrue,
        reason: '${nsolve.error?.type} ${nsolve.error?.message}',
      );
      expect(nsolve.result!.isApproximate, isTrue);
      expect(nsolve.result!.solveMethod, 'numericBisection');
      expect(nsolve.result!.displayResult, contains('0.739'));
    });

    test('non-polynomial solve without interval returns typed error', () {
      final outcome = engine.evaluate('solve(sin(x)=0, x)', context: exactRad);

      expect(outcome.isFailure, isTrue);
      expect(
        outcome.error!.type,
        CalculationErrorType.unsupportedSolveForm,
      );
    });

    test('diff derivativeAt integral and integrate are available', () {
      final diff = engine.evaluate('diff(x^2, x)', context: exact);
      final derivativeAt = engine.evaluate(
        'derivativeAt(x^2, x, 3)',
        context: exact,
      );
      final integral = engine.evaluate('integral(2*x, x)', context: exact);
      final integrate = engine.evaluate(
        'integrate(sin(x), x, 0, pi)',
        context: exactRad,
      );

      expect(diff.isSuccess, isTrue);
      expect(diff.result!.valueKind, CalculatorValueKind.expressionTransform);
      expect(diff.result!.displayResult, contains('2'));
      expect(diff.result!.derivativeDisplayResult, isNotNull);

      expect(derivativeAt.isSuccess, isTrue);
      expect(derivativeAt.result!.numericValue, closeTo(6, 1e-8));

      expect(integral.isSuccess, isTrue);
      expect(integral.result!.valueKind, CalculatorValueKind.expressionTransform);
      expect(integral.result!.integralDisplayResult, isNotNull);

      expect(integrate.isSuccess, isTrue);
      expect(integrate.result!.numericValue, closeTo(2, 1e-3));
    });

    test('unsupported derivative forms return typed errors', () {
      final outcome = engine.evaluate('diff(abs(x), x)', context: exact);

      expect(outcome.isFailure, isTrue);
      expect(
        outcome.error!.type,
        CalculationErrorType.unsupportedExpressionTransform,
      );
    });
  });
}
