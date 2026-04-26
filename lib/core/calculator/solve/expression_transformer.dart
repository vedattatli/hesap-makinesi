import '../ast_nodes.dart';

class ExpressionTransformer {
  const ExpressionTransformer._();

  static NumberNode zero({int position = 0}) =>
      NumberNode(rawValue: '0', value: 0, position: position);

  static NumberNode one({int position = 0}) =>
      NumberNode(rawValue: '1', value: 1, position: position);

  static NumberNode integer(int value, {int position = 0}) => NumberNode(
    rawValue: value.toString(),
    value: value.toDouble(),
    position: position,
  );

  static ExpressionNode clone(ExpressionNode node) {
    if (node is NumberNode) {
      return NumberNode(
        rawValue: node.rawValue,
        value: node.value,
        position: node.position,
      );
    }
    if (node is ConstantNode) {
      return ConstantNode(name: node.name, position: node.position);
    }
    if (node is UnaryOperationNode) {
      return UnaryOperationNode(
        operator: node.operator,
        operand: clone(node.operand),
        position: node.position,
      );
    }
    if (node is BinaryOperationNode) {
      return BinaryOperationNode(
        left: clone(node.left),
        operator: node.operator,
        right: clone(node.right),
        position: node.position,
      );
    }
    if (node is FunctionCallNode) {
      return FunctionCallNode(
        name: node.name,
        arguments: node.arguments.map(clone).toList(growable: false),
        position: node.position,
      );
    }
    if (node is EquationNode) {
      return EquationNode(
        left: clone(node.left),
        right: clone(node.right),
        position: node.position,
      );
    }
    if (node is ListLiteralNode) {
      return ListLiteralNode(
        elements: node.elements.map(clone).toList(growable: false),
        position: node.position,
      );
    }
    if (node is UnitAttachmentNode) {
      return UnitAttachmentNode(
        valueExpression: clone(node.valueExpression),
        unitExpression: clone(node.unitExpression),
        position: node.position,
      );
    }
    throw UnsupportedError('Unsupported AST node: ${node.runtimeType}');
  }

  static ExpressionNode substitute(
    ExpressionNode node,
    Map<String, ExpressionNode> replacements,
  ) {
    if (node is ConstantNode && replacements.containsKey(node.name)) {
      return clone(replacements[node.name]!);
    }
    if (node is NumberNode || node is ConstantNode) {
      return clone(node);
    }
    if (node is UnaryOperationNode) {
      return UnaryOperationNode(
        operator: node.operator,
        operand: substitute(node.operand, replacements),
        position: node.position,
      );
    }
    if (node is BinaryOperationNode) {
      return BinaryOperationNode(
        left: substitute(node.left, replacements),
        operator: node.operator,
        right: substitute(node.right, replacements),
        position: node.position,
      );
    }
    if (node is FunctionCallNode) {
      return FunctionCallNode(
        name: node.name,
        arguments: node.arguments
            .map((argument) => substitute(argument, replacements))
            .toList(growable: false),
        position: node.position,
      );
    }
    if (node is EquationNode) {
      return EquationNode(
        left: substitute(node.left, replacements),
        right: substitute(node.right, replacements),
        position: node.position,
      );
    }
    if (node is ListLiteralNode) {
      return ListLiteralNode(
        elements: node.elements
            .map((argument) => substitute(argument, replacements))
            .toList(growable: false),
        position: node.position,
      );
    }
    if (node is UnitAttachmentNode) {
      return UnitAttachmentNode(
        valueExpression: substitute(node.valueExpression, replacements),
        unitExpression: substitute(node.unitExpression, replacements),
        position: node.position,
      );
    }
    throw UnsupportedError('Unsupported AST node: ${node.runtimeType}');
  }

  static ExpressionNode negate(ExpressionNode node) {
    if (_isNumericLiteral(node, 0)) {
      return node;
    }
    if (node is UnaryOperationNode && node.operator == '-') {
      return node.operand;
    }
    if (node is NumberNode) {
      return NumberNode(
        rawValue: (-node.value).toStringAsFixed(0) == (-node.value).toString()
            ? (-node.value).toString()
            : '-${node.rawValue}',
        value: -node.value,
        position: node.position,
      );
    }
    return UnaryOperationNode(
      operator: '-',
      operand: node,
      position: node.position,
    );
  }

