import '../calculation_error.dart';

class CalculatorException implements Exception {
  const CalculatorException(this.error);

  final CalculationError error;
}
