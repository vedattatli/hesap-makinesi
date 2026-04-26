import '../../../../core/calculator/calculator.dart';
import 'worksheet_symbol.dart';

class WorksheetSymbolTable {
  const WorksheetSymbolTable({
    this.variableValues = const <String, CalculatorValue>{},
    this.functionDefinitions = const <String, ScopedFunctionDefinition>{},
    this.symbols = const <WorksheetSymbol>[],
  });

  final Map<String, CalculatorValue> variableValues;
  final Map<String, ScopedFunctionDefinition> functionDefinitions;
  final List<WorksheetSymbol> symbols;

  EvaluationScope toEvaluationScope({int maxCallDepth = 32}) {
    return EvaluationScope(
      variables: variableValues,
      functions: functionDefinitions,
      maxCallDepth: maxCallDepth,
    );
  }
}
