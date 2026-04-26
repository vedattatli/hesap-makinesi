/// App-level worksheet and export error codes.
enum WorksheetErrorCode {
  storageError,
  invalidWorksheet,
  invalidBlock,
  blockRunFailed,
  exportFailed,
  graphExportFailed,
  worksheetNotFound,
  blockNotFound,
  limitExceeded,
  duplicateSymbol,
  reservedSymbolName,
  invalidSymbolName,
  undefinedSymbol,
  dependencyCycle,
  invalidFunctionDefinition,
  invalidFunctionArity,
  recursiveFunction,
  staleDependency,
  worksheetScopeError,
  solveBlockFailed,
  invalidSolveBlock,
  solveDependencyError,
}

/// Typed worksheet error surfaced by worksheet controller and exporters.
class WorksheetError {
  const WorksheetError({
    required this.code,
    required this.message,
    this.details,
  });

  final WorksheetErrorCode code;
  final String message;
  final String? details;

  @override
  String toString() => 'WorksheetError($code, $message)';
}

/// Exception wrapper used inside worksheet infrastructure.
class WorksheetException implements Exception {
  const WorksheetException(this.error);

  final WorksheetError error;

  @override
  String toString() => 'WorksheetException(${error.code}, ${error.message})';
}
