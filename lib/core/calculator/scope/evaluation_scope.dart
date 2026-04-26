import '../values/calculator_value.dart';
import 'scoped_function_definition.dart';

/// Optional scoped symbol table used by graphing and worksheet execution.
class EvaluationScope {
  const EvaluationScope({
    this.variables = const <String, CalculatorValue>{},
    this.functions = const <String, ScopedFunctionDefinition>{},
    this.parent,
    this.callStack = const <String>[],
    this.maxCallDepth = defaultMaxCallDepth,
  });

  static const int defaultMaxCallDepth = 32;

  final Map<String, CalculatorValue> variables;
  final Map<String, ScopedFunctionDefinition> functions;
  final EvaluationScope? parent;
  final List<String> callStack;
  final int maxCallDepth;

  CalculatorValue? resolveVariable(String name) {
    return variables[name] ?? parent?.resolveVariable(name);
  }

  ScopedFunctionDefinition? resolveFunction(String name) {
    return functions[name] ?? parent?.resolveFunction(name);
  }

  bool isFunctionActive(ScopedFunctionDefinition function) {
    return callStack.contains(function.identityToken);
  }

  EvaluationScope withVariable(String name, CalculatorValue value) {
    return withVariables(<String, CalculatorValue>{name: value});
  }

  EvaluationScope withVariables(Map<String, CalculatorValue> values) {
    return EvaluationScope(
      variables: Map<String, CalculatorValue>.unmodifiable(values),
      parent: this,
      callStack: callStack,
      maxCallDepth: maxCallDepth,
    );
  }

  EvaluationScope withFunction(ScopedFunctionDefinition function) {
    return withFunctions(<String, ScopedFunctionDefinition>{
      function.name: function,
    });
  }

  EvaluationScope withFunctions(
    Map<String, ScopedFunctionDefinition> definitions,
  ) {
    return EvaluationScope(
      functions: Map<String, ScopedFunctionDefinition>.unmodifiable(definitions),
      parent: this,
      callStack: callStack,
      maxCallDepth: maxCallDepth,
    );
  }

  EvaluationScope enterFunction(ScopedFunctionDefinition function) {
    return EvaluationScope(
      parent: this,
      callStack: List<String>.unmodifiable(<String>[
        ...callStack,
        function.identityToken,
      ]),
      maxCallDepth: maxCallDepth,
    );
  }
}
