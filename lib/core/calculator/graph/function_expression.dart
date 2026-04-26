import '../ast_nodes.dart';
import '../src/expression_printer.dart';

/// Parsed function expression limited to a single graph variable.
class FunctionExpression {
  FunctionExpression({
    required this.originalExpression,
    required this.expressionAst,
    this.variableName = 'x',
    String? normalizedExpression,
  }) : normalizedExpression =
           normalizedExpression ?? ExpressionPrinter().print(expressionAst);

  final String variableName;
  final String originalExpression;
  final String normalizedExpression;
  final ExpressionNode expressionAst;
}
