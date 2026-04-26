import '../../../core/calculator/performance/calculator_benchmarks.dart';
import 'execution/worksheet_executor.dart';
import 'worksheet_document.dart';

class WorksheetBenchmarkHarness {
  WorksheetBenchmarkHarness({WorksheetExecutor? executor})
    : _executor = executor ?? WorksheetExecutor();

  final WorksheetExecutor _executor;

  CalculatorBenchmarkResult benchmarkRunAll(
    WorksheetDocument worksheet, {
    int iterations = 3,
  }) {
    final safeIterations = iterations < 1 ? 1 : iterations;
    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < safeIterations; index++) {
      _executor.runAll(worksheet);
    }
    stopwatch.stop();
    return CalculatorBenchmarkResult(
      name: 'worksheet: runAll',
      iterations: safeIterations,
      elapsed: stopwatch.elapsed,
      operationCount: safeIterations,
    );
  }
}
