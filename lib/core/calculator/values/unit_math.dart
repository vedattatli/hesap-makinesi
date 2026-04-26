import 'dart:math' as math;

import '../units/unit_converter.dart';
import '../units/unit_expression.dart';
import '../units/unit_registry.dart';
import 'calculator_value.dart';
import 'complex_value.dart';
import 'double_value.dart';
import 'scalar_value_math.dart';
import 'unit_value.dart';

/// Unit-aware arithmetic for [UnitValue] while preserving scalar semantics.
class UnitMath {
  const UnitMath._();

  static CalculatorValue attach(
    CalculatorValue magnitude,
    UnitExpression unitExpression,
  ) {
    return _collapseUnit(
      UnitValue.fromDisplayMagnitude(
        displayMagnitude: magnitude,
        displayUnit: unitExpression,
      ),
    );
  }

  static CalculatorValue add(UnitValue left, UnitValue right) {
    _requireQuantity(left, 'Toplama icin yalnizca fiziksel buyuklukler kullanilabilir.');
    _requireQuantity(right, 'Toplama icin yalnizca fiziksel buyuklukler kullanilabilir.');
    _requireSameDimension(left, right);

    if (left.isAffineAbsolute && right.isAffineAbsolute) {
      throw UnsupportedError(
        'Adding two absolute temperatures is not physically meaningful. Use deltaC/deltaF for temperature differences.',
      );
    }

    if (left.isAffineAbsolute && right.isAffineDelta) {
      return _collapseUnit(
        UnitValue.fromBaseMagnitude(
          baseMagnitude: _addScalar(left.baseMagnitude, right.baseMagnitude),
          displayUnit: left.displayUnit,
        ),
      );
    }

    if (left.isAffineDelta && right.isAffineAbsolute) {
      return _collapseUnit(
        UnitValue.fromBaseMagnitude(
          baseMagnitude: _addScalar(left.baseMagnitude, right.baseMagnitude),
          displayUnit: right.displayUnit,
        ),
      );
    }

    final sum = _addScalar(left.baseMagnitude, right.baseMagnitude);
    return _collapseUnit(
      UnitValue.fromBaseMagnitude(
        baseMagnitude: sum,
        displayUnit: left.displayUnit,
      ),
    );
  }

  static CalculatorValue subtract(UnitValue left, UnitValue right) {
    _requireQuantity(left, 'Cikarma icin yalnizca fiziksel buyuklukler kullanilabilir.');
    _requireQuantity(right, 'Cikarma icin yalnizca fiziksel buyuklukler kullanilabilir.');
    _requireSameDimension(left, right);

    if (left.isAffineAbsolute && right.isAffineAbsolute) {
      final deltaUnit =
          UnitRegistry.instance.deltaCounterpart(left.displayUnit) ??
          UnitRegistry.instance.baseExpressionForDimension(left.dimension);
      return _collapseUnit(
        UnitValue.fromBaseMagnitude(
          baseMagnitude: _subtractScalar(left.baseMagnitude, right.baseMagnitude),
          displayUnit: deltaUnit,
        ),
      );
    }

    if (left.isAffineAbsolute && right.isAffineDelta) {
      return _collapseUnit(
        UnitValue.fromBaseMagnitude(
          baseMagnitude: _subtractScalar(left.baseMagnitude, right.baseMagnitude),
          displayUnit: left.displayUnit,
        ),
      );
    }

    if (left.isAffineDelta && right.isAffineAbsolute) {
      throw UnsupportedError(
        'Subtracting an absolute temperature from a temperature difference is not physically meaningful.',
      );
    }

    return _collapseUnit(
      UnitValue.fromBaseMagnitude(
        baseMagnitude: _subtractScalar(left.baseMagnitude, right.baseMagnitude),
        displayUnit: left.displayUnit,
      ),
    );
  }

  static CalculatorValue multiply(UnitValue left, UnitValue right) {
    if (left.isAffineAbsolute || right.isAffineAbsolute) {
      throw UnsupportedError(
        'Absolute temperature values cannot be multiplied or divided.',
      );
    }

    if (left.isUnitExpressionOnly && right.isUnitExpressionOnly) {
      return UnitValue.expression(left.displayUnit.multiply(right.displayUnit));
    }

    if (left.isUnitExpressionOnly) {
      final displayUnit = UnitRegistry.instance.canonicalize(
        left.displayUnit.multiply(right.displayUnit),
      );
      return _collapseUnit(
        UnitValue.fromBaseMagnitude(
          baseMagnitude: right.baseMagnitude,
          displayUnit: displayUnit,
        ),
      );
    }
    if (right.isUnitExpressionOnly) {
      final displayUnit = UnitRegistry.instance.canonicalize(
        left.displayUnit.multiply(right.displayUnit),
      );
      return _collapseUnit(
        UnitValue.fromBaseMagnitude(
          baseMagnitude: left.baseMagnitude,
          displayUnit: displayUnit,
        ),
      );
    }

    final displayUnit = UnitRegistry.instance.canonicalize(
      left.displayUnit.multiply(right.displayUnit),
    );
    return _collapseUnit(
      UnitValue.fromBaseMagnitude(
        baseMagnitude: _multiplyScalar(left.baseMagnitude, right.baseMagnitude),
        displayUnit: displayUnit,
      ),
    );
  }

