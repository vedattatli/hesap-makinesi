import '../ast_nodes.dart';
import '../calculation_context.dart';
import '../calculation_error.dart';
import '../scope/builtin_symbol_catalog.dart';
import '../scope/evaluation_scope.dart';
import '../solve/expression_transformer.dart';
import '../solve/polynomial_detector.dart';
import '../src/calculator_exception.dart';
import '../src/expression_printer.dart';
import '../values/expression_transform_value.dart';
import 'cas_step.dart';
import 'polynomial_expression_builder.dart';

class CasSimplifier {
  const CasSimplifier({
    PolynomialDetector polynomialDetector = const PolynomialDetector(
      maxSupportedExpansionDegree: 8,
    ),
    PolynomialExpressionBuilder builder = const PolynomialExpressionBuilder(),
  }) : _polynomialDetector = polynomialDetector,
       _builder = builder;

  final PolynomialDetector _polynomialDetector;
  final PolynomialExpressionBuilder _builder;

  ExpressionTransformValue simplify(
    ExpressionNode expression, {
    required CalculationContext context,
    EvaluationScope scope = const EvaluationScope(),
  }) {
    final steps = <CasStep>[];
    final simplified = _simplifyNode(expression, steps);
    final variable = _singleVariableCandidate(simplified);
    var output = simplified;
    if (variable != null) {
      final polynomial = _polynomialDetector.detect(
        simplified,
        variableName: variable,
        context: context,
        scope: scope,
      );
      if (polynomial != null && polynomial.degree <= 8) {
        final canonical = _builder.build(polynomial);
        if (ExpressionPrinter().print(canonical) !=
            ExpressionPrinter().print(simplified)) {
          output = canonical;
          steps.add(
            const CasStep(
              title: 'Canonicalized polynomial terms',
              detail: 'Like terms were combined into a stable polynomial form.',
            ),
          );
        }
      }
    }
    if (steps.isEmpty) {
      steps.add(const CasStep(title: 'Expression already simplified'));
    }
    return ExpressionTransformValue(
      kindLabel: ExpressionTransformKind.simplify,
      originalExpression: ExpressionPrinter().print(expression),
      normalizedExpression: ExpressionPrinter().print(output),
      expressionAst: output,
      steps: List<CasStep>.unmodifiable(steps),
    );
  }

  ExpressionNode _simplifyNode(ExpressionNode node, List<CasStep> steps) {
    if (node is NumberNode || node is ConstantNode) {
      return ExpressionTransformer.clone(node);
    }
    if (node is UnaryOperationNode) {
      final operand = _simplifyNode(node.operand, steps);
      if (node.operator == '-') {
        final simplified = ExpressionTransformer.negate(operand);
        if (simplified != operand) {
          steps.add(const CasStep(title: 'Simplified unary minus'));
        }
        return simplified;
      }
      return operand;
    }
    if (node is BinaryOperationNode) {
      final left = _simplifyNode(node.left, steps);
      final right = _simplifyNode(node.right, steps);
      final before = ExpressionPrinter().print(
        BinaryOperationNode(
          left: left,
          operator: node.operator,
          right: right,
          position: node.position,
        ),
      );
      final simplified = switch (node.operator) {
        '+' => ExpressionTransformer.add(left, right),
        '-' => ExpressionTransformer.subtract(left, right),
        '*' => ExpressionTransformer.multiply(left, right),
        '/' => ExpressionTransformer.divide(left, right),
        '^' => ExpressionTransformer.power(left, right),
        _ => BinaryOperationNode(
          left: left,
          operator: node.operator,
          right: right,
          position: node.position,
        ),
      };
      if (ExpressionPrinter().print(simplified) != before) {
        steps.add(CasStep(title: 'Applied identity rule', detail: before));
      }
      return simplified;
    }
    if (node is FunctionCallNode) {
      final args = node.arguments
          .map((argument) => _simplifyNode(argument, steps))
          .toList(growable: false);
      final folded = _foldKnownFunction(node.name, args);
      if (folded != null) {
        steps.add(
          CasStep(
            title: 'Folded known function value',
            detail: '${node.name}(${ExpressionPrinter().print(args.single)})',
          ),
        );
        return folded;
      }
      return FunctionCallNode(
        name: node.name,
        arguments: args,
        position: node.position,
      );
    }
    if (node is EquationNode) {
      return EquationNode(
        left: _simplifyNode(node.left, steps),
        right: _simplifyNode(node.right, steps),
        position: node.position,
      );
    }
    if (node is ListLiteralNode) {
      return ListLiteralNode(
        elements: node.elements
            .map((element) => _simplifyNode(element, steps))
            .toList(growable: false),
        position: node.position,
      );
    }
    if (node is UnitAttachmentNode) {
      return UnitAttachmentNode(
        valueExpression: _simplifyNode(node.valueExpression, steps),
        unitExpression: _simplifyNode(node.unitExpression, steps),
        position: node.position,
      );
    }
    throw const CalculatorException(
      CalculationError(
        type: CalculationErrorType.unsupportedCasTransform,
        message: 'This expression node cannot be simplified in CAS-lite.',
      ),
    );
  }

  ExpressionNode? _foldKnownFunction(String name, List<ExpressionNode> args) {
    if (args.length != 1) {
      return null;
    }
    final normalized = name.toLowerCase();
    final argument = args.single;
    if (ExpressionTransformer.isZero(argument)) {
      switch (normalized) {
        case 'sin':
        case 'tan':
          return ExpressionTransformer.zero(position: argument.position);
        case 'cos':
        case 'exp':
          return ExpressionTransformer.one(position: argument.position);
      }
    }
    if (normalized == 'ln' && ExpressionTransformer.isOne(argument)) {
      return ExpressionTransformer.zero(position: argument.position);
    }
    return null;
  }

  String? _singleVariableCandidate(ExpressionNode node) {
    final collector = _VariableCollector();
    collector.visit(node);
    if (collector.variables.length == 1) {
      return collector.variables.single;
    }
    return null;
  }
}

class _VariableCollector {
  final Set<String> variables = <String>{};

  void visit(ExpressionNode node) {
    if (node is ConstantNode) {
      if (!BuiltInSymbolCatalog.isBuiltInConstant(node.name) &&
          !BuiltInSymbolCatalog.isUnitIdentifier(node.name)) {
        variables.add(node.name);
      }
      return;
    }
    if (node is UnaryOperationNode) {
      visit(node.operand);
      return;
    }
    if (node is BinaryOperationNode) {
      visit(node.left);
      visit(node.right);
      return;
    }
    if (node is FunctionCallNode) {
      if (!BuiltInSymbolCatalog.isBuiltInFunction(node.name)) {
        variables.add(node.name);
      }
      for (final argument in node.arguments) {
        visit(argument);
      }
      return;
    }
    if (node is EquationNode) {
      visit(node.left);
      visit(node.right);
      return;
    }
    if (node is ListLiteralNode) {
      for (final element in node.elements) {
        visit(element);
      }
      return;
    }
    if (node is UnitAttachmentNode) {
      visit(node.valueExpression);
    }
  }
}
