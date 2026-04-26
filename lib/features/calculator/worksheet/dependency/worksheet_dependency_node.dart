import '../../../../core/calculator/calculator.dart';
import '../worksheet_block.dart';

class WorksheetDependencyNode {
  const WorksheetDependencyNode({
    required this.block,
    required this.dependencies,
    required this.variableDependencies,
    required this.functionDependencies,
    this.definedSymbol,
    this.ast,
    this.parseError,
  });

  final WorksheetBlock block;
  final List<String> dependencies;
  final List<String> variableDependencies;
  final List<String> functionDependencies;
  final String? definedSymbol;
  final ExpressionNode? ast;
  final CalculationError? parseError;
}
