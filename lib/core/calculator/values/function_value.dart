import '../graph/function_expression.dart';
import 'calculator_value.dart';

/// Calculator value that represents a graphable single-variable function.
class FunctionValue extends CalculatorValue {
  const FunctionValue({required this.function});

  final FunctionExpression function;

  String get variableName => function.variableName;

  String get originalExpression => function.originalExpression;

  String get normalizedExpression => function.normalizedExpression;

  @override
  CalculatorValueKind get kind => CalculatorValueKind.function;

  @override
  bool get isExact => true;

  @override
  double toDouble() => double.nan;
}
