import 'angle_mode.dart';
import 'calculation_domain.dart';
import 'numeric_mode.dart';
import 'unit_mode.dart';

/// Controls how the calculator engine evaluates and formats expressions.
class CalculationContext {
  /// Creates a calculator evaluation context.
  const CalculationContext({
    this.angleMode = AngleMode.degree,
    this.precision = 12,
    this.preferExactResult = false,
    NumericMode? numericMode,
    this.calculationDomain = CalculationDomain.real,
    this.unitMode = UnitMode.disabled,
    this.numberFormatStyle = NumberFormatStyle.auto,
    this.maxTokenCount = 512,
  }) : assert(precision > 0, 'precision must be positive'),
       numericMode =
           numericMode ??
           (preferExactResult ? NumericMode.exact : NumericMode.approximate);

  /// Trigonometric mode used by the evaluator.
  final AngleMode angleMode;

  /// Preferred output precision.
  final int precision;

  /// Placeholder for a future exact/approximate engine split.
  final bool preferExactResult;

  /// Numeric calculation policy.
  final NumericMode numericMode;

  /// Real or complex evaluation domain.
  final CalculationDomain calculationDomain;

  /// Whether physical unit parsing is active.
  final UnitMode unitMode;

  /// Preferred display formatting mode.
  final NumberFormatStyle numberFormatStyle;

  /// Upper bound for tokens generated from a single expression.
  final int maxTokenCount;

  /// Creates a modified copy of the current context.
  CalculationContext copyWith({
    AngleMode? angleMode,
    int? precision,
    bool? preferExactResult,
    NumericMode? numericMode,
    CalculationDomain? calculationDomain,
    UnitMode? unitMode,
    NumberFormatStyle? numberFormatStyle,
    int? maxTokenCount,
  }) {
    return CalculationContext(
      angleMode: angleMode ?? this.angleMode,
      precision: precision ?? this.precision,
      preferExactResult: preferExactResult ?? this.preferExactResult,
      numericMode: numericMode ?? this.numericMode,
      calculationDomain: calculationDomain ?? this.calculationDomain,
      unitMode: unitMode ?? this.unitMode,
      numberFormatStyle: numberFormatStyle ?? this.numberFormatStyle,
      maxTokenCount: maxTokenCount ?? this.maxTokenCount,
    );
  }
}

/// Determines how numeric values are rendered for display.
enum NumberFormatStyle {
  /// Chooses decimal or scientific notation automatically.
  auto,

  /// Prefers decimal rendering.
  decimal,

  /// Prefers fraction rendering when the result is rational.
  fraction,

  /// Prefers symbolic rendering when the result supports it.
  symbolic,

  /// Prefers scientific rendering.
  scientific,
}
