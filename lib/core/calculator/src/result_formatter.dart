import 'dart:math' as math;

import '../angle_mode.dart';
import '../calculation_context.dart';
import '../graph/graph_result_metadata.dart';
import '../graph/plot_value.dart';
import '../numeric_mode.dart';
import '../values/calculator_value.dart';
import '../values/complex_value.dart';
import '../values/dataset_value.dart';
import '../values/double_value.dart';
import '../values/equation_value.dart';
import '../values/expression_transform_value.dart';
import '../values/function_value.dart';
import '../values/linear_algebra.dart';
import '../values/matrix_value.dart';
import '../values/rational_value.dart';
import '../values/regression_value.dart';
import '../values/scalar_value_math.dart';
import '../values/solve_result_value.dart';
import '../values/symbolic_value.dart';
import '../values/system_solve_result_value.dart';
import '../values/unit_value.dart';
import '../values/vector_value.dart';
import '../units/unit_registry.dart';

class ResultFormatter {
  FormattedCalculationValue format(
    CalculatorValue value,
    CalculationContext context, {
    String? statisticName,
    int? sampleSize,
    GraphResultMetadata? graphMetadata,
  }) {
    final formatted = switch (value) {
      EquationValue() => _formatEquation(value, context),
      SystemSolveResultValue() => _formatSystemSolveResult(value, context),
      SolveResultValue() => _formatSolveResult(value, context),
      ExpressionTransformValue() => _formatExpressionTransform(value, context),
      FunctionValue() => _formatFunction(value, context),
      PlotValue() => _formatPlot(value, context),
      DatasetValue() => _formatDataset(value, context),
      RegressionValue() => _formatRegression(value, context),
      MatrixValue() => _formatMatrix(value, context),
      VectorValue() => _formatVector(value, context),
      ComplexValue() => _formatComplex(value, context),
      UnitValue() => _formatUnit(value, context),
      RationalValue() => _formatRational(value, context),
      SymbolicValue() => _formatSymbolic(value, context),
      DoubleValue() => _formatDouble(value, context),
      _ => _formatDouble(DoubleValue(value.toDouble()), context),
    };
    return _attachGraphMetadata(
      _attachStatisticsMetadata(
        formatted,
        value,
        statisticName: statisticName,
        sampleSize: sampleSize,
      ),
      graphMetadata,
    );
  }

