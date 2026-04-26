enum StatisticsErrorType {
  invalidDataset,
  invalidArgument,
  invalidProbabilityParameter,
  insufficientData,
  dimensionMismatch,
  unsupportedOperation,
  domainError,
  computationLimit,
}

class StatisticsException implements Exception {
  const StatisticsException(this.type, this.message);

  final StatisticsErrorType type;
  final String message;

  @override
  String toString() => message;
}
