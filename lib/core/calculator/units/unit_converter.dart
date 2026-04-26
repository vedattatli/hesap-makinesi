import '../values/calculator_value.dart';
import '../values/complex_value.dart';
import '../values/rational_value.dart';
import '../values/scalar_value_math.dart';
import '../values/unit_value.dart';
import 'unit_expression.dart';

/// Converts between display magnitudes and SI-base magnitudes for units.
class UnitConverter {
  const UnitConverter._();

  static CalculatorValue displayToBaseMagnitude(
    CalculatorValue displayMagnitude,
    UnitExpression unit,
  ) {
    if (unit.isAffineAbsolute) {
      return _addScalar(
        _multiplyScalar(displayMagnitude, unit.factorToBase),
        unit.offsetToBase,
      );
    }
    return _multiplyScalar(displayMagnitude, unit.factorToBase);
  }

  static CalculatorValue displayToBaseDifference(
    CalculatorValue displayMagnitude,
    UnitExpression unit,
  ) {
    return _multiplyScalar(displayMagnitude, unit.factorToBase);
  }

  static CalculatorValue baseToDisplayMagnitude(
    CalculatorValue baseMagnitude,
    UnitExpression unit,
  ) {
    if (unit.isAffineAbsolute) {
      return _divideScalar(
        _subtractScalar(baseMagnitude, unit.offsetToBase),
        unit.factorToBase,
      );
    }
    return _divideScalar(baseMagnitude, unit.factorToBase);
  }

  static CalculatorValue baseToDisplayDifference(
    CalculatorValue baseMagnitude,
    UnitExpression unit,
  ) {
    return _divideScalar(baseMagnitude, unit.factorToBase);
  }

  static UnitValue convert(UnitValue value, UnitExpression targetUnit) {
    if (!value.isConvertibleTo(targetUnit)) {
      throw ArgumentError.value(
        targetUnit,
        'targetUnit',
        'Incompatible unit conversion.',
      );
    }
    return UnitValue.fromBaseMagnitude(
      baseMagnitude: value.baseMagnitude,
      displayUnit: targetUnit,
      isUnitExpressionOnly: value.isUnitExpressionOnly,
    );
  }

  static CalculatorValue _addScalar(CalculatorValue left, CalculatorValue right) {
    if (left is ComplexValue || right is ComplexValue) {
      return ComplexValue.promote(left).addValue(right);
    }
    return ScalarValueMath.add(left, right);
  }

  static CalculatorValue _subtractScalar(
    CalculatorValue left,
    CalculatorValue right,
  ) {
    if (left is ComplexValue || right is ComplexValue) {
      return ComplexValue.promote(left).subtractValue(right);
    }
    return ScalarValueMath.subtract(left, right);
  }

  static CalculatorValue _multiplyScalar(
    CalculatorValue left,
    RationalValue right,
  ) {
    if (left is ComplexValue) {
      return ComplexValue.promote(left).multiplyValue(right);
    }
    return ScalarValueMath.multiply(left, right);
  }

  static CalculatorValue _divideScalar(
    CalculatorValue left,
    RationalValue right,
  ) {
    if (left is ComplexValue) {
      return ComplexValue.promote(left).divideValue(right);
    }
    return ScalarValueMath.divide(left, right);
  }
}
