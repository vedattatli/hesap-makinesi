import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/execution/worksheet_executor.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_block.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_document.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_error.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_graph_state.dart';

void main() {
  WorksheetGraphState graphState(String expression) {
    final now = DateTime.utc(2026, 4, 26, 12);
    return WorksheetGraphState(
      id: 'graph-$expression',
      title: 'Graph',
      expressions: <String>[expression],
      viewport: GraphViewport(xMin: -5, xMax: 5, yMin: -10, yMax: 10),
      autoY: false,
      showGrid: true,
      showAxes: true,
      initialSamples: 128,
      maxSamples: 1024,
      adaptiveDepth: 4,
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

  WorksheetDocument document(List<WorksheetBlock> blocks) {
    final now = DateTime.utc(2026, 4, 26, 12);
    return WorksheetDocument(
      id: 'worksheet-1',
      title: 'Scoped',
      blocks: blocks,
      createdAt: now,
      updatedAt: now,
      version: WorksheetDocument.currentVersion,
    );
  }

  WorksheetBlock variableBlock(
    String id,
    int order,
    String name,
    String expression,
  ) {
    return WorksheetBlock.variableDefinition(
      id: id,
      orderIndex: order,
      name: name,
      expression: expression,
      angleMode: AngleMode.degree,
      precision: 10,
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.disabled,
      resultFormat: NumberFormatStyle.auto,
    );
  }

  WorksheetBlock functionBlock(
    String id,
    int order,
    String name,
    List<String> parameters,
    String body,
  ) {
    return WorksheetBlock.functionDefinition(
      id: id,
      orderIndex: order,
      name: name,
      parameters: parameters,
      bodyExpression: body,
      angleMode: AngleMode.degree,
      precision: 10,
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.disabled,
      resultFormat: NumberFormatStyle.auto,
    );
  }

  WorksheetBlock calcBlock(String id, int order, String expression) {
    return WorksheetBlock.calculation(
      id: id,
      orderIndex: order,
      expression: expression,
      angleMode: AngleMode.degree,
      precision: 10,
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.disabled,
      resultFormat: NumberFormatStyle.auto,
    );
  }

  WorksheetBlock solveBlock(
    String id,
    int order,
    String equation,
    String variable, {
    String? min,
    String? max,
    WorksheetSolveMethodPreference method = WorksheetSolveMethodPreference.auto,
  }) {
    return WorksheetBlock.solve(
      id: id,
      orderIndex: order,
      equationExpression: equation,
      variableName: variable,
      intervalMinExpression: min,
      intervalMaxExpression: max,
      methodPreference: method,
      angleMode: AngleMode.radian,
      precision: 10,
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.disabled,
      resultFormat: NumberFormatStyle.auto,
    );
  }

  WorksheetBlock casBlock(
    String id,
    int order,
    String expression, {
    WorksheetCasTransformType transformType =
        WorksheetCasTransformType.simplify,
  }) {
    return WorksheetBlock.casTransform(
      id: id,
      orderIndex: order,
      expression: expression,
      transformType: transformType,
      angleMode: AngleMode.degree,
      precision: 10,
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.disabled,
      resultFormat: NumberFormatStyle.auto,
    );
  }

  group('WorksheetExecutor', () {
    final executor = WorksheetExecutor();

    test(
      'runAll evaluates in dependency order while preserving display order',
      () {
        final input = document(<WorksheetBlock>[
          calcBlock('calc', 0, 'b * 4'),
          variableBlock('b', 1, 'b', 'a + 3'),
          variableBlock('a', 2, 'a', '2'),
        ]);

        final execution = executor.runAll(input);
        final blocks = execution.worksheet.blocks;

        expect(blocks.map((block) => block.id), <String>['calc', 'b', 'a']);
        expect(blocks.first.result?.displayResult, '20');
        expect(blocks[1].result?.displayResult, '5');
        expect(blocks[2].result?.displayResult, '2');
        expect(
          execution.symbolTable.symbols.map((symbol) => symbol.name),
          containsAll(<String>['a', 'b']),
        );
      },
    );

    test(
      'worksheet functions can depend on variables and calculations can call them',
      () {
        final input = document(<WorksheetBlock>[
          functionBlock('f', 0, 'f', const <String>['x'], 'x^2 + a'),
          variableBlock('a', 1, 'a', '1'),
          calcBlock('calc', 2, 'f(3)'),
        ]);

        final execution = executor.runAll(input);

        expect(execution.worksheet.blocks[2].result?.displayResult, '10');
        expect(
          execution.worksheet.blocks[0].result?.displayResult,
          contains('f(x)'),
        );
      },
    );

    test('cycles are detected and surfaced as worksheet errors', () {
      final input = document(<WorksheetBlock>[
        variableBlock('a', 0, 'a', 'b + 1'),
        variableBlock('b', 1, 'b', 'a + 1'),
      ]);

      final validation = executor.validate(input);

      expect(
        validation.worksheet.blocks.every(
          (block) =>
              block.worksheetErrorCode == WorksheetErrorCode.dependencyCycle,
        ),
        isTrue,
      );
      expect(
        validation.worksheet.blocks.first.worksheetErrorMessage,
        contains('Dependency cycle detected'),
      );
    });

    test('graph blocks can resolve worksheet scoped functions', () {
      final input = document(<WorksheetBlock>[
        functionBlock('f', 0, 'f', const <String>['x'], 'x^2'),
        WorksheetBlock.graph(
          id: 'graph',
          orderIndex: 1,
          graphState: graphState('f(x)'),
        ),
      ]);

      final execution = executor.runAll(input);
      final graphBlock = execution.worksheet.blocks[1];

      expect(graphBlock.graphState?.plotSeriesCount, 1);
      expect(graphBlock.isStale, isFalse);
      expect(execution.generatedPlots['graph'], isNotNull);
    });

    test('graph blocks can resolve worksheet scoped variables', () {
      final input = document(<WorksheetBlock>[
        variableBlock('a', 0, 'a', '2'),
        WorksheetBlock.graph(
          id: 'graph',
          orderIndex: 1,
          graphState: graphState('a*x'),
        ),
      ]);

      final execution = executor.runAll(input);

      expect(execution.worksheet.blocks[1].worksheetErrorCode, isNull);
      expect(execution.generatedPlots['graph'], isNotNull);
    });

    test('solve blocks evaluate scoped variables and functions', () {
      final input = document(<WorksheetBlock>[
        variableBlock('a', 0, 'a', '2'),
        functionBlock('f', 1, 'f', const <String>['x'], 'x^2 - a^2'),
        solveBlock('solveA', 2, 'a*x + 4 = 0', 'x'),
        solveBlock('solveF', 3, 'f(x) = 0', 'x'),
      ]);

      final execution = executor.runAll(input);
      final blocks = execution.worksheet.blocks;

      expect(blocks[2].result?.displayResult, 'x = -2');
      expect(blocks[2].result?.solveMethod, 'exactLinear');
      expect(blocks[3].result?.displayResult, 'x = {-2, 2}');
    });

    test('solve blocks ignore local solve variable in dependency graph', () {
      final input = document(<WorksheetBlock>[
        variableBlock('a', 0, 'a', '2'),
        solveBlock('solveA', 1, 'a*x + 4 = 0', 'x'),
      ]);

      final graph = executor.dependencyGraphFor(input);
      final dependencies = graph.nodesByBlockId['solveA']!.dependencies;

      expect(dependencies, <String>{'a'});
      expect(dependencies.contains('x'), isFalse);
    });

    test(
      'failed solve blocks store error snapshots without defining symbols',
      () {
        final input = document(<WorksheetBlock>[
          solveBlock('solve', 0, 'sin(x) = 0', 'x'),
          calcBlock('calc', 1, '2+2'),
        ]);

        final execution = executor.runAll(input);

        expect(execution.worksheet.blocks[0].result?.hasError, isTrue);
        expect(execution.worksheet.blocks[1].result?.displayResult, '4');
        expect(execution.symbolTable.variableValues, isEmpty);
      },
    );

    test('cas transform blocks run and store CAS step snapshots', () {
      final input = document(<WorksheetBlock>[
        casBlock('simplify', 0, 'x + x'),
        casBlock(
          'expand',
          1,
          '(x + 1)^2',
          transformType: WorksheetCasTransformType.expand,
        ),
      ]);

      final execution = executor.runAll(input);
      final blocks = execution.worksheet.blocks;

      expect(blocks[0].result?.displayResult, '2 * x');
      expect(blocks[0].result?.alternativeResults['steps'], isNotNull);
      expect(blocks[1].result?.displayResult, 'x ^ 2 + 2 * x + 1');
      expect(blocks.every((block) => block.isStale == false), isTrue);
    });

    test('direct recursive function definitions are rejected', () {
      final input = document(<WorksheetBlock>[
        functionBlock('f', 0, 'f', const <String>['x'], 'f(x) + 1'),
      ]);

      final validation = executor.validate(input);

      expect(
        validation.worksheet.blocks.single.worksheetErrorCode,
        WorksheetErrorCode.recursiveFunction,
      );
    });
  });
}
