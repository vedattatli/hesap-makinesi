import '../ast_nodes.dart';
import '../calculation_context.dart';
import '../calculation_error.dart';
import '../scope/evaluation_scope.dart';
import '../src/calculator_exception.dart';
import '../src/expression_evaluator.dart';
import '../values/calculator_value.dart';
import '../values/complex_value.dart';
import '../values/double_value.dart';
import '../values/equation_value.dart';
import '../values/expression_transform_value.dart';
import '../values/function_value.dart';
import '../values/matrix_value.dart';
import '../values/rational_value.dart';
import '../values/regression_value.dart';
import '../values/scalar_value_math.dart';
import '../values/solve_result_value.dart';
import '../values/symbolic_value.dart';
import '../values/unit_value.dart';
import '../values/vector_value.dart';
import 'expression_transformer.dart';
import 'polynomial.dart';

class PolynomialDetector {
  const PolynomialDetector({
    this.maxExactDegree = 2,
    this.maxSupportedExpansionDegree = 12,
  });

  final int maxExactDegree;
  final int maxSupportedExpansionDegree;

  Polynomial? detect(
    ExpressionNode node, {
    required String variableName,
    required CalculationContext context,
    EvaluationScope scope = const EvaluationScope(),
  }) {
    return _detect(
      node,
      variableName: variableName,
      context: context,
      scope: scope,
      activeFunctions: const <String>{},
    );
  }

  Polynomial? _detect(
    ExpressionNode node, {
    required String variableName,
    required CalculationContext context,
    required EvaluationScope scope,
    required Set<String> activeFunctions,
  }) {
    if (node is NumberNode) {
      return Polynomial(
        variableName: variableName,
        coefficients: <int, CalculatorValue>{
          0: _constantValue(node, context: context, scope: scope),
        },
      );
    }
    if (node is ConstantNode) {
      if (node.name == variableName) {
        return Polynomial(
          variableName: variableName,
          coefficients: <int, CalculatorValue>{
            1: RationalValue.one,
          },
        );
      }
      return Polynomial(
        variableName: variableName,
        coefficients: <int, CalculatorValue>{
          0: _constantValue(node, context: context, scope: scope),
        },
      );
    }
    if (node is UnaryOperationNode) {
      final operand = _detect(
        node.operand,
        variableName: variableName,
        context: context,
        scope: scope,
        activeFunctions: activeFunctions,
      );
      if (operand == null) {
        return null;
      }
      if (node.operator == '-') {
        return operand.scale(RationalValue.fromInt(-1));
      }
      return operand;
    }
    if (node is BinaryOperationNode) {
      final left = _detect(
        node.left,
        variableName: variableName,
        context: context,
        scope: scope,
        activeFunctions: activeFunctions,
      );
      final right = _detect(
        node.right,
        variableName: variableName,
        context: context,
        scope: scope,
        activeFunctions: activeFunctions,
      );
      switch (node.operator) {
        case '+':
          if (left == null || right == null) {
            return null;
          }
          return left.add(right);
        case '-':
          if (left == null || right == null) {
            return null;
          }
          return left.subtract(right);
        case '*':
          if (left == null || right == null) {
            return null;
          }
          final product = left.multiply(right);
          if (product.degree > maxSupportedExpansionDegree) {
            return null;
          }
          return product;
        case '/':
          if (left == null || right == null || right.degree != 0) {
            return null;
          }
          return left.divideByScalar(right.coefficientOf(0));
        case '^':
          if (left == null || right == null || right.degree != 0) {
            return null;
          }
          final exponentValue = right.coefficientOf(0);
          final exponent = _tryIntegerExponent(exponentValue);
          if (exponent == null) {
            return null;
          }
          if (exponent < 0 || exponent > maxSupportedExpansionDegree) {
            return null;
          }
          var result = Polynomial(
            variableName: variableName,
            coefficients: <int, CalculatorValue>{0: RationalValue.one},
          );
          for (var index = 0; index < exponent; index++) {
            result = result.multiply(left);
            if (result.degree > maxSupportedExpansionDegree) {
              return null;
            }
          }
          return result;
        default:
          return null;
      }
    }
    if (node is FunctionCallNode) {
      final scopedFunction = scope.resolveFunction(node.name);
      if (scopedFunction == null) {
        return null;
      }
      if (activeFunctions.contains(scopedFunction.identityToken)) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidFunctionExpression,
            message:
                'Recursive function "${scopedFunction.name}" is not supported in polynomial solving.',
            position: node.position,
          ),
        );
      }
      if (scopedFunction.parameters.length != node.arguments.length) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidArgumentCount,
            message:
                'Function "${scopedFunction.name}" expects ${scopedFunction.parameters.length} argument(s) but got ${node.arguments.length}.',
            position: node.position,
          ),
        );
      }
      final replacements = <String, ExpressionNode>{};
      for (var i = 0; i < node.arguments.length; i++) {
        replacements[scopedFunction.parameters[i]] = node.arguments[i];
      }
      final substituted = ExpressionTransformer.substitute(
        scopedFunction.bodyAst,
        replacements,
      );
      return _detect(
        substituted,
        variableName: variableName,
        context: context,
        scope: scope,
        activeFunctions: <String>{
          ...activeFunctions,
          scopedFunction.identityToken,
        },
      );
    }
    return null;
  }

  CalculatorValue _constantValue(
    ExpressionNode node, {
    required CalculationContext context,
    required EvaluationScope scope,
  }) {
    if (node is NumberNode) {
      return RationalValue.parseLiteral(node.rawValue);
    }
    final evaluator = ExpressionEvaluator(context, scope: scope);
    final evaluated = evaluator.evaluate(node).value;
    if (evaluated is RationalValue ||
        evaluated is SymbolicValue ||
        evaluated is DoubleValue) {
      return evaluated;
    }
    if (evaluated is ComplexValue ||
        evaluated is UnitValue ||
        evaluated is VectorValue ||
        evaluated is MatrixValue ||
        evaluated is RegressionValue ||
        evaluated is SolveResultValue ||
        evaluated is EquationValue ||
        evaluated is ExpressionTransformValue ||
        evaluated is FunctionValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedSolveForm,
          message:
              'Polynomial coefficients must resolve to real scalar constants in this phase.',
          position: node.position,
        ),
      );
    }
    return ScalarValueMath.collapse(evaluated);
  }

  int? _tryIntegerExponent(CalculatorValue value) {
    if (value is RationalValue && value.isInteger) {
      return value.numerator.toInt();
    }
    final numeric = value.toDouble();
    if (!numeric.isFinite) {
      return null;
    }
    final rounded = numeric.round();
    if ((numeric - rounded).abs() > 1e-10) {
      return null;
    }
    return rounded;
  }
}
