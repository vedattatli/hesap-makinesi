import '../calculation_context.dart';
import '../calculation_outcome.dart';
import '../calculator_engine.dart';
import '../calculator_lexer.dart';
import '../expression_parser.dart';

/// Deterministic, local-only benchmark result. This is intentionally not
/// telemetry; callers decide when and where to run it.
class CalculatorBenchmarkResult {
  const CalculatorBenchmarkResult({
    required this.name,
    required this.iterations,
    required this.elapsed,
    required this.operationCount,
  });

  final String name;
  final int iterations;
  final Duration elapsed;
  final int operationCount;

  double get averageMicroseconds =>
      elapsed.inMicroseconds / iterations.clamp(1, 1 << 30);

  Map<String, Object> toJson() => <String, Object>{
    'name': name,
    'iterations': iterations,
    'elapsedMicroseconds': elapsed.inMicroseconds,
    'averageMicroseconds': averageMicroseconds,
    'operationCount': operationCount,
  };
}

class CalculatorBenchmarkCase {
  const CalculatorBenchmarkCase({
    required this.name,
    required this.iterations,
    required this.body,
  });

  final String name;
  final int iterations;
  final Object? Function() body;

  CalculatorBenchmarkResult run() {
    final stopwatch = Stopwatch()..start();
    var operations = 0;
    for (var index = 0; index < iterations; index++) {
      body();
      operations++;
    }
    stopwatch.stop();
    return CalculatorBenchmarkResult(
      name: name,
      iterations: iterations,
      elapsed: stopwatch.elapsed,
      operationCount: operations,
    );
  }
}

class CalculatorBenchmarkSuite {
  const CalculatorBenchmarkSuite({
    this.engine = const CalculatorEngine(),
    this.lexer = const CalculatorLexer(),
    this.parser = const ExpressionParser(),
  });

  final CalculatorEngine engine;
  final CalculatorLexer lexer;
  final ExpressionParser parser;

  List<CalculatorBenchmarkResult> runStandard({
    int iterations = 3,
    CalculationContext context = const CalculationContext(),
  }) {
    final safeIterations = iterations < 1 ? 1 : iterations;
    final cases = <CalculatorBenchmarkCase>[
      parserBenchmark(
        'parser: polynomial',
        'x^3 - 6*x^2 + 11*x - 6',
        iterations: safeIterations,
      ),
      expressionBenchmark(
        'graph: sin plot',
        'plot(sin(x), -pi, pi)',
        iterations: safeIterations,
        context: context,
      ),
      expressionBenchmark(
        'matrix: determinant',
        'det(identity(4))',
        iterations: safeIterations,
        context: context,
      ),
      expressionBenchmark(
        'solve: quadratic',
        'solve(x^2 - 4 = 0, x)',
        iterations: safeIterations,
        context: context,
      ),
      expressionBenchmark(
        'stats: mean',
        'mean(data(1,2,3,4,5,6,7,8,9,10))',
        iterations: safeIterations,
        context: context,
      ),
    ];
    return cases.map((benchmark) => benchmark.run()).toList(growable: false);
  }

  CalculatorBenchmarkCase parserBenchmark(
    String name,
    String expression, {
    int iterations = 10,
  }) {
    return CalculatorBenchmarkCase(
      name: name,
      iterations: iterations,
      body: () => parser.parse(lexer.tokenize(expression)),
    );
  }

  CalculatorBenchmarkCase expressionBenchmark(
    String name,
    String expression, {
    int iterations = 3,
    CalculationContext context = const CalculationContext(),
  }) {
    return CalculatorBenchmarkCase(
      name: name,
      iterations: iterations,
      body: () {
        final outcome = engine.evaluate(expression, context: context);
        _throwIfFailed(expression, outcome);
        return outcome.result;
      },
    );
  }

  static void _throwIfFailed(String expression, CalculationOutcome outcome) {
    if (outcome.isFailure) {
      throw StateError(
        'Benchmark expression failed: $expression -> ${outcome.error?.message}',
      );
    }
  }
}
