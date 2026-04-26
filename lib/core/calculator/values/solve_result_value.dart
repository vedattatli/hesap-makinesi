import '../calculation_domain.dart';
import '../solve/equation_model.dart';
import '../solve/solve_method.dart';
import 'calculator_value.dart';

class SolveResultValue extends CalculatorValue {
  const SolveResultValue({
    required this.variableName,
    required this.equation,
    required this.solutions,
    required this.method,
    required this.domain,
    required this.exact,
    this.warnings = const <String>[],
    this.noSolutionReason,
    this.infiniteSolutions = false,
    this.intervalMin,
    this.intervalMax,
  });

  final String variableName;
  final EquationModel equation;
  final List<CalculatorValue> solutions;
  final SolveMethod method;
  final CalculationDomain domain;
  final bool exact;
  final List<String> warnings;
  final String? noSolutionReason;
  final bool infiniteSolutions;
  final double? intervalMin;
  final double? intervalMax;

  bool get hasSolutions => solutions.isNotEmpty;
  bool get hasNoSolution => !infiniteSolutions && solutions.isEmpty;

  @override
  CalculatorValueKind get kind => CalculatorValueKind.solveResult;

  @override
  bool get isExact => exact;

  @override
  double toDouble() {
    if (solutions.length == 1) {
      return solutions.single.toDouble();
    }
    return double.nan;
  }
}

