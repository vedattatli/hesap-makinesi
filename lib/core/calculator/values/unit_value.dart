import '../units/dimension_vector.dart';
import '../units/unit_converter.dart';
import '../units/unit_expression.dart';
import 'calculator_value.dart';
import 'rational_value.dart';

/// Physical quantity with an exact/approximate scalar magnitude and unit.
class UnitValue extends CalculatorValue {
  const UnitValue._({
    required this.baseMagnitude,
    required this.displayUnit,
    required this.isUnitExpressionOnly,
  });

  factory UnitValue.fromDisplayMagnitude({
    required CalculatorValue displayMagnitude,
    required UnitExpression displayUnit,
    bool isUnitExpressionOnly = false,
  }) {
    if (isUnitExpressionOnly) {
      return UnitValue.expression(displayUnit);
    }

    final baseMagnitude = displayUnit.isAffineDelta
        ? UnitConverter.displayToBaseDifference(displayMagnitude, displayUnit)
        : UnitConverter.displayToBaseMagnitude(displayMagnitude, displayUnit);
    return UnitValue._(
      baseMagnitude: baseMagnitude,
      displayUnit: displayUnit,
      isUnitExpressionOnly: false,
    );
  }

  factory UnitValue.fromBaseMagnitude({
    required CalculatorValue baseMagnitude,
    required UnitExpression displayUnit,
    bool isUnitExpressionOnly = false,
  }) {
    if (isUnitExpressionOnly) {
      return UnitValue.expression(displayUnit);
    }

    return UnitValue._(
      baseMagnitude: baseMagnitude,
      displayUnit: displayUnit,
      isUnitExpressionOnly: false,
    );
  }

  factory UnitValue.expression(UnitExpression unitExpression) {
    return UnitValue._(
      baseMagnitude: RationalValue.one,
      displayUnit: unitExpression,
      isUnitExpressionOnly: true,
    );
  }

  /// Magnitude expressed in SI-base units.
  final CalculatorValue baseMagnitude;

  /// Preferred display unit expression for the quantity.
  final UnitExpression displayUnit;

  /// Whether this instance stands for a pure unit expression such as `m/s`.
  final bool isUnitExpressionOnly;

  DimensionVector get dimension => displayUnit.dimension;

  bool get isDimensionless => dimension.isDimensionless;

  bool get isAffineAbsolute => displayUnit.isAffineAbsolute;

  bool get isAffineDelta => displayUnit.isAffineDelta;

  bool get isRegularUnit => !isAffineAbsolute && !isAffineDelta;

  CalculatorValue get displayMagnitude {
    if (isUnitExpressionOnly) {
      return RationalValue.one;
    }
    return isAffineDelta
        ? UnitConverter.baseToDisplayDifference(baseMagnitude, displayUnit)
        : UnitConverter.baseToDisplayMagnitude(baseMagnitude, displayUnit);
  }

  bool isConvertibleTo(UnitExpression targetUnit) {
    if (dimension != targetUnit.dimension) {
      return false;
    }

    if (displayUnit.isAffineAbsolute) {
      return !targetUnit.isAffineDelta;
    }
    if (displayUnit.isAffineDelta) {
      return !targetUnit.isAffineAbsolute;
    }
    if (targetUnit.isAffineAbsolute && !dimension.isPureTemperature) {
      return false;
    }
    return true;
  }

  UnitValue copyWith({
    CalculatorValue? baseMagnitude,
    UnitExpression? displayUnit,
    bool? isUnitExpressionOnly,
  }) {
    return UnitValue._(
      baseMagnitude: baseMagnitude ?? this.baseMagnitude,
      displayUnit: displayUnit ?? this.displayUnit,
      isUnitExpressionOnly: isUnitExpressionOnly ?? this.isUnitExpressionOnly,
    );
  }

  @override
  CalculatorValueKind get kind => CalculatorValueKind.unit;

  @override
  bool get isExact =>
      !isUnitExpressionOnly &&
      baseMagnitude.isExact &&
      !displayMagnitude.isApproximate;

  @override
  double toDouble() => baseMagnitude.toDouble();

  @override
  String toString() {
    if (isUnitExpressionOnly) {
      return displayUnit.toDisplayString();
    }
    return '$displayMagnitude ${displayUnit.toDisplayString()}';
  }
}