  FormattedCalculationValue _formatEquation(
    EquationValue value,
    CalculationContext context,
  ) {
    final display = value.displayEquation;
    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: display,
      symbolicDisplayResult: display,
      equationDisplayResult: display,
      summaryDisplayResult: display,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: false,
    );
  }

  FormattedCalculationValue _formatSolveResult(
    SolveResultValue value,
    CalculationContext context,
  ) {
    String display;
    String solutionsDisplay;
    if (value.infiniteSolutions) {
      display = 'Infinite solutions';
      solutionsDisplay = 'All real numbers';
    } else if (value.solutions.isEmpty) {
      display = 'No solution';
      solutionsDisplay = value.noSolutionReason ?? 'No solution';
    } else if (value.solutions.length == 1) {
      final solutionText = _formatInlineValue(
        value.solutions.single,
        context,
        exactMode: value.isExact,
      );
      display = '${value.variableName} = $solutionText';
      solutionsDisplay = solutionText;
    } else {
      final entries = value.solutions
          .map(
            (solution) =>
                _formatInlineValue(solution, context, exactMode: value.isExact),
          )
          .join(', ');
      display = '${value.variableName} = {$entries}';
      solutionsDisplay = '{$entries}';
    }

    final summary = '${value.method.name} | ${value.domain.name}';
    final alternativeResults = <String, String>{
      'equation': value.equation.displayEquation,
      'method': value.method.name,
      'domain': value.domain.name,
    };

    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: value.isExact ? display : null,
      decimalDisplayResult: value.isExact ? null : display,
      solveDisplayResult: display,
      equationDisplayResult: value.equation.displayEquation,
      solutionsDisplayResult: solutionsDisplay,
      summaryDisplayResult: summary,
      solutionCount: value.infiniteSolutions ? null : value.solutions.length,
      solveVariable: value.variableName,
      solveMethod: value.method.name,
      solveDomain: value.domain.name,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: value.isApproximate,
    );
  }

  FormattedCalculationValue _formatSystemSolveResult(
    SystemSolveResultValue value,
    CalculationContext context,
  ) {
    final assignments = <String>[];
    for (var index = 0; index < value.variables.length; index++) {
      assignments.add(
        '${value.variables[index]} = ${_formatInlineValue(value.solutions[index], context, exactMode: value.isExact)}',
      );
    }
    final display = assignments.join(', ');
    final alternativeResults = <String, String>{'method': value.method};
    if (value.steps.isNotEmpty) {
      alternativeResults['steps'] = value.steps
          .map((step) => step.display)
          .join('\n');
    }
    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: value.isExact ? display : null,
      decimalDisplayResult: value.isExact ? null : display,
      solveDisplayResult: display,
      solutionsDisplayResult: display,
      summaryDisplayResult: value.method,
      solutionCount: value.solutions.length,
      solveMethod: value.method,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: value.isApproximate,
    );
  }

  FormattedCalculationValue _formatExpressionTransform(
    ExpressionTransformValue value,
    CalculationContext context,
  ) {
    final display = value.normalizedExpression;
    final alternativeResults = <String, String>{
      'input': value.originalExpression,
    };
    if (value.steps.isNotEmpty) {
      alternativeResults['steps'] = value.steps
          .map((step) => step.display)
          .join('\n');
    }
    if (value.unsupportedReason != null) {
      alternativeResults['unsupportedReason'] = value.unsupportedReason!;
    }
    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: display,
      symbolicDisplayResult: display,
      derivativeDisplayResult:
          value.kindLabel == ExpressionTransformKind.derivative
          ? display
          : null,
      integralDisplayResult: value.kindLabel == ExpressionTransformKind.integral
          ? display
          : null,
      transformDisplayResult: display,
      summaryDisplayResult: value.kindLabel.name,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: false,
    );
  }

  FormattedCalculationValue _formatFunction(
    FunctionValue value,
    CalculationContext context,
  ) {
    final display = 'f(${value.variableName}) = ${value.normalizedExpression}';
    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: display,
      symbolicDisplayResult: display,
      functionDisplayResult: display,
      graphDisplayResult: display,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: false,
    );
  }

  FormattedCalculationValue _formatPlot(
    PlotValue value,
    CalculationContext context,
  ) {
    final seriesSummary = value.series.length == 1
        ? value.series.single.label
        : '${value.series.length} series';
    final display = 'Plot: $seriesSummary';
    final summary =
        '${value.seriesCount} series, ${value.pointCount} points, ${value.segmentCount} segments';
    return FormattedCalculationValue(
      displayResult: display,
      plotDisplayResult: display,
      graphDisplayResult: summary,
      summaryDisplayResult: summary,
      viewportDisplayResult: value.viewport.toDisplayString(),
      plotSeriesCount: value.seriesCount,
      plotPointCount: value.pointCount,
      plotSegmentCount: value.segmentCount,
      alternativeResults: <String, String>{
        'viewport': value.viewport.toDisplayString(),
      },
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: true,
    );
  }

  FormattedCalculationValue _formatDataset(
    DatasetValue value,
    CalculationContext context,
  ) {
    final exactDisplay = _formatDatasetEntries(
      value.values,
      context,
      exactMode: true,
    );
    final decimalDisplay = _formatDatasetEntries(
      value.values,
      context,
      exactMode: false,
    );
    final fullDisplay = switch (context.numberFormatStyle) {
      NumberFormatStyle.decimal ||
      NumberFormatStyle.scientific => decimalDisplay,
      _ => exactDisplay,
    };
    final preview = _previewDataset(
      fullDisplay,
      value,
      context,
      exactMode:
          context.numberFormatStyle != NumberFormatStyle.decimal &&
          context.numberFormatStyle != NumberFormatStyle.scientific,
    );
    final alternativeResults = <String, String>{};
    if (exactDisplay != fullDisplay) {
      alternativeResults['symbolic'] = exactDisplay;
    }
    if (decimalDisplay != fullDisplay) {
      alternativeResults['decimal'] = decimalDisplay;
    }
    if (preview != fullDisplay) {
      alternativeResults['full'] = fullDisplay;
    }

    return FormattedCalculationValue(
      displayResult: preview,
      exactDisplayResult: exactDisplay,
      decimalDisplayResult: decimalDisplay,
      datasetDisplayResult: exactDisplay,
      summaryDisplayResult: 'n = ${value.length}',
      sampleSize: value.length,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: value.isApproximate,
    );
  }

  FormattedCalculationValue _formatRegression(
    RegressionValue value,
    CalculationContext context,
  ) {
    final exactEquation = _formatRegressionEquation(
      value,
      context,
      exactMode: true,
    );
    final decimalEquation = _formatRegressionEquation(
      value,
      context,
      exactMode: false,
    );
    final display = switch (context.numberFormatStyle) {
      NumberFormatStyle.decimal ||
      NumberFormatStyle.scientific => decimalEquation,
      _ => exactEquation,
    };
    final rDisplay = _formatInlineValue(value.r, context, exactMode: true);
    final rSquaredDisplay = _formatInlineValue(
      value.rSquared,
      context,
      exactMode: true,
    );
    final slopeDisplay = _formatInlineValue(
      value.slope,
      context,
      exactMode: true,
    );
    final interceptDisplay = _formatInlineValue(
      value.intercept,
      context,
      exactMode: true,
    );
    final alternativeResults = <String, String>{
      'slope': slopeDisplay,
      'intercept': interceptDisplay,
      'r': rDisplay,
      'rSquared': rSquaredDisplay,
      'n': value.sampleSize.toString(),
    };
    if (exactEquation != display) {
      alternativeResults['symbolic'] = exactEquation;
    }
    if (decimalEquation != display) {
      alternativeResults['decimal'] = decimalEquation;
    }

    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: exactEquation,
      decimalDisplayResult: decimalEquation,
      regressionDisplayResult: exactEquation,
      summaryDisplayResult:
          'r = $rDisplay, R² = $rSquaredDisplay, n = ${value.sampleSize}',
      sampleSize: value.sampleSize,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: value.isApproximate,
    );
  }

  FormattedCalculationValue _attachStatisticsMetadata(
    FormattedCalculationValue base,
    CalculatorValue value, {
    String? statisticName,
    int? sampleSize,
  }) {
    final effectiveSampleSize = sampleSize ?? base.sampleSize;
    final isProbability =
        statisticName != null && _isProbabilityStatistic(statisticName);
    final statisticsDisplay = value is DatasetValue || value is RegressionValue
        ? base.statisticsDisplayResult
        : statisticName == null || isProbability
        ? base.statisticsDisplayResult
        : _buildStatisticSummary(statisticName, effectiveSampleSize);
    final probabilityDisplay = isProbability
        ? _buildStatisticSummary(statisticName, effectiveSampleSize)
        : base.probabilityDisplayResult;

    return base.copyWith(
      statisticName: statisticName ?? base.statisticName,
      sampleSize: effectiveSampleSize,
      statisticsDisplayResult: statisticsDisplay,
      probabilityDisplayResult: probabilityDisplay,
      summaryDisplayResult:
          base.summaryDisplayResult ?? probabilityDisplay ?? statisticsDisplay,
    );
  }

  FormattedCalculationValue _attachGraphMetadata(
    FormattedCalculationValue base,
    GraphResultMetadata? metadata,
  ) {
    if (metadata == null) {
      return base;
    }

    final alternativeResults = <String, String>{...base.alternativeResults};
    if (metadata.viewportDisplayResult != null) {
      alternativeResults['viewport'] = metadata.viewportDisplayResult!;
    }
    if (metadata.traceDisplayResult != null) {
      alternativeResults['trace'] = metadata.traceDisplayResult!;
    }
    if (metadata.rootDisplayResult != null) {
      alternativeResults['roots'] = metadata.rootDisplayResult!;
    }
    if (metadata.intersectionDisplayResult != null) {
      alternativeResults['intersections'] = metadata.intersectionDisplayResult!;
    }

    return base.copyWith(
      functionDisplayResult:
          metadata.functionDisplayResult ?? base.functionDisplayResult,
      plotDisplayResult: metadata.plotDisplayResult ?? base.plotDisplayResult,
      graphDisplayResult:
          metadata.graphDisplayResult ?? base.graphDisplayResult,
      traceDisplayResult:
          metadata.traceDisplayResult ?? base.traceDisplayResult,
      rootDisplayResult: metadata.rootDisplayResult ?? base.rootDisplayResult,
      intersectionDisplayResult:
          metadata.intersectionDisplayResult ?? base.intersectionDisplayResult,
      plotSeriesCount: metadata.plotSeriesCount ?? base.plotSeriesCount,
      plotPointCount: metadata.plotPointCount ?? base.plotPointCount,
      plotSegmentCount: metadata.plotSegmentCount ?? base.plotSegmentCount,
      viewportDisplayResult:
          metadata.viewportDisplayResult ?? base.viewportDisplayResult,
      alternativeResults: alternativeResults,
      summaryDisplayResult:
          base.summaryDisplayResult ?? metadata.graphDisplayResult,
    );
  }

  String _buildStatisticSummary(String statisticName, int? sampleSize) {
    final label = _prettyStatisticName(statisticName);
    if (sampleSize == null) {
      return label;
    }
    return '$label · n = $sampleSize';
  }

  bool _isProbabilityStatistic(String statisticName) {
    switch (statisticName) {
      case 'binomPmf':
      case 'binomCdf':
      case 'poissonPmf':
      case 'poissonCdf':
      case 'geomPmf':
      case 'geomCdf':
      case 'normalPdf':
      case 'normalCdf':
      case 'uniformPdf':
      case 'uniformCdf':
      case 'zscore':
        return true;
      default:
        return false;
    }
  }

  String _prettyStatisticName(String statisticName) {
    return switch (statisticName) {
      'data' => 'Dataset',
      'count' => 'Count',
      'sum' => 'Sum',
      'product' => 'Product',
      'mean' => 'Mean',
      'median' => 'Median',
      'mode' => 'Mode',
      'range' => 'Range',
      'varp' => 'Population Variance',
      'vars' => 'Sample Variance',
      'stdp' => 'Population Std Dev',
      'stds' => 'Sample Std Dev',
      'mad' => 'Mean Abs Deviation',
      'quantile' => 'Quantile',
      'percentile' => 'Percentile',
      'quartiles' => 'Quartiles',
      'iqr' => 'Interquartile Range',
      'wmean' => 'Weighted Mean',
      'factorial' => 'Factorial',
      'nCr' => 'Combination',
      'nPr' => 'Permutation',
      'binomPmf' => 'Binomial PMF',
      'binomCdf' => 'Binomial CDF',
      'poissonPmf' => 'Poisson PMF',
      'poissonCdf' => 'Poisson CDF',
      'geomPmf' => 'Geometric PMF',
      'geomCdf' => 'Geometric CDF',
      'normalPdf' => 'Normal PDF',
      'normalCdf' => 'Normal CDF',
      'uniformPdf' => 'Uniform PDF',
      'uniformCdf' => 'Uniform CDF',
      'zscore' => 'Z-Score',
      'covp' => 'Population Covariance',
      'covs' => 'Sample Covariance',
      'corr' => 'Correlation',
      'linreg' => 'Linear Regression',
      'linpred' => 'Regression Prediction',
      _ => statisticName,
    };
  }

  FormattedCalculationValue _formatRational(
    RationalValue value,
    CalculationContext context,
  ) {
    final fraction = value.toFractionString();
    final decimal = value.toDecimalString(context.precision);
    final scientific = _formatScientificDouble(
      _normalizeNoise(value.toDouble(), context.precision),
      context.precision,
    );

    final display = switch (context.numberFormatStyle) {
      NumberFormatStyle.decimal => decimal,
      NumberFormatStyle.fraction ||
      NumberFormatStyle.auto ||
      NumberFormatStyle.symbolic => fraction,
      NumberFormatStyle.scientific => scientific,
    };

    final alternativeResults = <String, String>{};
    if (fraction != display) {
      alternativeResults['fraction'] = fraction;
    }
    if (decimal != display) {
      alternativeResults['decimal'] = decimal;
    }

    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: fraction,
      symbolicDisplayResult: fraction,
      decimalDisplayResult: decimal,
      fractionDisplayResult: fraction,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: false,
    );
  }

  FormattedCalculationValue _formatSymbolic(
    SymbolicValue value,
    CalculationContext context,
  ) {
    final symbolic = value.toSymbolicString();
    final normalizedValue = _normalizeNoise(
      value.toDouble(),
      context.precision,
    );
    final decimal = _formatDecimalDouble(normalizedValue, context.precision);
    final scientific = _formatScientificDouble(
      normalizedValue,
      context.precision,
    );

    final display = switch (context.numberFormatStyle) {
      NumberFormatStyle.decimal => decimal,
      NumberFormatStyle.symbolic ||
      NumberFormatStyle.fraction ||
      NumberFormatStyle.auto => symbolic,
      NumberFormatStyle.scientific => scientific,
    };

    final alternativeResults = <String, String>{};
    if (symbolic != display) {
      alternativeResults['symbolic'] = symbolic;
    }
    if (decimal != display) {
      alternativeResults['decimal'] = decimal;
    }

    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: symbolic,
      symbolicDisplayResult: symbolic,
      decimalDisplayResult: decimal,
      fractionDisplayResult: null,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: false,
    );
  }

  FormattedCalculationValue _formatDouble(
    DoubleValue value,
    CalculationContext context,
  ) {
    final normalizedValue = _normalizeNoise(
      value.toDouble(),
      context.precision,
    );
    final decimal = _formatDecimalDouble(normalizedValue, context.precision);
    final display = switch (context.numberFormatStyle) {
      NumberFormatStyle.decimal ||
      NumberFormatStyle.fraction ||
      NumberFormatStyle.symbolic => decimal,
      NumberFormatStyle.scientific => _formatScientificDouble(
        normalizedValue,
        context.precision,
      ),
      NumberFormatStyle.auto => _formatAutoDouble(
        normalizedValue,
        context.precision,
      ),
    };

    final alternativeResults = <String, String>{};
    if (decimal != display) {
      alternativeResults['decimal'] = decimal;
    }

    return FormattedCalculationValue(
      displayResult: display,
      decimalDisplayResult: decimal,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: true,
    );
  }

  FormattedCalculationValue _formatComplex(
    ComplexValue value,
    CalculationContext context,
  ) {
    final exactRectangular = _formatComplexRectangular(
      value,
      context,
      exactMode: true,
    );
    final decimalRectangular = _formatComplexRectangular(
      value,
      context,
      exactMode: false,
    );
    final polar = _formatComplexPolar(value, context);
    final magnitude = _formatScalarDecimal(value.magnitude(), context);
    final argument = _formatAngleDecimal(
      value.argument(context.angleMode),
      context,
    );

    final display = switch (context.numberFormatStyle) {
      NumberFormatStyle.decimal ||
      NumberFormatStyle.scientific => decimalRectangular,
      NumberFormatStyle.auto ||
      NumberFormatStyle.fraction ||
      NumberFormatStyle.symbolic => exactRectangular,
    };

    final alternativeResults = <String, String>{};
    if (exactRectangular != display) {
      alternativeResults['symbolic'] = exactRectangular;
    }
    if (decimalRectangular != display) {
      alternativeResults['decimal'] = decimalRectangular;
    }
    alternativeResults['polar'] = polar;
    alternativeResults['magnitude'] = magnitude;
    alternativeResults['argument'] = argument;

    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: exactRectangular,
      symbolicDisplayResult: exactRectangular,
      decimalDisplayResult: decimalRectangular,
      fractionDisplayResult: exactRectangular,
      complexDisplayResult: exactRectangular,
      rectangularDisplayResult: exactRectangular,
      polarDisplayResult: polar,
      magnitudeDisplayResult: magnitude,
      argumentDisplayResult: argument,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: value.isApproximate,
    );
  }

  FormattedCalculationValue _formatUnit(
    UnitValue value,
    CalculationContext context,
  ) {
    final unitText = value.displayUnit.toDisplayString();
    final exactMagnitude = value.isUnitExpressionOnly
        ? null
        : _formatScalarExact(value.displayMagnitude, context);
    final decimalMagnitude = value.isUnitExpressionOnly
        ? null
        : _formatScalarDecimal(value.displayMagnitude, context);
    final exactDisplay = value.isUnitExpressionOnly
        ? unitText
        : '${exactMagnitude!} $unitText';
    final decimalDisplay = value.isUnitExpressionOnly
        ? unitText
        : '${decimalMagnitude!} $unitText';
    final display = switch (context.numberFormatStyle) {
      NumberFormatStyle.decimal ||
      NumberFormatStyle.scientific => decimalDisplay,
      _ => exactDisplay,
    };

    String? baseDisplay;
    if (!value.isDimensionless && !value.isUnitExpressionOnly) {
      final baseUnit = UnitRegistry.instance.baseExpressionForDimension(
        value.dimension,
      );
      final baseMagnitude = _formatScalarExact(value.baseMagnitude, context);
      baseDisplay = '$baseMagnitude ${baseUnit.toDisplayString()}';
    }

    final alternativeResults = <String, String>{};
    if (exactDisplay != display) {
      alternativeResults['exact'] = exactDisplay;
    }
    if (decimalDisplay != display) {
      alternativeResults['decimal'] = decimalDisplay;
    }
    if (baseDisplay != null && baseDisplay != display) {
      alternativeResults['base'] = baseDisplay;
    }

    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: exactDisplay,
      symbolicDisplayResult: exactDisplay,
      decimalDisplayResult: decimalDisplay,
      unitDisplayResult: exactDisplay,
      baseUnitDisplayResult: baseDisplay,
      dimensionDisplayResult: value.dimension.toDisplayString(),
      conversionDisplayResult: display,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: value.isApproximate,
    );
  }

  FormattedCalculationValue _formatVector(
    VectorValue value,
    CalculationContext context,
  ) {
    final exactDisplay = _formatVectorEntries(
      value.elements,
      context,
      exactMode: true,
    );
    final decimalDisplay = _formatVectorEntries(
      value.elements,
      context,
      exactMode: false,
    );
    final display = switch (context.numberFormatStyle) {
      NumberFormatStyle.decimal ||
      NumberFormatStyle.scientific => decimalDisplay,
      _ => exactDisplay,
    };

    final alternativeResults = <String, String>{};
    if (decimalDisplay != display) {
      alternativeResults['decimal'] = decimalDisplay;
    }
    if (exactDisplay != display) {
      alternativeResults['symbolic'] = exactDisplay;
    }

    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: exactDisplay,
      symbolicDisplayResult: exactDisplay,
      decimalDisplayResult: decimalDisplay,
      vectorDisplayResult: exactDisplay,
      shapeDisplayResult: '${value.length} \u00D7 1',
      rowCount: value.length,
      columnCount: 1,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: value.isApproximate,
    );
  }

  FormattedCalculationValue _formatMatrix(
    MatrixValue value,
    CalculationContext context,
  ) {
    final exactDisplay = _formatMatrixRows(
      value.rows,
      context,
      exactMode: true,
    );
    final decimalDisplay = _formatMatrixRows(
      value.rows,
      context,
      exactMode: false,
    );
    final displaySource = switch (context.numberFormatStyle) {
      NumberFormatStyle.decimal ||
      NumberFormatStyle.scientific => decimalDisplay,
      _ => exactDisplay,
    };
    final display = _previewMatrix(
      displaySource,
      value,
      context,
      exactMode:
          context.numberFormatStyle != NumberFormatStyle.decimal &&
          context.numberFormatStyle != NumberFormatStyle.scientific,
    );

    final alternativeResults = <String, String>{};
    if (decimalDisplay != displaySource) {
      alternativeResults['decimal'] = decimalDisplay;
    }
    if (exactDisplay != displaySource) {
      alternativeResults['symbolic'] = exactDisplay;
    }
    if (display != displaySource) {
      alternativeResults['full'] = displaySource;
    }

    return FormattedCalculationValue(
      displayResult: display,
      exactDisplayResult: exactDisplay,
      symbolicDisplayResult: exactDisplay,
      decimalDisplayResult: decimalDisplay,
      matrixDisplayResult: exactDisplay,
      shapeDisplayResult: '${value.rowCount} \u00D7 ${value.columnCount}',
      rowCount: value.rowCount,
      columnCount: value.columnCount,
      alternativeResults: alternativeResults,
      valueKind: value.kind,
      numericMode: context.numericMode,
      resultFormat: context.numberFormatStyle,
      isApproximate: value.isApproximate,
    );
  }

  String _formatComplexRectangular(
    ComplexValue value,
    CalculationContext context, {
    required bool exactMode,
  }) {
    final realZero = ScalarValueMath.isZero(value.realPart);
    final imagZero = ScalarValueMath.isZero(value.imaginaryPart);

    final realText = exactMode
        ? _formatScalarExact(value.realPart, context)
        : _formatScalarDecimal(value.realPart, context);
    final imagNegative = _isNegativeScalar(value.imaginaryPart);
    final imagAbs = _absoluteScalar(value.imaginaryPart);
    final imagText = exactMode
        ? _formatImaginaryExact(imagAbs, context)
        : _formatImaginaryDecimal(imagAbs, context);

    if (realZero && imagZero) {
      return '0';
    }
    if (imagZero) {
      return realText;
    }
    if (realZero) {
      return imagNegative ? '-$imagText' : imagText;
    }
    final separator = imagNegative ? ' - ' : ' + ';
    return '$realText$separator$imagText';
  }

  String _formatVectorEntries(
    List<CalculatorValue> elements,
    CalculationContext context, {
    required bool exactMode,
  }) {
    final entries = elements
        .map(
          (entry) => _formatInlineValue(entry, context, exactMode: exactMode),
        )
        .join(', ');
    return '[$entries]';
  }

  String _formatDatasetEntries(
    List<CalculatorValue> values,
    CalculationContext context, {
    required bool exactMode,
  }) {
    final entries = values
        .map(
          (entry) => _formatInlineValue(entry, context, exactMode: exactMode),
        )
        .join(', ');
    return 'data($entries)';
  }

  String _formatMatrixRows(
    List<List<CalculatorValue>> rows,
    CalculationContext context, {
    required bool exactMode,
  }) {
    final rowText = rows
        .map((row) => _formatVectorEntries(row, context, exactMode: exactMode))
        .join(', ');
    return '[$rowText]';
  }

  String _previewMatrix(
    String fullDisplay,
    MatrixValue value,
    CalculationContext context, {
    required bool exactMode,
  }) {
    if (value.rowCount <= LinearAlgebra.maxPreviewRows &&
        value.columnCount <= LinearAlgebra.maxPreviewColumns) {
      return fullDisplay;
    }

    final previewRows = <String>[];
    final rowLimit = math.min(value.rowCount, LinearAlgebra.maxPreviewRows);
    final columnLimit = math.min(
      value.columnCount,
      LinearAlgebra.maxPreviewColumns,
    );
    for (var row = 0; row < rowLimit; row++) {
      final buffer = <String>[];
      for (var column = 0; column < columnLimit; column++) {
        buffer.add(
          _formatInlineValue(
            value.entryAt(row, column),
            context,
            exactMode: exactMode,
          ),
        );
      }
      if (value.columnCount > columnLimit) {
        buffer.add('...');
      }
      previewRows.add('[${buffer.join(', ')}]');
    }
    if (value.rowCount > rowLimit) {
      previewRows.add('...');
    }
    return '[${previewRows.join(', ')}]';
  }

  String _previewDataset(
    String fullDisplay,
    DatasetValue value,
    CalculationContext context, {
    required bool exactMode,
  }) {
    const previewLimit = 50;
    if (value.length <= previewLimit) {
      return fullDisplay;
    }
    final prefix = value.values
        .take(previewLimit)
        .map(
          (entry) => _formatInlineValue(entry, context, exactMode: exactMode),
        )
        .join(', ');
    return 'data($prefix, ...; n=${value.length})';
  }

  String _formatInlineValue(
    CalculatorValue value,
    CalculationContext context, {
    required bool exactMode,
  }) {
    if (value is ComplexValue) {
      return _formatComplexRectangular(value, context, exactMode: exactMode);
    }
    if (value is UnitValue) {
      final magnitude = exactMode
          ? _formatScalarExact(value.displayMagnitude, context)
          : _formatScalarDecimal(value.displayMagnitude, context);
      return value.isUnitExpressionOnly
          ? value.displayUnit.toDisplayString()
          : '$magnitude ${value.displayUnit.toDisplayString()}';
    }
    return exactMode
        ? _formatScalarExact(value, context)
        : _formatScalarDecimal(value, context);
  }

  String _formatComplexPolar(ComplexValue value, CalculationContext context) {
    final magnitude = _formatScalarDecimal(value.magnitude(), context);
    final angle = _formatAngleDecimal(
      value.argument(context.angleMode),
      context,
    );
    final suffix = switch (context.angleMode) {
      AngleMode.degree => '\u00B0',
      AngleMode.radian => ' rad',
      AngleMode.gradian => ' grad',
    };
    return '$magnitude\u2220$angle$suffix';
  }

  String _formatRegressionEquation(
    RegressionValue value,
    CalculationContext context, {
    required bool exactMode,
  }) {
    final slopeText = _formatInlineValue(
      value.slope,
      context,
      exactMode: exactMode,
    );
    final interceptText = _formatInlineValue(
      _absoluteScalar(value.intercept),
      context,
      exactMode: exactMode,
    );
    final slopeIsOne =
        _formatInlineValue(
          _absoluteScalar(value.slope),
          context,
          exactMode: true,
        ) ==
        '1';
    final slopeNegative = _isNegativeScalar(value.slope);
    final interceptNegative = _isNegativeScalar(value.intercept);
    final interceptZero = ScalarValueMath.isZero(value.intercept);

    final slopePart = slopeIsOne
        ? (slopeNegative ? '-x' : 'x')
        : slopeNegative
        ? '-${_formatInlineValue(_absoluteScalar(value.slope), context, exactMode: exactMode)}x'
        : '${slopeText}x';
    if (interceptZero) {
      return 'y = $slopePart + 0';
    }
    final sign = interceptNegative ? ' - ' : ' + ';
    return 'y = $slopePart$sign$interceptText';
  }

  String _formatAngleDecimal(double value, CalculationContext context) {
    return _formatDecimalDouble(
      _normalizeNoise(value, context.precision),
      context.precision,
    );
  }

  String _formatScalarExact(CalculatorValue value, CalculationContext context) {
    if (value is VectorValue || value is MatrixValue) {
      return value.toString();
    }
    if (value is UnitValue) {
      return _formatInlineValue(value, context, exactMode: true);
    }
    if (value is RationalValue) {
      return value.toFractionString();
    }
    if (value is SymbolicValue) {
      return value.toSymbolicString();
    }
    if (value is DoubleValue) {
      return _formatDecimalDouble(
        _normalizeNoise(value.toDouble(), context.precision),
        context.precision,
      );
    }
    return _formatDecimalDouble(
      _normalizeNoise(value.toDouble(), context.precision),
      context.precision,
    );
  }

  String _formatScalarDecimal(
    CalculatorValue value,
    CalculationContext context,
  ) {
    if (value is VectorValue || value is MatrixValue) {
      return value.toString();
    }
    if (value is UnitValue) {
      return _formatInlineValue(value, context, exactMode: false);
    }
    if (value is RationalValue) {
      return value.toDecimalString(context.precision);
    }
    return _formatDecimalDouble(
      _normalizeNoise(value.toDouble(), context.precision),
      context.precision,
    );
  }

  String _formatImaginaryExact(
    CalculatorValue value,
    CalculationContext context,
  ) {
    if (value is RationalValue) {
      final numerator = value.numerator.abs();
      final denominator = value.denominator;
      if (denominator == BigInt.one) {
        return numerator == BigInt.one ? 'i' : '${numerator}i';
      }
      if (numerator == BigInt.one) {
        return 'i/$denominator';
      }
      return '${numerator}i/$denominator';
    }

    final text = _formatScalarExact(value, context);
    return _appendImaginarySuffix(text);
  }

  String _formatImaginaryDecimal(
    CalculatorValue value,
    CalculationContext context,
  ) {
    final normalized = _normalizeNoise(
      value.toDouble(),
      context.precision,
    ).abs();
    final text = _formatDecimalDouble(normalized, context.precision);
    if ((normalized - 1).abs() <
        math.pow(10, -(context.precision + 1)).toDouble()) {
      return 'i';
    }
    return _appendImaginarySuffix(text);
  }

  String _appendImaginarySuffix(String text) {
    if (text == '1') {
      return 'i';
    }
    if (text.contains(' + ') || text.contains(' - ')) {
      return '($text)i';
    }
    final slashIndex = text.indexOf('/');
    if (slashIndex != -1) {
      final numerator = text.substring(0, slashIndex);
      final denominator = text.substring(slashIndex + 1);
      return '${numerator}i/$denominator';
    }
    return '${text}i';
  }

  CalculatorValue _absoluteScalar(CalculatorValue value) {
    return ScalarValueMath.abs(value);
  }

  bool _isNegativeScalar(CalculatorValue value) {
    if (value is RationalValue) {
      return value.numerator.isNegative;
    }
    if (value is SymbolicValue) {
      return value.toDouble() < 0;
    }
    return value.toDouble() < 0;
  }

  double _normalizeNoise(double value, int precision) {
    final epsilon = math.pow(10, -(precision + 2)).toDouble();
    if (value == -0.0 || value.abs() < epsilon) {
      return 0.0;
    }
    return value;
  }

  String _formatAutoDouble(double value, int precision) {
    final absoluteValue = value.abs();
    if (absoluteValue != 0 &&
        (absoluteValue >= math.pow(10, precision - 1) ||
            absoluteValue < math.pow(10, -4))) {
      return _formatScientificDouble(value, precision);
    }

    return _formatDecimalDouble(value, precision);
  }

  String _formatDecimalDouble(double value, int precision) {
    final fixedText = value.toStringAsFixed(precision);
    final trimmedText = fixedText.replaceFirst(RegExp(r'\.?0+$'), '');
    if (trimmedText.isNotEmpty && trimmedText != '-0') {
      return trimmedText;
    }

    final precisionText = value.toStringAsPrecision(precision);
    if (precisionText.contains('e') || precisionText.contains('E')) {
      return precisionText;
    }

    return precisionText.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _formatScientificDouble(double value, int precision) {
    final digits = precision > 1 ? precision - 1 : 1;
    final text = value.toStringAsExponential(digits);
    return text.replaceFirst(RegExp(r'\.?0+e'), 'e');
  }
}

