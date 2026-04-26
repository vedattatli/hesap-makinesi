import '../ast_nodes.dart';
import '../calculation_error.dart';
import '../src/calculator_exception.dart';
import 'expression_transformer.dart';

class SymbolicIntegral {
  const SymbolicIntegral({this.maxNodeCount = 1000});

  final int maxNodeCount;

  ExpressionNode integrate(
    ExpressionNode node, {
    required String variableName,
  }) {
    final integral = _integrate(node, variableName: variableName);
    _guardNodeCount(integral);
    return integral;
  }

  ExpressionNode _integrate(
    ExpressionNode node, {
    required String variableName,
  }) {
    if (node is NumberNode) {
      return ExpressionTransformer.multiply(
        ExpressionTransformer.clone(node),
        ConstantNode(name: variableName, position: node.position),
      );
    }
    if (node is ConstantNode) {
      if (node.name == variableName) {
        return ExpressionTransformer.divide(
          ExpressionTransformer.power(
            ConstantNode(name: variableName, position: node.position),
            ExpressionTransformer.integer(2, position: node.position),
          ),
          ExpressionTransformer.integer(2, position: node.position),
        );
      }
      return ExpressionTransformer.multiply(
        ExpressionTransformer.clone(node),
        ConstantNode(name: variableName, position: node.position),
      );
    }
    if (node is UnaryOperationNode && node.operator == '-') {
      return ExpressionTransformer.negate(
        _integrate(node.operand, variableName: variableName),
      );
    }
    if (node is BinaryOperationNode) {
      switch (node.operator) {
        case '+':
          return ExpressionTransformer.add(
            _integrate(node.left, variableName: variableName),
            _integrate(node.right, variableName: variableName),
          );
        case '-':
          return ExpressionTransformer.subtract(
            _integrate(node.left, variableName: variableName),
            _integrate(node.right, variableName: variableName),
          );
        case '*':
          if (_isConstantLike(node.left, variableName: variableName)) {
            return ExpressionTransformer.multiply(
              ExpressionTransformer.clone(node.left),
              _integrate(node.right, variableName: variableName),
            );
          }
          if (_isConstantLike(node.right, variableName: variableName)) {
            return ExpressionTransformer.multiply(
              _integrate(node.left, variableName: variableName),
              ExpressionTransformer.clone(node.right),
            );
          }
          break;
        case '^':
          if (node.left is ConstantNode &&
              (node.left as ConstantNode).name == variableName) {
            final exponent = ExpressionTransformer.asInteger(node.right);
            if (exponent == -1) {
              throw CalculatorException(
                CalculationError(
                  type: CalculationErrorType.invalidIntegral,
                  message: 'integral(1/x, x) is intentionally unsupported symbolically in this phase.',
                  position: node.position,
                ),
              );
            }
            if (exponent != null) {
              final nextExponent = exponent + 1;
              return ExpressionTransformer.divide(
                ExpressionTransformer.power(
                  ConstantNode(name: variableName, position: node.position),
                  ExpressionTransformer.integer(nextExponent, position: node.position),
                ),
                ExpressionTransformer.integer(nextExponent, position: node.position),
              );
            }
          }
          break;
      }
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidIntegral,
          message: 'This integral form is not supported symbolically in this phase.',
          position: node.position,
        ),
      );
    }
    if (node is FunctionCallNode && node.arguments.length == 1) {
      final arg = node.arguments.single;
      if (!_isVariableNode(arg, variableName)) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidIntegral,
            message: 'Only direct single-variable integrals are supported symbolically in this phase.',
            position: node.position,
          ),
        );
      }
      switch (node.name.toLowerCase()) {
        case 'sin':
          return ExpressionTransformer.negate(
            ExpressionTransformer.call(
              'cos',
              <ExpressionNode>[ConstantNode(name: variableName, position: node.position)],
              position: node.position,
            ),
          );
        case 'cos':
          return ExpressionTransformer.call(
            'sin',
            <ExpressionNode>[ConstantNode(name: variableName, position: node.position)],
            position: node.position,
          );
        case 'exp':
          return ExpressionTransformer.call(
            'exp',
            <ExpressionNode>[ConstantNode(name: variableName, position: node.position)],
            position: node.position,
          );
      }
    }
    throw CalculatorException(
      CalculationError(
        type: CalculationErrorType.invalidIntegral,
        message: 'This integral form is not supported symbolically in this phase.',
        position: node.position,
      ),
    );
  }

  bool _isConstantLike(ExpressionNode node, {required String variableName}) {
    if (node is NumberNode) {
      return true;
    }
    if (node is ConstantNode) {
      return node.name != variableName;
    }
    return false;
  }

  bool _isVariableNode(ExpressionNode node, String variableName) {
    return node is ConstantNode && node.name == variableName;
  }

  void _guardNodeCount(ExpressionNode node) {
    var count = 0;
    void visit(ExpressionNode current) {
      count += 1;
      if (count > maxNodeCount) {
        throw const CalculatorException(
          CalculationError(
            type: CalculationErrorType.computationLimit,
            message: 'Integral transform exceeded the safe node limit.',
          ),
        );
      }
      if (current is UnaryOperationNode) {
        visit(current.operand);
      } else if (current is BinaryOperationNode) {
        visit(current.left);
        visit(current.right);
      } else if (current is FunctionCallNode) {
        for (final argument in current.arguments) {
          visit(argument);
        }
      }
    }

    visit(node);
  }
}

