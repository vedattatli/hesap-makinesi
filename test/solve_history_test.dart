import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/features/calculator/application/calculator_controller.dart';
import 'package:hesap_makinesi/features/calculator/data/calculator_history_item.dart';
import 'package:hesap_makinesi/features/calculator/data/memory_calculator_storage.dart';

void main() {
  group('Solve history integration', () {
    test('solve results are stored with solve metadata in history', () async {
      final controller = CalculatorController(storage: MemoryCalculatorStorage());
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);

      controller.setExpression('solve(x^2 - 4 = 0, x)');
      await controller.evaluate();

      final item = controller.state.history.single;
      expect(item.valueKind, CalculatorValueKind.solveResult);
      expect(item.solveDisplayResult, 'x = {-2, 2}');
      expect(item.equationDisplayResult, 'x ^ 2 - 4 = 0');
      expect(item.solutionCount, 2);
      expect(item.solveMethod, 'exactQuadratic');
      expect(item.solveDomain, 'real');
    });

    test('solve history serializes and restores new metadata safely', () {
      final now = DateTime.utc(2026, 4, 26, 15);
      final item = CalculatorHistoryItem(
        id: 'solve-1',
        expression: 'solve(x^2-4=0,x)',
        normalizedExpression: 'solve(x ^ 2 - 4 = 0, x)',
        displayResult: 'x = {-2, 2}',
        numericValue: null,
        angleMode: AngleMode.radian,
        precision: 10,
        isApproximate: false,
        numericMode: NumericMode.exact,
        calculationDomain: CalculationDomain.real,
        unitMode: UnitMode.disabled,
        resultFormat: NumberFormatStyle.auto,
        valueKind: CalculatorValueKind.solveResult,
        warnings: const <String>[],
        createdAt: now,
        equationDisplayResult: 'x ^ 2 - 4 = 0',
        solveDisplayResult: 'x = {-2, 2}',
        solutionsDisplayResult: '{-2, 2}',
        solutionCount: 2,
        solveVariable: 'x',
        solveMethod: 'exactQuadratic',
        solveDomain: 'real',
      );

      final decoded = CalculatorHistoryItem.fromJson(item.toJson());

      expect(decoded.valueKind, CalculatorValueKind.solveResult);
      expect(decoded.solveDisplayResult, 'x = {-2, 2}');
      expect(decoded.equationDisplayResult, 'x ^ 2 - 4 = 0');
      expect(decoded.solutionCount, 2);
      expect(decoded.solveVariable, 'x');
      expect(decoded.solveMethod, 'exactQuadratic');
      expect(decoded.solveDomain, 'real');
    });

    test('result formatter exposes equation and transform metadata', () {
      const engine = CalculatorEngine();
      final solve = engine.evaluate(
        'solve(x^2 - 4 = 0, x)',
        context: const CalculationContext(numericMode: NumericMode.exact),
      );
      final derivative = engine.evaluate(
        'diff(x^2, x)',
        context: const CalculationContext(numericMode: NumericMode.exact),
      );

      expect(solve.result!.equationDisplayResult, 'x ^ 2 - 4 = 0');
      expect(solve.result!.solutionsDisplayResult, '{-2, 2}');
      expect(derivative.result!.valueKind, CalculatorValueKind.expressionTransform);
      expect(derivative.result!.derivativeDisplayResult, isNotNull);
    });
  });
}
