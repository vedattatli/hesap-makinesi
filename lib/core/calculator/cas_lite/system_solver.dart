import '../ast_nodes.dart';
import '../calculation_context.dart';
import '../calculation_error.dart';
import '../scope/evaluation_scope.dart';
import '../solve/expression_transformer.dart';
import '../src/calculator_exception.dart';
import '../src/expression_evaluator.dart';
import '../src/expression_printer.dart';
import '../values/calculator_value.dart';
import '../values/complex_value.dart';
import '../values/dataset_value.dart';
import '../values/double_value.dart';
import '../values/expression_transform_value.dart';
import '../values/function_value.dart';
import '../values/linear_algebra.dart';
import '../values/matrix_value.dart';
import '../values/rational_value.dart';
import '../values/regression_value.dart';
import '../values/scalar_value_math.dart';
import '../values/solve_result_value.dart';
import '../values/symbolic_value.dart';
import '../values/system_solve_result_value.dart';
import '../values/unit_value.dart';
import '../values/vector_value.dart';
import 'cas_step.dart';

class CasSystemSolver {
  const CasSystemSolver();

  static const int maxVariables = 6;

  VectorValue linsolve(MatrixValue matrix, VectorValue vector) {
    if (!matrix.isSquare) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidSystem,
          message: 'linsolve requires a square coefficient matrix.',
        ),
      );
    }
    if (matrix.rowCount != vector.length) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.dimensionMismatch,
          message: 'linsolve requires vector length to match matrix row count.',
        ),
      );
    }
    try {
      return LinearAlgebra.multiplyMatrixVector(
        LinearAlgebra.inverse(matrix),
        vector,
      );
    } on LinearAlgebraException catch (error) {
      throw CalculatorException(
        CalculationError(
          type: error.type == LinearAlgebraErrorType.singularMatrix
              ? CalculationErrorType.singularSystem
              : CalculationErrorType.invalidSystem,
          message: error.message,
        ),
      );
    }
  }

  SystemSolveResultValue solveSystem({
    required List<ExpressionNode> equations,
    required List<String> variables,
    required CalculationContext context,
    EvaluationScope scope = const EvaluationScope(),
  }) {
    if (equations.isEmpty || variables.isEmpty) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidSystem,
          message: 'solveSystem requires equations and vars(...).',
        ),
      );
    }
    if (variables.length > maxVariables) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidSystem,
          message: 'CAS-lite solveSystem supports at most 6 variables.',
        ),
      );
    }
    if (equations.length != variables.length) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidSystem,
          message:
              'CAS-lite solveSystem currently supports square linear systems only.',
        ),
      );
    }

    final differenceAsts = equations
        .map(_differenceAst)
        .toList(growable: false);
    final rows = <List<CalculatorValue>>[];
    final constants = <CalculatorValue>[];
    for (final equation in differenceAsts) {
      final zero = _evaluateAt(
        equation,
        variables,
        List<CalculatorValue>.filled(variables.length, RationalValue.zero),
        context,
        scope,
      );
      final coefficients = <CalculatorValue>[];
      for (var index = 0; index < variables.length; index++) {
        final basis = List<CalculatorValue>.filled(
          variables.length,
          RationalValue.zero,
        );
        basis[index] = RationalValue.one;
        final value = _evaluateAt(equation, variables, basis, context, scope);
        coefficients.add(ScalarValueMath.subtract(value, zero));

        final doubled = List<CalculatorValue>.filled(
          variables.length,
          RationalValue.zero,
        );
        doubled[index] = RationalValue.fromInt(2);
        final doubledValue = _evaluateAt(
          equation,
          variables,
          doubled,
          context,
          scope,
        );
        final expected = ScalarValueMath.add(
          zero,
          ScalarValueMath.multiply(RationalValue.fromInt(2), coefficients.last),
        );
        if (!_sameScalar(doubledValue, expected)) {
          _throwNonlinear(equation);
        }
      }

      final ones = List<CalculatorValue>.filled(
        variables.length,
        RationalValue.one,
      );
      final allOnes = _evaluateAt(equation, variables, ones, context, scope);
      final expectedAll = coefficients.fold<CalculatorValue>(
        zero,
        (current, coefficient) => ScalarValueMath.add(current, coefficient),
      );
      if (!_sameScalar(allOnes, expectedAll)) {
        _throwNonlinear(equation);
      }

      rows.add(coefficients);
      constants.add(ScalarValueMath.negate(zero));
    }

    final solution = linsolve(MatrixValue(rows), VectorValue(constants));
    return SystemSolveResultValue(
      variables: List<String>.unmodifiable(variables),
      solutions: solution.elements,
      method: 'linearSystem',
      steps: <CasStep>[
        CasStep(
          title: 'Detected linear system',
          detail:
              '${equations.length} equations, ${variables.length} variables',
        ),
        const CasStep(title: 'Built coefficient matrix and constant vector'),
        const CasStep(title: 'Solved with guarded matrix inverse'),
      ],
    );
  }

  List<String> parseVars(ExpressionNode node) {
    if (node is! FunctionCallNode || node.name.toLowerCase() != 'vars') {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidSystem,
          message: 'solveSystem expects vars(x, y, ...) as the last argument.',
        ),
      );
    }
    final names = <String>[];
    for (final argument in node.arguments) {
      if (argument is! ConstantNode) {
        throw const CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidSystem,
            message: 'vars(...) may contain variable identifiers only.',
          ),
        );
      }
      if (names.contains(argument.name)) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidSystem,
            message: 'Duplicate variable "${argument.name}" in vars(...).',
          ),
        );
      }
      names.add(argument.name);
    }
    return List<String>.unmodifiable(names);
  }

  ExpressionNode _differenceAst(ExpressionNode node) {
    if (node is EquationNode) {
      return ExpressionTransformer.subtract(node.left, node.right);
    }
    if (node is FunctionCallNode &&
        node.name.toLowerCase() == 'eq' &&
        node.arguments.length == 2) {
      return ExpressionTransformer.subtract(
        node.arguments[0],
        node.arguments[1],
      );
    }
    return node;
  }

  CalculatorValue _evaluateAt(
    ExpressionNode expression,
    List<String> variables,
    List<CalculatorValue> values,
    CalculationContext context,
    EvaluationScope scope,
  ) {
    final variableValues = <String, CalculatorValue>{};
    for (var index = 0; index < variables.length; index++) {
      variableValues[variables[index]] = values[index];
    }
    final evaluator = ExpressionEvaluator(
      context,
      scope: scope.withVariables(variableValues),
    );
    final value = evaluator.evaluate(expression).value;
    return _requireSupportedScalar(value, expression.position);
  }

  CalculatorValue _requireSupportedScalar(CalculatorValue value, int position) {
    if (value is RationalValue ||
        value is DoubleValue ||
        value is SymbolicValue) {
      return ScalarValueMath.collapse(value);
    }
    if (value is ComplexValue ||
        value is UnitValue ||
        value is VectorValue ||
        value is MatrixValue ||
        value is DatasetValue ||
        value is RegressionValue ||
        value is SolveResultValue ||
        value is ExpressionTransformValue ||
        value is FunctionValue ||
        value is SystemSolveResultValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidSystem,
          message:
              'Linear system equations must evaluate to real scalar values.',
          position: position,
        ),
      );
    }
    return ScalarValueMath.collapse(value);
  }

  void _throwNonlinear(ExpressionNode equation) {
    throw CalculatorException(
      CalculationError(
        type: CalculationErrorType.nonlinearSystemUnsupported,
        message: 'CAS-lite solveSystem supports linear systems only.',
        position: equation.position,
        suggestion:
            'Use solve(...) per equation or keep each equation linear in vars(...).',
      ),
    );
  }

  bool _sameScalar(CalculatorValue left, CalculatorValue right) {
    if (left is RationalValue && right is RationalValue) {
      return left.compareTo(right) == 0;
    }
    return (left.toDouble() - right.toDouble()).abs() < 1e-9;
  }

  String equationDisplay(ExpressionNode node) =>
      ExpressionPrinter().print(node);
}
