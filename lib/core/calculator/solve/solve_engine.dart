import '../ast_nodes.dart';
import '../calculation_context.dart';
import '../calculation_error.dart';
import '../graph/function_expression.dart';
import '../graph/graph_analysis.dart';
import '../scope/evaluation_scope.dart';
import '../src/calculator_exception.dart';
import '../src/expression_evaluator.dart';
import '../src/expression_printer.dart';
import '../values/calculator_value.dart';
import '../values/double_value.dart';
import '../values/equation_value.dart';
import '../values/expression_transform_value.dart';
import '../values/solve_result_value.dart';
import 'equation_model.dart';
import 'polynomial_detector.dart';
import 'polynomial_solver.dart';
import 'solve_method.dart';
import 'symbolic_derivative.dart';
import 'symbolic_integral.dart';

class SolveEngine {
  const SolveEngine({
    PolynomialDetector polynomialDetector = const PolynomialDetector(),
    PolynomialSolver polynomialSolver = const PolynomialSolver(),
    SymbolicDerivative derivative = const SymbolicDerivative(),
    SymbolicIntegral integral = const SymbolicIntegral(),
    GraphAnalysis graphAnalysis = const GraphAnalysis(),
  }) : _polynomialDetector = polynomialDetector,
       _polynomialSolver = polynomialSolver,
       _derivative = derivative,
       _integral = integral,
       _graphAnalysis = graphAnalysis;

  final PolynomialDetector _polynomialDetector;
  final PolynomialSolver _polynomialSolver;
  final SymbolicDerivative _derivative;
  final SymbolicIntegral _integral;
  final GraphAnalysis _graphAnalysis;

  EquationValue equationValue(ExpressionNode node) {
    return EquationValue(equation: EquationModel.fromNode(node));
  }

