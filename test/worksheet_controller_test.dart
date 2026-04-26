import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/features/calculator/productization/examples_library.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/memory_worksheet_storage.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/saved_expression_template.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_controller.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_error.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_graph_state.dart';

void main() {
  WorksheetGraphState sampleGraphState() {
    final now = DateTime.utc(2026, 4, 26, 12);
    return WorksheetGraphState(
      id: 'graph-1',
      title: 'Graph Block',
      expressions: const <String>['sin(x)'],
      viewport: GraphViewport(
        xMin: -3.1415926535,
        xMax: 3.1415926535,
        yMin: -1.5,
        yMax: 1.5,
      ),
      autoY: false,
      showGrid: true,
      showAxes: true,
      initialSamples: 512,
      maxSamples: 4096,
      adaptiveDepth: 6,
      discontinuityThreshold: 6,
      minStep: 1e-4,
      angleMode: AngleMode.radian,
      numericMode: NumericMode.approximate,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.disabled,
      resultFormat: NumberFormatStyle.auto,
      precision: 10,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('WorksheetController', () {
    late WorksheetController controller;

    setUp(() {
      controller = WorksheetController(storage: MemoryWorksheetStorage());
    });

    test('initialize loads empty state', () async {
      await controller.initialize();

      expect(controller.state.worksheets, isEmpty);
      expect(controller.state.activeWorksheet, isNull);
    });

    test('create, select and delete worksheet updates state', () async {
      await controller.initialize();
      final first = await controller.createWorksheet('First');
      final second = await controller.createWorksheet('Second');

      expect(controller.state.worksheets, hasLength(2));
      expect(controller.state.activeWorksheetId, second.id);

      await controller.selectWorksheet(first.id);
      expect(controller.state.activeWorksheetId, first.id);

      await controller.deleteWorksheet(first.id);
      expect(controller.state.worksheets, hasLength(1));
      expect(controller.state.activeWorksheet?.title, 'Second');
    });

    test('sample worksheets can be added and cleared', () async {
      await controller.initialize();
      final samples = SampleWorksheetFactory.buildSamples(
        timestamp: DateTime.utc(2026, 4, 26),
      );

      await controller.addSampleWorksheets(samples);

      expect(controller.state.worksheets, hasLength(5));
      expect(controller.state.activeWorksheetId, samples.first.id);

      await controller.clearAllWorksheets();

      expect(controller.state.worksheets, isEmpty);
      expect(controller.state.activeWorksheet, isNull);
    });

    test('add calculation, text and graph blocks', () async {
      await controller.initialize();
      await controller.createWorksheet('Notebook');

      final calc = await controller.addCalculationBlock(expression: '1+1');
      final text = await controller.addTextBlock(text: 'Observation');
      final graph = await controller.addGraphBlock(sampleGraphState());

      final worksheet = controller.state.activeWorksheet!;
      expect(worksheet.blocks, hasLength(3));
      expect(calc.isCalculation, isTrue);
      expect(text.isText, isTrue);
      expect(graph.isGraph, isTrue);
    });

    test('run calculation block saves result snapshot', () async {
      await controller.initialize();
      await controller.createWorksheet('Notebook');
      final block = await controller.addCalculationBlock(
        expression: '1/3 + 1/6',
        numericMode: NumericMode.exact,
      );

      await controller.runBlock(block.id);

      final updated = controller.state.activeWorksheet!.blocks.single;
      expect(updated.result?.displayResult, '1/2');
      expect(updated.result?.valueKind, CalculatorValueKind.rational);
    });

    test('run all evaluates graph and continues after failures', () async {
      await controller.initialize();
      await controller.createWorksheet('Notebook');
      await controller.addCalculationBlock(expression: '1/0');
      await controller.addTextBlock(text: 'Keep going');
      await controller.addCalculationBlock(expression: '2+2');
      await controller.addGraphBlock(sampleGraphState());

      await controller.runAllBlocks();

      final blocks = controller.state.activeWorksheet!.blocks;
      expect(blocks[0].result?.hasError, isTrue);
      expect(blocks[2].result?.displayResult, '4');
      expect(blocks[3].graphState?.plotSeriesCount, 1);
    });

    test('save current calculation snapshot stores mode metadata', () async {
      await controller.initialize();

      final engine = const CalculatorEngine();
      final outcome = engine.evaluate(
        'sqrt(2)',
        context: const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.symbolic,
        ),
      );

      final block = await controller.saveCurrentCalculationResultAsBlock(
        expression: 'sqrt(2)',
        outcome: outcome,
        angleMode: AngleMode.degree,
        precision: 10,
        numericMode: NumericMode.exact,
        calculationDomain: CalculationDomain.real,
        unitMode: UnitMode.disabled,
        resultFormat: NumberFormatStyle.symbolic,
      );

      expect(block.result?.displayResult, '√2');
      expect(block.numericMode, NumericMode.exact);
      expect(controller.state.activeWorksheet?.blocks, hasLength(1));
    });

    test('recall helpers return calculation and graph data', () async {
      await controller.initialize();
      await controller.createWorksheet('Notebook');
      final calc = await controller.addCalculationBlock(expression: '2+2');
      final graph = await controller.addGraphBlock(sampleGraphState());

      expect(controller.recallCalculationExpression(calc.id), '2+2');
      expect(controller.recallGraphState(graph.id)?.expressions, <String>[
        'sin(x)',
      ]);
    });

    test('move block changes order indices', () async {
      await controller.initialize();
      await controller.createWorksheet('Notebook');
      final first = await controller.addTextBlock(text: 'first');
      final second = await controller.addTextBlock(text: 'second');

      await controller.moveBlock(second.id, 0);

      final blocks = controller.state.activeWorksheet!.blocks;
      expect(blocks.first.id, second.id);
      expect(blocks.first.orderIndex, 0);
      expect(blocks.last.id, first.id);
      expect(blocks.last.orderIndex, 1);
    });

    test(
      'templates can be added and removed without global resolution',
      () async {
        await controller.initialize();
        await controller.createWorksheet('Notebook');

        await controller.addSavedExpressionTemplate(
          label: 'Quadratic',
          expression: 'x^2',
          type: SavedExpressionTemplateType.graphFunction,
        );

        expect(
          controller.state.activeWorksheet?.savedExpressionTemplates,
          hasLength(1),
        );
        expect(
          controller
              .templateById(
                controller
                    .state
                    .activeWorksheet!
                    .savedExpressionTemplates
                    .single
                    .id,
              )
              ?.expression,
          'x^2',
        );

        await controller.deleteSavedExpressionTemplate(
          controller.state.activeWorksheet!.savedExpressionTemplates.single.id,
        );
        expect(
          controller.state.activeWorksheet?.savedExpressionTemplates,
          isEmpty,
        );
      },
    );

    test('export worksheet markdown and csv populate preview', () async {
      await controller.initialize();
      await controller.createWorksheet('Notebook');
      final block = await controller.addCalculationBlock(expression: '2+2');
      await controller.runBlock(block.id);

      final markdown = await controller.exportWorksheetMarkdown(
        controller.state.activeWorksheet!.id,
      );
      final csv = await controller.exportWorksheetCsv(
        controller.state.activeWorksheet!.id,
      );

      expect(markdown.contentText, contains('# Notebook'));
      expect(csv.contentText, contains('worksheetId,worksheetTitle'));
      expect(controller.state.exportPreview?.mimeType, 'text/csv');
    });

    test('graph exports regenerate plot output', () async {
      await controller.initialize();
      await controller.createWorksheet('Notebook');
      final graphBlock = await controller.addGraphBlock(sampleGraphState());

      final svg = await controller.exportGraphSvg(graphBlock.id);
      final csv = await controller.exportGraphDataCsv(graphBlock.id);

      expect(svg.contentText, startsWith('<svg'));
      expect(csv.contentText, contains('seriesIndex,seriesLabel'));
    });

    test('exporting invalid graph block throws worksheet exception', () async {
      await controller.initialize();
      await controller.createWorksheet('Notebook');
      final calc = await controller.addCalculationBlock(expression: '2+2');

      expect(
        () => controller.exportGraphSvg(calc.id),
        throwsA(
          isA<WorksheetException>().having(
            (error) => error.error.code,
            'code',
            WorksheetErrorCode.graphExportFailed,
          ),
        ),
      );
    });

    test(
      'variable and function blocks can be added and evaluated in worksheet scope',
      () async {
        await controller.initialize();
        await controller.createWorksheet('Notebook');

        await controller.addVariableDefinitionBlock('a', '2');
        await controller.addFunctionDefinitionBlock('f', const <String>[
          'x',
        ], 'x^2 + a');
        await controller.addCalculationBlock(expression: 'f(3)');

        await controller.runAllBlocks();

        final blocks = controller.state.activeWorksheet!.blocks;
        expect(blocks[0].result?.displayResult, '2');
        expect(blocks[1].result?.displayResult, contains('f(x)'));
        expect(blocks[2].result?.displayResult, '11');
        expect(
          controller.state.activeSymbols.map((symbol) => symbol.name),
          containsAll(<String>['a', 'f']),
        );
      },
    );

    test(
      'editing an upstream definition marks dependent blocks stale',
      () async {
        await controller.initialize();
        await controller.createWorksheet('Notebook');
        final variable = await controller.addVariableDefinitionBlock('a', '2');
        final calc = await controller.addCalculationBlock(expression: 'a + 3');

        await controller.runAllBlocks();
        await controller.updateVariableDefinitionBlock(variable.id, 'a', '5');

        final blocks = controller.state.activeWorksheet!.blocks;
        expect(blocks.first.isStale, isTrue);
        expect(blocks.last.id, calc.id);
        expect(blocks.last.isStale, isTrue);
      },
    );

    test('solve blocks can be added run and recalled', () async {
      await controller.initialize();
      await controller.createWorksheet('Notebook');
      await controller.addVariableDefinitionBlock('a', '2');
      final solve = await controller.addSolveBlock(
        equationExpression: 'a*x + 4 = 0',
        variableName: 'x',
      );

      await controller.runAllBlocks();

      final blocks = controller.state.activeWorksheet!.blocks;
      expect(blocks[1].result?.displayResult, 'x = -2');
      expect(blocks[1].result?.solveMethod, 'exactLinear');
      expect(
        controller.recallCalculationExpression(solve.id),
        contains('solve('),
      );
    });

    test(
      'editing an upstream variable marks solve blocks stale and rerun clears it',
      () async {
        await controller.initialize();
        await controller.createWorksheet('Notebook');
        final variable = await controller.addVariableDefinitionBlock('a', '2');
        final solve = await controller.addSolveBlock(
          equationExpression: 'a*x + 4 = 0',
          variableName: 'x',
        );

        await controller.runAllBlocks();
        await controller.updateVariableDefinitionBlock(variable.id, 'a', '4');

        expect(
          controller.state.activeWorksheet!.blocks
              .firstWhere((block) => block.id == solve.id)
              .isStale,
          isTrue,
        );

        await controller.runAffectedBlocks(variable.id);

        final updatedSolve = controller.state.activeWorksheet!.blocks
            .firstWhere((block) => block.id == solve.id);
        expect(updatedSolve.isStale, isFalse);
        expect(updatedSolve.result?.displayResult, 'x = -1');
      },
    );
  });
}