class FormattedCalculationValue {
  const FormattedCalculationValue({
    required this.displayResult,
    required this.valueKind,
    required this.numericMode,
    required this.resultFormat,
    required this.isApproximate,
    this.exactDisplayResult,
    this.symbolicDisplayResult,
    this.decimalDisplayResult,
    this.fractionDisplayResult,
    this.complexDisplayResult,
    this.rectangularDisplayResult,
    this.polarDisplayResult,
    this.magnitudeDisplayResult,
    this.argumentDisplayResult,
    this.functionDisplayResult,
    this.plotDisplayResult,
    this.graphDisplayResult,
    this.equationDisplayResult,
    this.solveDisplayResult,
    this.solutionsDisplayResult,
    this.traceDisplayResult,
    this.rootDisplayResult,
    this.intersectionDisplayResult,
    this.derivativeDisplayResult,
    this.integralDisplayResult,
    this.transformDisplayResult,
    this.datasetDisplayResult,
    this.statisticsDisplayResult,
    this.regressionDisplayResult,
    this.probabilityDisplayResult,
    this.summaryDisplayResult,
    this.vectorDisplayResult,
    this.matrixDisplayResult,
    this.unitDisplayResult,
    this.baseUnitDisplayResult,
    this.dimensionDisplayResult,
    this.conversionDisplayResult,
    this.shapeDisplayResult,
    this.rowCount,
    this.columnCount,
    this.sampleSize,
    this.statisticName,
    this.plotSeriesCount,
    this.plotPointCount,
    this.plotSegmentCount,
    this.viewportDisplayResult,
    this.solutionCount,
    this.solveVariable,
    this.solveMethod,
    this.solveDomain,
    this.residualDisplayResult,
    this.alternativeResults = const <String, String>{},
  });

