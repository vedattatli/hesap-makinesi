import 'calculation_error.dart';
import 'calculation_result.dart';

/// Wraps either a successful calculation result or a typed error.
class CalculationOutcome {
  /// Creates a successful outcome.
  const CalculationOutcome.success(CalculationResult this.result)
    : error = null;

  /// Creates a failed outcome.
  const CalculationOutcome.failure(CalculationError this.error) : result = null;

  /// Successful result, when present.
  final CalculationResult? result;

  /// Error payload, when present.
  final CalculationError? error;

  /// Returns `true` when evaluation completed successfully.
  bool get isSuccess => result != null;

  /// Returns `true` when evaluation failed.
  bool get isFailure => error != null;
}
