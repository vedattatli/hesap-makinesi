import 'dart:math' as math;

import '../ast_nodes.dart';
import '../calculation_context.dart';
import '../calculation_error.dart';
import '../scope/evaluation_scope.dart';
import '../src/calculator_exception.dart';
import '../src/expression_evaluator.dart';
import '../values/calculator_value.dart';
import '../values/double_value.dart';
import '../values/matrix_value.dart';
import 'function_expression.dart';
import 'graph_result_metadata.dart';
import 'graph_sampling_options.dart';

class GraphTraceResult {
  const GraphTraceResult({
    required this.x,
    required this.y,
    required this.metadata,
  });

  final CalculatorValue x;
  final CalculatorValue y;
  final GraphResultMetadata metadata;
}

class GraphIntersectionResult {
  const GraphIntersectionResult({
    required this.value,
    required this.metadata,
  });

  final CalculatorValue value;
  final GraphResultMetadata metadata;
}

/// Numeric graph analysis helpers used by evaluator graph functions.
class GraphAnalysis {
  const GraphAnalysis();

  static const int maxRootScanSamples = 2048;
  static const int maxBisectionIterations = 80;
  static const int maxIntegrationSubintervals = 4096;

  CalculatorValue evalAt(
    FunctionExpression function,
    CalculatorValue xValue,
    CalculationContext context,
    {EvaluationScope? scope}
  ) {
    final evaluator = ExpressionEvaluator(
      context,
      scope: (scope ?? const EvaluationScope()).withVariable(
        function.variableName,
        xValue,
      ),
    );
    return evaluator.evaluate(function.expressionAst).value;
  }

  GraphTraceResult traceAt(
    FunctionExpression function,
    CalculatorValue xValue,
    CalculationContext context,
    {EvaluationScope? scope}
  ) {
    final y = evalAt(function, xValue, context, scope: scope);
    return GraphTraceResult(
      x: xValue,
      y: y,
      metadata: GraphResultMetadata(
        traceDisplayResult: 'trace: x = ${_inline(xValue)}, y = ${_inline(y)}',
      ),
    );
  }

  List<double> roots(
    FunctionExpression function,
    double xMin,
    double xMax,
    CalculationContext context,
    {EvaluationScope? scope}
  ) {
    final sampleCount = math.min(
      maxRootScanSamples,
      GraphSamplingOptions().initialSamples * 4,
    );
    final roots = <double>[];
    final step = (xMax - xMin) / (sampleCount - 1);
    double? previousX;
    double? previousY;
    for (var index = 0; index < sampleCount; index++) {
      final x = xMin + step * index;
      final y = _safeEvaluateDouble(function, x, context, scope: scope);
      if (y == null || !y.isFinite) {
        previousX = null;
        previousY = null;
        continue;
      }
      if (y.abs() < 1e-10) {
        _addDistinctRoot(roots, x);
      } else if (previousX != null &&
          previousY != null &&
          previousY.isFinite &&
          previousY.sign != y.sign) {
        _addDistinctRoot(
          roots,
          _bisection(function, previousX, x, context, scope: scope),
        );
      }
      previousX = x;
      previousY = y;
    }
    return roots..sort();
  }

