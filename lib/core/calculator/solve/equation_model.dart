import '../ast_nodes.dart';
import '../src/expression_printer.dart';

class EquationModel {
  EquationModel({
    required this.left,
    required this.right,
    String? normalizedLeft,
    String? normalizedRight,
  }) : normalizedLeft = normalizedLeft ?? ExpressionPrinter().print(left),
       normalizedRight = normalizedRight ?? ExpressionPrinter().print(right);

  factory EquationModel.fromNode(ExpressionNode node) {
    if (node is EquationNode) {
      return EquationModel(left: node.left, right: node.right);
    }
    return EquationModel(
      left: node,
      right: NumberNode(rawValue: '0', value: 0, position: node.position),
      normalizedRight: '0',
    );
  }

  final ExpressionNode left;
  final ExpressionNode right;
  final String normalizedLeft;
  final String normalizedRight;

  String get displayEquation => '$normalizedLeft = $normalizedRight';

  ExpressionNode toDifferenceAst() {
    return BinaryOperationNode(
      left: left,
      operator: '-',
      right: right,
      position: left.position,
    );
  }
}