  FormattedCalculationValue copyWith({
    String? displayResult,
    CalculatorValueKind? valueKind,
    NumericMode? numericMode,
    NumberFormatStyle? resultFormat,
    bool? isApproximate,
    String? exactDisplayResult,
    String? symbolicDisplayResult,
    String? decimalDisplayResult,
    String? fractionDisplayResult,
    String? complexDisplayResult,
    String? rectangularDisplayResult,
    String? polarDisplayResult,
    String? magnitudeDisplayResult,
    String? argumentDisplayResult,
    String? functionDisplayResult,
    String? plotDisplayResult,
    String? graphDisplayResult,
    String? equationDisplayResult,
    String? solveDisplayResult,
    String? solutionsDisplayResult,
    String? traceDisplayResult,
    String? rootDisplayResult,
    String? intersectionDisplayResult,
    String? derivativeDisplayResult,
    String? integralDisplayResult,
    String? transformDisplayResult,
    String? datasetDisplayResult,
    String? statisticsDisplayResult,
    String? regressionDisplayResult,
    String? probabilityDisplayResult,
    String? summaryDisplayResult,
    String? vectorDisplayResult,
    String? matrixDisplayResult,
    String? unitDisplayResult,
    String? baseUnitDisplayResult,
    String? dimensionDisplayResult,
    String? conversionDisplayResult,
    String? shapeDisplayResult,
    int? rowCount,
    int? columnCount,
    int? sampleSize,
    String? statisticName,
    int? plotSeriesCount,
    int? plotPointCount,
    int? plotSegmentCount,
    String? viewportDisplayResult,
    int? solutionCount,
    String? solveVariable,
    String? solveMethod,
    String? solveDomain,
    String? residualDisplayResult,
    Map<String, String>? alternativeResults,
  }) {
    return FormattedCalculationValue(
      displayResult: displayResult ?? this.displayResult,
      valueKind: valueKind ?? this.valueKind,
      numericMode: numericMode ?? this.numericMode,
      resultFormat: resultFormat ?? this.resultFormat,
      isApproximate: isApproximate ?? this.isApproximate,
      exactDisplayResult: exactDisplayResult ?? this.exactDisplayResult,
      symbolicDisplayResult:
          symbolicDisplayResult ?? this.symbolicDisplayResult,
      decimalDisplayResult: decimalDisplayResult ?? this.decimalDisplayResult,
      fractionDisplayResult:
          fractionDisplayResult ?? this.fractionDisplayResult,
      complexDisplayResult: complexDisplayResult ?? this.complexDisplayResult,
      rectangularDisplayResult:
          rectangularDisplayResult ?? this.rectangularDisplayResult,
      polarDisplayResult: polarDisplayResult ?? this.polarDisplayResult,
      magnitudeDisplayResult:
          magnitudeDisplayResult ?? this.magnitudeDisplayResult,
      argumentDisplayResult:
          argumentDisplayResult ?? this.argumentDisplayResult,
      functionDisplayResult:
          functionDisplayResult ?? this.functionDisplayResult,
      plotDisplayResult: plotDisplayResult ?? this.plotDisplayResult,
      graphDisplayResult: graphDisplayResult ?? this.graphDisplayResult,
      equationDisplayResult:
          equationDisplayResult ?? this.equationDisplayResult,
      solveDisplayResult: solveDisplayResult ?? this.solveDisplayResult,
      solutionsDisplayResult:
          solutionsDisplayResult ?? this.solutionsDisplayResult,
      traceDisplayResult: traceDisplayResult ?? this.traceDisplayResult,
      rootDisplayResult: rootDisplayResult ?? this.rootDisplayResult,
      intersectionDisplayResult:
          intersectionDisplayResult ?? this.intersectionDisplayResult,
      derivativeDisplayResult:
          derivativeDisplayResult ?? this.derivativeDisplayResult,
      integralDisplayResult:
          integralDisplayResult ?? this.integralDisplayResult,
      transformDisplayResult:
          transformDisplayResult ?? this.transformDisplayResult,
      datasetDisplayResult: datasetDisplayResult ?? this.datasetDisplayResult,
      statisticsDisplayResult:
          statisticsDisplayResult ?? this.statisticsDisplayResult,
      regressionDisplayResult:
          regressionDisplayResult ?? this.regressionDisplayResult,
      probabilityDisplayResult:
          probabilityDisplayResult ?? this.probabilityDisplayResult,
      summaryDisplayResult: summaryDisplayResult ?? this.summaryDisplayResult,
      vectorDisplayResult: vectorDisplayResult ?? this.vectorDisplayResult,
      matrixDisplayResult: matrixDisplayResult ?? this.matrixDisplayResult,
      unitDisplayResult: unitDisplayResult ?? this.unitDisplayResult,
      baseUnitDisplayResult:
          baseUnitDisplayResult ?? this.baseUnitDisplayResult,
      dimensionDisplayResult:
          dimensionDisplayResult ?? this.dimensionDisplayResult,
      conversionDisplayResult:
          conversionDisplayResult ?? this.conversionDisplayResult,
      shapeDisplayResult: shapeDisplayResult ?? this.shapeDisplayResult,
      rowCount: rowCount ?? this.rowCount,
      columnCount: columnCount ?? this.columnCount,
      sampleSize: sampleSize ?? this.sampleSize,
      statisticName: statisticName ?? this.statisticName,
      plotSeriesCount: plotSeriesCount ?? this.plotSeriesCount,
      plotPointCount: plotPointCount ?? this.plotPointCount,
      plotSegmentCount: plotSegmentCount ?? this.plotSegmentCount,
      viewportDisplayResult:
          viewportDisplayResult ?? this.viewportDisplayResult,
      solutionCount: solutionCount ?? this.solutionCount,
      solveVariable: solveVariable ?? this.solveVariable,
      solveMethod: solveMethod ?? this.solveMethod,
      solveDomain: solveDomain ?? this.solveDomain,
      residualDisplayResult:
          residualDisplayResult ?? this.residualDisplayResult,
      alternativeResults: alternativeResults ?? this.alternativeResults,
    );
  }