  SolveResultValue solve(
    ExpressionNode node, {
    required String variableName,
    required CalculationContext context,
    EvaluationScope scope = const EvaluationScope(),
    double? intervalMin,
    double? intervalMax,
    bool numericOnly = false,
  }) {
    final equation = EquationModel.fromNode(node);
    final differenceAst = equation.toDifferenceAst();
    final polynomial = numericOnly
        ? null
        : _polynomialDetector.detect(
            differenceAst,
            variableName: variableName,
            context: context,
            scope: scope,
          );

    if (!numericOnly && polynomial != null) {
      if (polynomial.degree == 0 &&
          !_expressionContainsVariable(differenceAst, variableName)) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidSolveVariable,
            message: 'Variable $variableName does not appear in the equation.',
            position: node.position,
          ),
        );
      }
      final outcome = _polynomialSolver.solve(
        polynomial,
        domain: context.calculationDomain,
      );
      return SolveResultValue(
        variableName: variableName,
        equation: equation,
        solutions: outcome.solutions,
        method: outcome.method,
        domain: context.calculationDomain,
        exact: outcome.exact,
        noSolutionReason: outcome.noSolutionReason,
        infiniteSolutions: outcome.infiniteSolutions,
        intervalMin: intervalMin,
        intervalMax: intervalMax,
      );
    }

    if (intervalMin == null || intervalMax == null) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedSolveForm,
          message: 'Non-polynomial solving requires an interval.',
          suggestion: 'Provide an interval: solve(expr, x, min, max).',
        ),
      );
    }

    final function = FunctionExpression(
      originalExpression: ExpressionPrinter().print(differenceAst),
      expressionAst: differenceAst,
      variableName: variableName,
    );
    final roots = _graphAnalysis.roots(
      function,
      intervalMin,
      intervalMax,
      context,
      scope: scope,
    );
    return SolveResultValue(
      variableName: variableName,
      equation: equation,
      solutions: roots.map((value) => DoubleValue(value)).toList(growable: false),
      method: numericOnly ? SolveMethod.numericBisection : SolveMethod.graphRootReuse,
      domain: context.calculationDomain,
      exact: false,
      warnings: <String>[
        'Numeric solving used interval [$intervalMin, $intervalMax].',
      ],
      noSolutionReason: roots.isEmpty ? 'No solution' : null,
      intervalMin: intervalMin,
      intervalMax: intervalMax,
    );
  }

  ExpressionTransformValue derivative(
    ExpressionNode expression, {
    required String variableName,
  }) {
    final transformed = _derivative.differentiate(
      expression,
      variableName: variableName,
    );
    return ExpressionTransformValue(
      kindLabel: ExpressionTransformKind.derivative,
      variableName: variableName,
      originalExpression: ExpressionPrinter().print(expression),
      normalizedExpression: ExpressionPrinter().print(transformed),
      expressionAst: transformed,
    );
  }

  CalculatorValue derivativeAt(
    ExpressionNode expression, {
    required String variableName,
    required CalculatorValue value,
    required CalculationContext context,
    EvaluationScope scope = const EvaluationScope(),
  }) {
    try {
      final transformed = derivative(expression, variableName: variableName);
      final evaluator = ExpressionEvaluator(
        context,
        scope: scope.withVariable(variableName, value),
      );
      return evaluator.evaluate(transformed.expressionAst).value;
    } on CalculatorException {
      final function = FunctionExpression(
        originalExpression: ExpressionPrinter().print(expression),
        expressionAst: expression,
        variableName: variableName,
      );
      final x = value.toDouble();
      final h = (x.abs() * 1e-5).clamp(1e-5, 1e-3);
      final center = _graphAnalysis.evalAt(
        function,
        DoubleValue(x),
        context,
        scope: scope,
      ).toDouble();
      final left = _graphAnalysis.evalAt(
        function,
        DoubleValue(x - h),
        context,
        scope: scope,
      ).toDouble();
      final right = _graphAnalysis.evalAt(
        function,
        DoubleValue(x + h),
        context,
        scope: scope,
      ).toDouble();
      final leftSlope = (center - left) / h;
      final rightSlope = (right - center) / h;
      if ((leftSlope - rightSlope).abs() > 1e-2) {
        throw const CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidDerivative,
            message: 'Derivative is not stable at this point.',
          ),
        );
      }
      return DoubleValue((right - left) / (2 * h));
    }
  }

  ExpressionTransformValue integral(
    ExpressionNode expression, {
    required String variableName,
  }) {
    final transformed = _integral.integrate(
      expression,
      variableName: variableName,
    );
    return ExpressionTransformValue(
      kindLabel: ExpressionTransformKind.integral,
      variableName: variableName,
      originalExpression: ExpressionPrinter().print(expression),
      normalizedExpression: ExpressionPrinter().print(transformed),
      expressionAst: transformed,
    );
  }

  CalculatorValue integrate(
    ExpressionNode expression, {
    required String variableName,
    required double min,
    required double max,
    required CalculationContext context,
    EvaluationScope scope = const EvaluationScope(),
  }) {
    final function = FunctionExpression(
      originalExpression: ExpressionPrinter().print(expression),
      expressionAst: expression,
      variableName: variableName,
    );
    return DoubleValue(_graphAnalysis.area(function, min, max, context, scope: scope));
  }

  bool _expressionContainsVariable(ExpressionNode node, String variableName) {
    if (node is ConstantNode) {
      return node.name == variableName;
    }
    if (node is UnaryOperationNode) {
      return _expressionContainsVariable(node.operand, variableName);
    }
    if (node is BinaryOperationNode) {
      return _expressionContainsVariable(node.left, variableName) ||
          _expressionContainsVariable(node.right, variableName);
    }
    if (node is FunctionCallNode) {
      return node.arguments.any(
        (argument) => _expressionContainsVariable(argument, variableName),
      );
    }
    if (node is EquationNode) {
      return _expressionContainsVariable(node.left, variableName) ||
          _expressionContainsVariable(node.right, variableName);
    }
    if (node is ListLiteralNode) {
      return node.elements.any(
        (argument) => _expressionContainsVariable(argument, variableName),
      );
    }
    if (node is UnitAttachmentNode) {
      return _expressionContainsVariable(node.valueExpression, variableName) ||
          _expressionContainsVariable(node.unitExpression, variableName);
    }
    return false;
  }
}
