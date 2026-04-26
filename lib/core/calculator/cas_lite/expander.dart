import '../ast_nodes.dart';
import '../calculation_context.dart';
import '../calculation_error.dart';
import '../scope/evaluation_scope.dart';
import '../solve/polynomial_detector.dart';
import '../src/calculator_exception.dart';
import '../src/expression_printer.dart';
import '../values/expression_transform_value.dart';
import 'cas_step.dart';
import 'polynomial_expression_builder.dart';

class CasExpander {
  const CasExpander({
    this.maxDegree = 8,
    this.maxTerms = 200,
    PolynomialExpressionBuilder builder = const PolynomialExpressionBuilder(),
  }) : _builder = builder;

  final int maxDegree;
  final int maxTerms;
  final PolynomialExpressionBuilder _builder;

  ExpressionTransformValue expand(
    ExpressionNode expression, {
    required String variableName,
    required CalculationContext context,
    EvaluationScope scope = const EvaluationScope(),
  }) {
    final detector = PolynomialDetector(maxSupportedExpansionDegree: maxDegree);
    final polynomial = detector.detect(
      expression,
      variableName: variableName,
      context: context,
      scope: scope,
    );
    if (polynomial == null) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedCasTransform,
          message:
              'CAS-lite expand supports polynomial addition, multiplication and non-negative integer powers only.',
        ),
      );
    }
    if (polynomial.degree > maxDegree) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.polynomialExpansionLimit,
          message: 'Polynomial expansion degree limit exceeded.',
          suggestion: 'This phase expands polynomials up to degree $maxDegree.',
        ),
      );
    }
    if (polynomial.coefficients.length > maxTerms) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.polynomialExpansionLimit,
          message: 'Polynomial expansion term limit exceeded.',
          suggestion: 'This phase expands at most $maxTerms terms.',
        ),
      );
    }
    final expanded = _builder.build(polynomial);
    return ExpressionTransformValue(
      kindLabel: ExpressionTransformKind.expand,
      originalExpression: ExpressionPrinter().print(expression),
      normalizedExpression: ExpressionPrinter().print(expanded),
      expressionAst: expanded,
      steps: <CasStep>[
        const CasStep(
          title: 'Converted expression to polynomial form',
          detail: 'Supported products and powers were expanded.',
        ),
        CasStep(
          title: 'Canonical polynomial degree',
          detail: polynomial.degree.toString(),
        ),
      ],
    );
  }
}