  static CalculatorValue divide(UnitValue left, UnitValue right) {
    if (!right.isUnitExpressionOnly && _isZeroScalar(right.baseMagnitude)) {
      throw ArgumentError.value(right, 'right', 'Division by zero.');
    }
    if (left.isAffineAbsolute || right.isAffineAbsolute) {
      throw UnsupportedError(
        'Absolute temperature values cannot be multiplied or divided.',
      );
    }

    if (right.isUnitExpressionOnly && left.isUnitExpressionOnly) {
      return UnitValue.expression(left.displayUnit.divide(right.displayUnit));
    }

    if (left.isUnitExpressionOnly) {
      throw UnsupportedError('A bare unit expression cannot be divided by a quantity.');
    }

    if (right.isUnitExpressionOnly) {
      final displayUnit = UnitRegistry.instance.canonicalize(
        left.displayUnit.divide(right.displayUnit),
      );
      return _collapseUnit(
        UnitValue.fromBaseMagnitude(
          baseMagnitude: left.baseMagnitude,
          displayUnit: displayUnit,
        ),
      );
    }

    final displayUnit = UnitRegistry.instance.canonicalize(
      left.displayUnit.divide(right.displayUnit),
    );
    return _collapseUnit(
      UnitValue.fromBaseMagnitude(
        baseMagnitude: _divideScalar(left.baseMagnitude, right.baseMagnitude),
        displayUnit: displayUnit,
      ),
    );
  }

  static CalculatorValue multiplyScalar(
    CalculatorValue scalar,
    UnitValue unitValue,
  ) {
    if (unitValue.isAffineAbsolute) {
      if (unitValue.isUnitExpressionOnly) {
        return attach(scalar, unitValue.displayUnit);
      }
      throw UnsupportedError(
        'Absolute temperature values cannot be multiplied or scaled.',
      );
    }

    if (unitValue.isUnitExpressionOnly) {
      return _collapseUnit(
        UnitValue.fromDisplayMagnitude(
          displayMagnitude: scalar,
          displayUnit: unitValue.displayUnit,
        ),
      );
    }

    return _collapseUnit(
      UnitValue.fromBaseMagnitude(
        baseMagnitude: _multiplyScalar(scalar, unitValue.baseMagnitude),
        displayUnit: unitValue.displayUnit,
      ),
    );
  }

  static CalculatorValue divideByScalar(UnitValue unitValue, CalculatorValue scalar) {
    if (_isZeroScalar(scalar)) {
      throw ArgumentError.value(scalar, 'scalar', 'Division by zero.');
    }
    if (unitValue.isAffineAbsolute) {
      throw UnsupportedError(
        'Absolute temperature values cannot be divided by scalars.',
      );
    }
    if (unitValue.isUnitExpressionOnly) {
      throw UnsupportedError('Bare unit expressions cannot be divided by scalars.');
    }
    return _collapseUnit(
      UnitValue.fromBaseMagnitude(
        baseMagnitude: _divideScalar(unitValue.baseMagnitude, scalar),
        displayUnit: unitValue.displayUnit,
      ),
    );
  }

  static CalculatorValue divideScalarByUnit(
    CalculatorValue scalar,
    UnitValue unitValue,
  ) {
    if (!unitValue.isUnitExpressionOnly &&
        _isZeroScalar(unitValue.baseMagnitude)) {
      throw ArgumentError.value(unitValue, 'unitValue', 'Division by zero.');
    }
    if (unitValue.isAffineAbsolute) {
      throw UnsupportedError(
        'Absolute temperature values cannot appear in denominator conversions.',
      );
    }
    final reciprocalUnit = UnitRegistry.instance.canonicalize(
      UnitExpression.dimensionless().divide(unitValue.displayUnit),
    );
    if (unitValue.isUnitExpressionOnly) {
      return _collapseUnit(
        UnitValue.fromDisplayMagnitude(
          displayMagnitude: scalar,
          displayUnit: reciprocalUnit,
        ),
      );
    }
    return _collapseUnit(
      UnitValue.fromBaseMagnitude(
        baseMagnitude: _divideScalar(scalar, unitValue.baseMagnitude),
        displayUnit: reciprocalUnit,
      ),
    );
  }

  static CalculatorValue integerPower(UnitValue unitValue, int exponent) {
    if (unitValue.isAffineAbsolute && exponent != 1) {
      throw UnsupportedError(
        'Absolute temperature values do not support non-trivial powers.',
      );
    }

    final poweredUnit = UnitRegistry.instance.canonicalize(
      unitValue.displayUnit.integerPower(exponent),
    );
    if (unitValue.isUnitExpressionOnly) {
      return UnitValue.expression(unitValue.displayUnit.integerPower(exponent));
    }
    final poweredMagnitude = exponent >= 0
        ? _integerPowerScalar(unitValue.baseMagnitude, exponent)
        : _integerPowerScalar(unitValue.baseMagnitude, exponent);
    return _collapseUnit(
      UnitValue.fromBaseMagnitude(
        baseMagnitude: poweredMagnitude,
        displayUnit: poweredUnit,
      ),
    );
  }

