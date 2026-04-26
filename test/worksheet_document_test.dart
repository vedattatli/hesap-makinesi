import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/saved_expression_template.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_block.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_block_result.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_document.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_graph_state.dart';

void main() {
  WorksheetGraphState sampleGraphState() {
    final now = DateTime.utc(2026, 4, 26, 12);
    return WorksheetGraphState(
      id: 'graph-1',
      title: 'Trig Graph',
      expressions: const <String>['sin(x)', 'cos(x)'],
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
      plotSeriesCount: 2,
      plotPointCount: 1024,
      plotSegmentCount: 2,
      lastPlotSummary: '2 series, 1024 points, 2 segments',
    );
  }

  WorksheetBlockResult sampleResult() {
    return const WorksheetBlockResult(
      displayResult: '1/2',
      valueKind: CalculatorValueKind.rational,
      isApproximate: false,
      warnings: <String>[],
      normalizedExpression: '1 / 2',
      exactDisplayResult: '1/2',
      decimalDisplayResult: '0.5',
    );
  }

  group('WorksheetDocument', () {
    test('uses default title fallback', () {
      final document = WorksheetDocument.fromJson(<String, dynamic>{
        'id': 'worksheet-1',
        'title': '',
        'blocks': const <dynamic>[],
        'createdAt': '2026-04-26T12:00:00.000Z',
        'updatedAt': '2026-04-26T12:00:00.000Z',
      });

      expect(document.title, 'Untitled Worksheet');
      expect(document.version, WorksheetDocument.currentVersion);
    });

    test('serializes worksheet with blocks, templates and saved graphs', () {
      final graphState = sampleGraphState();
      final document = WorksheetDocument(
        id: 'worksheet-1',
        title: 'Experiment Log',
        blocks: <WorksheetBlock>[
          WorksheetBlock.calculation(
            id: 'calc-1',
            orderIndex: 0,
            expression: '1/3 + 1/6',
            angleMode: AngleMode.degree,
            precision: 10,
            numericMode: NumericMode.exact,
            calculationDomain: CalculationDomain.real,
            unitMode: UnitMode.disabled,
            resultFormat: NumberFormatStyle.auto,
            createdAt: DateTime.utc(2026, 4, 26, 12),
            updatedAt: DateTime.utc(2026, 4, 26, 12, 1),
            result: sampleResult(),
          ),
          WorksheetBlock.text(
            id: 'text-1',
            orderIndex: 1,
            text: '## Experiment\nsin(x) and cos(x)',
            format: WorksheetTextFormat.markdownLite,
            createdAt: DateTime.utc(2026, 4, 26, 12, 2),
          ),
          WorksheetBlock.graph(
            id: 'graph-block-1',
            orderIndex: 2,
            graphState: graphState,
            createdAt: DateTime.utc(2026, 4, 26, 12, 3),
          ),
        ],
        createdAt: DateTime.utc(2026, 4, 26, 12),
        updatedAt: DateTime.utc(2026, 4, 26, 12, 4),
        version: WorksheetDocument.currentVersion,
        activeGraphState: graphState,
        savedExpressionTemplates: <SavedExpressionTemplate>[
          SavedExpressionTemplate(
            id: 'template-1',
            label: 'Quadratic',
            expression: 'x^2',
            type: SavedExpressionTemplateType.graphFunction,
            variableName: 'x',
            createdAt: DateTime.utc(2026, 4, 26, 12),
            updatedAt: DateTime.utc(2026, 4, 26, 12),
          ),
        ],
        savedGraphStates: <WorksheetGraphState>[graphState],
      );

      final restored = WorksheetDocument.fromJson(document.toJson());

      expect(restored.title, 'Experiment Log');
      expect(restored.blocks, hasLength(3));
      expect(restored.blocks.first.expression, '1/3 + 1/6');
      expect(restored.blocks[1].textFormat, WorksheetTextFormat.markdownLite);
      expect(restored.blocks.last.graphState?.expressions, <String>['sin(x)', 'cos(x)']);
      expect(restored.savedExpressionTemplates.single.expression, 'x^2');
      expect(restored.savedGraphStates.single.lastPlotSummary, contains('1024'));
      expect(restored.activeGraphState?.title, 'Trig Graph');
    });

    test('unknown block types are skipped safely', () {
      final document = WorksheetDocument.fromJson(<String, dynamic>{
        'id': 'worksheet-1',
        'title': 'Legacy',
        'blocks': <dynamic>[
          <String, dynamic>{
            'id': 'unknown-1',
            'type': 'mystery',
            'createdAt': '2026-04-26T12:00:00.000Z',
            'updatedAt': '2026-04-26T12:00:00.000Z',
            'orderIndex': 0,
          },
          WorksheetBlock.text(
            id: 'text-1',
            orderIndex: 1,
            text: 'hello',
            createdAt: DateTime.utc(2026, 4, 26, 12, 1),
          ).toJson(),
        ],
        'createdAt': '2026-04-26T12:00:00.000Z',
        'updatedAt': '2026-04-26T12:00:00.000Z',
      });

      expect(document.blocks, hasLength(1));
      expect(document.blocks.single.isText, isTrue);
    });

    test('block ordering is restored by orderIndex', () {
      final raw = <String, dynamic>{
        'id': 'worksheet-1',
        'title': 'Ordered',
        'blocks': <dynamic>[
          WorksheetBlock.text(
            id: 'text-2',
            orderIndex: 2,
            text: 'last',
            createdAt: DateTime.utc(2026, 4, 26, 12, 2),
          ).toJson(),
          WorksheetBlock.text(
            id: 'text-0',
            orderIndex: 0,
            text: 'first',
            createdAt: DateTime.utc(2026, 4, 26, 12, 0),
          ).toJson(),
          WorksheetBlock.text(
            id: 'text-1',
            orderIndex: 1,
            text: 'middle',
            createdAt: DateTime.utc(2026, 4, 26, 12, 1),
          ).toJson(),
        ],
        'createdAt': '2026-04-26T12:00:00.000Z',
        'updatedAt': '2026-04-26T12:00:00.000Z',
      };

      final document = WorksheetDocument.fromJson(raw);

      expect(document.blocks.map((block) => block.text).toList(), <String?>[
        'first',
        'middle',
        'last',
      ]);
    });

    test('stored string helpers decode and encode safely', () {
      final document = WorksheetDocument(
        id: 'worksheet-1',
        title: 'Stored',
        blocks: const <WorksheetBlock>[],
        createdAt: DateTime.utc(2026, 4, 26, 12),
        updatedAt: DateTime.utc(2026, 4, 26, 12),
        version: WorksheetDocument.currentVersion,
      );

      final encoded = WorksheetDocument.listToStoredString(<WorksheetDocument>[
        document,
      ]);
      final restored = WorksheetDocument.listFromStoredString(encoded);

      expect(restored, hasLength(1));
      expect(restored.single.title, 'Stored');
    });

    test('corrupt worksheet json falls back to empty list', () {
      expect(WorksheetDocument.listFromStoredString('{oops'), isEmpty);
    });

    test('old json missing optional fields uses safe defaults', () {
      final document = WorksheetDocument.fromJson(<String, dynamic>{
        'id': 'worksheet-legacy',
        'title': 'Legacy',
        'blocks': const <dynamic>[],
        'createdAt': '2026-04-26T12:00:00.000Z',
        'updatedAt': '2026-04-26T12:00:00.000Z',
      });

      expect(document.isArchived, isFalse);
      expect(document.savedExpressionTemplates, isEmpty);
      expect(document.savedGraphStates, isEmpty);
      expect(document.activeGraphState, isNull);
    });
  });

  group('WorksheetBlock', () {
    test('calculation block serializes result metadata', () {
      final block = WorksheetBlock.calculation(
        id: 'calc-1',
        orderIndex: 0,
        expression: '1/3 + 1/6',
        angleMode: AngleMode.degree,
        precision: 10,
        numericMode: NumericMode.exact,
        calculationDomain: CalculationDomain.real,
        unitMode: UnitMode.disabled,
        resultFormat: NumberFormatStyle.auto,
        result: sampleResult(),
      );

      final restored = WorksheetBlock.tryFromJson(block.toJson());

      expect(restored?.isCalculation, isTrue);
      expect(restored?.result?.displayResult, '1/2');
      expect(restored?.numericMode, NumericMode.exact);
    });

    test('graph block serializes graph state', () {
      final block = WorksheetBlock.graph(
        id: 'graph-1',
        orderIndex: 0,
        graphState: sampleGraphState(),
      );

      final restored = WorksheetBlock.tryFromJson(block.toJson());

      expect(restored?.isGraph, isTrue);
      expect(restored?.graphState?.plotSeriesCount, 2);
    });

    test('text block serializes markdown format', () {
      final block = WorksheetBlock.text(
        id: 'text-1',
        orderIndex: 0,
        text: '## Experiment',
        format: WorksheetTextFormat.markdownLite,
      );

      final restored = WorksheetBlock.tryFromJson(block.toJson());

      expect(restored?.isText, isTrue);
      expect(restored?.textFormat, WorksheetTextFormat.markdownLite);
    });

    test('variable definition block serializes scoped metadata', () {
      final block = WorksheetBlock.variableDefinition(
        id: 'var-1',
        orderIndex: 0,
        name: 'a',
        expression: '1/3 + 1/6',
        angleMode: AngleMode.degree,
        precision: 10,
        numericMode: NumericMode.exact,
        calculationDomain: CalculationDomain.real,
        unitMode: UnitMode.disabled,
        resultFormat: NumberFormatStyle.auto,
        dependencies: const <String>[],
        isStale: true,
      );

      final restored = WorksheetBlock.tryFromJson(block.toJson());

      expect(restored?.isVariableDefinition, isTrue);
      expect(restored?.symbolName, 'a');
      expect(restored?.expression, '1/3 + 1/6');
    });

    test('function definition block serializes parameters and body', () {
      final block = WorksheetBlock.functionDefinition(
        id: 'fn-1',
        orderIndex: 1,
        name: 'f',
        parameters: const <String>['x', 'y'],
        bodyExpression: 'x + y',
        angleMode: AngleMode.degree,
        precision: 10,
        numericMode: NumericMode.exact,
        calculationDomain: CalculationDomain.real,
        unitMode: UnitMode.disabled,
        resultFormat: NumberFormatStyle.auto,
        dependencies: const <String>['a'],
        isStale: true,
      );

      final restored = WorksheetBlock.tryFromJson(block.toJson());

      expect(restored?.isFunctionDefinition, isTrue);
      expect(restored?.symbolName, 'f');
      expect(restored?.parameters, <String>['x', 'y']);
      expect(restored?.bodyExpression, 'x + y');
      expect(restored?.dependencies, <String>['a']);
    });

    test('unknown block type returns null', () {
      final restored = WorksheetBlock.tryFromJson(<String, dynamic>{
        'id': 'unknown',
        'type': 'mystery',
      });

      expect(restored, isNull);
    });
  });

  test('worksheet stored json remains stable for deterministic assertions', () {
    final document = WorksheetDocument(
      id: 'worksheet-1',
      title: 'Stable',
      blocks: const <WorksheetBlock>[],
      createdAt: DateTime.utc(2026, 4, 26, 12),
      updatedAt: DateTime.utc(2026, 4, 26, 12),
      version: WorksheetDocument.currentVersion,
    );

    final decoded = jsonDecode(document.toStoredString()) as Map<String, dynamic>;

    expect(decoded['title'], 'Stable');
    expect(decoded['version'], WorksheetDocument.currentVersion);
  });
}
