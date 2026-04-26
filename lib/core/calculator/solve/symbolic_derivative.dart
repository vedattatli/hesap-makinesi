import '../ast_nodes.dart';
import '../calculation_error.dart';
import '../src/calculator_exception.dart';
import 'expression_transformer.dart';

class SymbolicDerivative {
  const SymbolicDerivative({this.maxNodeCount = 1000});

  final int maxNodeCount;

  ExpressionNode differentiate(
    ExpressionNode node, {
    required String variableName,
  }) {
    final derivative = _differentiate(node, variableName: variableName);
    _guardNodeCount(derivative);
    return derivative;
  }

  ExpressionNode _differentiate(
    ExpressionNode node, {
    required String variableName,
  }) {
    if (node is NumberNode) {
      return ExpressionTransformer.zero(position: node.position);
    }
    if (node is ConstantNode) {
      return node.name == variableName
          ? ExpressionTransformer.one(position: node.position)
          : ExpressionTransformer.zero(position: node.position);
    }
    if (node is UnaryOperationNode) {
      if (node.operator == '-') {
        return ExpressionTransformer.negate(
          _differentiate(node.operand, variableName: variableName),
        );
      }
      return _differentiate(node.operand, variableName: variableName);
    }
    if (node is BinaryOperationNode) {
      final leftPrime = _differentiate(node.left, variableName: variableName);
      final rightPrime = _differentiate(node.right, variableName: variableName);
      switch (node.operator) {
        case '+':
          return ExpressionTransformer.add(leftPrime, rightPrime);
        case '-':
          return ExpressionTransformer.subtract(leftPrime, rightPrime);
        case '*':
          return ExpressionTransformer.add(
            ExpressionTransformer.multiply(leftPrime, ExpressionTransformer.clone(node.right)),
            ExpressionTransformer.multiply(ExpressionTransformer.clone(node.left), rightPrime),
          );
        case '/':
          return ExpressionTransformer.divide(
            ExpressionTransformer.subtract(
              ExpressionTransformer.multiply(leftPrime, ExpressionTransformer.clone(node.right)),
              ExpressionTransformer.multiply(ExpressionTransformer.clone(node.left), rightPrime),
            ),
            ExpressionTransformer.power(
              ExpressionTransformer.clone(node.right),
              ExpressionTransformer.integer(2, position: node.position),
            ),
          );
        case '^':
          final exponent = ExpressionTransformer.asInteger(node.right);
          if (exponent != null) {
            return ExpressionTransformer.multiply(
              ExpressionTransformer.multiply(
                ExpressionTransformer.integer(exponent, position: node.position),
                ExpressionTransformer.power(
                  ExpressionTransformer.clone(node.left),
                  ExpressionTransformer.integer(exponent - 1, position: node.position),
                ),
              ),
              leftPrime,
            );
          }
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.unsupportedExpressionTransform,
              message: 'Only integer powers are supported by diff in this phase.',
              position: node.position,
            ),
          );
        default:
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.unsupportedExpressionTransform,
              message: 'Unsupported derivative operator: ${node.operator}.',
              position: node.position,
            ),
          );
      }
    }
    if (node is FunctionCallNode) {
      if (node.arguments.length != 1) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.unsupportedExpressionTransform,
            message: 'Only single-argument symbolic derivatives are supported in this phase.',
            position: node.position,
          ),
        );
      }
      final inner = node.arguments.single;
      final innerPrime = _differentiate(inner, variableName: variableName);
      ExpressionNode outer;
      switch (node.name.toLowerCase()) {
        case 'sin':
          outer = ExpressionTransformer.call(
            'cos',
            <ExpressionNode>[ExpressionTransformer.clone(inner)],
            position: node.position,
          );
        case 'cos':
          outer = ExpressionTransformer.negate(
            ExpressionTransformer.call(
              'sin',
              <ExpressionNode>[ExpressionTransformer.clone(inner)],
              position: node.position,
            ),
          );
        case 'tan':
          outer = ExpressionTransformer.divide(
            ExpressionTransformer.one(position: node.position),
            ExpressionTransformer.power(
              ExpressionTransformer.call(
                'cos',
                <ExpressionNode>[ExpressionTransformer.clone(inner)],
                position: node.position,
              ),
              ExpressionTransformer.integer(2, position: node.position),
            ),
          );
        case 'exp':
          outer = ExpressionTransformer.call(
            'exp',
            <ExpressionNode>[ExpressionTransformer.clone(inner)],
            position: node.position,
          );
        case 'ln':
          outer = ExpressionTransformer.divide(
            ExpressionTransformer.one(position: node.position),
            ExpressionTransformer.clone(inner),
          );
        default:
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.unsupportedExpressionTransform,
              message: 'diff does not support ${node.name} in this phase.',
              position: node.position,
            ),
          );
      }
      if (ExpressionTransformer.isOne(innerPrime)) {
        return outer;
      }
      return ExpressionTransformer.multiply(outer, innerPrime);
    }
    throw CalculatorException(
      CalculationError(
        type: CalculationErrorType.unsupportedExpressionTransform,
        message: 'Unsupported derivative form: ${node.runtimeType}.',
        position: node.position,
      ),
    );
  }

  void _guardNodeCount(ExpressionNode node) {
    var count = 0;
    void visit(ExpressionNode current) {
      count += 1;
      if (count > maxNodeCount) {
        throw const CalculatorException(
          CalculationError(
            type: CalculationErrorType.computationLimit,
            message: 'Derivative transform exceeded the safe node limit.',
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