  double root(
    FunctionExpression function,
    double xMin,
    double xMax,
    CalculationContext context,
    {EvaluationScope? scope}
  ) {
    final candidates = roots(function, xMin, xMax, context, scope: scope);
    if (candidates.isEmpty) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.noRootFound,
          message: 'Belirtilen aralikta kok bulunamadi.',
          suggestion: 'Daha genis veya daha uygun bir aralik deneyin.',
        ),
      );
    }
    return candidates.first;
  }

  GraphIntersectionResult intersections(
    FunctionExpression left,
    FunctionExpression right,
    double xMin,
    double xMax,
    CalculationContext context,
    {EvaluationScope? scope}
  ) {
    final difference = FunctionExpression(
      originalExpression:
          '(${left.normalizedExpression}) - (${right.normalizedExpression})',
      normalizedExpression:
          '(${left.normalizedExpression}) - (${right.normalizedExpression})',
      expressionAst: BinaryOperationNode(
        left: left.expressionAst,
        operator: '-',
        right: right.expressionAst,
        position: left.expressionAst.position,
      ),
    );
    final rootsFound = roots(difference, xMin, xMax, context, scope: scope);
    final rows = rootsFound
        .map((x) {
          final y = _safeEvaluateDouble(left, x, context, scope: scope) ?? double.nan;
          return <CalculatorValue>[DoubleValue(x), DoubleValue(y)];
        })
        .toList(growable: false);
    if (rows.isEmpty) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.noRootFound,
          message: 'Belirtilen aralikta kesisim bulunamadi.',
          suggestion: 'Daha genis veya daha uygun bir aralik deneyin.',
        ),
      );
    }
    final value = MatrixValue(rows);
    return GraphIntersectionResult(
      value: value,
      metadata: GraphResultMetadata(
        intersectionDisplayResult:
            'intersection points: ${rows.length} within [$xMin, $xMax]',
        rootDisplayResult: 'x = ${rootsFound.join(', ')}',
      ),
    );
  }

  double slope(
    FunctionExpression function,
    double x,
    CalculationContext context,
    {EvaluationScope? scope}
  ) {
    final h = math.max(1e-5, x.abs() * 1e-5);
    final left = _safeEvaluateDouble(function, x - h, context, scope: scope);
    final right = _safeEvaluateDouble(function, x + h, context, scope: scope);
    if (left == null || right == null) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidGraphOperation,
          message: 'Bu noktada turev yaklasimi hesaplanamadi.',
          suggestion: 'Fonksiyonun tanimli oldugu baska bir x degeri deneyin.',
        ),
      );
    }
    return (right - left) / (2 * h);
  }

  double area(
    FunctionExpression function,
    double xMin,
    double xMax,
    CalculationContext context,
    {EvaluationScope? scope}
  ) {
    final intervalCount = maxIntegrationSubintervals;
    final step = (xMax - xMin) / intervalCount;
    var total = 0.0;
    for (var i = 0; i <= intervalCount; i++) {
      final x = xMin + i * step;
      final y = _safeEvaluateDouble(function, x, context, scope: scope);
      if (y == null) {
        throw const CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidGraphOperation,
            message: 'Integral araliginda tanimsiz nokta bulundu.',
            suggestion: 'Fonksiyonun surekli oldugu bir aralik deneyin.',
          ),
        );
      }
      final weight = (i == 0 || i == intervalCount) ? 0.5 : 1.0;
      total += weight * y;
    }
    return total * step;
  }

  void _addDistinctRoot(List<double> roots, double candidate) {
    if (roots.any((existing) => (existing - candidate).abs() < 1e-6)) {
      return;
    }
    roots.add(candidate);
  }

  double _bisection(
    FunctionExpression function,
    double left,
    double right,
    CalculationContext context,
    {EvaluationScope? scope}
  ) {
    var a = left;
    var b = right;
    var fa = _safeEvaluateDouble(function, a, context, scope: scope) ?? 0.0;
    for (var iteration = 0; iteration < maxBisectionIterations; iteration++) {
      final mid = (a + b) / 2;
      final fm = _safeEvaluateDouble(function, mid, context, scope: scope);
      if (fm == null) {
        break;
      }
      if (fm.abs() < 1e-12 || (b - a).abs() < 1e-8) {
        return mid;
      }
      if (fa.sign == fm.sign) {
        a = mid;
        fa = fm;
      } else {
        b = mid;
      }
    }
    return (a + b) / 2;
  }

  double? _safeEvaluateDouble(
    FunctionExpression function,
    double x,
    CalculationContext context,
    {EvaluationScope? scope}
  ) {
    try {
      final value = evalAt(function, DoubleValue(x), context, scope: scope);
      return value.toDouble();
    } on CalculatorException {
      return null;
    }
  }

  String _inline(CalculatorValue value) {
    if (value is DoubleValue) {
      final numeric = value.value;
      if (numeric == numeric.roundToDouble()) {
        return numeric.toInt().toString();
      }
      return numeric.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return value.toDouble().toString();
  }
}
