import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/features/calculator/application/calculator_controller.dart';
import 'package:hesap_makinesi/features/calculator/data/calculator_settings.dart';
import 'package:hesap_makinesi/features/calculator/data/memory_calculator_storage.dart';

void main() {
  group('CalculatorController', () {
    late MemoryCalculatorStorage storage;
    late CalculatorController controller;

    setUp(() {
      storage = MemoryCalculatorStorage();
      controller = CalculatorController(storage: storage);
    });

    test('initialize loads default state', () async {
      await controller.initialize();

      expect(controller.state.expression, isEmpty);
      expect(controller.state.cursorPosition, 0);
      expect(controller.state.angleMode, AngleMode.degree);
      expect(controller.state.precision, 10);
      expect(controller.state.numericMode, NumericMode.approximate);
      expect(controller.state.calculationDomain, CalculationDomain.real);
      expect(controller.state.unitMode, UnitMode.disabled);
      expect(controller.state.resultFormat, NumberFormatStyle.auto);
      expect(controller.state.history, isEmpty);
    });

    test('insertText appends at cursor position', () async {
      await controller.initialize();

      controller.insertText('12');

      expect(controller.state.expression, '12');
      expect(controller.state.cursorPosition, 2);
    });

    test('insertFunction adds implicit multiplication when needed', () async {
      await controller.initialize();
      controller.insertText('2');

      controller.insertFunction('sin');

      expect(controller.state.expression, '2×sin(');
      expect(controller.state.cursorPosition, 6);
    });

    test('insertOperator updates expression', () async {
      await controller.initialize();
      controller.insertText('12');

      controller.insertOperator('+');

      expect(controller.state.expression, '12+');
      expect(controller.state.cursorPosition, 3);
    });

    test('backspace removes character before cursor', () async {
      await controller.initialize();
      controller.setExpression('12+3', cursorPosition: 4);

      controller.backspace();

      expect(controller.state.expression, '12+');
      expect(controller.state.cursorPosition, 3);
    });

    test('moveCursorLeft and moveCursorRight keep cursor in bounds', () async {
      await controller.initialize();
      controller.setExpression('123', cursorPosition: 3);

      controller.moveCursorLeft();
      controller.moveCursorLeft();
      controller.moveCursorRight();

      expect(controller.state.cursorPosition, 2);
    });

    test('clearExpression clears only the editor text', () async {
      await controller.initialize();
      controller.setExpression('2+2');
      await controller.evaluate();

      controller.clearExpression();

      expect(controller.state.expression, isEmpty);
      expect(controller.state.result, isNotNull);
    });

    test('clearAll resets expression and outcome', () async {
      await controller.initialize();
      controller.setExpression('2+2');
      await controller.evaluate();

      controller.clearAll();

      expect(controller.state.expression, isEmpty);
      expect(controller.state.outcome, isNull);
    });

    test('evaluate success updates outcome', () async {
      await controller.initialize();
      controller.setExpression('2+3*4');

      await controller.evaluate();

      expect(controller.state.outcome?.isSuccess, isTrue);
      expect(controller.state.result?.displayResult, '14');
    });

    test('evaluate error updates failure state', () async {
      await controller.initialize();
      controller.setExpression('sqrt(-1)');

      await controller.evaluate();

      expect(controller.state.outcome?.isFailure, isTrue);
      expect(controller.state.lastErrorMessage, isNotNull);
    });

    test('successful evaluation adds history', () async {
      await controller.initialize();
      controller.setExpression('7+8');

      await controller.evaluate();

      expect(controller.state.history, hasLength(1));
      expect(controller.state.history.first.expression, '7+8');
    });

    test('failed evaluation does not add history', () async {
      await controller.initialize();
      controller.setExpression('1/0');

      await controller.evaluate();

      expect(controller.state.history, isEmpty);
    });

    test('setAngleMode reevaluates the active expression', () async {
      await controller.initialize();
      controller.setExpression('sin(30)');
      await controller.evaluate();

      expect(controller.state.result?.displayResult, '0.5');

      await controller.setAngleMode(AngleMode.radian);

      expect(controller.state.angleMode, AngleMode.radian);
      expect(
        controller.state.result?.numericValue,
        closeTo(-0.9880316240928618, 1e-10),
      );
    });

    test('setPrecision reformats the active result', () async {
      await controller.initialize();
      controller.setExpression('1/3');
      await controller.evaluate();

      await controller.setPrecision(4);

      expect(controller.state.precision, 4);
      expect(controller.state.result?.displayResult, '0.3333');
    });

    test('setNumericMode exact updates state', () async {
      await controller.initialize();

      await controller.setNumericMode(NumericMode.exact);

      expect(controller.state.numericMode, NumericMode.exact);
    });

    test('setCalculationDomain complex updates state', () async {
      await controller.initialize();

      await controller.setCalculationDomain(CalculationDomain.complex);

      expect(controller.state.calculationDomain, CalculationDomain.complex);
    });

    test('setUnitMode enabled updates state', () async {
      await controller.initialize();

      await controller.setUnitMode(UnitMode.enabled);

      expect(controller.state.unitMode, UnitMode.enabled);
    });

    test('setReduceMotion persists accessibility motion preference', () async {
      await controller.initialize();

      await controller.setReduceMotion(true);

      expect(controller.state.settings.reduceMotion, isTrue);
      final restored = await storage.loadSettings();
      expect(restored?.reduceMotion, isTrue);
    });

    test(
      'setHighContrast persists accessibility contrast preference',
      () async {
        await controller.initialize();

        await controller.setHighContrast(true);

        expect(controller.state.settings.highContrast, isTrue);
        final restored = await storage.loadSettings();
        expect(restored?.highContrast, isTrue);
      },
    );

    test('setLanguage persists app language preference', () async {
      await controller.initialize();

      await controller.setLanguage(CalculatorAppLanguage.tr);

      expect(controller.state.settings.language, CalculatorAppLanguage.tr);
      final restored = await storage.loadSettings();
      expect(restored?.language, CalculatorAppLanguage.tr);
    });

    test('setOnboardingCompleted persists first launch state', () async {
      await controller.initialize();

      await controller.setOnboardingCompleted(true);

      expect(controller.state.settings.onboardingCompleted, isTrue);
      final restored = await storage.loadSettings();
      expect(restored?.onboardingCompleted, isTrue);
    });

    test(
      'resetSettings restores defaults while preserving onboarding',
      () async {
        await controller.initialize();
        await controller.setHighContrast(true);
        await controller.setOnboardingCompleted(true);

        await controller.resetSettings();

        expect(controller.state.settings.highContrast, isFalse);
        expect(controller.state.settings.onboardingCompleted, isTrue);
      },
    );

    test('numericMode change reevaluates the active expression', () async {
      await controller.initialize();
      controller.setExpression('1/3 + 1/6');
      await controller.evaluate();

      expect(controller.state.result?.displayResult, '0.5');

      await controller.setNumericMode(NumericMode.exact);

      expect(controller.state.result?.displayResult, '1/2');
      expect(controller.state.result?.decimalDisplayResult, '0.5');
    });

    test('setResultFormat changes exact display behavior', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('sqrt(2)');
      await controller.evaluate();

      expect(controller.state.result?.displayResult, '\u221A2');

      await controller.setResultFormat(NumberFormatStyle.decimal);

      expect(controller.state.resultFormat, NumberFormatStyle.decimal);
      expect(controller.state.result?.displayResult, '1.4142135624');
      expect(controller.state.result?.symbolicDisplayResult, '\u221A2');
    });

    test('exact evaluation adds exact history entry', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('sqrt(2)');

      await controller.evaluate();

      expect(controller.state.history, hasLength(1));
      expect(controller.state.history.first.numericMode, NumericMode.exact);
      expect(controller.state.history.first.displayResult, '\u221A2');
      expect(
        controller.state.history.first.valueKind,
        CalculatorValueKind.symbolic,
      );
    });

    test('failed exact evaluation does not add history', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('1/0');

      await controller.evaluate();

      expect(controller.state.history, isEmpty);
    });

    test('duplicate policy takes numeric mode into account', () async {
      await controller.initialize();
      controller.setExpression('1/3 + 1/6');
      await controller.evaluate();

      await controller.setNumericMode(NumericMode.exact);
      await controller.evaluate();

      expect(controller.state.history, hasLength(2));
      expect(controller.state.history.first.numericMode, NumericMode.exact);
      expect(
        controller.state.history.last.numericMode,
        NumericMode.approximate,
      );
    });

    test(
      'recallHistoryItem restores expression and result including mode',
      () async {
        await controller.initialize();
        await controller.setNumericMode(NumericMode.exact);
        controller.setExpression('sqrt(2) + sqrt(8)');
        await controller.evaluate();
        final item = controller.state.history.first;

        controller.clearAll();
        controller.recallHistoryItem(item);

        expect(controller.state.expression, 'sqrt(2) + sqrt(8)');
        expect(controller.state.result?.displayResult, '3\u221A2');
        expect(controller.state.numericMode, NumericMode.exact);
      },
    );

    test('exact mode evaluates sqrt(2) as symbolic result', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('sqrt(2)');

      await controller.evaluate();

      expect(controller.state.result?.displayResult, '\u221A2');
      expect(controller.state.result?.valueKind, CalculatorValueKind.symbolic);
      expect(controller.state.result?.warnings, isEmpty);
    });

    test(
      'mode change switches between approximate and symbolic exact result',
      () async {
        await controller.initialize();
        controller.setExpression('sqrt(2)');
        await controller.evaluate();

        final approximateDisplay = controller.state.result?.displayResult;
        await controller.setNumericMode(NumericMode.exact);

        expect(approximateDisplay, isNot('\u221A2'));
        expect(controller.state.result?.displayResult, '\u221A2');
      },
    );

    test('setResultFormat symbolic keeps symbolic display', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('sqrt(2)');
      await controller.evaluate();

      await controller.setResultFormat(NumberFormatStyle.symbolic);

      expect(controller.state.resultFormat, NumberFormatStyle.symbolic);
      expect(controller.state.result?.displayResult, '\u221A2');
    });

    test(
      'domain change reevaluates active expression for complex support',
      () async {
        await controller.initialize();
        controller.setExpression('sqrt(-1)');
        await controller.evaluate();

        expect(controller.state.outcome?.isFailure, isTrue);

        await controller.setCalculationDomain(CalculationDomain.complex);

        expect(controller.state.result?.displayResult, 'i');
        expect(controller.state.result?.valueKind, CalculatorValueKind.complex);
      },
    );

    test('complex evaluation adds complex history entry', () async {
      await controller.initialize();
      await controller.setCalculationDomain(CalculationDomain.complex);
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('sqrt(-1)');

      await controller.evaluate();

      expect(controller.state.history, hasLength(1));
      expect(
        controller.state.history.first.calculationDomain,
        CalculationDomain.complex,
      );
      expect(
        controller.state.history.first.valueKind,
        CalculatorValueKind.complex,
      );
      expect(controller.state.history.first.displayResult, 'i');
    });

    test('failed complex evaluation does not add history', () async {
      await controller.initialize();
      await controller.setCalculationDomain(CalculationDomain.complex);
      controller.setExpression('(1+i)/(0)');

      await controller.evaluate();

      expect(controller.state.history, isEmpty);
    });

    test('duplicate policy takes calculation domain into account', () async {
      await controller.initialize();
      controller.setExpression('sqrt(-1)');
      await controller.evaluate();

      await controller.setCalculationDomain(CalculationDomain.complex);
      await controller.evaluate();

      expect(controller.state.history, hasLength(1));
      expect(
        controller.state.history.first.calculationDomain,
        CalculationDomain.complex,
      );
    });

    test('result format decimal affects exact complex display', () async {
      await controller.initialize();
      await controller.setCalculationDomain(CalculationDomain.complex);
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('sqrt(-2)');
      await controller.evaluate();

      expect(controller.state.result?.displayResult, '\u221A2i');

      await controller.setResultFormat(NumberFormatStyle.decimal);

      expect(controller.state.result?.displayResult, '1.4142135624i');
      expect(controller.state.result?.symbolicDisplayResult, '\u221A2i');
    });

    test(
      'vector evaluation saves vector display and shape to history',
      () async {
        await controller.initialize();
        await controller.setNumericMode(NumericMode.exact);
        controller.setExpression('vec(1,2,3)');

        await controller.evaluate();

        expect(controller.state.result?.displayResult, '[1, 2, 3]');
        expect(controller.state.result?.valueKind, CalculatorValueKind.vector);
        expect(controller.state.result?.shapeDisplayResult, '3 \u00D7 1');
        expect(controller.state.history, hasLength(1));
        expect(
          controller.state.history.first.valueKind,
          CalculatorValueKind.vector,
        );
        expect(controller.state.history.first.vectorDisplayResult, '[1, 2, 3]');
        expect(controller.state.history.first.shapeDisplayResult, '3 \u00D7 1');
      },
    );

    test(
      'matrix evaluation saves matrix display and shape to history',
      () async {
        await controller.initialize();
        await controller.setNumericMode(NumericMode.exact);
        controller.setExpression('mat(2,2,1,2,3,4)');

        await controller.evaluate();

        expect(controller.state.result?.displayResult, '[[1, 2], [3, 4]]');
        expect(controller.state.result?.valueKind, CalculatorValueKind.matrix);
        expect(controller.state.result?.shapeDisplayResult, '2 \u00D7 2');
        expect(controller.state.history, hasLength(1));
        expect(
          controller.state.history.first.valueKind,
          CalculatorValueKind.matrix,
        );
        expect(
          controller.state.history.first.matrixDisplayResult,
          '[[1, 2], [3, 4]]',
        );
        expect(controller.state.history.first.shapeDisplayResult, '2 \u00D7 2');
      },
    );

    test('failed matrix evaluation is not added to history', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('inv(mat(2,2,1,2,2,4))');

      await controller.evaluate();

      expect(controller.state.outcome?.isFailure, isTrue);
      expect(controller.state.history, isEmpty);
    });

    test('recall matrix expression restores matrix state', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('mat(2,2,1,2,3,4)');
      await controller.evaluate();
      final item = controller.state.history.first;

      controller.clearAll();
      controller.recallHistoryItem(item);

      expect(controller.state.expression, 'mat(2,2,1,2,3,4)');
      expect(controller.state.result?.displayResult, '[[1, 2], [3, 4]]');
      expect(controller.state.result?.valueKind, CalculatorValueKind.matrix);
      expect(controller.state.result?.shapeDisplayResult, '2 \u00D7 2');
    });

    test(
      'unit mode evaluates unit expressions and saves unit history',
      () async {
        await controller.initialize();
        await controller.setUnitMode(UnitMode.enabled);
        await controller.setNumericMode(NumericMode.exact);
        controller.setExpression('3 m + 20 cm');

        await controller.evaluate();

        expect(controller.state.result?.displayResult, '16/5 m');
        expect(controller.state.result?.valueKind, CalculatorValueKind.unit);
        expect(controller.state.result?.unitDisplayResult, '16/5 m');
        expect(controller.state.result?.dimensionDisplayResult, 'L');
        expect(controller.state.history, hasLength(1));
        expect(controller.state.history.first.unitMode, UnitMode.enabled);
        expect(
          controller.state.history.first.valueKind,
          CalculatorValueKind.unit,
        );
        expect(controller.state.history.first.unitDisplayResult, '16/5 m');
        expect(controller.state.history.first.dimensionDisplayResult, 'L');
      },
    );

    test('unit mode change reevaluates active expression', () async {
      await controller.initialize();
      controller.setExpression('3 m + 20 cm');
      await controller.evaluate();

      expect(controller.state.outcome?.isFailure, isTrue);

      await controller.setUnitMode(UnitMode.enabled);

      expect(controller.state.result?.displayResult, '3.2 m');
      expect(controller.state.result?.valueKind, CalculatorValueKind.unit);
    });

    test('failed unit evaluation is not added to history', () async {
      await controller.initialize();
      await controller.setUnitMode(UnitMode.enabled);
      controller.setExpression('3 m + 2 s');

      await controller.evaluate();

      expect(controller.state.outcome?.isFailure, isTrue);
      expect(controller.state.history, isEmpty);
    });

    test('duplicate policy takes unit mode into account', () async {
      await controller.initialize();
      controller.setExpression('2');
      await controller.evaluate();

      await controller.setUnitMode(UnitMode.enabled);
      await controller.evaluate();

      expect(controller.state.history, hasLength(2));
      expect(controller.state.history.first.unitMode, UnitMode.enabled);
      expect(controller.state.history.last.unitMode, UnitMode.disabled);
    });

    test('recall unit expression restores stored unit mode', () async {
      await controller.initialize();
      await controller.setUnitMode(UnitMode.enabled);
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('to(25 degC, degF)');
      await controller.evaluate();
      final item = controller.state.history.first;

      controller.clearAll();
      await controller.setUnitMode(UnitMode.disabled);
      controller.recallHistoryItem(item);

      expect(controller.state.expression, 'to(25 degC, degF)');
      expect(controller.state.unitMode, UnitMode.enabled);
      expect(controller.state.result?.displayResult, '77 degF');
      expect(controller.state.result?.valueKind, CalculatorValueKind.unit);
    });

    test('duplicate policy collapses identical matrix history items', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('mat(2,2,1,2,3,4)');

      await controller.evaluate();
      await controller.evaluate();

      expect(controller.state.history, hasLength(1));
      expect(
        controller.state.history.first.valueKind,
        CalculatorValueKind.matrix,
      );
    });

    test('dataset evaluation saves dataset metadata to history', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('data(1,2,3,4)');

      await controller.evaluate();

      expect(controller.state.result?.valueKind, CalculatorValueKind.dataset);
      expect(controller.state.result?.displayResult, 'data(1, 2, 3, 4)');
      expect(controller.state.result?.sampleSize, 4);
      expect(controller.state.history, hasLength(1));
      expect(
        controller.state.history.first.valueKind,
        CalculatorValueKind.dataset,
      );
      expect(
        controller.state.history.first.datasetDisplayResult,
        'data(1, 2, 3, 4)',
      );
      expect(controller.state.history.first.sampleSize, 4);
      expect(controller.state.history.first.statisticName, 'data');
    });

    test(
      'statistics scalar results save statistics summary to history',
      () async {
        await controller.initialize();
        await controller.setNumericMode(NumericMode.exact);
        controller.setExpression('mean(data(1,2,3,4))');

        await controller.evaluate();

        expect(controller.state.result?.displayResult, '5/2');
        expect(
          controller.state.result?.statisticsDisplayResult,
          contains('Mean'),
        );
        expect(controller.state.result?.sampleSize, 4);
        expect(controller.state.history, hasLength(1));
        expect(
          controller.state.history.first.statisticsDisplayResult,
          contains('Mean'),
        );
        expect(controller.state.history.first.sampleSize, 4);
        expect(controller.state.history.first.statisticName, 'mean');
      },
    );

    test(
      'regression result saves structured regression metadata to history',
      () async {
        await controller.initialize();
        await controller.setNumericMode(NumericMode.exact);
        controller.setExpression('linreg(data(1,2,3),data(2,4,6))');

        await controller.evaluate();

        expect(
          controller.state.result?.valueKind,
          CalculatorValueKind.regression,
        );
        expect(controller.state.result?.displayResult, 'y = 2x + 0');
        expect(controller.state.result?.regressionDisplayResult, 'y = 2x + 0');
        expect(
          controller.state.result?.summaryDisplayResult,
          contains('r = 1'),
        );
        expect(controller.state.history, hasLength(1));
        expect(
          controller.state.history.first.valueKind,
          CalculatorValueKind.regression,
        );
        expect(
          controller.state.history.first.regressionDisplayResult,
          'y = 2x + 0',
        );
        expect(
          controller.state.history.first.summaryDisplayResult,
          contains('r = 1'),
        );
        expect(controller.state.history.first.statisticName, 'linreg');
      },
    );

    test('failed statistics evaluation is not added to history', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('vars(data(1))');

      await controller.evaluate();

      expect(controller.state.outcome?.isFailure, isTrue);
      expect(controller.state.history, isEmpty);
    });

    test('recall dataset expression restores stored dataset outcome', () async {
      await controller.initialize();
      await controller.setNumericMode(NumericMode.exact);
      controller.setExpression('data(1,2,3,4)');
      await controller.evaluate();
      final item = controller.state.history.first;

      controller.clearAll();
      controller.recallHistoryItem(item);

      expect(controller.state.expression, 'data(1,2,3,4)');
      expect(controller.state.result?.displayResult, 'data(1, 2, 3, 4)');
      expect(controller.state.result?.valueKind, CalculatorValueKind.dataset);
      expect(controller.state.result?.sampleSize, 4);
    });

    test(
      'duplicate policy collapses identical statistics history items',
      () async {
        await controller.initialize();
        await controller.setNumericMode(NumericMode.exact);
        controller.setExpression('mean(data(1,2,3,4))');

        await controller.evaluate();
        await controller.evaluate();

        expect(controller.state.history, hasLength(1));
        expect(
          controller.state.history.first.statisticsDisplayResult,
          contains('Mean'),
        );
        expect(controller.state.history.first.statisticName, 'mean');
      },
    );

    test('plot evaluation saves graph metadata to history', () async {
      await controller.initialize();
      controller.setExpression('plot(x^2, -5, 5)');

      await controller.evaluate();

      expect(controller.state.result?.valueKind, CalculatorValueKind.plot);
      expect(controller.state.result?.plotSeriesCount, 1);
      expect(controller.state.result?.viewportDisplayResult, isNotNull);
      expect(controller.state.history, hasLength(1));
      expect(
        controller.state.history.first.valueKind,
        CalculatorValueKind.plot,
      );
      expect(controller.state.history.first.plotSeriesCount, 1);
      expect(controller.state.history.first.viewportDisplayResult, isNotNull);
    });

    test('failed plot evaluation is not added to history', () async {
      await controller.initialize();
      await controller.setCalculationDomain(CalculationDomain.complex);
      controller.setExpression('plot(i*x, -1, 1)');

      await controller.evaluate();

      expect(controller.state.outcome?.isFailure, isTrue);
      expect(controller.state.history, isEmpty);
    });

    test('recall plot expression restores stored graph outcome', () async {
      await controller.initialize();
      controller.setExpression('plot(x^2, -5, 5)');
      await controller.evaluate();
      final item = controller.state.history.first;

      controller.clearAll();
      controller.recallHistoryItem(item);

      expect(controller.state.expression, 'plot(x^2, -5, 5)');
      expect(controller.state.result?.valueKind, CalculatorValueKind.plot);
      expect(controller.state.result?.plotSeriesCount, 1);
    });

    test('deleteHistoryItem removes the selected entry', () async {
      await controller.initialize();
      controller.setExpression('4+4');
      await controller.evaluate();
      final item = controller.state.history.first;

      await controller.deleteHistoryItem(item);

      expect(controller.state.history, isEmpty);
    });

    test('clearHistory removes all entries', () async {
      await controller.initialize();
      controller.setExpression('2+2');
      await controller.evaluate();
      controller.setExpression('3+3');
      await controller.evaluate();

      await controller.clearHistory();

      expect(controller.state.history, isEmpty);
    });
  });
}