  final String displayResult;
  final CalculatorValueKind valueKind;
  final NumericMode numericMode;
  final NumberFormatStyle resultFormat;
  final bool isApproximate;
  final String? exactDisplayResult;
  final String? symbolicDisplayResult;
  final String? decimalDisplayResult;
  final String? fractionDisplayResult;
  final String? complexDisplayResult;
  final String? rectangularDisplayResult;
  final String? polarDisplayResult;
  final String? magnitudeDisplayResult;
  final String? argumentDisplayResult;
  final String? functionDisplayResult;
  final String? plotDisplayResult;
  final String? graphDisplayResult;
  final String? equationDisplayResult;
  final String? solveDisplayResult;
  final String? solutionsDisplayResult;
  final String? traceDisplayResult;
  final String? rootDisplayResult;
  final String? intersectionDisplayResult;
  final String? derivativeDisplayResult;
  final String? integralDisplayResult;
  final String? transformDisplayResult;
  final String? datasetDisplayResult;
  final String? statisticsDisplayResult;
  final String? regressionDisplayResult;
  final String? probabilityDisplayResult;
  final String? summaryDisplayResult;
  final String? vectorDisplayResult;
  final String? matrixDisplayResult;
  final String? unitDisplayResult;
  final String? baseUnitDisplayResult;
  final String? dimensionDisplayResult;
  final String? conversionDisplayResult;
  final String? shapeDisplayResult;
  final int? rowCount;
  final int? columnCount;
  final int? sampleSize;
  final String? statisticName;
  final int? plotSeriesCount;
  final int? plotPointCount;
  final int? plotSegmentCount;
  final String? viewportDisplayResult;
  final int? solutionCount;
  final String? solveVariable;
  final String? solveMethod;
  final String? solveDomain;
  final String? residualDisplayResult;
  final Map<String, String> alternativeResults;
}