  static ExpressionNode add(ExpressionNode left, ExpressionNode right) {
    if (_isNumericLiteral(left, 0)) {
      return right;
    }
    if (_isNumericLiteral(right, 0)) {
      return left;
    }
    final folded = _foldNumeric(left, '+', right);
    return folded ??
        BinaryOperationNode(
          left: left,
          operator: '+',
          right: right,
          position: left.position,
        );
  }

  static ExpressionNode subtract(ExpressionNode left, ExpressionNode right) {
    if (_isNumericLiteral(right, 0)) {
      return left;
    }
    final folded = _foldNumeric(left, '-', right);
    return folded ??
        BinaryOperationNode(
          left: left,
          operator: '-',
          right: right,
          position: left.position,
        );
  }

  static ExpressionNode multiply(ExpressionNode left, ExpressionNode right) {
    if (_isNumericLiteral(left, 0) || _isNumericLiteral(right, 0)) {
      return zero(position: left.position);
    }
    if (_isNumericLiteral(left, 1)) {
      return right;
    }
    if (_isNumericLiteral(right, 1)) {
      return left;
    }
    if (_isNumericLiteral(left, -1)) {
      return negate(right);
    }
    if (_isNumericLiteral(right, -1)) {
      return negate(left);
    }
    final folded = _foldNumeric(left, '*', right);
    return folded ??
        BinaryOperationNode(
          left: left,
          operator: '*',
          right: right,
          position: left.position,
        );
  }

  static ExpressionNode divide(ExpressionNode left, ExpressionNode right) {
    if (_isNumericLiteral(left, 0)) {
      return zero(position: left.position);
    }
    if (_isNumericLiteral(right, 1)) {
      return left;
    }
    final folded = _foldNumeric(left, '/', right);
    return folded ??
        BinaryOperationNode(
          left: left,
          operator: '/',
          right: right,
          position: left.position,
        );
  }

  static ExpressionNode power(ExpressionNode base, ExpressionNode exponent) {
    if (_isNumericLiteral(exponent, 0)) {
      return one(position: exponent.position);
    }
    if (_isNumericLiteral(exponent, 1)) {
      return base;
    }
    final folded = _foldNumeric(base, '^', exponent);
    return folded ??
        BinaryOperationNode(
          left: base,
          operator: '^',
          right: exponent,
          position: base.position,
        );
  }

  static ExpressionNode call(
    String name,
    List<ExpressionNode> arguments, {
    int position = 0,
  }) {
    return FunctionCallNode(
      name: name,
      arguments: arguments,
      position: position,
    );
  }

  static bool isZero(ExpressionNode node) => _isNumericLiteral(node, 0);

  static bool isOne(ExpressionNode node) => _isNumericLiteral(node, 1);

  static int? asInteger(ExpressionNode node) {
    if (node is NumberNode && node.value == node.value.roundToDouble()) {
      return node.value.round();
    }
    if (node is UnaryOperationNode &&
        node.operator == '-' &&
        node.operand is NumberNode) {
      return -((node.operand as NumberNode).value.round());
    }
    return null;
  }

  static NumberNode? _foldNumeric(
    ExpressionNode left,
    String operator,
    ExpressionNode right,
  ) {
    if (left is! NumberNode || right is! NumberNode) {
      return null;
    }
    final value = switch (operator) {
      '+' => left.value + right.value,
      '-' => left.value - right.value,
      '*' => left.value * right.value,
      '/' => right.value == 0 ? double.nan : left.value / right.value,
      '^' => left.value == 0 && right.value == 0
          ? double.nan
          : left.value == left.value
          ? left.value == 0 && right.value < 0
              ? double.nan
              : left.value.pow(right.value)
          : double.nan,
      _ => double.nan,
    };
    if (!value.isFinite) {
      return null;
    }
    final raw = value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
    return NumberNode(rawValue: raw, value: value, position: left.position);
  }

  static bool _isNumericLiteral(ExpressionNode node, num value) {
    if (node is NumberNode) {
      return (node.value - value).abs() < 1e-12;
    }
    if (node is UnaryOperationNode &&
        node.operator == '-' &&
        node.operand is NumberNode) {
      return (((node.operand as NumberNode).value * -1) - value).abs() < 1e-12;
    }
    return false;
  }
}

extension on double {
  double pow(double exponent) => exponent == exponent.roundToDouble()
      ? _integerPow(this, exponent.round())
      : double.nan;

  static double _integerPow(double base, int exponent) {
    var result = 1.0;
    final positive = exponent.abs();
    for (var i = 0; i < positive; i++) {
      result *= base;
    }
    if (exponent < 0) {
      return 1 / result;
    }
    return result;
  }
}

