import '../solve/equation_model.dart';
import 'calculator_value.dart';

class EquationValue extends CalculatorValue {
  const EquationValue({required this.equation});

  final EquationModel equation;

  String get displayEquation => equation.displayEquation;

  @override
  CalculatorValueKind get kind => CalculatorValueKind.equation;

  @override
  bool get isExact => true;

  @override
  double toDouble() => double.nan;
}

