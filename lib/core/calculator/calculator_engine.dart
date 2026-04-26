import 'calculation_context.dart';
import 'calculation_error.dart';
import 'calculation_outcome.dart';
import 'calculation_result.dart';
import 'calculator_lexer.dart';
import 'expression_parser.dart';
import 'scope/evaluation_scope.dart';
import 'values/calculator_value.dart';
import 'src/calculator_exception.dart';
import 'src/expression_evaluator.dart';
import 'src/expression_printer.dart';
import 'src/result_formatter.dart';

/// Public entry point for calculator expression evaluation.
class CalculatorEngine {
  /// Creates an engine with overridable lexer and parser collaborators.
  const CalculatorEngine({
    CalculatorLexer lexer = const CalculatorLexer(),
    ExpressionParser parser = const ExpressionParser(),
  }) : _lexer = lexer,
       _parser = parser;

  final CalculatorLexer _lexer;
  final ExpressionParser _parser;

  /// Evaluates a user expression and returns either a result or a typed error.
  CalculationOutcome evaluate(
    String expression, {
    CalculationContext context = const CalculationContext(),
    EvaluationScope? scope,
  }) {
    final trimmedExpression = expression.trim();
    if (trimmedExpression.isEmpty) {
      return const CalculationOutcome.failure(
        CalculationError(
          type: CalculationErrorType.syntaxError,
          message: 'Bos ifade hesaplanamaz.',
          suggestion: 'Once bir matematik ifadesi girin.',
        ),
      );
    }

    try {
      final tokens = _lexer.tokenize(
        trimmedExpression,
        maxTokenCount: context.maxTokenCount,
      );
      final ast = _parser.parse(
        tokens,
        allowEquation: _shouldAllowEquationSyntax(trimmedExpression),
      );
      final evaluator = ExpressionEvaluator(context, scope: scope);
      final evaluatedValue = evaluator.evaluate(ast);
      final normalizedExpression = ExpressionPrinter().print(ast);
      final formattedValue = ResultFormatter().format(
        evaluatedValue.value,
        context,
        statisticName: evaluatedValue.statisticName,
        sampleSize: evaluatedValue.sampleSize,
        graphMetadata: evaluatedValue.graphMetadata,
      );
      final numericValue = switch (evaluatedValue.value.kind) {
        CalculatorValueKind.dataset ||
        CalculatorValueKind.regression ||
        CalculatorValueKind.function ||
        CalculatorValueKind.plot ||
        CalculatorValueKind.equation ||
        CalculatorValueKind.solveResult ||
        CalculatorValueKind.expressionTransform => null,
        _ => evaluatedValue.value.toDouble(),
      };

      return CalculationOutcome.success(
        CalculationResult(
          normalizedExpression: normalizedExpression,
          displayResult: formattedValue.displayResult,
          numericValue: numericValue,
          isApproximate: evaluatedValue.isApproximate,
          warnings: List.unmodifiable(evaluator.warnings),
          value: evaluatedValue.value,
          valueKind: formattedValue.valueKind,
          numericMode: formattedValue.numericMode,
          calculationDomain: context.calculationDomain,
          resultFormat: formattedValue.resultFormat,
          exactDisplayResult: formattedValue.exactDisplayResult,
          symbolicDisplayResult: formattedValue.symbolicDisplayResult,
          decimalDisplayResult: formattedValue.decimalDisplayResult,
          fractionDisplayResult: formattedValue.fractionDisplayResult,
          complexDisplayResult: formattedValue.complexDisplayResult,
          rectangularDisplayResult: formattedValue.rectangularDisplayResult,
          polarDisplayResult: formattedValue.polarDisplayResult,
          magnitudeDisplayResult: formattedValue.magnitudeDisplayResult,
          argumentDisplayResult: formattedValue.argumentDisplayResult,
          functionDisplayResult: formattedValue.functionDisplayResult,
          plotDisplayResult: formattedValue.plotDisplayResult,
          graphDisplayResult: formattedValue.graphDisplayResult,
          equationDisplayResult: formattedValue.equationDisplayResult,
          solveDisplayResult: formattedValue.solveDisplayResult,
          solutionsDisplayResult: formattedValue.solutionsDisplayResult,
          traceDisplayResult: formattedValue.traceDisplayResult,
          rootDisplayResult: formattedValue.rootDisplayResult,
          intersectionDisplayResult: formattedValue.intersectionDisplayResult,
          derivativeDisplayResult: formattedValue.derivativeDisplayResult,
          integralDisplayResult: formattedValue.integralDisplayResult,
          transformDisplayResult: formattedValue.transformDisplayResult,
          datasetDisplayResult: formattedValue.datasetDisplayResult,
          statisticsDisplayResult: formattedValue.statisticsDisplayResult,
          regressionDisplayResult: formattedValue.regressionDisplayResult,
          probabilityDisplayResult: formattedValue.probabilityDisplayResult,
          summaryDisplayResult: formattedValue.summaryDisplayResult,
          vectorDisplayResult: formattedValue.vectorDisplayResult,
          matrixDisplayResult: formattedValue.matrixDisplayResult,
          unitDisplayResult: formattedValue.unitDisplayResult,
          baseUnitDisplayResult: formattedValue.baseUnitDisplayResult,
          dimensionDisplayResult: formattedValue.dimensionDisplayResult,
          conversionDisplayResult: formattedValue.conversionDisplayResult,
          shapeDisplayResult: formattedValue.shapeDisplayResult,
          rowCount: formattedValue.rowCount,
          columnCount: formattedValue.columnCount,
          sampleSize: formattedValue.sampleSize,
          statisticName: formattedValue.statisticName,
          plotSeriesCount: formattedValue.plotSeriesCount,
          plotPointCount: formattedValue.plotPointCount,
          plotSegmentCount: formattedValue.plotSegmentCount,
          viewportDisplayResult: formattedValue.viewportDisplayResult,
          solutionCount: formattedValue.solutionCount,
          solveVariable: formattedValue.solveVariable,
          solveMethod: formattedValue.solveMethod,
          solveDomain: formattedValue.solveDomain,
          residualDisplayResult: formattedValue.residualDisplayResult,
          graphWarnings: List.unmodifiable(
            evaluatedValue.graphMetadata?.graphWarnings ?? const <String>[],
          ),
          alternativeResults: Map.unmodifiable(
            formattedValue.alternativeResults,
          ),
        ),
      );
    } on CalculatorException catch (exception) {
      return CalculationOutcome.failure(exception.error);
    } catch (_) {
      return const CalculationOutcome.failure(
        CalculationError(
          type: CalculationErrorType.internalError,
          message: 'Beklenmeyen bir hesaplama hatasi olustu.',
          suggestion: 'Ifadeyi sadelestirip tekrar deneyin.',
        ),
      );
    }
  }

  bool _shouldAllowEquationSyntax(String expression) {
    final lower = expression.toLowerCase();
    return lower.contains('solve(') ||
        lower.contains('nsolve(') ||
        lower.contains('solvesystem(');
  }
}
