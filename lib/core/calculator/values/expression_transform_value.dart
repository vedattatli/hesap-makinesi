import '../ast_nodes.dart';
import '../cas_lite/cas_step.dart';
import 'calculator_value.dart';

enum ExpressionTransformKind { simplify, expand, factor, derivative, integral }

class ExpressionTransformValue extends CalculatorValue {
  const ExpressionTransformValue({
    required this.kindLabel,
    required this.originalExpression,
    required this.normalizedExpression,
    required this.expressionAst,
    this.variableName,
    this.steps = const <CasStep>[],
    this.warnings = const <String>[],
    this.unsupportedReason,
  });

  final ExpressionTransformKind kindLabel;
  final String? variableName;
  final String originalExpression;
  final String normalizedExpression;
  final ExpressionNode expressionAst;
  final List<CasStep> steps;
  final List<String> warnings;
  final String? unsupportedReason;

  @override
  CalculatorValueKind get kind => CalculatorValueKind.expressionTransform;

  @override
  bool get isExact => true;

  @override
  double toDouble() => double.nan;
}
