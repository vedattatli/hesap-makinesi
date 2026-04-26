/// Enumerates the error categories exposed by the calculator engine.
enum CalculationErrorType {
  syntaxError,
  unexpectedToken,
  missingParenthesis,
  divisionByZero,
  domainError,
  dimensionMismatch,
  invalidDataset,
  invalidStatisticsArgument,
  invalidProbabilityParameter,
  insufficientData,
  undefinedVariable,
  invalidFunctionExpression,
  invalidViewport,
  invalidPlotRange,
  unsupportedGraphValue,
  graphSamplingLimit,
  noRootFound,
  invalidGraphOperation,
  invalidEquation,
  invalidSolveVariable,
  unsupportedSolveForm,
  noSolution,
  infiniteSolutions,
  solverDidNotConverge,
  polynomialDegreeLimit,
  invalidDerivative,
  invalidIntegral,
  unsupportedExpressionTransform,
  unsupportedCasTransform,
  polynomialExpansionLimit,
  factorizationLimit,
  invalidSystem,
  nonlinearSystemUnsupported,
  singularSystem,
  invalidInequality,
  unsupportedInequality,
  unknownUnit,
  invalidUnitConversion,
  invalidUnitOperation,
  affineUnitOperation,
  invalidMatrixShape,
  singularMatrix,
  unsupportedOperation,
  unknownFunction,
  unknownConstant,
  invalidArgumentCount,
  computationLimit,
  internalError,
}

/// Represents a typed, explainable calculation failure.
class CalculationError {
  /// Creates a new calculation error.
  const CalculationError({
    required this.type,
    required this.message,
    this.position,
    this.suggestion,
  });

  /// Kind of error that occurred.
  final CalculationErrorType type;

  /// Human readable explanation for the user.
  final String message;

  /// Optional input offset where the error occurred.
  final int? position;

  /// Optional follow-up hint for the user.
  final String? suggestion;
}
