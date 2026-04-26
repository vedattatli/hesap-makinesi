import 'calculator_value.dart';

/// Structured linear regression result.
class RegressionValue extends CalculatorValue {
  const RegressionValue({
    required this.slope,
    required this.intercept,
    required this.r,
    required this.rSquared,
    required this.sampleSize,
    required this.xMean,
    required this.yMean,
  });

  final CalculatorValue slope;
  final CalculatorValue intercept;
  final CalculatorValue r;
  final CalculatorValue rSquared;
  final int sampleSize;
  final CalculatorValue xMean;
  final CalculatorValue yMean;

  @override
  CalculatorValueKind get kind => CalculatorValueKind.regression;

  @override
  bool get isExact =>
      slope.isExact &&
      intercept.isExact &&
      r.isExact &&
      rSquared.isExact &&
      xMean.isExact &&
      yMean.isExact;

  @override
  double toDouble() => slope.toDouble();
}
