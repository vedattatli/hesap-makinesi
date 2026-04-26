import 'dart:math' as math;

import '../calculation_context.dart';
import '../calculation_error.dart';
import '../scope/evaluation_scope.dart';
import '../src/calculator_exception.dart';
import '../src/expression_evaluator.dart';
import '../src/expression_printer.dart';
import '../values/calculator_value.dart';
import '../values/double_value.dart';
import '../values/unit_value.dart';
import 'function_expression.dart';
import 'graph_sampling_options.dart';
import 'graph_viewport.dart';
import 'plot_point.dart';
import 'plot_segment.dart';
import 'plot_series.dart';
import 'plot_value.dart';

/// Pure Dart graph engine responsible for sampling and discontinuity detection.
class GraphEngine {
  const GraphEngine();

  PlotValue plotFunction(
    FunctionExpression function,
    GraphViewport viewport,
    CalculationContext context, {
    GraphSamplingOptions options = const GraphSamplingOptions(),
    EvaluationScope? scope,
  }) {
    return plotFunctions(
      <FunctionExpression>[function],
      viewport,
      context,
      options: options,
      scope: scope,
    );
  }

  PlotValue plotFunctions(
    List<FunctionExpression> functions,
    GraphViewport viewport,
    CalculationContext context, {
    GraphSamplingOptions options = const GraphSamplingOptions(),
    EvaluationScope? scope,
  }) {
    _validateSamplingBudget(functions.length, options);
    if (functions.isEmpty) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidFunctionExpression,
          message: 'Cizmek icin en az bir fonksiyon gerekli.',
        ),
      );
    }

    final warnings = <String>[];
    final provisionalViewport = viewport.autoY
        ? viewport.copyWith(autoY: true)
        : viewport;
    final series = functions
        .map(
          (function) => _sampleSeries(
            function,
            provisionalViewport,
            context,
            options,
            scope,
          ),
        )
        .toList(growable: false);
    warnings.addAll(series.expand((item) => item.warnings));

    final effectiveViewport = viewport.autoY
        ? _autoYViewport(series, viewport)
        : viewport;

    return PlotValue(
      viewport: effectiveViewport,
      series: series,
      autoYUsed: viewport.autoY,
      warnings: warnings,
    );
  }

  PlotSeries _sampleSeries(
    FunctionExpression function,
    GraphViewport viewport,
    CalculationContext context,
    GraphSamplingOptions options,
    EvaluationScope? scope,
  ) {
    final printer = ExpressionPrinter();
    final points = <PlotPoint>[];
    final warnings = <String>[];
    final initialSamples = options.initialSamples;
    final step = viewport.width / (initialSamples - 1);
    var errorCount = 0;

    PlotPoint evaluatePoint(double x) {
      try {
        final evaluator = ExpressionEvaluator(
          context,
          scope: (scope ?? const EvaluationScope()).withVariable(
            function.variableName,
            DoubleValue(x),
          ),
        );
        final value = evaluator.evaluate(function.expressionAst).value;
        final numeric = _extractGraphScalar(
          value,
          position: function.expressionAst.position,
        );
        if (!numeric.isFinite) {
          return PlotPoint(
            x: x,
            y: double.nan,
            isDefined: false,
            errorReason: 'non-finite',
          );
        }
        return PlotPoint(x: x, y: numeric, isDefined: true);
      } on CalculatorException catch (error) {
        if (_isHardGraphFailure(error.error.type)) {
          rethrow;
        }
        errorCount++;
        return PlotPoint(
          x: x,
          y: double.nan,
          isDefined: false,
          errorReason: error.error.message,
        );
      }
    }

    for (var index = 0; index < initialSamples; index++) {
      final x = viewport.xMin + step * index;
      points.add(evaluatePoint(x));
      if (errorCount > options.maxEvaluationErrors) {
        throw const CalculatorException(
          CalculationError(
            type: CalculationErrorType.graphSamplingLimit,
            message:
                'Cok fazla tanimsiz nokta uretildigi icin cizim durduruldu.',
          ),
        );
      }
    }

    final refined = options.enableAdaptiveSampling
        ? _refinePoints(points, evaluatePoint, viewport, options, depth: 0)
        : points;
    final segments = _buildSegments(refined, viewport, options);
    if (segments.length > 1) {
      warnings.add('Discontinuity detected; segments were split.');
    }
    final definedCount = refined.where((point) => point.isDefined).length;
    return PlotSeries(
      expression: function.originalExpression,
      normalizedExpression: printer.print(function.expressionAst),
      label: 'y = ${function.normalizedExpression}',
      segments: segments,
      sampleCount: refined.length,
      definedPointCount: definedCount,
      undefinedPointCount: refined.length - definedCount,
      warnings: warnings,
    );
  }

  List<PlotPoint> _refinePoints(
    List<PlotPoint> points,
    PlotPoint Function(double x) evaluatePoint,
    GraphViewport viewport,
    GraphSamplingOptions options, {
    required int depth,
  }) {
    if (depth >= options.adaptiveDepth || points.length >= options.maxSamples) {
      return points;
    }

    final refined = <PlotPoint>[];
    for (var index = 0; index < points.length - 1; index++) {
      final left = points[index];
      final right = points[index + 1];
      refined.add(left);
      final intervalWidth = right.x - left.x;
      if (intervalWidth <= options.minStep) {
        continue;
      }
      if (!_shouldRefine(left, right, viewport, options)) {
        continue;
      }
      if (refined.length >= options.maxSamples) {
        break;
      }
      final midX = (left.x + right.x) / 2;
      refined.add(evaluatePoint(midX));
    }
    refined.add(points.last);
    if (refined.length == points.length) {
      return points;
    }
    return _refinePoints(
      refined,
      evaluatePoint,
      viewport,
      options,
      depth: depth + 1,
    );
  }

  bool _shouldRefine(
    PlotPoint left,
    PlotPoint right,
    GraphViewport viewport,
    GraphSamplingOptions options,
  ) {
    if (!left.isDefined && !right.isDefined) {
      return false;
    }
    if (!left.isDefined || !right.isDefined) {
      return true;
    }
    final span = math.max(viewport.height.abs(), 1.0);
    final delta = (right.y - left.y).abs();
    return delta > span / 4;
  }

  List<PlotSegment> _buildSegments(
    List<PlotPoint> points,
    GraphViewport viewport,
    GraphSamplingOptions options,
  ) {
    final segments = <PlotSegment>[];
    final current = <PlotPoint>[];
    final span = math.max(viewport.height.abs(), 1.0);

    void flush() {
      if (current.length >= 2) {
        segments.add(
          PlotSegment(List<PlotPoint>.unmodifiable(current.toList())),
        );
      }
      current.clear();
    }

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (!point.isDefined) {
        flush();
        continue;
      }
      if (current.isNotEmpty && options.enableDiscontinuityDetection) {
        final previous = current.last;
        final yJump = (point.y - previous.y).abs();
        if (yJump > options.discontinuityThreshold * span) {
          flush();
        }
      }
      current.add(point);
    }
    flush();
    return List<PlotSegment>.unmodifiable(segments);
  }

  GraphViewport _autoYViewport(
    List<PlotSeries> series,
    GraphViewport original,
  ) {
    final values = series
        .expand((item) => item.segments)
        .expand((segment) => segment.points)
        .map((point) => point.y)
        .where((value) => value.isFinite && value.abs() <= 1000)
        .toList(growable: false);
    if (values.isEmpty) {
      return original.copyWith(autoY: true);
    }
    var yMin = values.reduce(math.min);
    var yMax = values.reduce(math.max);
    if ((yMax - yMin).abs() < 1e-9) {
      yMin -= 1;
      yMax += 1;
    } else {
      final padding = (yMax - yMin) * 0.1;
      yMin -= padding;
      yMax += padding;
    }
    return GraphViewport(
      xMin: original.xMin,
      xMax: original.xMax,
      yMin: yMin,
      yMax: yMax,
      autoY: true,
    );
  }

  void _validateSamplingBudget(int seriesCount, GraphSamplingOptions options) {
    if (seriesCount > GraphSamplingOptions.hardMaxSeries) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.graphSamplingLimit,
          message: 'Graph series count exceeds the safe rendering limit.',
        ),
      );
    }
    if (options.initialSamples < 8 ||
        options.initialSamples > GraphSamplingOptions.hardMaxInitialSamples ||
        options.maxSamples < options.initialSamples ||
        options.maxSamples > GraphSamplingOptions.hardMaxSamples ||
        options.adaptiveDepth < 0 ||
        options.minStep <= 0 ||
        options.discontinuityThreshold <= 0 ||
        options.maxEvaluationErrors < 0) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.graphSamplingLimit,
          message:
              'Graph sampling options are outside the safe runtime limits.',
        ),
      );
    }
    if (seriesCount * options.maxSamples >
        GraphSamplingOptions.hardMaxTotalPoints) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.graphSamplingLimit,
          message: 'Graph point budget exceeds the safe runtime limit.',
        ),
      );
    }
  }

  double _extractGraphScalar(CalculatorValue value, {required int position}) {
    if (value is UnitValue) {
      if (!value.isDimensionless) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.unsupportedGraphValue,
            message:
                'Birimli sonuc dogrudan cizilemez. Once dimensionless bir ifadeye donusturun.',
            position: position,
          ),
        );
      }
      return value.baseMagnitude.toDouble();
    }

    switch (value.kind) {
      case CalculatorValueKind.doubleValue:
      case CalculatorValueKind.rational:
      case CalculatorValueKind.symbolic:
        return value.toDouble();
      default:
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.unsupportedGraphValue,
            message:
                'Grafik yalnizca scalar gercek sayi ureten ifadeleri cizebilir.',
            position: position,
            suggestion:
                'Complex/unit/vector/matrix sonucu scalar hale getirin.',
          ),
        );
    }
  }

  bool _isHardGraphFailure(CalculationErrorType type) {
    switch (type) {
      case CalculationErrorType.unsupportedGraphValue:
      case CalculationErrorType.invalidFunctionExpression:
      case CalculationErrorType.invalidGraphOperation:
      case CalculationErrorType.undefinedVariable:
      case CalculationErrorType.invalidViewport:
      case CalculationErrorType.invalidPlotRange:
      case CalculationErrorType.graphSamplingLimit:
        return true;
      default:
        return false;
    }
  }
}
