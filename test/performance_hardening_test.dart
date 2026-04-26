import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/core/calculator/src/calculator_exception.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/execution/worksheet_executor.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_benchmarks.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_block.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_block_result.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_document.dart';

void main() {
  ExpressionNode parseExpression(String source) {
    const lexer = CalculatorLexer();
    const parser = ExpressionParser();
    return parser.parse(lexer.tokenize(source));
  }

  FunctionExpression functionOf(String source) {
    return FunctionExpression(
      originalExpression: source,
      expressionAst: parseExpression(source),
    );
  }

  WorksheetDocument worksheetOf(List<WorksheetBlock> blocks) {
    final now = DateTime.utc(2026, 4, 26, 12);
    return WorksheetDocument(
      id: 'worksheet-performance',
      title: 'Performance',
      blocks: blocks,
      createdAt: now,
      updatedAt: now,
      version: WorksheetDocument.currentVersion,
    );
  }

  WorksheetBlock cleanCalculationBlock() {
    final now = DateTime.utc(2026, 4, 26, 12);
    return WorksheetBlock.calculation(
      id: 'clean-calc',
      orderIndex: 0,
      expression: '2+2',
      angleMode: AngleMode.degree,
      precision: 10,
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.disabled,
      resultFormat: NumberFormatStyle.auto,
      createdAt: now,
      updatedAt: now,
      isStale: false,
      lastEvaluatedAt: now,
      result: const WorksheetBlockResult(
        displayResult: '4',
        valueKind: CalculatorValueKind.rational,
        isApproximate: false,
        warnings: <String>[],
      ),
    );
  }

  group('ComputationTaskRunner', () {
    test('reports cancellation without running the body', () {
      const runner = ComputationTaskRunner();
      final token = ComputationCancellationToken()..cancel();
      var ranBody = false;

      final result = runner.runSync<int>('cancelled task', (_) {
        ranBody = true;
        return 1;
      }, token: token);

      expect(result.isCancelled, isTrue);
      expect(ranBody, isFalse);
    });
  });

  group('benchmark harness', () {
    test('runs local calculator benchmark smoke cases', () {
      const suite = CalculatorBenchmarkSuite();

      final results = suite.runStandard(iterations: 1);

      expect(results, hasLength(5));
      expect(
        results.map((result) => result.name),
        containsAll(<String>[
          'parser: polynomial',
          'graph: sin plot',
          'matrix: determinant',
          'solve: quadratic',
          'stats: mean',
        ]),
      );
      expect(results.every((result) => result.operationCount == 1), isTrue);
    });

    test('runs worksheet benchmark without persisting telemetry', () {
      final harness = WorksheetBenchmarkHarness();
      final worksheet = worksheetOf(<WorksheetBlock>[cleanCalculationBlock()]);

      final result = harness.benchmarkRunAll(worksheet, iterations: 1);

      expect(result.name, 'worksheet: runAll');
      expect(result.operationCount, 1);
    });
  });

  group('performance guards', () {
    test('graph sampling rejects budgets above runtime limits', () {
      const engine = GraphEngine();

      expect(
        () => engine.plotFunction(
          functionOf('sin(x)'),
          GraphViewport(xMin: -1, xMax: 1, yMin: -1, yMax: 1),
          const CalculationContext(),
          options: const GraphSamplingOptions(
            initialSamples: 8,
            maxSamples: GraphSamplingOptions.hardMaxSamples + 1,
          ),
        ),
        throwsA(
          isA<CalculatorException>().having(
            (error) => error.error.type,
            'type',
            CalculationErrorType.graphSamplingLimit,
          ),
        ),
      );
    });

    test('matrix determinant guard remains active', () {
      const engine = CalculatorEngine();

      final outcome = engine.evaluate(
        'det(identity(7))',
        context: const CalculationContext(
          numericMode: NumericMode.exact,
          preferExactResult: true,
        ),
      );

      expect(outcome.isFailure, isTrue);
      expect(outcome.error?.type, CalculationErrorType.computationLimit);
    });

    test('distribution summation guard remains active', () {
      const engine = CalculatorEngine();

      final outcome = engine.evaluate('poissonCdf(100001, 2)');

      expect(outcome.isFailure, isTrue);
      expect(outcome.error?.type, CalculationErrorType.computationLimit);
    });
  });

  group('worksheet run-all performance', () {
    test('skips clean non-symbol blocks while preserving results', () {
      final executor = WorksheetExecutor();
      final worksheet = worksheetOf(<WorksheetBlock>[cleanCalculationBlock()]);

      final execution = executor.runAll(worksheet);

      expect(execution.skippedBlockIds, <String>['clean-calc']);
      expect(execution.executedBlockIds, isEmpty);
      expect(execution.worksheet.blocks.single.result?.displayResult, '4');
      expect(execution.summary, contains('skipped clean: 1'));
    });
  });
}
