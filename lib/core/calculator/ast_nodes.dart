/// Base type for parsed calculator expressions.
abstract class ExpressionNode {
  /// Creates an expression node.
  const ExpressionNode({required this.position});

  /// Start offset of the node inside the original expression.
  final int position;
}

/// Represents a numeric literal.
class NumberNode extends ExpressionNode {
  /// Creates a numeric literal node.
  const NumberNode({
    required this.rawValue,
    required this.value,
    required super.position,
  });

  /// Original numeric literal as typed by the user.
  final String rawValue;

  /// Parsed floating-point value.
  final double value;
}

/// Represents a named constant such as `pi` or `e`.
class ConstantNode extends ExpressionNode {
  /// Creates a constant node.
  const ConstantNode({required this.name, required super.position});

  /// Constant identifier.
  final String name;
}

/// Represents a unary prefix operation.
class UnaryOperationNode extends ExpressionNode {
  /// Creates a unary operation node.
  const UnaryOperationNode({
    required this.operator,
    required this.operand,
    required super.position,
  });

  /// Unary operator such as `+` or `-`.
  final String operator;

  /// Operand of the unary operator.
  final ExpressionNode operand;
}

/// Represents an infix binary operation.
class BinaryOperationNode extends ExpressionNode {
  /// Creates a binary operation node.
  const BinaryOperationNode({
    required this.left,
    required this.operator,
    required this.right,
    required super.position,
  });

  /// Left operand.
  final ExpressionNode left;

  /// Operator symbol.
  final String operator;

  /// Right operand.
  final ExpressionNode right;
}

/// Represents a function call with zero or more arguments.
class FunctionCallNode extends ExpressionNode {
  /// Creates a function call node.
  const FunctionCallNode({
    required this.name,
    required this.arguments,
    required super.position,
  });

  /// Function identifier.
  final String name;

  /// Function arguments.
  final List<ExpressionNode> arguments;
}

/// Represents an equation with left and right expression sides.
class EquationNode extends ExpressionNode {
  /// Creates an equation node.
  const EquationNode({
    required this.left,
    required this.right,
    required super.position,
  });

  /// Left side of the equation.
  final ExpressionNode left;

  /// Right side of the equation.
  final ExpressionNode right;
}

/// Represents a bracket-based list literal such as `[1, 2, 3]`.
class ListLiteralNode extends ExpressionNode {
  /// Creates a list literal node.
  const ListLiteralNode({required this.elements, required super.position});

  /// Literal elements in source order.
  final List<ExpressionNode> elements;
}

/// Represents a scalar expression immediately followed by a unit expression.
class UnitAttachmentNode extends ExpressionNode {
  /// Creates a unit-attachment node such as `3 m` or `sqrt(2) m^2`.
  const UnitAttachmentNode({
    required this.valueExpression,
    required this.unitExpression,
    required super.position,
  });

  /// Magnitude expression to be interpreted in the attached unit.
  final ExpressionNode valueExpression;

  /// Unit-only expression attached to the magnitude.
  final ExpressionNode unitExpression;
}