  static CalculatorValue squareRoot(UnitValue unitValue) {
    if (unitValue.isAffineAbsolute || unitValue.isAffineDelta) {
      throw UnsupportedError('Temperature units do not support square roots.');
    }
    final unitRoot = unitValue.displayUnit.squareRoot();
    if (unitRoot == null) {
      throw UnsupportedError(
        'Square root is only supported when all unit exponents remain integers.',
      );
    }
    if (unitValue.isUnitExpressionOnly) {
      return UnitValue.expression(unitRoot);
    }
    return _collapseUnit(
      UnitValue.fromBaseMagnitude(
        baseMagnitude: _squareRootScalar(unitValue.baseMagnitude),
        displayUnit: UnitRegistry.instance.canonicalize(unitRoot),
      ),
    );
  }

  static CalculatorValue abs(UnitValue unitValue) {
    _requireQuantity(unitValue, 'Mutlak deger yalnizca fiziksel buyukluklerde hesaplanabilir.');
    return _collapseUnit(
      UnitValue.fromBaseMagnitude(
        baseMagnitude: _absScalar(unitValue.baseMagnitude),
        displayUnit: unitValue.displayUnit,
      ),
    );
  }

  static CalculatorValue round(
    UnitValue unitValue,
    CalculatorValue Function(CalculatorValue value) roundingOperation,
  ) {
    _requireQuantity(unitValue, 'Yuvarlama yalnizca fiziksel buyukluklerde hesaplanabilir.');
    final roundedDisplay = roundingOperation(unitValue.displayMagnitude);
    return _collapseUnit(
      UnitValue.fromDisplayMagnitude(
        displayMagnitude: roundedDisplay,
        displayUnit: unitValue.displayUnit,
      ),
    );
  }

  static int compare(UnitValue left, UnitValue right) {
    _requireQuantity(left, 'Karsilastirma yalnizca fiziksel buyukluklerde kullanilabilir.');
    _requireQuantity(right, 'Karsilastirma yalnizca fiziksel buyukluklerde kullanilabilir.');
    _requireSameDimension(left, right);
    return _compareScalar(left.baseMagnitude, right.baseMagnitude);
  }

  static CalculatorValue convert(UnitValue value, UnitExpression targetUnit) {
    _requireQuantity(value, 'Donusum yalnizca fiziksel buyuklukler icin yapilabilir.');
    if (!value.isConvertibleTo(targetUnit)) {
      throw UnsupportedError('Incompatible unit conversion.');
    }
    return _collapseUnit(UnitConverter.convert(value, targetUnit));
  }

  static void _requireSameDimension(UnitValue left, UnitValue right) {
    if (left.dimension != right.dimension) {
      throw ArgumentError('Dimension mismatch.');
    }
  }

  static void _requireQuantity(UnitValue value, String message) {
    if (value.isUnitExpressionOnly) {
      throw UnsupportedError(message);
    }
  }

  static CalculatorValue _collapseUnit(UnitValue value) {
    if (value.isUnitExpressionOnly) {
      return value;
    }
    if (value.dimension.isDimensionless) {
      return value.displayMagnitude;
    }
    return value;
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
    CalculatorValue right,
  ) {
    if (left is ComplexValue || right is ComplexValue) {
      return ComplexValue.promote(left).multiplyValue(right);
    }
    return ScalarValueMath.multiply(left, right);
  }

  static CalculatorValue _divideScalar(
    CalculatorValue left,
    CalculatorValue right,
  ) {
    if (left is ComplexValue || right is ComplexValue) {
      return ComplexValue.promote(left).divideValue(right);
    }
    return ScalarValueMath.divide(left, right);
  }

  static CalculatorValue _absScalar(CalculatorValue value) {
    if (value is ComplexValue) {
      return value.magnitude();
    }
    return ScalarValueMath.abs(value);
  }

  static CalculatorValue _squareRootScalar(CalculatorValue value) {
    if (value is ComplexValue) {
      return DoubleValue(math.sqrt(value.toDouble()));
    }
    return ScalarValueMath.squareRoot(value);
  }

  static CalculatorValue _integerPowerScalar(CalculatorValue value, int exponent) {
    if (value is ComplexValue) {
      return ComplexValue.promote(value).integerPower(exponent);
    }
    return ScalarValueMath.integerPower(value, exponent);
  }

  static int _compareScalar(CalculatorValue left, CalculatorValue right) {
    if (left is ComplexValue || right is ComplexValue) {
      return left.toDouble().compareTo(right.toDouble());
    }
    return ScalarValueMath.compare(left, right);
  }

  static bool _isZeroScalar(CalculatorValue value) {
    if (value is ComplexValue) {
      return ScalarValueMath.isZero(value.realPart) &&
          ScalarValueMath.isZero(value.imaginaryPart);
    }
    return ScalarValueMath.isZero(value);
  }
}
