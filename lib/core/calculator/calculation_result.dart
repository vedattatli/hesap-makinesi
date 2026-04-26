import 'calculation_context.dart';
import 'calculation_domain.dart';
import 'numeric_mode.dart';
import 'values/calculator_value.dart';

/// Represents a successful calculation result.
class CalculationResult {
  /// Creates a successful result payload.
  const CalculationResult({
    required this.normalizedExpression,
    required this.displayResult,
    required this.numericValue,
    required this.isApproximate,
    required this.warnings,
    this.value,
    this.valueKind = CalculatorValueKind.doubleValue,
    this.numericMode = NumericMode.approximate,
    this.calculationDomain = CalculationDomain.real,
    this.resultFormat = NumberFormatStyle.auto,
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
    this.graphWarnings = const <String>[],
    this.alternativeResults = const <String, String>{},
  });

  /// Expression rewritten into a normalized engine-friendly representation.
  final String normalizedExpression;

  /// Main string shown to the user.
  final String displayResult;

  /// Numeric value produced by the evaluator when available.
  final double? numericValue;

  /// Indicates whether the displayed value is approximate.
  final bool isApproximate;

  /// Informational warnings collected during evaluation.
  final List<String> warnings;

  /// Raw calculator value, when available from the evaluator.
  final CalculatorValue? value;

  /// Result value kind used by history and UI badges.
  final CalculatorValueKind valueKind;

  /// Numeric calculation mode used for this evaluation.
  final NumericMode numericMode;

  /// Real or complex evaluation domain used for this result.
  final CalculationDomain calculationDomain;

  /// Display format selected for the primary result string.
  final NumberFormatStyle resultFormat;

  /// Exact display text when available.
  final String? exactDisplayResult;

  /// Symbolic rendering of the result when available.
  final String? symbolicDisplayResult;

  /// Decimal rendering of the result when available.
  final String? decimalDisplayResult;

  /// Fraction rendering of the result when available.
  final String? fractionDisplayResult;

  /// Complex-aware display rendering when the result is complex.
  final String? complexDisplayResult;

  /// Rectangular complex display when available.
  final String? rectangularDisplayResult;

  /// Polar complex display when available.
  final String? polarDisplayResult;

  /// Magnitude alternative for complex results.
  final String? magnitudeDisplayResult;

  /// Argument alternative for complex results.
  final String? argumentDisplayResult;

  /// Function display when the result is a scoped graph function.
  final String? functionDisplayResult;

  /// Plot summary display when the result is a graph plot.
  final String? plotDisplayResult;

  /// General graph summary for trace, slope, area or plot results.
  final String? graphDisplayResult;

  /// Equation display when the result is an equation object.
  final String? equationDisplayResult;

  /// Solve summary display when the result is a solve output.
  final String? solveDisplayResult;

  /// Solution-set display when available.
  final String? solutionsDisplayResult;

  /// Structured trace display when available.
  final String? traceDisplayResult;

  /// Root search summary text when available.
  final String? rootDisplayResult;

  /// Intersection summary text when available.
  final String? intersectionDisplayResult;

  /// Symbolic derivative summary text when available.
  final String? derivativeDisplayResult;

  /// Symbolic or numeric integral summary text when available.
  final String? integralDisplayResult;

  /// Generic transform summary text for diff/integral helpers.
  final String? transformDisplayResult;

  /// Dataset display when the result is a dataset.
  final String? datasetDisplayResult;

  /// Descriptive statistics summary when useful.
  final String? statisticsDisplayResult;

  /// Regression summary when the result is a regression model.
  final String? regressionDisplayResult;

  /// Probability function summary when useful.
  final String? probabilityDisplayResult;

  /// Generic structured summary text for UI/history.
  final String? summaryDisplayResult;

  /// Vector display when the result is a vector.
  final String? vectorDisplayResult;

  /// Matrix display when the result is a matrix.
  final String? matrixDisplayResult;

  /// Unit-aware display when the result is a physical quantity.
  final String? unitDisplayResult;

  /// SI-base rendering of the unit value when available.
  final String? baseUnitDisplayResult;

  /// Dimension signature such as `L` or `L*T^-2`.
  final String? dimensionDisplayResult;

  /// Explicit conversion rendering when the expression requested one.
  final String? conversionDisplayResult;

  /// Shape label such as `2 x 3`.
  final String? shapeDisplayResult;

  /// Matrix row count when applicable.
  final int? rowCount;

  /// Matrix column count when applicable.
  final int? columnCount;

  /// Sample size associated with a dataset/statistics/regression result.
  final int? sampleSize;

  /// Function/statistic label when the result came from a stats helper.
  final String? statisticName;

  /// Number of plotted series when applicable.
  final int? plotSeriesCount;

  /// Number of sampled plot points when applicable.
  final int? plotPointCount;

  /// Number of continuous segments when applicable.
  final int? plotSegmentCount;

  /// Human-readable viewport summary.
  final String? viewportDisplayResult;

  /// Number of solutions when applicable.
  final int? solutionCount;

  /// Solve variable name when applicable.
  final String? solveVariable;

  /// Solve method summary label.
  final String? solveMethod;

  /// Solve domain summary label.
  final String? solveDomain;

  /// Residual summary when numeric solving reports one.
  final String? residualDisplayResult;

  /// Plot-specific warnings.
  final List<String> graphWarnings;

  /// Additional named display alternatives.
  final Map<String, String> alternativeResults;
}
