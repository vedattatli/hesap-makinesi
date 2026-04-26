import '../cas_lite/cas_step.dart';
import 'calculator_value.dart';

class SystemSolveResultValue extends CalculatorValue {
  const SystemSolveResultValue({
    required this.variables,
    required this.solutions,
    required this.method,
    this.steps = const <CasStep>[],
    this.warnings = const <String>[],
  });

  final List<String> variables;
  final List<CalculatorValue> solutions;
  final String method;
  final List<CasStep> steps;
  final List<String> warnings;

  @override
  CalculatorValueKind get kind => CalculatorValueKind.solveResult;

  @override
  bool get isExact => solutions.every((solution) => solution.isExact);

  @override
  double toDouble() => double.nan;
}
