import '../ast_nodes.dart';

class ExpressionPrinter {
  String print(ExpressionNode node) {
    return _print(node, _Precedence.none);
  }

  String _print(ExpressionNode node, int parentPrecedence) {
    if (node is NumberNode) {
      return node.rawValue;
    }

    if (node is ConstantNode) {
      return node.name;
    }

    if (node is UnaryOperationNode) {
      final operand = _print(node.operand, _Precedence.unary);
      final text = '${node.operator}$operand';
      if (_Precedence.unary < parentPrecedence) {
        return '($text)';
      }
      return text;
    }

    if (node is BinaryOperationNode) {
      final precedence = _binaryPrecedence(node.operator);
      final left = _print(node.left, precedence);
      final rightPrecedence = node.operator == '^'
          ? precedence - 1
          : precedence + 1;
      final right = _print(node.right, rightPrecedence);
      final text = '$left ${node.operator} $right';
      if (precedence < parentPrecedence) {
        return '($text)';
      }
      return text;
    }

    if (node is FunctionCallNode) {
      final arguments = node.arguments
          .map((argument) {
            return _print(argument, _Precedence.none);
          })
          .join(', ');
      return '${node.name}($arguments)';
    }

    if (node is EquationNode) {
      final left = _print(node.left, _Precedence.none);
      final right = _print(node.right, _Precedence.none);
      return '$left = $right';
    }

    if (node is ListLiteralNode) {
      final elements = node.elements
          .map((element) => _print(element, _Precedence.none))
          .join(', ');
      return '[$elements]';
    }

    if (node is UnitAttachmentNode) {
      final value = _print(node.valueExpression, _Precedence.none);
      final unit = _print(node.unitExpression, _Precedence.none);
      return '$value $unit';
    }

    throw UnsupportedError('Unsupported node: ${node.runtimeType}');
  }

  int _binaryPrecedence(String operator) {
    return switch (operator) {
      '+' || '-' => _Precedence.additive,
      '*' || '/' => _Precedence.multiplicative,
      '^' => _Precedence.power,
      _ => _Precedence.none,
    };
  }
}

class _Precedence {
  static const none = 0;
  static const additive = 1;
  static const multiplicative = 2;
  static const unary = 3;
  static const power = 4;
}
