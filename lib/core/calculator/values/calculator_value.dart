/// Supported calculator value kinds.
enum CalculatorValueKind {
  doubleValue,
  rational,
  symbolic,
  complex,
  unit,
  vector,
  matrix,
  dataset,
  regression,
  function,
  plot,
  equation,
  solveResult,
  expressionTransform,
}

/// Base type for calculator values produced by the evaluator.
abstract class CalculatorValue {
  const CalculatorValue();

  CalculatorValueKind get kind;

  bool get isExact;

  bool get isApproximate => !isExact;

  double toDouble();
}
