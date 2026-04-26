import '../scope/evaluation_scope.dart';
import '../values/calculator_value.dart';

/// Scoped variable bindings used only for graph and function evaluation.
class GraphVariableScope extends EvaluationScope {
  const GraphVariableScope([
    Map<String, CalculatorValue> variables = const <String, CalculatorValue>{},
  ]) : super(variables: variables);

  @override
  GraphVariableScope withVariable(String name, CalculatorValue value) {
    return GraphVariableScope(<String, CalculatorValue>{
      ...variables,
      name: value,
    });
  }
}
