import 'calculator_value.dart';

/// Approximate floating-point calculator value.
class DoubleValue extends CalculatorValue {
  const DoubleValue(double value) : value = value == -0.0 ? 0.0 : value;

  final double value;

  @override
  CalculatorValueKind get kind => CalculatorValueKind.doubleValue;

  @override
  bool get isExact => false;

  bool get isFinite => value.isFinite;

  @override
  double toDouble() => value;
}
