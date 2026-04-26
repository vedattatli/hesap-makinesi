import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/features/calculator/application/calculator_controller.dart';
import 'package:hesap_makinesi/features/calculator/data/calculator_settings.dart';
import 'package:hesap_makinesi/features/calculator/data/memory_calculator_storage.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/memory_worksheet_storage.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_controller.dart';
import 'package:hesap_makinesi/main.dart';

void main() {
  Future<CalculatorController> pumpCalculator(
    WidgetTester tester, {
    Size size = const Size(1400, 1000),
    bool onboardingCompleted = true,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = CalculatorController(
      storage: MemoryCalculatorStorage(
        settings: CalculatorSettings.defaults.copyWith(
          onboardingCompleted: onboardingCompleted,
        ),
      ),
    );
    final worksheetController = WorksheetController(
      storage: MemoryWorksheetStorage(),
    );
    await controller.initialize();
    await worksheetController.initialize();
    await tester.pumpWidget(
      ScientificCalculatorApp(
        controller: controller,
        worksheetController: worksheetController,
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Finder toolbarOption(Key key, String label) {
    return find.descendant(of: find.byKey(key), matching: find.text(label));
  }

  Future<void> submitExpression(WidgetTester tester, String expression) async {
    await tester.enterText(
      find.byKey(const Key('expression-input')),
      expression,
    );
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  Future<void> openWorksheetPanel(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('worksheet-mode-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('app opens and evaluates an expression', (tester) async {
    await pumpCalculator(tester);

    await submitExpression(tester, '7+8');

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );
    expect(resultText.data, '15');
  });

  testWidgets('numeric mode toggle is visible and exact mode is selectable', (
    tester,
  ) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('numeric-mode-toggle')), findsOneWidget);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();

    await submitExpression(tester, 'sqrt(2)');

    expect(find.text('\u221A2'), findsWidgets);
    expect(find.byKey(const Key('decimal-alternative-text')), findsOneWidget);
  });

  testWidgets('error message is shown for invalid real expression', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await submitExpression(tester, 'sqrt(-1)');

    expect(find.byKey(const Key('status-message')), findsOneWidget);
  });

  testWidgets('exact mode symbolic result is shown without warning', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();

    await submitExpression(tester, 'sqrt(2)');

    expect(find.text('\u221A2'), findsWidgets);
    expect(find.byKey(const Key('status-message')), findsNothing);
  });

  testWidgets(
    'exact mode fallback warning is shown for unsupported symbolic operation',
    (tester) async {
      await pumpCalculator(tester);

      await tester.tap(
        toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'),
      );
      await tester.pumpAndSettle();

      await submitExpression(tester, 'ln(pi)');

      expect(find.byKey(const Key('status-message')), findsOneWidget);
    },
  );

  testWidgets('GRAD mode is visible and affects evaluation', (tester) async {
    await pumpCalculator(tester);

    expect(find.text('GRAD'), findsOneWidget);

    await tester.tap(find.text('GRAD'));
    await tester.pumpAndSettle();

    await submitExpression(tester, 'sin(100)');

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );
    expect(resultText.data, '1');
  });

  testWidgets('history records exact entries and supports recall', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();

    await submitExpression(tester, 'sqrt(2) + sqrt(8)');

    expect(find.byKey(const Key('history-panel')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('history-panel')),
        matching: find.text('3\u221A2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('history-panel')),
        matching: find.text('SYMBOLIC'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('expression-input')), '9+9');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-item-0')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expression-input')))
          .controller
          ?.text,
      'sqrt(2) + sqrt(8)',
    );
  });

  testWidgets('settings can change result format for exact mode', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('open-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EXACT').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decimal'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Settings'))).pop();
    await tester.pumpAndSettle();

    await submitExpression(tester, 'sqrt(2)');

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );
    expect(resultText.data, '1.4142135624');
    expect(find.byKey(const Key('symbolic-alternative-text')), findsOneWidget);
  });

  testWidgets('exact mode can render exact trig table results', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();

    await submitExpression(tester, 'sin(30)');

    expect(find.text('1/2'), findsWidgets);
  });

  testWidgets('complex domain toggle is visible and selectable', (
    tester,
  ) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('calculation-domain-toggle')), findsOneWidget);

    await tester.tap(
      toolbarOption(const Key('calculation-domain-toggle'), 'COMPLEX'),
    );
    await tester.pumpAndSettle();

    expect(find.text('COMPLEX'), findsWidgets);
  });

  testWidgets('keypad exposes imaginary unit button', (tester) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('button-i')), findsOneWidget);
  });

  testWidgets('complex mode evaluates sqrt(-1) as i and shows complex badge', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();
    await tester.tap(
      toolbarOption(const Key('calculation-domain-toggle'), 'COMPLEX'),
    );
    await tester.pumpAndSettle();

    await submitExpression(tester, 'sqrt(-1)');

    expect(find.text('i'), findsWidgets);
    expect(find.text('COMPLEX'), findsWidgets);
    expect(find.byKey(const Key('polar-alternative-text')), findsOneWidget);
  });

  testWidgets(
    'complex mode renders symbolic exact radical and decimal alternative',
    (tester) async {
      await pumpCalculator(tester);

      await tester.tap(
        toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        toolbarOption(const Key('calculation-domain-toggle'), 'COMPLEX'),
      );
      await tester.pumpAndSettle();

      await submitExpression(tester, 'sqrt(-2)');

      expect(find.text('\u221A2i'), findsWidgets);
      expect(find.byKey(const Key('decimal-alternative-text')), findsOneWidget);
      expect(
        find.byKey(const Key('magnitude-alternative-text')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('argument-alternative-text')),
        findsOneWidget,
      );
    },
  );

  testWidgets('complex history shows complex badge', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();
    await tester.tap(
      toolbarOption(const Key('calculation-domain-toggle'), 'COMPLEX'),
    );
    await tester.pumpAndSettle();

    await submitExpression(tester, 'sqrt(-1)');

    expect(
      find.descendant(
        of: find.byKey(const Key('history-panel')),
        matching: find.text('COMPLEX'),
      ),
      findsWidgets,
    );
  });

  testWidgets('unit mode toggle is visible and selectable', (tester) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('unit-mode-toggle')), findsOneWidget);

    await tester.tap(toolbarOption(const Key('unit-mode-toggle'), 'UNITS ON'));
    await tester.pumpAndSettle();

    expect(find.text('UNITS ON'), findsWidgets);
  });

  testWidgets('unit keypad buttons are visible', (tester) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('button-to')), findsOneWidget);
    expect(find.byKey(const Key('button-m')), findsOneWidget);
    expect(find.byKey(const Key('button-cm')), findsOneWidget);
    expect(find.byKey(const Key('button-degC')), findsOneWidget);
  });

  testWidgets('to function button inserts conversion template', (tester) async {
    await pumpCalculator(tester);

    await tester.ensureVisible(find.byKey(const Key('button-to')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('button-to')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expression-input')))
          .controller
          ?.text,
      'to(',
    );
  });

  testWidgets('unit mode evaluates unit expressions and shows unit badge', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('unit-mode-toggle'), 'UNITS ON'));
    await tester.pumpAndSettle();
    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();

    await submitExpression(tester, '3 m + 20 cm');

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );
    expect(resultText.data, '16/5 m');
    expect(find.text('UNIT'), findsWidgets);
    expect(find.byKey(const Key('base-unit-alternative-text')), findsOneWidget);
    expect(find.byKey(const Key('dimension-alternative-text')), findsOneWidget);
  });

  testWidgets('temperature conversion result is shown in unit mode', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('unit-mode-toggle'), 'UNITS ON'));
    await tester.pumpAndSettle();

    await submitExpression(tester, 'to(25 degC, degF)');

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );
    expect(resultText.data, '77 degF');
    expect(find.text('UNIT'), findsWidgets);
  });

  testWidgets('dimension errors are shown for incompatible unit addition', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('unit-mode-toggle'), 'UNITS ON'));
    await tester.pumpAndSettle();

    await submitExpression(tester, '3 m + 2 s');

    expect(find.byKey(const Key('status-message')), findsOneWidget);
  });

  testWidgets('unit history shows unit badge', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('unit-mode-toggle'), 'UNITS ON'));
    await tester.pumpAndSettle();
    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();

    await submitExpression(tester, '3 m + 20 cm');

    expect(
      find.descendant(
        of: find.byKey(const Key('history-panel')),
        matching: find.text('UNIT'),
      ),
      findsWidgets,
    );
  });

  testWidgets('vector and matrix keypad buttons are visible', (tester) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('button-vec')), findsOneWidget);
    expect(find.byKey(const Key('button-mat')), findsOneWidget);
    expect(find.byKey(const Key('button-det')), findsOneWidget);
    expect(find.byKey(const Key('button-inv')), findsOneWidget);
  });

  testWidgets('statistics keypad buttons are visible', (tester) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('button-data')), findsOneWidget);
    expect(find.byKey(const Key('button-mean')), findsOneWidget);
    expect(find.byKey(const Key('button-median')), findsOneWidget);
    expect(find.byKey(const Key('button-var')), findsOneWidget);
    expect(find.byKey(const Key('button-nCr')), findsOneWidget);
    expect(find.byKey(const Key('button-linreg')), findsOneWidget);
  });

  testWidgets('solve keypad buttons are visible', (tester) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('button-solve')), findsOneWidget);
    expect(find.byKey(const Key('button-eq')), findsOneWidget);
    expect(find.byKey(const Key('button-nsolve')), findsOneWidget);
    expect(find.byKey(const Key('button-diff')), findsOneWidget);
    expect(find.byKey(const Key('button-dAt')), findsOneWidget);
    expect(find.byKey(const Key('button-int')), findsOneWidget);
    expect(find.byKey(const Key('button-integrate')), findsOneWidget);
    expect(find.byKey(const Key('button-simplify')), findsOneWidget);
    expect(find.byKey(const Key('button-expand')), findsOneWidget);
    expect(find.byKey(const Key('button-factor')), findsOneWidget);
    expect(find.byKey(const Key('button-sys')), findsOneWidget);
    expect(find.byKey(const Key('button-linsolve')), findsOneWidget);
  });

  testWidgets('data function button inserts dataset template', (tester) async {
    await pumpCalculator(tester);

    await tester.ensureVisible(find.byKey(const Key('button-data')));
    await tester.tap(find.byKey(const Key('button-data')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expression-input')))
          .controller
          ?.text,
      'data(',
    );
  });

  testWidgets('vector function button inserts vec template', (tester) async {
    await pumpCalculator(tester);

    await tester.ensureVisible(find.byKey(const Key('button-vec')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('button-vec')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expression-input')))
          .controller
          ?.text,
      'vec(',
    );
  });

  testWidgets('matrix function button inserts mat template', (tester) async {
    await pumpCalculator(tester);

    await tester.ensureVisible(find.byKey(const Key('button-mat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('button-mat')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expression-input')))
          .controller
          ?.text,
      'mat(',
    );
  });

  testWidgets('vector evaluation shows vector badge and shape', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();
    await submitExpression(tester, 'vec(1,2,3)');

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );
    expect(resultText.data, '[1, 2, 3]');
    expect(find.text('VECTOR'), findsWidgets);
    expect(find.text('3 \u00D7 1'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const Key('history-panel')),
        matching: find.text('VECTOR'),
      ),
      findsWidgets,
    );
  });

  testWidgets('matrix evaluation shows matrix badge and shape', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();
    await submitExpression(tester, 'mat(2,2,1,2,3,4)');

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );
    expect(resultText.data, '[[1, 2], [3, 4]]');
    expect(find.text('MATRIX'), findsWidgets);
    expect(find.text('2 \u00D7 2'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const Key('history-panel')),
        matching: find.text('MATRIX'),
      ),
      findsWidgets,
    );
  });

  testWidgets('determinant evaluation shows scalar result', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();
    await submitExpression(tester, 'det(mat(2,2,1,2,3,4))');

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );
    expect(resultText.data, '-2');
  });

  testWidgets('statistics evaluation shows STATS badge and sample size', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();

    await submitExpression(tester, 'mean(data(1,2,3,4))');

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );
    expect(resultText.data, '5/2');
    expect(find.text('STATS'), findsWidgets);
    expect(find.byKey(const Key('sample-size-text')), findsOneWidget);
    expect(find.byKey(const Key('statistics-summary-text')), findsOneWidget);
  });

  testWidgets('regression evaluation shows regression badge and equation', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();

    await submitExpression(tester, 'linreg(data(1,2,3),data(2,4,6))');

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );
    expect(resultText.data, 'y = 2x + 0');
    expect(find.text('REGRESSION'), findsWidgets);
    expect(find.byKey(const Key('summary-alternative-text')), findsOneWidget);
  });

  testWidgets(
    'probability button is visible and probability result evaluates',
    (tester) async {
      await pumpCalculator(tester);

      expect(find.byKey(const Key('button-binom')), findsOneWidget);

      await submitExpression(tester, 'binomPmf(10,0.5,3)');

      final resultText = tester.widget<Text>(
        find.byKey(const Key('result-text')),
      );
      expect(resultText.data, '0.1171875');
      expect(find.text('PROBABILITY'), findsWidgets);
      expect(find.byKey(const Key('probability-summary-text')), findsOneWidget);
    },
  );

  testWidgets('history shows dataset and regression badges', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();

    await submitExpression(tester, 'data(1,2,3,4)');
    await submitExpression(tester, 'linreg(data(1,2,3),data(2,4,6))');

    expect(
      find.descendant(
        of: find.byKey(const Key('history-panel')),
        matching: find.text('DATASET'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('history-panel')),
        matching: find.text('REGRESSION'),
      ),
      findsWidgets,
    );
  });

  testWidgets('invalid statistics input shows typed error', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(toolbarOption(const Key('numeric-mode-toggle'), 'EXACT'));
    await tester.pumpAndSettle();

    await submitExpression(tester, 'vars(data(1))');

    expect(find.byKey(const Key('status-message')), findsOneWidget);
  });

  testWidgets('GRAPH button opens graph panel and x shortcut is visible', (
    tester,
  ) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('graph-mode-button')), findsOneWidget);
    expect(find.byKey(const Key('button-x')), findsOneWidget);

    await tester.tap(find.byKey(const Key('graph-mode-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('graph-panel')), findsOneWidget);
    expect(find.byKey(const Key('graph-plot-button')), findsOneWidget);
  });

  testWidgets('graph panel plots sin(x) and shows canvas', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('graph-mode-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('graph-expression-0')),
      'sin(x)',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('graph-plot-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('graph-canvas')), findsOneWidget);
    expect(find.byKey(const Key('graph-panel-summary-text')), findsOneWidget);
  });

  testWidgets('invalid graph expression shows graph error', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('graph-mode-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('graph-expression-0')),
      'vec(x,x)',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('graph-plot-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('graph-error-text')), findsOneWidget);
  });

  testWidgets('plot expression result shows PLOT badge and history stores it', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await submitExpression(tester, 'plot(x^2,-5,5)');

    expect(find.text('PLOT'), findsWidgets);
    expect(find.byKey(const Key('plot-counts-text')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('history-panel')),
        matching: find.text('PLOT'),
      ),
      findsWidgets,
    );
  });

  testWidgets('WORKSHEET button opens worksheet panel', (tester) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('worksheet-mode-button')), findsOneWidget);

    await openWorksheetPanel(tester);

    expect(find.byKey(const Key('worksheet-panel')), findsOneWidget);
    expect(find.byKey(const Key('worksheet-create-button')), findsOneWidget);
  });

  testWidgets('worksheet panel shows variable and function block actions', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await openWorksheetPanel(tester);

    expect(
      find.byKey(const Key('worksheet-add-variable-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('worksheet-add-function-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('worksheet-add-solve-button')), findsOneWidget);
    expect(find.byKey(const Key('worksheet-add-cas-button')), findsOneWidget);
    expect(find.byKey(const Key('worksheet-validate-button')), findsOneWidget);
  });

  testWidgets('evaluating solve expression shows solve badge and metadata', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await submitExpression(tester, 'solve(x^2-4=0,x)');

    expect(find.text('SOLVE'), findsWidgets);
    expect(find.byKey(const Key('equation-alternative-text')), findsOneWidget);
    expect(find.text('x = {-2, 2}'), findsWidgets);
  });

  testWidgets('worksheet can create and run a calculation block', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await submitExpression(tester, '1/3 + 1/6');
    await openWorksheetPanel(tester);

    await tester.tap(find.byKey(const Key('worksheet-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('worksheet-add-calculation-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('worksheet-run-block-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('worksheet-block-result-0')), findsOneWidget);
    expect(find.text('0.5'), findsWidgets);
  });

  testWidgets('current calculator result can be saved to worksheet', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await submitExpression(tester, '7+8');
    await tester.tap(find.byKey(const Key('save-result-to-worksheet-button')));
    await tester.pumpAndSettle();
    await openWorksheetPanel(tester);

    expect(find.byKey(const Key('worksheet-block-0')), findsOneWidget);
    expect(find.text('15'), findsWidgets);
  });

  testWidgets('graph can be saved to worksheet and exported', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('graph-mode-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('graph-expression-0')),
      'sin(x)',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('graph-plot-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('graph-save-to-worksheet-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('graph-save-to-worksheet-button')));
    await tester.pumpAndSettle();

    await openWorksheetPanel(tester);
    expect(find.byKey(const Key('worksheet-block-0')), findsOneWidget);
    expect(
      find.byKey(const Key('worksheet-export-graph-svg-0')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('worksheet-export-graph-svg-0')),
    );
    await tester.tap(find.byKey(const Key('worksheet-export-graph-svg-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('worksheet-export-preview')), findsOneWidget);
    expect(find.textContaining('<svg'), findsOneWidget);
  });

  testWidgets('worksheet export markdown preview is visible', (tester) async {
    await pumpCalculator(tester);

    await submitExpression(tester, '2+2');
    await tester.tap(find.byKey(const Key('save-result-to-worksheet-button')));
    await tester.pumpAndSettle();
    await openWorksheetPanel(tester);

    await tester.tap(find.byKey(const Key('worksheet-export-markdown-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('worksheet-export-preview')), findsOneWidget);
    expect(
      find.byKey(const Key('worksheet-export-preview-text')),
      findsOneWidget,
    );
    expect(find.textContaining('# Untitled Worksheet'), findsOneWidget);
  });

  testWidgets('worksheet can add scoped variable and function blocks', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await openWorksheetPanel(tester);
    await tester.tap(find.byKey(const Key('worksheet-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('worksheet-add-variable-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('worksheet-variable-name-0')),
      'a',
    );
    await tester.enterText(
      find.byKey(const Key('worksheet-variable-expression-0')),
      '2',
    );
    await tester.ensureVisible(
      find.byKey(const Key('worksheet-save-variable-0')),
    );
    await tester.tap(find.byKey(const Key('worksheet-save-variable-0')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('worksheet-run-variable-0')),
    );
    await tester.tap(find.byKey(const Key('worksheet-run-variable-0')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('worksheet-add-function-button')),
    );
    await tester.tap(find.byKey(const Key('worksheet-add-function-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('worksheet-function-name-1')),
      'f',
    );
    await tester.enterText(
      find.byKey(const Key('worksheet-function-parameters-1')),
      'x',
    );
    await tester.enterText(
      find.byKey(const Key('worksheet-function-body-1')),
      'x^2 + a',
    );
    await tester.ensureVisible(
      find.byKey(const Key('worksheet-save-function-1')),
    );
    await tester.tap(find.byKey(const Key('worksheet-save-function-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('worksheet-symbol-a')), findsOneWidget);
    expect(find.byKey(const Key('worksheet-symbol-f')), findsOneWidget);
  });

  testWidgets(
    'worksheet can add and run a solve block with stale propagation',
    (tester) async {
      await pumpCalculator(tester);

      await openWorksheetPanel(tester);
      await tester.tap(find.byKey(const Key('worksheet-create-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('worksheet-add-variable-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('worksheet-variable-name-0')),
        'a',
      );
      await tester.enterText(
        find.byKey(const Key('worksheet-variable-expression-0')),
        '2',
      );
      await tester.ensureVisible(
        find.byKey(const Key('worksheet-save-variable-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('worksheet-save-variable-0')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('worksheet-add-solve-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('worksheet-add-solve-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('worksheet-solve-equation-1')),
        'a*x + 4 = 0',
      );
      await tester.enterText(
        find.byKey(const Key('worksheet-solve-variable-1')),
        'x',
      );
      await tester.ensureVisible(
        find.byKey(const Key('worksheet-save-solve-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('worksheet-save-solve-1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('worksheet-run-solve-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('worksheet-run-solve-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('worksheet-solve-result-1')), findsOneWidget);
      expect(find.text('x = -2'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('worksheet-variable-expression-0')),
        '4',
      );
      await tester.ensureVisible(
        find.byKey(const Key('worksheet-save-variable-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('worksheet-save-variable-0')));
      await tester.pumpAndSettle();

      expect(find.text('STALE'), findsWidgets);

      await tester.ensureVisible(
        find.byKey(const Key('worksheet-run-all-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('worksheet-run-all-button')));
      await tester.pumpAndSettle();

      expect(find.text('x = -1'), findsWidgets);
    },
  );

  testWidgets('worksheet can add and run a CAS transform block', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await openWorksheetPanel(tester);
    await tester.tap(find.byKey(const Key('worksheet-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('worksheet-add-cas-button')),
    );
    await tester.tap(find.byKey(const Key('worksheet-add-cas-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('worksheet-cas-expression-0')),
      'x + x',
    );
    await tester.ensureVisible(find.byKey(const Key('worksheet-save-cas-0')));
    await tester.tap(find.byKey(const Key('worksheet-save-cas-0')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('worksheet-run-cas-0')));
    await tester.tap(find.byKey(const Key('worksheet-run-cas-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('worksheet-cas-result-0')), findsOneWidget);
    expect(find.text('2 * x'), findsWidgets);
  });

  testWidgets('premium mode navigation and command palette are visible', (
    tester,
  ) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('mode-navigation-rail')), findsOneWidget);
    expect(find.text('CAS'), findsWidgets);
    expect(find.text('STATS'), findsWidgets);
    expect(find.text('MATRIX'), findsWidgets);

    await tester.tap(find.byKey(const Key('open-command-palette-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('command-palette-dialog')), findsOneWidget);
    expect(find.text('Insert solve'), findsOneWidget);
  });

  testWidgets('keypad categories switch without removing core callbacks', (
    tester,
  ) async {
    await pumpCalculator(tester);

    expect(find.byKey(const Key('keypad-category-tabs')), findsOneWidget);
    expect(find.byKey(const Key('button-mean')), findsOneWidget);

    await tester.tap(find.byKey(const Key('keypad-category-CAS')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('button-solve')), findsOneWidget);
    expect(find.byKey(const Key('button-simplify')), findsOneWidget);
    expect(find.byKey(const Key('button-mean')), findsNothing);
  });

  testWidgets('settings exposes reduced motion preference', (tester) async {
    final controller = await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('open-settings-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reduce-motion-switch')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('reduce-motion-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reduce-motion-switch')));
    await tester.pumpAndSettle();

    expect(controller.state.settings.reduceMotion, isTrue);
  });

  testWidgets('settings persists high contrast and language preferences', (
    tester,
  ) async {
    final controller = await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('open-settings-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('high-contrast-switch')));
    await tester.tap(find.byKey(const Key('high-contrast-switch')));
    await tester.pumpAndSettle();
    expect(controller.state.settings.highContrast, isTrue);

    final turkishOption = find.descendant(
      of: find.byKey(const Key('language-toggle')),
      matching: find.text('Turkish'),
    );
    await tester.ensureVisible(turkishOption);
    await tester.tap(turkishOption);
    await tester.pumpAndSettle();

    expect(controller.state.settings.language, CalculatorAppLanguage.tr);
  });

  testWidgets('first-launch onboarding can be completed', (tester) async {
    final controller = await pumpCalculator(tester, onboardingCompleted: false);

    expect(find.byKey(const Key('product-onboarding-card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-skip-button')));
    await tester.pumpAndSettle();

    expect(controller.state.settings.onboardingCompleted, isTrue);
    expect(find.byKey(const Key('product-onboarding-card')), findsNothing);
  });

  testWidgets('examples library inserts calculator examples', (tester) async {
    final controller = await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('open-examples-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('examples-library-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('example-statistics')));
    await tester.pumpAndSettle();

    expect(controller.state.expression, 'mean(data(1,2,3,4))');
  });

  testWidgets('help reference panel opens from toolbar', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('open-help-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('help-reference-dialog')), findsOneWidget);
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
  });

  testWidgets('backup export and corrupt restore are safe in settings', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('open-settings-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('settings-export-backup-button')),
    );
    await tester.tap(find.byKey(const Key('settings-export-backup-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('backup-export-dialog')), findsOneWidget);
    expect(find.byKey(const Key('backup-export-preview-text')), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const Key('backup-export-dialog'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('settings-restore-backup-button')),
    );
    await tester.tap(find.byKey(const Key('settings-restore-backup-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('backup-import-field')), '{');
    await tester.tap(find.byKey(const Key('backup-import-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('backup-import-message')), findsOneWidget);
    expect(find.text('Backup JSON is not valid.'), findsOneWidget);
  });

  testWidgets('result card exposes semantics and copy action', (tester) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments;
          if (arguments is Map) {
            copiedText = arguments['text'] as String?;
          }
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpCalculator(tester);

    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any(
            (widget) =>
                widget.properties.label == 'Expression editor' &&
                widget.properties.textField == true,
          ),
      isTrue,
    );

    await submitExpression(tester, '7+8');

    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any(
            (widget) =>
                widget.properties.label?.contains('Calculation result') ??
                false,
          ),
      isTrue,
    );
    await tester.tap(find.byKey(const Key('copy-result-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(copiedText, '15');
  });

  testWidgets('desktop keyboard shortcuts switch premium modes', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('graph-panel')), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('worksheet-panel')), findsOneWidget);
  });

  testWidgets('compact layout uses bottom mode bar', (tester) async {
    await pumpCalculator(tester, size: const Size(390, 820));

    expect(find.byKey(const Key('mode-bottom-bar')), findsOneWidget);
    expect(find.byKey(const Key('mode-chip-GRAPH')), findsOneWidget);
  });

  testWidgets('autocomplete replaces the current token with a function', (
    tester,
  ) async {
    final controller = await pumpCalculator(tester);

    await tester.enterText(find.byKey(const Key('expression-input')), 'so');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('autocomplete-suggestion-solve')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('autocomplete-suggestion-solve')));
    await tester.pumpAndSettle();

    expect(controller.state.expression, 'solve(');
  });

  testWidgets('function palette inserts CAS functions', (tester) async {
    final controller = await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('open-function-palette-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('function-symbol-palette')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('palette-category-CAS')));
    await tester.tap(find.byKey(const Key('palette-category-CAS')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('palette-item-solve')));
    await tester.tap(find.byKey(const Key('palette-item-solve')));
    await tester.pumpAndSettle();

    expect(controller.state.expression, 'solve(');
  });

  testWidgets(
    'structured editors insert matrix vector dataset unit and solve templates',
    (tester) async {
      final controller = await pumpCalculator(tester);

      await tester.tap(find.byKey(const Key('open-matrix-editor-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('matrix-editor-sheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('matrix-editor-insert')));
      await tester.pumpAndSettle();
      expect(controller.state.expression, startsWith('mat(2,2'));

      controller.clearExpression();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-vector-editor-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('vector-editor-insert')));
      await tester.pumpAndSettle();
      expect(controller.state.expression, 'vec(1,2,3)');

      controller.clearExpression();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-dataset-editor-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dataset-summary-text')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dataset-editor-insert')));
      await tester.pumpAndSettle();
      expect(controller.state.expression, 'data(1, 2, 3, 4)');

      controller.clearExpression();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-unit-converter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unit-converter-insert')));
      await tester.pumpAndSettle();
      expect(controller.state.expression, 'to(72 km/h, m/s)');

      controller.clearExpression();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-solve-cas-editor-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('solve-cas-editor-insert')));
      await tester.pumpAndSettle();
      expect(controller.state.expression, 'solve(x^2 - 4 = 0, x)');
    },
  );

  testWidgets('graph function editor applies multiple graph expressions', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(find.byKey(const Key('graph-mode-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('graph-function-editor-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('graph-function-editor-sheet')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('graph-editor-expressions')),
      'sin(x)\ncos(x)',
    );
    await tester.tap(find.byKey(const Key('graph-editor-apply')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('graph-expression-0')), findsOneWidget);
    expect(find.byKey(const Key('graph-expression-1')), findsOneWidget);
  });

  testWidgets('worksheet block editor opens focused run and validation sheet', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await openWorksheetPanel(tester);
    await tester.tap(find.byKey(const Key('worksheet-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('worksheet-add-calculation-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('worksheet-edit-block-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('worksheet-block-editor-0')), findsOneWidget);
    expect(
      find.byKey(const Key('worksheet-block-editor-run-0')),
      findsOneWidget,
    );
  });

  testWidgets('keyboard shortcut Ctrl+L clears the expression', (tester) async {
    final controller = await pumpCalculator(tester);

    await tester.enterText(find.byKey(const Key('expression-input')), '1+2');
    await tester.pumpAndSettle();
    expect(controller.state.expression, '1+2');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(controller.state.expression, isEmpty);
  });
}
