import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/graph_data_csv_exporter.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/graph_svg_exporter.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_block.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_block_result.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_document.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_export_service.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_graph_state.dart';

void main() {
  PlotValue samplePlot() {
    return PlotValue(
      viewport: GraphViewport(xMin: -5, xMax: 5, yMin: -2, yMax: 10),
      autoYUsed: false,
      series: const <PlotSeries>[
        PlotSeries(
          expression: '1/x',
          normalizedExpression: '1 / x',
          label: 'y = 1 / x',
          segments: <PlotSegment>[
            PlotSegment(<PlotPoint>[
              PlotPoint(x: -2, y: -0.5, isDefined: true),
              PlotPoint(x: -1, y: -1, isDefined: true),
            ]),
            PlotSegment(<PlotPoint>[
              PlotPoint(x: 1, y: 1, isDefined: true),
              PlotPoint(x: 2, y: 0.5, isDefined: true),
            ]),
          ],
          sampleCount: 4,
          definedPointCount: 4,
          undefinedPointCount: 1,
          warnings: <String>['Discontinuity detected'],
        ),
      ],
      warnings: const <String>['Discontinuity detected'],
    );
  }

  WorksheetGraphState sampleGraphState() {
    final now = DateTime.utc(2026, 4, 26, 12);
    return WorksheetGraphState(
      id: 'graph-1',
      title: 'Reciprocal',
      expressions: const <String>['1/x'],
      viewport: GraphViewport(xMin: -5, xMax: 5, yMin: -2, yMax: 10),
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
      plotSeriesCount: 1,
      plotPointCount: 4,
      plotSegmentCount: 2,
      lastPlotSummary: '1 series, 4 points, 2 segments',
      warnings: const <String>['Discontinuity detected'],
    );
  }

  WorksheetDocument sampleWorksheet() {
    return WorksheetDocument(
      id: 'worksheet-1',
      title: 'Export Demo',
      blocks: <WorksheetBlock>[
        WorksheetBlock.variableDefinition(
          id: 'var-1',
          orderIndex: 0,
          name: 'a',
          expression: '2',
          angleMode: AngleMode.degree,
          precision: 10,
          numericMode: NumericMode.exact,
          calculationDomain: CalculationDomain.real,
          unitMode: UnitMode.disabled,
          resultFormat: NumberFormatStyle.auto,
          result: const WorksheetBlockResult(
            displayResult: '2',
            valueKind: CalculatorValueKind.rational,
            isApproximate: false,
            warnings: <String>[],
          ),
          dependencies: const <String>[],
        ),
        WorksheetBlock.functionDefinition(
          id: 'fn-1',
          orderIndex: 1,
          name: 'f',
          parameters: const <String>['x'],
          bodyExpression: 'x^2 + a',
          angleMode: AngleMode.degree,
          precision: 10,
          numericMode: NumericMode.exact,
          calculationDomain: CalculationDomain.real,
          unitMode: UnitMode.disabled,
          resultFormat: NumberFormatStyle.auto,
          result: const WorksheetBlockResult(
            displayResult: 'f(x) = x^2 + a',
            valueKind: CalculatorValueKind.function,
            isApproximate: false,
            warnings: <String>[],
          ),
          dependencies: const <String>['a'],
        ),
        WorksheetBlock.text(
          id: 'text-1',
          orderIndex: 2,
          text: '## Experiment\nTesting worksheet export',
          format: WorksheetTextFormat.markdownLite,
        ),
        WorksheetBlock.calculation(
          id: 'calc-1',
          orderIndex: 3,
          expression: '1/3 + 1/6',
          angleMode: AngleMode.degree,
          precision: 10,
          numericMode: NumericMode.exact,
          calculationDomain: CalculationDomain.real,
          unitMode: UnitMode.disabled,
          resultFormat: NumberFormatStyle.auto,
          result: const WorksheetBlockResult(
            displayResult: '1/2',
            valueKind: CalculatorValueKind.rational,
            isApproximate: false,
            warnings: <String>['Exact mode'],
            normalizedExpression: '1 / 2',
            exactDisplayResult: '1/2',
            decimalDisplayResult: '0.5',
          ),
        ),
        WorksheetBlock.casTransform(
          id: 'cas-1',
          orderIndex: 4,
          expression: 'x + x',
          transformType: WorksheetCasTransformType.simplify,
          angleMode: AngleMode.degree,
          precision: 10,
          numericMode: NumericMode.exact,
          calculationDomain: CalculationDomain.real,
          unitMode: UnitMode.disabled,
          resultFormat: NumberFormatStyle.auto,
          result: const WorksheetBlockResult(
            displayResult: '2 * x',
            valueKind: CalculatorValueKind.expressionTransform,
            isApproximate: false,
            warnings: <String>[],
            alternativeResults: <String, String>{
              'steps': 'Canonicalized polynomial terms',
            },
          ),
        ),
        WorksheetBlock.graph(
          id: 'graph-1',
          orderIndex: 5,
          graphState: sampleGraphState(),
          dependencies: const <String>['f'],
        ),
      ],
      createdAt: DateTime.utc(2026, 4, 26, 12),
      updatedAt: DateTime.utc(2026, 4, 26, 12, 30),
      version: WorksheetDocument.currentVersion,
    );
  }

  group('WorksheetExportService', () {
    const service = WorksheetExportService();

    test('exports markdown with deterministic structure', () {
      final export = service.exportMarkdown(sampleWorksheet());

      expect(export.extension, 'md');
      expect(export.contentText, contains('# Export Demo'));
      expect(export.contentText, contains('## Variable'));
      expect(export.contentText, contains('Definition: `a = 2`'));
      expect(export.contentText, contains('## Function'));
      expect(export.contentText, contains('Definition: `f(x) = x^2 + a`'));
      expect(export.contentText, contains('## Calculation'));
      expect(export.contentText, contains('Expression: `1/3 + 1/6`'));
      expect(export.contentText, contains('Result: `1/2`'));
      expect(export.contentText, contains('## CAS Transform'));
      expect(export.contentText, contains('Transform: `simplify`'));
      expect(export.contentText, contains('Result: `2 * x`'));
      expect(export.contentText, contains('## Graph'));
      expect(export.contentText, contains('Viewport: `'));
      expect(export.contentText.contains('\r\n'), isFalse);
    });

    test('exports worksheet csv with stable header and escaping', () {
      final worksheet = sampleWorksheet().copyWith(
        blocks: <WorksheetBlock>[
          WorksheetBlock.text(
            id: 'text-1',
            orderIndex: 0,
            text: 'Line 1,\n"quoted"',
          ),
        ],
      );

      final export = service.exportWorksheetCsv(worksheet);
      final lines = export.contentText.trim().split('\n');

      expect(lines.first, startsWith('worksheetId,worksheetTitle,blockId'));
      expect(lines.first, contains('casTransformType'));
      expect(lines.first, contains('casSteps'));
      expect(lines, hasLength(3));
      expect(lines[1], contains('"Line 1,'));
      expect(lines[2], contains('""quoted"""'));
    });
  });

  group('Graph exporters', () {
    const svgExporter = GraphSvgExporter();
    const csvExporter = GraphDataCsvExporter();

    test('svg exporter emits deterministic segmented svg', () {
      final svg = svgExporter.export(samplePlot(), sampleGraphState());

      expect(svg, startsWith('<svg'));
      expect(svg, contains('viewBox="0 0 800 480"'));
      expect(svg, contains('<polyline'));
      expect(RegExp(r'<polyline').allMatches(svg).length, 2);
      expect(svg, contains('#2563eb'));
    });

    test('graph csv exporter emits point rows with headers', () {
      final csv = csvExporter.export(samplePlot());
      final lines = csv.trim().split('\n');

      expect(
        lines.first,
        'seriesIndex,seriesLabel,segmentIndex,pointIndex,x,y,defined',
      );
      expect(lines, hasLength(5));
      expect(lines.last, contains('2,0.5,true'));
    });
  });
}
