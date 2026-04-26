import 'dart:math' as math;

import '../angle_mode.dart';
import '../ast_nodes.dart';
import '../cas_lite/expander.dart';
import '../cas_lite/factorer.dart';
import '../cas_lite/simplifier.dart';
import '../cas_lite/system_solver.dart';
import '../calculation_context.dart';
import '../calculation_domain.dart';
import '../calculation_error.dart';
import '../graph/function_expression.dart';
import '../graph/graph_analysis.dart';
import '../graph/graph_engine.dart';
import '../graph/graph_result_metadata.dart';
import '../graph/graph_sampling_options.dart';
import '../graph/graph_variable_scope.dart';
import '../graph/graph_viewport.dart';
import '../graph/plot_value.dart';
import '../numeric_mode.dart';
import '../scope/evaluation_scope.dart';
import '../scope/builtin_symbol_catalog.dart';
import '../scope/scoped_function_definition.dart';
import '../solve/solve_engine.dart';
import '../statistics/combinatorics.dart';
import '../statistics/descriptive_statistics.dart';
import '../statistics/distributions.dart';
import '../statistics/quantiles.dart';
import '../statistics/regression.dart';
import '../statistics/statistics_errors.dart';
import '../unit_mode.dart';
import '../units/unit_expression.dart';
import '../units/unit_registry.dart';
import '../values/calculator_value.dart';
import '../values/complex_value.dart';
import '../values/dataset_value.dart';
import '../values/double_value.dart';
import '../values/equation_value.dart';
import '../values/function_value.dart';
import '../values/linear_algebra.dart';
import '../values/matrix_value.dart';
import '../values/rational_value.dart';
import '../values/regression_value.dart';
import '../values/scalar_value_math.dart';
import '../values/symbolic_factor.dart';
import '../values/symbolic_simplifier.dart';
import '../values/symbolic_term.dart';
import '../values/symbolic_value.dart';
import '../values/unit_math.dart';
import '../values/unit_value.dart';
import '../values/vector_value.dart';
import 'calculator_exception.dart';
import 'expression_printer.dart';

class ExpressionEvaluator {
  ExpressionEvaluator(
    this._context, {
    EvaluationScope? scope,
    GraphVariableScope? variableScope,
  }) : _scope = scope ?? variableScope ?? const EvaluationScope();

  static const _maxExactDigits = 10000;
  static const _maxExactExponentMagnitude = 2048;

  final CalculationContext _context;
  final EvaluationScope _scope;
  final List<String> warnings = <String>[];

  EvaluatedValue evaluate(ExpressionNode node) {
    final evaluated = _visit(node);
    if (!_isStructuredNonNumericValue(evaluated.value)) {
      final numericValue = evaluated.value.toDouble();
      if (!numericValue.isFinite) {
        throw const CalculatorException(
          CalculationError(
            type: CalculationErrorType.computationLimit,
            message: 'Sonuc sayisal araligi asti.',
            suggestion: 'Daha kucuk bir ifade deneyin.',
          ),
        );
      }
    }

    _guardExactValue(evaluated.value, node.position);
    return evaluated;
  }

  EvaluatedValue _visit(ExpressionNode node) {
    if (node is NumberNode) {
      return _evaluateNumber(node);
    }
    if (node is ConstantNode) {
      return _evaluateConstant(node);
    }
    if (node is UnaryOperationNode) {
      return _evaluateUnary(node);
    }
    if (node is BinaryOperationNode) {
      return _evaluateBinary(node);
    }
    if (node is EquationNode) {
      return _evaluateEquation(node);
    }
    if (node is FunctionCallNode) {
      return _evaluateFunction(node);
    }
    if (node is ListLiteralNode) {
      return _evaluateListLiteral(node);
    }
    if (node is UnitAttachmentNode) {
      return _evaluateUnitAttachment(node);
    }

    throw const CalculatorException(
      CalculationError(
        type: CalculationErrorType.internalError,
        message: 'Bilinmeyen AST dugumu ile karsilasildi.',
      ),
    );
  }

  EvaluatedValue _evaluateNumber(NumberNode node) {
    if (_context.numericMode == NumericMode.exact) {
      try {
        final rational = RationalValue.parseLiteral(
          node.rawValue,
          maxDigits: _maxExactDigits,
        );
        _guardExactDigits(rational, node.position);
        return EvaluatedValue(value: rational, isApproximate: false);
      } on RangeError {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.computationLimit,
            message: 'Sayi literali exact mode icin cok buyuk.',
            position: node.position,
            suggestion: 'Daha kucuk bir literal deneyin.',
          ),
        );
      } on FormatException {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.syntaxError,
            message: 'Sayi literali cozumlenemedi: "${node.rawValue}".',
            position: node.position,
          ),
        );
      }
    }

    return EvaluatedValue(
      value: DoubleValue(node.value),
      isApproximate:
          node.rawValue.contains('.') || node.rawValue.contains(RegExp('[eE]')),
    );
  }

  EvaluatedValue _evaluateConstant(ConstantNode node) {
    switch (node.name) {
      case 'pi':
        if (_context.numericMode == NumericMode.exact) {
          return _exactValue(_piMultiple(RationalValue.one), node.position);
        }
        return const EvaluatedValue(
          value: DoubleValue(math.pi),
          isApproximate: true,
        );
      case 'e':
        if (_context.numericMode == NumericMode.exact) {
          return _exactValue(SymbolicSimplifier.fromE(), node.position);
        }
        return const EvaluatedValue(
          value: DoubleValue(math.e),
          isApproximate: true,
        );
      case 'i':
        if (_context.calculationDomain != CalculationDomain.complex) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.unknownConstant,
              message: '"i" adli sabit real mode da tanimli degil.',
              position: node.position,
              suggestion: 'COMPLEX domain secerek i sabitini kullanin.',
            ),
          );
        }
        return EvaluatedValue(
          value: ComplexValue.imaginaryUnit,
          isApproximate: false,
        );
      default:
        final scopedValue = _scope.resolveVariable(node.name);
        if (scopedValue != null) {
          return EvaluatedValue(
            value: scopedValue,
            isApproximate: scopedValue.isApproximate,
          );
        }
        if (_context.unitMode == UnitMode.enabled) {
          final unitDefinition = UnitRegistry.instance.lookup(node.name);
          if (unitDefinition != null) {
            return EvaluatedValue(
              value: UnitValue.expression(
                UnitExpression.fromDefinition(unitDefinition),
              ),
              isApproximate: false,
            );
          }
        }
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.unknownConstant,
            message: '"${node.name}" adli sabit tanimli degil.',
            position: node.position,
            suggestion: _context.calculationDomain == CalculationDomain.complex
                ? 'Desteklenen sabitler: pi, e ve i.'
                : 'Desteklenen sabitler: pi ve e.',
          ),
        );
    }
  }

  EvaluatedValue _evaluateUnitAttachment(UnitAttachmentNode node) {
    if (_context.unitMode == UnitMode.disabled) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unknownUnit,
          message: 'Physical unit parsing is disabled.',
          position: node.position,
          suggestion: 'UNITS ON secerek 3 m gibi ifadeleri etkinlestirin.',
        ),
      );
    }

    final magnitude = _visit(node.valueExpression);
    final unitValue = _visit(node.unitExpression).value;
    if (unitValue is! UnitValue || !unitValue.isUnitExpressionOnly) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unknownUnit,
          message: 'Gecerli bir birim ifadesi bekleniyordu.',
          position: node.position,
          suggestion: 'Ornek: m, cm, km/h veya degC.',
        ),
      );
    }

    _requireScalarValue(
      magnitude.value,
      position: node.position,
      message: 'Birim eki yalnizca scalar bir buyukluge eklenebilir.',
    );

    try {
      return _composeValue(
        UnitMath.attach(magnitude.value, unitValue.displayUnit),
        inputs: <EvaluatedValue>[magnitude],
      );
    } on UnsupportedError catch (error) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidUnitOperation,
          message: error.message ?? 'Birim eki uygulanamadi.',
          position: node.position,
        ),
      );
    }
  }

  EvaluatedValue _evaluateListLiteral(ListLiteralNode node) {
    if (node.elements.isEmpty) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidMatrixShape,
          message: 'Bos vector veya matrix literali desteklenmiyor.',
          position: node.position,
          suggestion: 'En az bir eleman iceren bir literal kullanin.',
        ),
      );
    }

    final elements = node.elements.map(_visit).toList(growable: false);
    final values = elements.map((item) => item.value).toList(growable: false);
    final hasVectors = values.any((value) => value is VectorValue);
    final hasMatrices = values.any((value) => value is MatrixValue);

    if (hasMatrices) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidMatrixShape,
          message: 'Ic ice matrix literal bu fazda desteklenmiyor.',
          position: node.position,
        ),
      );
    }

    if (hasVectors) {
      if (!values.every((value) => value is VectorValue)) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidMatrixShape,
            message: 'Matrix literal satirlari ayni turde olmali.',
            position: node.position,
            suggestion:
                'Matrix literal icin [[1, 2], [3, 4]] gibi duzenli satirlar kullanin.',
          ),
        );
      }

      final rows = values.cast<VectorValue>();
      final rowLength = rows.first.length;
      if (rows.any((row) => row.length != rowLength)) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidMatrixShape,
            message: 'Matrix literal satirlari ayni uzunlukta olmali.',
            position: node.position,
            suggestion: 'Her satira esit sayida eleman girin.',
          ),
        );
      }

      try {
        return _composeValue(
          MatrixValue(rows.map((row) => row.elements).toList(growable: false)),
          inputs: elements,
        );
      } on ArgumentError {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidMatrixShape,
            message: 'Matrix literal dikdortgen degil.',
            position: node.position,
          ),
        );
      }
    }

    try {
      for (final value in values) {
        _requireScalarValue(
          value,
          position: node.position,
          message: 'Vector literal yalnizca scalar elemanlar icerebilir.',
        );
      }
      return _composeValue(
        LinearAlgebra.createVector(values),
        inputs: elements,
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    } on UnsupportedError {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidMatrixShape,
          message: 'Vector literal olusturulamadi.',
          position: node.position,
        ),
      );
    }
  }

  EvaluatedValue _evaluateUnary(UnaryOperationNode node) {
    final operand = _visit(node.operand);

    switch (node.operator) {
      case '+':
        return operand;
      case '-':
        return _composeValue(
          _negateRawValue(operand.value, node.position),
          inputs: <EvaluatedValue>[operand],
        );
      default:
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.internalError,
            message: 'Bilinmeyen unary operator: ${node.operator}.',
            position: node.position,
          ),
        );
    }
  }

  EvaluatedValue _evaluateBinary(BinaryOperationNode node) {
    final left = _visit(node.left);
    final right = _visit(node.right);

    switch (node.operator) {
      case '+':
        return _composeValue(
          _addRawValues(left.value, right.value, node.position),
          inputs: <EvaluatedValue>[left, right],
        );
      case '-':
        return _composeValue(
          _subtractRawValues(left.value, right.value, node.position),
          inputs: <EvaluatedValue>[left, right],
        );
      case '*':
        return _composeValue(
          _multiplyRawValues(left.value, right.value, node.position),
          inputs: <EvaluatedValue>[left, right],
        );
      case '/':
        if (_isZeroValue(right.value)) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.divisionByZero,
              message: 'Sifira bolme tanimsizdir.',
              position: node.position,
              suggestion: 'Paydanin sifir olmadigindan emin olun.',
            ),
          );
        }

        final divided = _divideRawValues(
          left.value,
          right.value,
          node.position,
        );
        if (_isComplexValue(left.value) || _isComplexValue(right.value)) {
          return _composeValue(divided, inputs: <EvaluatedValue>[left, right]);
        }

        if (_isExactScalarValue(divided)) {
          return _composeValue(divided, inputs: <EvaluatedValue>[left, right]);
        }

        final leftDouble = left.value.toDouble();
        final rightDouble = right.value.toDouble();
        final integerDivisionIsExact =
            _isNearlyInteger(leftDouble) &&
            _isNearlyInteger(rightDouble) &&
            rightDouble != 0 &&
            leftDouble.remainder(rightDouble) == 0;
        return _composeValue(
          divided,
          inputs: <EvaluatedValue>[left, right],
          approximate: !integerDivisionIsExact,
        );
      case '^':
        return _evaluatePower(node, left, right);
      default:
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.internalError,
            message: 'Bilinmeyen binary operator: ${node.operator}.',
            position: node.position,
          ),
        );
    }
  }

  EvaluatedValue _evaluateEquation(EquationNode node) {
    return EvaluatedValue(
      value: EquationValue(
        equation: SolveEngine().equationValue(node).equation,
      ),
      isApproximate: false,
    );
  }

  EvaluatedValue _evaluatePower(
    BinaryOperationNode node,
    EvaluatedValue left,
    EvaluatedValue right,
  ) {
    final leftValue = left.value;
    final rightValue = right.value;

    if (_isVectorOrMatrixValue(leftValue) ||
        _isVectorOrMatrixValue(rightValue)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message:
              'Power operator vector ve matrix degerleri icin desteklenmiyor.',
          position: node.position,
          suggestion:
              'Matrix carpmak icin "*", determinant icin "det(...)" kullanin.',
        ),
      );
    }

    if (_isUnitValue(rightValue)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidUnitOperation,
          message: 'Birimli bir deger us olarak kullanilamaz.',
          position: node.position,
        ),
      );
    }

    if (leftValue is UnitValue) {
      try {
        if (_isRealIntegerLike(rightValue)) {
          final exponent = _integerFromValue(rightValue);
          _guardExactExponent(BigInt.from(exponent), node.position);
          return _composeValue(
            UnitMath.integerPower(leftValue, exponent),
            inputs: <EvaluatedValue>[left, right],
          );
        }

        if (_isHalfLike(rightValue)) {
          return _composeValue(
            UnitMath.squareRoot(leftValue),
            inputs: <EvaluatedValue>[left, right],
          );
        }

        if (_isNegativeHalfLike(rightValue)) {
          final root = UnitMath.squareRoot(leftValue);
          return _composeValue(
            _divideRawValues(RationalValue.one, root, node.position),
            inputs: <EvaluatedValue>[left, right],
          );
        }
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.unsupportedOperation,
            message:
                error.message ??
                'Birimli ifadelerde yalnizca tam usler veya uygun karekok desteklenir.',
            position: node.position,
          ),
        );
      }

      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message:
              'Birimli ifadelerde yalnizca tam usler veya uygun karekok desteklenir.',
          position: node.position,
        ),
      );
    }

    final rightDouble = rightValue.toDouble();
    final leftDouble = leftValue.toDouble();

    if ((_isComplexValue(leftValue) || _isComplexValue(rightValue)) &&
        _isRealIntegerLike(rightValue)) {
      final exponent = _integerFromValue(rightValue);
      _guardExactExponent(BigInt.from(exponent), node.position);
      return _composeValue(
        ComplexValue.promote(leftValue).integerPower(exponent),
        inputs: <EvaluatedValue>[left, right],
      );
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(leftValue) &&
        rightValue is RationalValue &&
        rightValue.isInteger) {
      final exponentBigInt = rightValue.numerator;
      _guardExactExponent(exponentBigInt, node.position);
      return _exactValue(
        _performExactOperation(
          () => ScalarValueMath.integerPower(leftValue, exponentBigInt.toInt()),
          node.position,
        ),
        node.position,
      );
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(leftValue) &&
        rightValue is RationalValue &&
        _isHalf(rightValue)) {
      if (!_isComplexValue(leftValue) &&
          _compareScalarWithZero(leftValue) < 0 &&
          _context.calculationDomain == CalculationDomain.complex) {
        final sqrtValue = _complexSquareRootOfNegativeScalar(
          leftValue,
          node.position,
        );
        return _exactValue(sqrtValue, node.position);
      }
      return _exactValue(
        _performExactOperation(
          () => SymbolicSimplifier.halfPower(leftValue),
          node.position,
        ),
        node.position,
      );
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(leftValue) &&
        rightValue is RationalValue &&
        _isNegativeHalf(rightValue)) {
      if (!_isComplexValue(leftValue) &&
          _compareScalarWithZero(leftValue) < 0 &&
          _context.calculationDomain == CalculationDomain.complex) {
        final sqrtValue = _complexSquareRootOfNegativeScalar(
          leftValue,
          node.position,
        );
        return _exactValue(
          _divideRawValues(RationalValue.one, sqrtValue, node.position),
          node.position,
        );
      }
      return _exactValue(
        _performExactOperation(
          () => SymbolicSimplifier.negativeHalfPower(leftValue),
          node.position,
        ),
        node.position,
      );
    }

    if (_context.calculationDomain == CalculationDomain.complex &&
        !_isComplexValue(leftValue) &&
        _compareScalarWithZero(leftValue) < 0 &&
        (_isHalfLike(rightValue) || _isNegativeHalfLike(rightValue))) {
      final sqrtValue = _complexSquareRootOfNegativeScalar(
        leftValue,
        node.position,
      );
      if (_isNegativeHalfLike(rightValue)) {
        return _composeValue(
          _divideRawValues(RationalValue.one, sqrtValue, node.position),
          inputs: <EvaluatedValue>[left, right],
        );
      }
      return _composeValue(sqrtValue, inputs: <EvaluatedValue>[left, right]);
    }

    if (leftDouble < 0 &&
        !_isNearlyInteger(rightDouble) &&
        _context.calculationDomain == CalculationDomain.real) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.domainError,
          message:
              'Negatif taban, kesirli us ile gercek sayilarda tanimli degil.',
          position: node.position,
          suggestion: 'Bu ifade icin COMPLEX domain gerekli olabilir.',
        ),
      );
    }

    if (_context.calculationDomain == CalculationDomain.complex &&
        (_isComplexValue(leftValue) ||
            _isComplexValue(rightValue) ||
            (leftDouble < 0 && !_isNearlyInteger(rightDouble)))) {
      if (_context.numericMode == NumericMode.exact) {
        _warnApproximation('Complex non-integer power approximate hesaplandi.');
      }
      return _composeValue(
        _approximateComplexPower(leftValue, rightValue),
        inputs: <EvaluatedValue>[left, right],
        approximate: true,
      );
    }

    if (_context.numericMode == NumericMode.exact) {
      _warnApproximation(
        'Non-integer exponent exact mode da approximate hesaplandi.',
      );
    }

    return _composeValue(
      DoubleValue(math.pow(leftDouble, rightDouble).toDouble()),
      inputs: <EvaluatedValue>[left, right],
      approximate:
          !_isNearlyInteger(rightDouble) ||
          _context.numericMode == NumericMode.exact,
    );
  }

  EvaluatedValue _evaluateFunction(FunctionCallNode node) {
    final normalizedName = node.name.toLowerCase();
    if (_isLazyFunction(normalizedName)) {
      return _evaluateLazyFunction(node, normalizedName);
    }

    final arguments = node.arguments.map(_visit).toList(growable: false);
    final argumentValues = arguments
        .map((argument) => argument.value)
        .toList(growable: false);

    void expectArgumentCount(int count) {
      if (arguments.length != count) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidArgumentCount,
            message:
                '"${node.name}" fonksiyonu $count arguman bekliyor, ${arguments.length} arguman aldi.',
            position: node.position,
          ),
        );
      }
    }

    if ((node.name == 'min' || node.name == 'max') && arguments.isEmpty) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidArgumentCount,
          message: '"${node.name}" fonksiyonu en az bir arguman bekliyor.',
          position: node.position,
        ),
      );
    }

    switch (normalizedName) {
      case 'data':
      case 'dataset':
      case 'ds':
        return _evaluateDatasetConstructor(node, arguments);
      case 'vec':
      case 'vector':
        return _evaluateVectorConstructor(node, arguments);
      case 'mat':
      case 'matrix':
        return _evaluateMatrixConstructor(node, arguments);
      case 'identity':
      case 'eye':
        expectArgumentCount(1);
        return _evaluateIdentity(node, arguments.single);
      case 'zeros':
        expectArgumentCount(2);
        return _evaluateZeros(node, arguments[0], arguments[1]);
      case 'ones':
        expectArgumentCount(2);
        return _evaluateOnes(node, arguments[0], arguments[1]);
      case 'diag':
        return _evaluateDiag(node, arguments);
      case 'to':
      case 'convert':
        expectArgumentCount(2);
        return _evaluateConversion(node, arguments[0], arguments[1]);
      case 'dot':
        expectArgumentCount(2);
        return _evaluateDot(node, arguments[0], arguments[1]);
      case 'cross':
        expectArgumentCount(2);
        return _evaluateCross(node, arguments[0], arguments[1]);
      case 'norm':
      case 'mag':
        expectArgumentCount(1);
        return _evaluateNorm(node, arguments.single);
      case 'unit':
        expectArgumentCount(1);
        return _evaluateUnit(node, arguments.single);
      case 'transpose':
      case 'tr':
        expectArgumentCount(1);
        return _evaluateTranspose(node, arguments.single);
      case 'det':
        expectArgumentCount(1);
        return _evaluateDeterminant(node, arguments.single);
      case 'inv':
        expectArgumentCount(1);
        return _evaluateInverse(node, arguments.single);
      case 'linsolve':
        expectArgumentCount(2);
        return _evaluateLinearSystemSolve(node, arguments[0], arguments[1]);
      case 'trace':
        expectArgumentCount(1);
        return _evaluateTrace(node, arguments.single);
      case 'count':
        expectArgumentCount(1);
        return _evaluateCount(node, arguments.single);
      case 'sum':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'sum', arguments.single);
      case 'product':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'product', arguments.single);
      case 'mean':
      case 'avg':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'mean', arguments.single);
      case 'median':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'median', arguments.single);
      case 'mode':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'mode', arguments.single);
      case 'range':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'range', arguments.single);
      case 'varp':
      case 'variancep':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'varp', arguments.single);
      case 'vars':
      case 'variances':
      case 'variance':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'vars', arguments.single);
      case 'stdp':
      case 'stdevp':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'stdp', arguments.single);
      case 'stds':
      case 'stdevs':
      case 'stddev':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'stds', arguments.single);
      case 'mad':
      case 'meanabsdev':
        expectArgumentCount(1);
        return _evaluateDatasetStatistic(node, 'mad', arguments.single);
      case 'quantile':
        expectArgumentCount(2);
        return _evaluateQuantile(node, arguments[0], arguments[1]);
      case 'percentile':
        expectArgumentCount(2);
        return _evaluatePercentile(node, arguments[0], arguments[1]);
      case 'quartiles':
        expectArgumentCount(1);
        return _evaluateQuartiles(node, arguments.single);
      case 'iqr':
        expectArgumentCount(1);
        return _evaluateIqr(node, arguments.single);
      case 'wmean':
      case 'weightedmean':
        expectArgumentCount(2);
        return _evaluateWeightedMean(node, arguments[0], arguments[1]);
      case 'factorial':
      case 'fact':
        expectArgumentCount(1);
        return _evaluateFactorial(node, arguments.single);
      case 'ncr':
      case 'comb':
      case 'choose':
        expectArgumentCount(2);
        return _evaluateCombination(node, arguments[0], arguments[1]);
      case 'npr':
      case 'perm':
        expectArgumentCount(2);
        return _evaluatePermutation(node, arguments[0], arguments[1]);
      case 'binompmf':
      case 'binomialpmf':
        expectArgumentCount(3);
        return _evaluateBinomialPmf(
          node,
          arguments[0],
          arguments[1],
          arguments[2],
        );
      case 'binomcdf':
      case 'binomialcdf':
        expectArgumentCount(3);
        return _evaluateBinomialCdf(
          node,
          arguments[0],
          arguments[1],
          arguments[2],
        );
      case 'poissonpmf':
        expectArgumentCount(2);
        return _evaluatePoissonPmf(node, arguments[0], arguments[1]);
      case 'poissoncdf':
        expectArgumentCount(2);
        return _evaluatePoissonCdf(node, arguments[0], arguments[1]);
      case 'geompmf':
        expectArgumentCount(2);
        return _evaluateGeometricPmf(node, arguments[0], arguments[1]);
      case 'geomcdf':
        expectArgumentCount(2);
        return _evaluateGeometricCdf(node, arguments[0], arguments[1]);
      case 'normalpdf':
      case 'normpdf':
        expectArgumentCount(3);
        return _evaluateNormalPdf(
          node,
          arguments[0],
          arguments[1],
          arguments[2],
        );
      case 'normalcdf':
      case 'normcdf':
        expectArgumentCount(3);
        return _evaluateNormalCdf(
          node,
          arguments[0],
          arguments[1],
          arguments[2],
        );
      case 'zscore':
        expectArgumentCount(3);
        return _evaluateZScore(node, arguments[0], arguments[1], arguments[2]);
      case 'uniformpdf':
        expectArgumentCount(3);
        return _evaluateUniformPdf(
          node,
          arguments[0],
          arguments[1],
          arguments[2],
        );
      case 'uniformcdf':
        expectArgumentCount(3);
        return _evaluateUniformCdf(
          node,
          arguments[0],
          arguments[1],
          arguments[2],
        );
      case 'covp':
        expectArgumentCount(2);
        return _evaluateCovariance(
          node,
          arguments[0],
          arguments[1],
          sample: false,
        );
      case 'covs':
        expectArgumentCount(2);
        return _evaluateCovariance(
          node,
          arguments[0],
          arguments[1],
          sample: true,
        );
      case 'corr':
      case 'correlation':
        expectArgumentCount(2);
        return _evaluateCorrelation(node, arguments[0], arguments[1]);
      case 'linreg':
      case 'linearregression':
        expectArgumentCount(2);
        return _evaluateLinearRegression(node, arguments[0], arguments[1]);
      case 'linpred':
        expectArgumentCount(3);
        return _evaluateLinearPrediction(
          node,
          arguments[0],
          arguments[1],
          arguments[2],
        );
      case 'sin':
        expectArgumentCount(1);
        return _evaluateTrig(node, 'sin', arguments.single);
      case 'cos':
        expectArgumentCount(1);
        return _evaluateTrig(node, 'cos', arguments.single);
      case 'tan':
        expectArgumentCount(1);
        return _evaluateTrig(node, 'tan', arguments.single);
      case 'asin':
        expectArgumentCount(1);
        return _evaluateInverseTrig(node, 'asin', arguments.single);
      case 'acos':
        expectArgumentCount(1);
        return _evaluateInverseTrig(node, 'acos', arguments.single);
      case 'atan':
        expectArgumentCount(1);
        return _evaluateInverseTrig(node, 'atan', arguments.single);
      case 'sqrt':
        expectArgumentCount(1);
        return _evaluateSqrt(node, arguments.single);
      case 'abs':
        expectArgumentCount(1);
        return _evaluateAbs(node, arguments.single);
      case 'conj':
        expectArgumentCount(1);
        return _evaluateConjugate(node, arguments.single);
      case 're':
        expectArgumentCount(1);
        return _evaluateRealPart(node, arguments.single);
      case 'im':
        expectArgumentCount(1);
        return _evaluateImaginaryPart(node, arguments.single);
      case 'arg':
        expectArgumentCount(1);
        return _evaluateArgument(node, arguments.single);
      case 'polar':
        expectArgumentCount(2);
        return _evaluatePolar(node, arguments[0], arguments[1]);
      case 'cis':
        expectArgumentCount(1);
        return _evaluateCis(node, arguments.single);
      case 'ln':
        expectArgumentCount(1);
        return _evaluateNaturalLog(node, arguments.single);
      case 'log':
      case 'log10':
        expectArgumentCount(1);
        return _evaluateLogarithm(node, arguments.single, base: 10);
      case 'log2':
        expectArgumentCount(1);
        return _evaluateLogarithm(node, arguments.single, base: 2);
      case 'exp':
        expectArgumentCount(1);
        return _evaluateExp(node, arguments.single);
      case 'pow':
        expectArgumentCount(2);
        return _evaluatePower(
          BinaryOperationNode(
            left: node.arguments[0],
            operator: '^',
            right: node.arguments[1],
            position: node.position,
          ),
          arguments[0],
          arguments[1],
        );
      case 'min':
        if (arguments.length == 1 &&
            _isDatasetCompatibleValue(arguments.single.value)) {
          return _evaluateDatasetStatistic(node, 'min', arguments.single);
        }
        if (argumentValues.any(_isVectorOrMatrixValue)) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.unsupportedOperation,
              message: 'min vector ve matrix degerleri icin desteklenmiyor.',
              position: node.position,
            ),
          );
        }
        if (argumentValues.any(_isComplexValue)) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.domainError,
              message: 'min complex sayilar icin bu fazda desteklenmiyor.',
              position: node.position,
            ),
          );
        }
        try {
          final minimum = arguments.reduce((current, candidate) {
            if (_compareScalars(candidate.value, current.value) < 0) {
              return candidate;
            }
            return current;
          });
          return _composeValue(minimum.value, inputs: arguments);
        } on ArgumentError {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.dimensionMismatch,
              message:
                  'min yalnizca ayni boyuttaki birimler arasinda kullanilabilir.',
              position: node.position,
            ),
          );
        }
      case 'max':
        if (arguments.length == 1 &&
            _isDatasetCompatibleValue(arguments.single.value)) {
          return _evaluateDatasetStatistic(node, 'max', arguments.single);
        }
        if (argumentValues.any(_isVectorOrMatrixValue)) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.unsupportedOperation,
              message: 'max vector ve matrix degerleri icin desteklenmiyor.',
              position: node.position,
            ),
          );
        }
        if (argumentValues.any(_isComplexValue)) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.domainError,
              message: 'max complex sayilar icin bu fazda desteklenmiyor.',
              position: node.position,
            ),
          );
        }
        try {
          final maximum = arguments.reduce((current, candidate) {
            if (_compareScalars(candidate.value, current.value) > 0) {
              return candidate;
            }
            return current;
          });
          return _composeValue(maximum.value, inputs: arguments);
        } on ArgumentError {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.dimensionMismatch,
              message:
                  'max yalnizca ayni boyuttaki birimler arasinda kullanilabilir.',
              position: node.position,
            ),
          );
        }
      case 'floor':
        expectArgumentCount(1);
        return _evaluateRounding(node, 'floor', arguments.single);
      case 'ceil':
        expectArgumentCount(1);
        return _evaluateRounding(node, 'ceil', arguments.single);
      case 'round':
        expectArgumentCount(1);
        return _evaluateRounding(node, 'round', arguments.single);
      default:
        final scopedFunction = _scope.resolveFunction(node.name);
        if (scopedFunction != null) {
          return _evaluateScopedFunction(node, scopedFunction, arguments);
        }
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.unknownFunction,
            message: '"${node.name}" adli fonksiyon desteklenmiyor.',
            position: node.position,
            suggestion:
                'Desteklenen fonksiyonlardan birini kullanin: sin, cos, tan, sqrt, log, ln...',
          ),
        );
    }
  }

  EvaluatedValue _evaluateScopedFunction(
    FunctionCallNode node,
    ScopedFunctionDefinition definition,
    List<EvaluatedValue> arguments,
  ) {
    if (definition.parameters.length != arguments.length) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidArgumentCount,
          message:
              'Function "${definition.name}" expects ${definition.parameters.length} argument(s) but got ${arguments.length}.',
          position: node.position,
        ),
      );
    }
    if (_scope.isFunctionActive(definition)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidFunctionExpression,
          message:
              'Recursive worksheet function "${definition.name}" is not supported in this phase.',
          position: node.position,
        ),
      );
    }
    if (_scope.callStack.length >= _scope.maxCallDepth) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.computationLimit,
          message: 'Worksheet function call depth limit was exceeded.',
          position: node.position,
        ),
      );
    }

    final localVariables = <String, CalculatorValue>{};
    for (var index = 0; index < definition.parameters.length; index++) {
      localVariables[definition.parameters[index]] = arguments[index].value;
    }
    final nestedScope = _scope
        .enterFunction(definition)
        .withVariables(localVariables);
    final evaluator = ExpressionEvaluator(_context, scope: nestedScope);
    final evaluated = evaluator.evaluate(definition.bodyAst);
    warnings.addAll(evaluator.warnings);
    return evaluated;
  }

  bool _isLazyFunction(String functionName) {
    switch (functionName) {
      case 'eq':
      case 'solve':
      case 'nsolve':
      case 'diff':
      case 'derivative':
      case 'derivativeat':
      case 'integral':
      case 'integrate':
      case 'simplify':
      case 'expand':
      case 'factor':
      case 'solvesystem':
      case 'fn':
      case 'function':
      case 'plot':
      case 'evalat':
      case 'trace':
      case 'root':
      case 'roots':
      case 'intersect':
      case 'intersections':
      case 'slope':
      case 'area':
        return true;
      default:
        return false;
    }
  }

  EvaluatedValue _evaluateLazyFunction(
    FunctionCallNode node,
    String functionName,
  ) {
    void expectArgumentCount(List<int> counts) {
      if (counts.contains(node.arguments.length)) {
        return;
      }
      final expected = counts.join(' veya ');
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidArgumentCount,
          message:
              '"${node.name}" fonksiyonu $expected arguman bekliyor, ${node.arguments.length} arguman aldi.',
          position: node.position,
        ),
      );
    }

    final analysis = const GraphAnalysis();
    final engine = const GraphEngine();
    final solveEngine = const SolveEngine();
    final simplifier = const CasSimplifier();
    final expander = const CasExpander();
    final factorer = const CasFactorer();
    final systemSolver = const CasSystemSolver();

    switch (functionName) {
      case 'eq':
        expectArgumentCount(<int>[2]);
        return EvaluatedValue(
          value: solveEngine.equationValue(
            EquationNode(
              left: node.arguments[0],
              right: node.arguments[1],
              position: node.position,
            ),
          ),
          isApproximate: false,
        );
      case 'solve':
      case 'nsolve':
        expectArgumentCount(<int>[2, 4]);
        final variableName = _requireRawVariableIdentifier(
          node.arguments[1],
          node.position,
          functionName: node.name,
        );
        double? intervalMin;
        double? intervalMax;
        final evaluatedBounds = <EvaluatedValue>[];
        if (node.arguments.length == 4) {
          final left = _visit(node.arguments[2]);
          final right = _visit(node.arguments[3]);
          intervalMin = _requireDimensionlessRealScalar(
            node,
            left,
            functionName: node.name,
            errorType: CalculationErrorType.invalidPlotRange,
          ).toDouble();
          intervalMax = _requireDimensionlessRealScalar(
            node,
            right,
            functionName: node.name,
            errorType: CalculationErrorType.invalidPlotRange,
          ).toDouble();
          if (!intervalMin.isFinite ||
              !intervalMax.isFinite ||
              intervalMin >= intervalMax) {
            throw CalculatorException(
              CalculationError(
                type: CalculationErrorType.invalidPlotRange,
                message:
                    '${node.name} icin min < max ve sonlu degerler gerekli.',
                position: node.position,
              ),
            );
          }
          evaluatedBounds.addAll(<EvaluatedValue>[left, right]);
        }
        final solved = solveEngine.solve(
          node.arguments[0],
          variableName: variableName,
          context: _context,
          scope: _scope,
          intervalMin: intervalMin,
          intervalMax: intervalMax,
          numericOnly: functionName == 'nsolve',
        );
        warnings.addAll(solved.warnings);
        return _composeValue(solved, inputs: evaluatedBounds);
      case 'diff':
      case 'derivative':
        expectArgumentCount(<int>[2]);
        final variableName = _requireRawVariableIdentifier(
          node.arguments[1],
          node.position,
          functionName: node.name,
        );
        final derivative = solveEngine.derivative(
          node.arguments[0],
          variableName: variableName,
        );
        return EvaluatedValue(value: derivative, isApproximate: false);
      case 'derivativeat':
        expectArgumentCount(<int>[3]);
        final variableName = _requireRawVariableIdentifier(
          node.arguments[1],
          node.position,
          functionName: node.name,
        );
        final atValue = _visit(node.arguments[2]);
        final value = solveEngine.derivativeAt(
          node.arguments[0],
          variableName: variableName,
          value: atValue.value,
          context: _context,
          scope: _scope,
        );
        return _composeValue(
          value,
          inputs: <EvaluatedValue>[atValue],
          approximate: value is DoubleValue,
        );
      case 'integral':
        expectArgumentCount(<int>[2]);
        final variableName = _requireRawVariableIdentifier(
          node.arguments[1],
          node.position,
          functionName: node.name,
        );
        final integral = solveEngine.integral(
          node.arguments[0],
          variableName: variableName,
        );
        return EvaluatedValue(value: integral, isApproximate: false);
      case 'integrate':
        expectArgumentCount(<int>[4]);
        final variableName = _requireRawVariableIdentifier(
          node.arguments[1],
          node.position,
          functionName: node.name,
        );
        final minValue = _visit(node.arguments[2]);
        final maxValue = _visit(node.arguments[3]);
        final min = _requireDimensionlessRealScalar(
          node,
          minValue,
          functionName: node.name,
          errorType: CalculationErrorType.invalidIntegral,
        ).toDouble();
        final max = _requireDimensionlessRealScalar(
          node,
          maxValue,
          functionName: node.name,
          errorType: CalculationErrorType.invalidIntegral,
        ).toDouble();
        return _composeValue(
          solveEngine.integrate(
            node.arguments[0],
            variableName: variableName,
            min: min,
            max: max,
            context: _context,
            scope: _scope,
          ),
          inputs: <EvaluatedValue>[minValue, maxValue],
          approximate: true,
        );
      case 'simplify':
        expectArgumentCount(<int>[1]);
        final simplified = simplifier.simplify(
          node.arguments.single,
          context: _context,
          scope: _scope,
        );
        warnings.addAll(simplified.warnings);
        return EvaluatedValue(value: simplified, isApproximate: false);
      case 'expand':
        expectArgumentCount(<int>[1, 2]);
        final variableName = node.arguments.length == 2
            ? _requireRawVariableIdentifier(
                node.arguments[1],
                node.position,
                functionName: node.name,
              )
            : _inferCasVariableName(node.arguments.first, node.position);
        final expanded = expander.expand(
          node.arguments.first,
          variableName: variableName,
          context: _context,
          scope: _scope,
        );
        warnings.addAll(expanded.warnings);
        return EvaluatedValue(value: expanded, isApproximate: false);
      case 'factor':
        expectArgumentCount(<int>[1, 2]);
        final variableName = node.arguments.length == 2
            ? _requireRawVariableIdentifier(
                node.arguments[1],
                node.position,
                functionName: node.name,
              )
            : _inferCasVariableName(node.arguments.first, node.position);
        final factored = factorer.factor(
          node.arguments.first,
          variableName: variableName,
          context: _context,
          scope: _scope,
        );
        warnings.addAll(factored.warnings);
        return EvaluatedValue(value: factored, isApproximate: false);
      case 'solvesystem':
        if (node.arguments.length < 2) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.invalidArgumentCount,
              message: 'solveSystem en az bir equation ve vars(...) bekler.',
              position: node.position,
            ),
          );
        }
        final variables = systemSolver.parseVars(node.arguments.last);
        final result = systemSolver.solveSystem(
          equations: node.arguments
              .take(node.arguments.length - 1)
              .toList(growable: false),
          variables: variables,
          context: _context,
          scope: _scope,
        );
        warnings.addAll(result.warnings);
        return EvaluatedValue(
          value: result,
          isApproximate: result.isApproximate,
        );
      case 'fn':
      case 'function':
        expectArgumentCount(<int>[1]);
        final function = _coerceFunctionExpression(
          node.arguments.single,
          position: node.position,
        );
        final display =
            'f(${function.variableName}) = ${function.normalizedExpression}';
        return EvaluatedValue(
          value: FunctionValue(function: function),
          isApproximate: false,
          graphMetadata: GraphResultMetadata(
            functionDisplayResult: display,
            graphDisplayResult: display,
          ),
        );
      case 'plot':
        expectArgumentCount(<int>[3, 5]);
        final functions = _coerceFunctionExpressions(
          node.arguments.first,
          position: node.position,
        );
        final xMinValue = _visit(node.arguments[1]);
        final xMaxValue = _visit(node.arguments[2]);
        final xMin = _requireDimensionlessRealScalar(
          node,
          xMinValue,
          functionName: 'plot',
          errorType: CalculationErrorType.invalidPlotRange,
        ).toDouble();
        final xMax = _requireDimensionlessRealScalar(
          node,
          xMaxValue,
          functionName: 'plot',
          errorType: CalculationErrorType.invalidPlotRange,
        ).toDouble();
        if (!xMin.isFinite || !xMax.isFinite || xMin >= xMax) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.invalidPlotRange,
              message: 'plot icin xMin < xMax ve sonlu degerler gerekli.',
              position: node.position,
              suggestion: 'Ornek: plot(sin(x), -pi, pi).',
            ),
          );
        }
        GraphViewport viewport;
        if (node.arguments.length == 5) {
          final yMinValue = _visit(node.arguments[3]);
          final yMaxValue = _visit(node.arguments[4]);
          final yMin = _requireDimensionlessRealScalar(
            node,
            yMinValue,
            functionName: 'plot',
            errorType: CalculationErrorType.invalidViewport,
          ).toDouble();
          final yMax = _requireDimensionlessRealScalar(
            node,
            yMaxValue,
            functionName: 'plot',
            errorType: CalculationErrorType.invalidViewport,
          ).toDouble();
          if (!yMin.isFinite || !yMax.isFinite || yMin >= yMax) {
            throw CalculatorException(
              CalculationError(
                type: CalculationErrorType.invalidViewport,
                message: 'plot icin yMin < yMax ve sonlu degerler gerekli.',
                position: node.position,
              ),
            );
          }
          viewport = GraphViewport(
            xMin: xMin,
            xMax: xMax,
            yMin: yMin,
            yMax: yMax,
            autoY: false,
          );
        } else {
          viewport = GraphViewport(
            xMin: xMin,
            xMax: xMax,
            yMin: -10,
            yMax: 10,
            autoY: true,
          );
        }
        final plotValue = engine.plotFunctions(
          functions,
          viewport,
          _context,
          options: const GraphSamplingOptions(),
          scope: _scope,
        );
        warnings.addAll(plotValue.warnings);
        final graphLabel = functions.length == 1
            ? 'Plot: y = ${functions.first.normalizedExpression}, x ∈ [$xMin, $xMax]'
            : 'Plot: ${functions.length} series, x ∈ [$xMin, $xMax]';
        return EvaluatedValue(
          value: plotValue,
          isApproximate: true,
          graphMetadata: GraphResultMetadata(
            plotDisplayResult: graphLabel,
            graphDisplayResult: graphLabel,
            viewportDisplayResult: plotValue.viewport.toDisplayString(),
            plotSeriesCount: plotValue.seriesCount,
            plotPointCount: plotValue.pointCount,
            plotSegmentCount: plotValue.segmentCount,
            graphWarnings: plotValue.warnings,
          ),
        );
      case 'evalat':
        expectArgumentCount(<int>[2]);
        final function = _coerceFunctionExpression(
          node.arguments[0],
          position: node.position,
        );
        final xValue = _visit(node.arguments[1]);
        final evaluated = analysis.evalAt(
          function,
          xValue.value,
          _context,
          scope: _scope,
        );
        return _composeValue(
          evaluated,
          inputs: <EvaluatedValue>[xValue],
          graphMetadata: GraphResultMetadata(
            functionDisplayResult:
                'f(${function.variableName}) = ${function.normalizedExpression}',
          ),
        );
      case 'trace':
        expectArgumentCount(<int>[2]);
        final function = _coerceFunctionExpression(
          node.arguments[0],
          position: node.position,
        );
        final xValue = _visit(node.arguments[1]);
        final trace = analysis.traceAt(
          function,
          xValue.value,
          _context,
          scope: _scope,
        );
        return _composeValue(
          trace.y,
          inputs: <EvaluatedValue>[xValue],
          graphMetadata: trace.metadata,
        );
      case 'root':
        expectArgumentCount(<int>[3]);
        final function = _coerceFunctionExpression(
          node.arguments[0],
          position: node.position,
        );
        final xMin = _visit(node.arguments[1]);
        final xMax = _visit(node.arguments[2]);
        final left = _requireDimensionlessRealScalar(
          node,
          xMin,
          functionName: 'root',
          errorType: CalculationErrorType.invalidPlotRange,
        ).toDouble();
        final right = _requireDimensionlessRealScalar(
          node,
          xMax,
          functionName: 'root',
          errorType: CalculationErrorType.invalidPlotRange,
        ).toDouble();
        final rootValue = analysis.root(
          function,
          left,
          right,
          _context,
          scope: _scope,
        );
        return _composeValue(
          DoubleValue(rootValue),
          inputs: <EvaluatedValue>[xMin, xMax],
          approximate: true,
          graphMetadata: GraphResultMetadata(
            rootDisplayResult:
                'root: x ≈ ${rootValue.toStringAsFixed(6).replaceFirst(RegExp(r"\\.?0+$"), "")}',
          ),
        );
      case 'roots':
        expectArgumentCount(<int>[3]);
        final function = _coerceFunctionExpression(
          node.arguments[0],
          position: node.position,
        );
        final xMin = _visit(node.arguments[1]);
        final xMax = _visit(node.arguments[2]);
        final left = _requireDimensionlessRealScalar(
          node,
          xMin,
          functionName: 'roots',
          errorType: CalculationErrorType.invalidPlotRange,
        ).toDouble();
        final right = _requireDimensionlessRealScalar(
          node,
          xMax,
          functionName: 'roots',
          errorType: CalculationErrorType.invalidPlotRange,
        ).toDouble();
        final roots = analysis.roots(
          function,
          left,
          right,
          _context,
          scope: _scope,
        );
        if (roots.isEmpty) {
          throw const CalculatorException(
            CalculationError(
              type: CalculationErrorType.noRootFound,
              message: 'Belirtilen aralikta kok bulunamadi.',
            ),
          );
        }
        final value = VectorValue(
          roots.map((root) => DoubleValue(root)).toList(growable: false),
        );
        return _composeValue(
          value,
          inputs: <EvaluatedValue>[xMin, xMax],
          approximate: true,
          graphMetadata: GraphResultMetadata(
            rootDisplayResult:
                'roots: [${roots.map((root) => root.toStringAsFixed(6).replaceFirst(RegExp(r"\\.?0+$"), "")).join(', ')}]',
          ),
        );
      case 'intersect':
      case 'intersections':
        expectArgumentCount(<int>[4]);
        final leftFunction = _coerceFunctionExpression(
          node.arguments[0],
          position: node.position,
        );
        final rightFunction = _coerceFunctionExpression(
          node.arguments[1],
          position: node.position,
        );
        final xMin = _visit(node.arguments[2]);
        final xMax = _visit(node.arguments[3]);
        final left = _requireDimensionlessRealScalar(
          node,
          xMin,
          functionName: 'intersections',
          errorType: CalculationErrorType.invalidPlotRange,
        ).toDouble();
        final right = _requireDimensionlessRealScalar(
          node,
          xMax,
          functionName: 'intersections',
          errorType: CalculationErrorType.invalidPlotRange,
        ).toDouble();
        final intersections = analysis.intersections(
          leftFunction,
          rightFunction,
          left,
          right,
          _context,
          scope: _scope,
        );
        return _composeValue(
          intersections.value,
          inputs: <EvaluatedValue>[xMin, xMax],
          approximate: true,
          graphMetadata: intersections.metadata,
        );
      case 'slope':
        expectArgumentCount(<int>[2]);
        final function = _coerceFunctionExpression(
          node.arguments[0],
          position: node.position,
        );
        final xValue = _visit(node.arguments[1]);
        final x = _requireDimensionlessRealScalar(
          node,
          xValue,
          functionName: 'slope',
          errorType: CalculationErrorType.invalidGraphOperation,
        ).toDouble();
        final slopeValue = analysis.slope(function, x, _context, scope: _scope);
        return _composeValue(
          DoubleValue(slopeValue),
          inputs: <EvaluatedValue>[xValue],
          approximate: true,
          graphMetadata: GraphResultMetadata(
            graphDisplayResult:
                'slope: x = ${x.toStringAsFixed(6).replaceFirst(RegExp(r"\\.?0+$"), "")}, y\' ≈ ${slopeValue.toStringAsFixed(6).replaceFirst(RegExp(r"\\.?0+$"), "")}',
          ),
        );
      case 'area':
        expectArgumentCount(<int>[3]);
        final function = _coerceFunctionExpression(
          node.arguments[0],
          position: node.position,
        );
        final xMin = _visit(node.arguments[1]);
        final xMax = _visit(node.arguments[2]);
        final left = _requireDimensionlessRealScalar(
          node,
          xMin,
          functionName: 'area',
          errorType: CalculationErrorType.invalidPlotRange,
        ).toDouble();
        final right = _requireDimensionlessRealScalar(
          node,
          xMax,
          functionName: 'area',
          errorType: CalculationErrorType.invalidPlotRange,
        ).toDouble();
        final areaValue = analysis.area(
          function,
          left,
          right,
          _context,
          scope: _scope,
        );
        return _composeValue(
          DoubleValue(areaValue),
          inputs: <EvaluatedValue>[xMin, xMax],
          approximate: true,
          graphMetadata: GraphResultMetadata(
            graphDisplayResult:
                'area: [$left, $right] ≈ ${areaValue.toStringAsFixed(6).replaceFirst(RegExp(r"\\.?0+$"), "")}',
          ),
        );
      default:
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.unknownFunction,
            message: '"${node.name}" adli lazy fonksiyon desteklenmiyor.',
            position: node.position,
          ),
        );
    }
  }

  String _requireRawVariableIdentifier(
    ExpressionNode node,
    int position, {
    required String functionName,
  }) {
    if (node is ConstantNode) {
      return node.name;
    }
    throw CalculatorException(
      CalculationError(
        type: CalculationErrorType.invalidSolveVariable,
        message:
            '$functionName degisken olarak yalnizca bir identifier bekler.',
        position: position,
      ),
    );
  }

  String _inferCasVariableName(ExpressionNode node, int position) {
    final collector = _CasVariableCollector();
    collector.visit(node);
    if (collector.names.isEmpty) {
      return 'x';
    }
    if (collector.names.length == 1) {
      return collector.names.single;
    }
    throw CalculatorException(
      CalculationError(
        type: CalculationErrorType.unsupportedCasTransform,
        message:
            'Bu CAS-lite transform birden fazla degisken icin variable argumani ister.',
        position: position,
        suggestion: 'Ornek: expand(expr, x) veya factor(expr, y).',
      ),
    );
  }

  List<FunctionExpression> _coerceFunctionExpressions(
    ExpressionNode node, {
    required int position,
  }) {
    if (node is ListLiteralNode) {
      if (node.elements.isEmpty) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidFunctionExpression,
            message: 'plot icin en az bir fonksiyon gerekli.',
            position: position,
          ),
        );
      }
      return node.elements
          .map(
            (element) => _coerceFunctionExpression(element, position: position),
          )
          .toList(growable: false);
    }
    return <FunctionExpression>[
      _coerceFunctionExpression(node, position: position),
    ];
  }

  FunctionExpression _coerceFunctionExpression(
    ExpressionNode node, {
    required int position,
  }) {
    if (node is FunctionCallNode) {
      final name = node.name.toLowerCase();
      if (name == 'fn' || name == 'function') {
        if (node.arguments.length != 1) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.invalidArgumentCount,
              message: '"${node.name}" fonksiyonu bir ifade bekler.',
              position: position,
            ),
          );
        }
        return _buildFunctionExpression(
          node.arguments.single,
          position: position,
        );
      }
    }
    return _buildFunctionExpression(node, position: position);
  }

  FunctionExpression _buildFunctionExpression(
    ExpressionNode expressionNode, {
    required int position,
  }) {
    _validateGraphExpression(expressionNode, position: position);
    final normalized = ExpressionPrinter().print(expressionNode);
    return FunctionExpression(
      originalExpression: normalized,
      normalizedExpression: normalized,
      expressionAst: expressionNode,
    );
  }

  void _validateGraphExpression(
    ExpressionNode node, {
    required int position,
    String variableName = 'x',
  }) {
    if (node is NumberNode) {
      return;
    }
    if (node is ConstantNode) {
      if (node.name == variableName ||
          node.name == 'pi' ||
          node.name == 'e' ||
          node.name == 'i' ||
          _scope.resolveVariable(node.name) != null) {
        return;
      }
      if (_context.unitMode == UnitMode.enabled &&
          UnitRegistry.instance.lookup(node.name) != null) {
        return;
      }
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.undefinedVariable,
          message:
              'Graph ifadelerinde yalnizca "$variableName" degiskeni ve tanimli sabitler kullanilabilir.',
          position: position,
          suggestion: 'Ornek: plot(sin(x), -pi, pi).',
        ),
      );
    }
    if (node is UnaryOperationNode) {
      _validateGraphExpression(
        node.operand,
        position: position,
        variableName: variableName,
      );
      return;
    }
    if (node is BinaryOperationNode) {
      _validateGraphExpression(
        node.left,
        position: position,
        variableName: variableName,
      );
      _validateGraphExpression(
        node.right,
        position: position,
        variableName: variableName,
      );
      return;
    }
    if (node is FunctionCallNode) {
      if (_scope.resolveFunction(node.name) == null &&
          !_isKnownFunction(node.name)) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.undefinedVariable,
            message:
                'Graph ifadelerinde "$node.name" icin tanimli bir fonksiyon bulunamadi.',
            position: position,
            suggestion: 'Ornek: plot(sin(x), -pi, pi).',
          ),
        );
      }
      for (final argument in node.arguments) {
        _validateGraphExpression(
          argument,
          position: position,
          variableName: variableName,
        );
      }
      return;
    }
    if (node is ListLiteralNode) {
      for (final element in node.elements) {
        _validateGraphExpression(
          element,
          position: position,
          variableName: variableName,
        );
      }
      return;
    }
    if (node is UnitAttachmentNode) {
      _validateGraphExpression(
        node.valueExpression,
        position: position,
        variableName: variableName,
      );
      _validateGraphExpression(
        node.unitExpression,
        position: position,
        variableName: variableName,
      );
      return;
    }
  }

  bool _isKnownFunction(String name) {
    return BuiltInSymbolCatalog.isBuiltInFunction(name);
  }

  EvaluatedValue _evaluateTrig(
    FunctionCallNode node,
    String functionName,
    EvaluatedValue argument,
  ) {
    if (_isVectorOrMatrixValue(argument.value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message:
              '$functionName vector ve matrix degerleri icin desteklenmiyor.',
          position: node.position,
        ),
      );
    }

    final scalarArgument = _requireDimensionlessValue(
      argument.value,
      position: node.position,
      functionName: functionName,
    );

    if (_isComplexValue(scalarArgument)) {
      if (_context.numericMode == NumericMode.exact) {
        _warnApproximation(
          '"$functionName" complex arguman icin approximate hesaplandi.',
        );
      }
      final result = _approximateComplexTrig(
        functionName,
        ComplexValue.promote(scalarArgument),
      );
      return _composeValue(
        result,
        inputs: <EvaluatedValue>[argument],
        approximate: true,
      );
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(scalarArgument)) {
      final exactResult = _tryExactTrigValue(
        functionName,
        scalarArgument,
        node.position,
      );
      if (exactResult != null) {
        return _exactValue(exactResult, node.position);
      }
      _warnApproximation(
        '"$functionName" exact table disinda approximate hesaplandi.',
      );
    }

    final numericValue = argument.value.toDouble();
    final radians = _toRadians(numericValue);
    switch (functionName) {
      case 'sin':
        return EvaluatedValue(
          value: DoubleValue(math.sin(radians)),
          isApproximate: true,
        );
      case 'cos':
        return EvaluatedValue(
          value: DoubleValue(math.cos(radians)),
          isApproximate: true,
        );
      case 'tan':
        final cosine = math.cos(radians);
        if (cosine.abs() < 1e-12) {
          warnings.add(
            'tan ifadesi tanimsizlik noktasina cok yakin; sonuc sayisal yaklasimdir.',
          );
        }
        return EvaluatedValue(
          value: DoubleValue(math.tan(radians)),
          isApproximate: true,
        );
      default:
        throw StateError('Unsupported trig function: $functionName');
    }
  }

  EvaluatedValue _evaluateInverseTrig(
    FunctionCallNode node,
    String functionName,
    EvaluatedValue argument,
  ) {
    if (_isVectorOrMatrixValue(argument.value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message:
              '$functionName vector ve matrix degerleri icin desteklenmiyor.',
          position: node.position,
        ),
      );
    }

    final scalarArgument = _requireDimensionlessValue(
      argument.value,
      position: node.position,
      functionName: functionName,
    );

    if (_isComplexValue(scalarArgument)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.domainError,
          message:
              '$functionName complex arguman icin bu fazda desteklenmiyor.',
          position: node.position,
          suggestion:
              'Real bir arguman veya desteklenen helper fonksiyonlari deneyin.',
        ),
      );
    }

    final numericValue = argument.value.toDouble();
    _assertUnitInterval(node, numericValue);

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(scalarArgument)) {
      final exactResult = _tryExactInverseTrigValue(
        functionName,
        scalarArgument,
        node.position,
      );
      if (exactResult != null) {
        return _exactValue(exactResult, node.position);
      }
      _warnApproximation(
        '"$functionName" exact table disinda approximate hesaplandi.',
      );
    }

    switch (functionName) {
      case 'asin':
        return EvaluatedValue(
          value: DoubleValue(_fromRadians(math.asin(numericValue))),
          isApproximate: true,
        );
      case 'acos':
        return EvaluatedValue(
          value: DoubleValue(_fromRadians(math.acos(numericValue))),
          isApproximate: true,
        );
      case 'atan':
        return EvaluatedValue(
          value: DoubleValue(_fromRadians(math.atan(numericValue))),
          isApproximate: true,
        );
      default:
        throw StateError('Unsupported inverse trig function: $functionName');
    }
  }

  EvaluatedValue _evaluateSqrt(FunctionCallNode node, EvaluatedValue argument) {
    if (_isVectorOrMatrixValue(argument.value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'sqrt vector ve matrix degerleri icin desteklenmiyor.',
          position: node.position,
        ),
      );
    }

    if (argument.value is UnitValue) {
      try {
        return _composeValue(
          UnitMath.squareRoot(argument.value as UnitValue),
          inputs: <EvaluatedValue>[argument],
        );
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.unsupportedOperation,
            message:
                error.message ??
                'Bu birimli ifade icin karekok islemi desteklenmiyor.',
            position: node.position,
          ),
        );
      }
    }

    if (_isComplexValue(argument.value)) {
      if (_context.calculationDomain != CalculationDomain.complex) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.domainError,
            message: 'sqrt complex arguman icin complex domain gerektirir.',
            position: node.position,
          ),
        );
      }
      if (_context.numericMode == NumericMode.exact) {
        _warnApproximation('Genel complex sqrt approximate hesaplandi.');
      }
      return _composeValue(
        _approximateComplexSquareRoot(ComplexValue.promote(argument.value)),
        inputs: <EvaluatedValue>[argument],
        approximate: true,
      );
    }

    final numericValue = argument.value.toDouble();
    if (numericValue < 0) {
      if (_context.calculationDomain == CalculationDomain.real) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.domainError,
            message: 'sqrt negatif sayilar icin real mode da tanimli degil.',
            position: node.position,
            suggestion: 'Bu ifade icin COMPLEX domain gerekli olabilir.',
          ),
        );
      }

      final complexValue = _complexSquareRootOfNegativeScalar(
        argument.value,
        node.position,
      );
      return _composeValue(complexValue, inputs: <EvaluatedValue>[argument]);
    }

    if (_context.numericMode == NumericMode.exact) {
      if (argument.value is RationalValue) {
        return _exactValue(
          _performExactOperation(
            () => SymbolicSimplifier.fromRadicalRational(
              argument.value as RationalValue,
            ),
            node.position,
          ),
          node.position,
        );
      }
      _warnApproximation(
        'sqrt symbolic exact table disinda approximate hesaplandi.',
      );
    }

    final root = math.sqrt(numericValue);
    final isExactRoot =
        _isNearlyInteger(numericValue) && _isNearlyInteger(root);
    return _composeValue(
      DoubleValue(root),
      inputs: <EvaluatedValue>[argument],
      approximate: !isExactRoot || _context.numericMode == NumericMode.exact,
    );
  }

  EvaluatedValue _evaluateVectorConstructor(
    FunctionCallNode node,
    List<EvaluatedValue> arguments,
  ) {
    if (arguments.isEmpty) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidArgumentCount,
          message: 'vec en az bir eleman bekliyor.',
          position: node.position,
        ),
      );
    }

    try {
      final values = <CalculatorValue>[];
      for (final argument in arguments) {
        _requireScalarValue(
          argument.value,
          position: node.position,
          message: 'Vector elemanlari scalar olmali.',
        );
        values.add(argument.value);
      }
      return _composeValue(
        LinearAlgebra.createVector(values),
        inputs: arguments,
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateMatrixConstructor(
    FunctionCallNode node,
    List<EvaluatedValue> arguments,
  ) {
    if (arguments.length < 3) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidArgumentCount,
          message: 'mat en az rows, cols ve bir deger bekliyor.',
          position: node.position,
        ),
      );
    }

    final rows = _requirePositiveInteger(
      arguments[0].value,
      position: node.position,
      parameterName: 'rows',
    );
    final columns = _requirePositiveInteger(
      arguments[1].value,
      position: node.position,
      parameterName: 'cols',
    );
    final values = <CalculatorValue>[];
    for (final argument in arguments.skip(2)) {
      _requireScalarValue(
        argument.value,
        position: node.position,
        message: 'Matrix girisleri scalar olmali.',
      );
      values.add(argument.value);
    }

    try {
      return _composeValue(
        LinearAlgebra.createMatrix(rows, columns, values),
        inputs: arguments,
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateIdentity(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    final size = _requirePositiveInteger(
      argument.value,
      position: node.position,
      parameterName: 'size',
    );
    try {
      return _composeValue(
        LinearAlgebra.identity(size),
        inputs: <EvaluatedValue>[argument],
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateZeros(
    FunctionCallNode node,
    EvaluatedValue rows,
    EvaluatedValue columns,
  ) {
    final rowCount = _requirePositiveInteger(
      rows.value,
      position: node.position,
      parameterName: 'rows',
    );
    final columnCount = _requirePositiveInteger(
      columns.value,
      position: node.position,
      parameterName: 'cols',
    );
    try {
      return _composeValue(
        LinearAlgebra.zeros(rowCount, columnCount),
        inputs: <EvaluatedValue>[rows, columns],
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateOnes(
    FunctionCallNode node,
    EvaluatedValue rows,
    EvaluatedValue columns,
  ) {
    final rowCount = _requirePositiveInteger(
      rows.value,
      position: node.position,
      parameterName: 'rows',
    );
    final columnCount = _requirePositiveInteger(
      columns.value,
      position: node.position,
      parameterName: 'cols',
    );
    try {
      return _composeValue(
        LinearAlgebra.ones(rowCount, columnCount),
        inputs: <EvaluatedValue>[rows, columns],
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateDiag(
    FunctionCallNode node,
    List<EvaluatedValue> arguments,
  ) {
    if (arguments.isEmpty) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidArgumentCount,
          message: 'diag en az bir deger bekliyor.',
          position: node.position,
        ),
      );
    }

    final diagonalEntries = <CalculatorValue>[];
    if (arguments.length == 1 && arguments.single.value is VectorValue) {
      diagonalEntries.addAll((arguments.single.value as VectorValue).elements);
    } else {
      for (final argument in arguments) {
        _requireScalarValue(
          argument.value,
          position: node.position,
          message: 'diag scalar degerler veya tek bir vector bekler.',
        );
        diagonalEntries.add(argument.value);
      }
    }

    try {
      return _composeValue(
        LinearAlgebra.diagonal(diagonalEntries),
        inputs: arguments,
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateDot(
    FunctionCallNode node,
    EvaluatedValue left,
    EvaluatedValue right,
  ) {
    if (left.value is! VectorValue || right.value is! VectorValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'dot iki vector bekler.',
          position: node.position,
        ),
      );
    }
    try {
      return _composeValue(
        LinearAlgebra.dot(
          left.value as VectorValue,
          right.value as VectorValue,
        ),
        inputs: <EvaluatedValue>[left, right],
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateCross(
    FunctionCallNode node,
    EvaluatedValue left,
    EvaluatedValue right,
  ) {
    if (left.value is! VectorValue || right.value is! VectorValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'cross iki vector bekler.',
          position: node.position,
        ),
      );
    }
    try {
      return _composeValue(
        LinearAlgebra.cross(
          left.value as VectorValue,
          right.value as VectorValue,
        ),
        inputs: <EvaluatedValue>[left, right],
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateNorm(FunctionCallNode node, EvaluatedValue argument) {
    if (argument.value is! VectorValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'norm bir vector bekler.',
          position: node.position,
        ),
      );
    }
    try {
      return _composeValue(
        LinearAlgebra.norm(argument.value as VectorValue),
        inputs: <EvaluatedValue>[argument],
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateUnit(FunctionCallNode node, EvaluatedValue argument) {
    if (argument.value is! VectorValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'unit bir vector bekler.',
          position: node.position,
        ),
      );
    }
    try {
      return _composeValue(
        LinearAlgebra.unit(argument.value as VectorValue),
        inputs: <EvaluatedValue>[argument],
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateTranspose(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    if (argument.value is! MatrixValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'transpose bir matrix bekler.',
          position: node.position,
        ),
      );
    }
    return _composeValue(
      LinearAlgebra.transpose(argument.value as MatrixValue),
      inputs: <EvaluatedValue>[argument],
    );
  }

  EvaluatedValue _evaluateDeterminant(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    if (argument.value is! MatrixValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'det bir matrix bekler.',
          position: node.position,
        ),
      );
    }
    try {
      return _composeValue(
        LinearAlgebra.determinant(argument.value as MatrixValue),
        inputs: <EvaluatedValue>[argument],
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateInverse(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    if (argument.value is! MatrixValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'inv bir matrix bekler.',
          position: node.position,
        ),
      );
    }
    try {
      return _composeValue(
        LinearAlgebra.inverse(argument.value as MatrixValue),
        inputs: <EvaluatedValue>[argument],
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateLinearSystemSolve(
    FunctionCallNode node,
    EvaluatedValue matrix,
    EvaluatedValue vector,
  ) {
    if (matrix.value is! MatrixValue || vector.value is! VectorValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidSystem,
          message: 'linsolve bir matrix ve bir vector bekler.',
          position: node.position,
        ),
      );
    }
    final solution = const CasSystemSolver().linsolve(
      matrix.value as MatrixValue,
      vector.value as VectorValue,
    );
    return _composeValue(solution, inputs: <EvaluatedValue>[matrix, vector]);
  }

  EvaluatedValue _evaluateTrace(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    if (argument.value is! MatrixValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'trace bir matrix bekler.',
          position: node.position,
        ),
      );
    }
    try {
      return _composeValue(
        LinearAlgebra.trace(argument.value as MatrixValue),
        inputs: <EvaluatedValue>[argument],
      );
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, node.position);
    }
  }

  EvaluatedValue _evaluateConversion(
    FunctionCallNode node,
    EvaluatedValue source,
    EvaluatedValue target,
  ) {
    if (source.value is! UnitValue ||
        (source.value as UnitValue).isUnitExpressionOnly) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidUnitConversion,
          message: 'to(...) kaynagi fiziksel bir buyukluk olmali.',
          position: node.position,
          suggestion: 'Ornek: to(100 cm, m)',
        ),
      );
    }
    if (target.value is! UnitValue ||
        !(target.value as UnitValue).isUnitExpressionOnly) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidUnitConversion,
          message: 'to(...) hedefi yalnizca bir birim ifadesi olmali.',
          position: node.position,
          suggestion: 'Ornek: to(5 km/h, m/s)',
        ),
      );
    }

    final sourceUnit = source.value as UnitValue;
    final targetUnit = (target.value as UnitValue).displayUnit;
    try {
      return _composeValue(
        UnitMath.convert(sourceUnit, targetUnit),
        inputs: <EvaluatedValue>[source],
      );
    } on UnsupportedError {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidUnitConversion,
          message: 'Kaynak ve hedef birimler birbiriyle uyumlu degil.',
          position: node.position,
          suggestion: 'Ayni boyuta sahip birimler arasinda donusum yapin.',
        ),
      );
    }
  }

  EvaluatedValue _evaluateDatasetConstructor(
    FunctionCallNode node,
    List<EvaluatedValue> arguments,
  ) {
    if (arguments.isEmpty) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidDataset,
          message: 'data(...) en az bir deger bekler.',
          position: node.position,
          suggestion: 'Ornek: data(1, 2, 3, 4)',
        ),
      );
    }

    final values = <CalculatorValue>[];
    if (arguments.length == 1 && arguments.single.value is VectorValue) {
      values.addAll((arguments.single.value as VectorValue).elements);
    } else {
      for (final argument in arguments) {
        if (argument.value is DatasetValue) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.invalidDataset,
              message: 'Nested dataset degerleri bu fazda desteklenmiyor.',
              position: node.position,
            ),
          );
        }
        if (argument.value is VectorValue || argument.value is MatrixValue) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.unsupportedOperation,
              message:
                  'data(...) icinde vector veya matrix ic ice kullanimi desteklenmiyor.',
              position: node.position,
            ),
          );
        }
        values.add(argument.value);
      }
    }

    try {
      final dataset = DatasetValue(values);
      return _composeValue(
        dataset,
        inputs: arguments,
        statisticName: 'data',
        sampleSize: dataset.length,
      );
    } on ArgumentError {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidDataset,
          message: 'Dataset bos olamaz.',
          position: node.position,
        ),
      );
    }
  }

  EvaluatedValue _evaluateCount(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    final dataset = _coerceDatasetValue(node, argument, functionName: 'count');
    return _composeValue(
      DescriptiveStatistics.count(dataset),
      inputs: <EvaluatedValue>[argument],
      statisticName: 'count',
      sampleSize: dataset.length,
    );
  }

  EvaluatedValue _evaluateDatasetStatistic(
    FunctionCallNode node,
    String statisticName,
    EvaluatedValue argument,
  ) {
    final dataset = _coerceDatasetValue(
      node,
      argument,
      functionName: statisticName,
    );
    try {
      final value = switch (statisticName) {
        'sum' => DescriptiveStatistics.sum(dataset),
        'product' => DescriptiveStatistics.product(dataset),
        'mean' => DescriptiveStatistics.mean(dataset),
        'median' => DescriptiveStatistics.median(dataset),
        'mode' => DescriptiveStatistics.mode(dataset),
        'range' => DescriptiveStatistics.range(dataset),
        'min' => DescriptiveStatistics.min(dataset),
        'max' => DescriptiveStatistics.max(dataset),
        'varp' => DescriptiveStatistics.variancePopulation(dataset),
        'vars' => DescriptiveStatistics.varianceSample(dataset),
        'stdp' => DescriptiveStatistics.standardDeviationPopulation(dataset),
        'stds' => DescriptiveStatistics.standardDeviationSample(dataset),
        'mad' => DescriptiveStatistics.meanAbsoluteDeviation(dataset),
        _ => throw StateError('Unsupported dataset statistic: $statisticName'),
      };
      return _composeValue(
        value,
        inputs: <EvaluatedValue>[argument],
        statisticName: statisticName,
        sampleSize: dataset.length,
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateQuantile(
    FunctionCallNode node,
    EvaluatedValue datasetArgument,
    EvaluatedValue quantileArgument,
  ) {
    final dataset = _coerceDatasetValue(
      node,
      datasetArgument,
      functionName: 'quantile',
    );
    final quantileValue = _requireDimensionlessRealScalar(
      node,
      quantileArgument,
      functionName: 'quantile',
      errorType: CalculationErrorType.invalidStatisticsArgument,
    );
    final sorted = dataset.sortedValues(StatisticsScalarMath.compare);

    try {
      final exactQ = _tryCollapseToRational(quantileValue);
      final result = exactQ != null
          ? _interpolateQuantileExact(sorted, exactQ)
          : _interpolateQuantileApproximate(sorted, quantileValue.toDouble());
      return _composeValue(
        result,
        inputs: <EvaluatedValue>[datasetArgument, quantileArgument],
        statisticName: 'quantile',
        sampleSize: dataset.length,
        approximate:
            exactQ == null ||
            quantileArgument.isApproximate ||
            quantileValue is DoubleValue,
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluatePercentile(
    FunctionCallNode node,
    EvaluatedValue datasetArgument,
    EvaluatedValue percentileArgument,
  ) {
    final percentileValue = _requireDimensionlessRealScalar(
      node,
      percentileArgument,
      functionName: 'percentile',
      errorType: CalculationErrorType.invalidStatisticsArgument,
    );
    final exact = _tryCollapseToRational(percentileValue);
    final quantile = exact != null
        ? exact.divide(RationalValue.fromInt(100))
        : DoubleValue(percentileValue.toDouble() / 100);
    return _evaluateQuantile(
      node,
      datasetArgument,
      EvaluatedValue(
        value: quantile,
        isApproximate:
            percentileArgument.isApproximate || quantile is DoubleValue,
        statisticName: 'percentile',
      ),
    );
  }

  EvaluatedValue _evaluateQuartiles(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    final dataset = _coerceDatasetValue(
      node,
      argument,
      functionName: 'quartiles',
    );
    try {
      final sorted = dataset.sortedValues(StatisticsScalarMath.compare);
      final q1 = _interpolateQuantileExact(
        sorted,
        RationalValue(BigInt.one, BigInt.from(4)),
      );
      final q2 = _interpolateQuantileExact(
        sorted,
        RationalValue(BigInt.one, BigInt.from(2)),
      );
      final q3 = _interpolateQuantileExact(
        sorted,
        RationalValue(BigInt.from(3), BigInt.from(4)),
      );
      return _composeValue(
        VectorValue(<CalculatorValue>[q1, q2, q3]),
        inputs: <EvaluatedValue>[argument],
        statisticName: 'quartiles',
        sampleSize: dataset.length,
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateIqr(FunctionCallNode node, EvaluatedValue argument) {
    final dataset = _coerceDatasetValue(node, argument, functionName: 'iqr');
    try {
      final sorted = dataset.sortedValues(StatisticsScalarMath.compare);
      final q1 = _interpolateQuantileExact(
        sorted,
        RationalValue(BigInt.one, BigInt.from(4)),
      );
      final q3 = _interpolateQuantileExact(
        sorted,
        RationalValue(BigInt.from(3), BigInt.from(4)),
      );
      return _composeValue(
        StatisticsScalarMath.subtract(q3, q1),
        inputs: <EvaluatedValue>[argument],
        statisticName: 'iqr',
        sampleSize: dataset.length,
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateWeightedMean(
    FunctionCallNode node,
    EvaluatedValue valuesArgument,
    EvaluatedValue weightsArgument,
  ) {
    final values = _coerceDatasetValue(
      node,
      valuesArgument,
      functionName: 'wmean',
    );
    final weights = _coerceDatasetValue(
      node,
      weightsArgument,
      functionName: 'wmean',
    );
    try {
      return _composeValue(
        DescriptiveStatistics.weightedMean(values, weights),
        inputs: <EvaluatedValue>[valuesArgument, weightsArgument],
        statisticName: 'wmean',
        sampleSize: values.length,
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateFactorial(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    final n = _requireNonNegativeIntegerArgument(
      node,
      argument,
      functionName: 'factorial',
    );
    try {
      return _composeValue(
        RationalValue(StatisticsCombinatorics.factorial(n), BigInt.one),
        inputs: <EvaluatedValue>[argument],
        statisticName: 'factorial',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateCombination(
    FunctionCallNode node,
    EvaluatedValue nArgument,
    EvaluatedValue rArgument,
  ) {
    final n = _requireNonNegativeIntegerArgument(
      node,
      nArgument,
      functionName: 'nCr',
    );
    final r = _requireNonNegativeIntegerArgument(
      node,
      rArgument,
      functionName: 'nCr',
    );
    try {
      return _composeValue(
        RationalValue(StatisticsCombinatorics.combinations(n, r), BigInt.one),
        inputs: <EvaluatedValue>[nArgument, rArgument],
        statisticName: 'nCr',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluatePermutation(
    FunctionCallNode node,
    EvaluatedValue nArgument,
    EvaluatedValue rArgument,
  ) {
    final n = _requireNonNegativeIntegerArgument(
      node,
      nArgument,
      functionName: 'nPr',
    );
    final r = _requireNonNegativeIntegerArgument(
      node,
      rArgument,
      functionName: 'nPr',
    );
    try {
      return _composeValue(
        RationalValue(StatisticsCombinatorics.permutations(n, r), BigInt.one),
        inputs: <EvaluatedValue>[nArgument, rArgument],
        statisticName: 'nPr',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateBinomialPmf(
    FunctionCallNode node,
    EvaluatedValue nArgument,
    EvaluatedValue pArgument,
    EvaluatedValue kArgument,
  ) {
    final n = _requireNonNegativeIntegerArgument(
      node,
      nArgument,
      functionName: 'binomPmf',
    );
    final pValue = _requireDimensionlessRealScalar(
      node,
      pArgument,
      functionName: 'binomPmf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final k = _requireNonNegativeIntegerArgument(
      node,
      kArgument,
      functionName: 'binomPmf',
    );

    try {
      final exactP = _tryCollapseToRational(pValue);
      if (_context.numericMode == NumericMode.exact && exactP != null) {
        return _composeValue(
          StatisticsDistributions.binomialPmfExact(n, exactP, k),
          inputs: <EvaluatedValue>[nArgument, pArgument, kArgument],
          statisticName: 'binomPmf',
        );
      }
      return _composeValue(
        DoubleValue(
          StatisticsDistributions.binomialPmf(n, pValue.toDouble(), k),
        ),
        inputs: <EvaluatedValue>[nArgument, pArgument, kArgument],
        approximate: true,
        statisticName: 'binomPmf',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateBinomialCdf(
    FunctionCallNode node,
    EvaluatedValue nArgument,
    EvaluatedValue pArgument,
    EvaluatedValue kArgument,
  ) {
    final n = _requireNonNegativeIntegerArgument(
      node,
      nArgument,
      functionName: 'binomCdf',
    );
    final pValue = _requireDimensionlessRealScalar(
      node,
      pArgument,
      functionName: 'binomCdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final k = _requireNonNegativeIntegerArgument(
      node,
      kArgument,
      functionName: 'binomCdf',
    );

    try {
      final exactP = _tryCollapseToRational(pValue);
      if (_context.numericMode == NumericMode.exact && exactP != null) {
        return _composeValue(
          StatisticsDistributions.binomialCdfExact(n, exactP, k),
          inputs: <EvaluatedValue>[nArgument, pArgument, kArgument],
          statisticName: 'binomCdf',
        );
      }
      return _composeValue(
        DoubleValue(
          StatisticsDistributions.binomialCdf(n, pValue.toDouble(), k),
        ),
        inputs: <EvaluatedValue>[nArgument, pArgument, kArgument],
        approximate: true,
        statisticName: 'binomCdf',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluatePoissonPmf(
    FunctionCallNode node,
    EvaluatedValue kArgument,
    EvaluatedValue lambdaArgument,
  ) {
    final k = _requireNonNegativeIntegerArgument(
      node,
      kArgument,
      functionName: 'poissonPmf',
    );
    final lambda = _requireDimensionlessRealScalar(
      node,
      lambdaArgument,
      functionName: 'poissonPmf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    try {
      return _composeValue(
        DoubleValue(StatisticsDistributions.poissonPmf(k, lambda.toDouble())),
        inputs: <EvaluatedValue>[kArgument, lambdaArgument],
        approximate: true,
        statisticName: 'poissonPmf',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluatePoissonCdf(
    FunctionCallNode node,
    EvaluatedValue kArgument,
    EvaluatedValue lambdaArgument,
  ) {
    final k = _requireNonNegativeIntegerArgument(
      node,
      kArgument,
      functionName: 'poissonCdf',
    );
    final lambda = _requireDimensionlessRealScalar(
      node,
      lambdaArgument,
      functionName: 'poissonCdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    try {
      return _composeValue(
        DoubleValue(StatisticsDistributions.poissonCdf(k, lambda.toDouble())),
        inputs: <EvaluatedValue>[kArgument, lambdaArgument],
        approximate: true,
        statisticName: 'poissonCdf',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateGeometricPmf(
    FunctionCallNode node,
    EvaluatedValue pArgument,
    EvaluatedValue kArgument,
  ) {
    final pValue = _requireDimensionlessRealScalar(
      node,
      pArgument,
      functionName: 'geomPmf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final k = _requirePositiveIntegerArgument(
      node,
      kArgument,
      functionName: 'geomPmf',
    );
    try {
      final exactP = _tryCollapseToRational(pValue);
      if (_context.numericMode == NumericMode.exact && exactP != null) {
        return _composeValue(
          StatisticsDistributions.geometricPmfExact(exactP, k),
          inputs: <EvaluatedValue>[pArgument, kArgument],
          statisticName: 'geomPmf',
        );
      }
      return _composeValue(
        DoubleValue(StatisticsDistributions.geometricPmf(pValue.toDouble(), k)),
        inputs: <EvaluatedValue>[pArgument, kArgument],
        approximate: true,
        statisticName: 'geomPmf',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateGeometricCdf(
    FunctionCallNode node,
    EvaluatedValue pArgument,
    EvaluatedValue kArgument,
  ) {
    final pValue = _requireDimensionlessRealScalar(
      node,
      pArgument,
      functionName: 'geomCdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final k = _requirePositiveIntegerArgument(
      node,
      kArgument,
      functionName: 'geomCdf',
    );
    try {
      final exactP = _tryCollapseToRational(pValue);
      if (_context.numericMode == NumericMode.exact && exactP != null) {
        return _composeValue(
          StatisticsDistributions.geometricCdfExact(exactP, k),
          inputs: <EvaluatedValue>[pArgument, kArgument],
          statisticName: 'geomCdf',
        );
      }
      return _composeValue(
        DoubleValue(StatisticsDistributions.geometricCdf(pValue.toDouble(), k)),
        inputs: <EvaluatedValue>[pArgument, kArgument],
        approximate: true,
        statisticName: 'geomCdf',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateNormalPdf(
    FunctionCallNode node,
    EvaluatedValue xArgument,
    EvaluatedValue meanArgument,
    EvaluatedValue sdArgument,
  ) {
    final x = _requireDimensionlessRealScalar(
      node,
      xArgument,
      functionName: 'normalPdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final mean = _requireDimensionlessRealScalar(
      node,
      meanArgument,
      functionName: 'normalPdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final sd = _requireDimensionlessRealScalar(
      node,
      sdArgument,
      functionName: 'normalPdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    try {
      return _composeValue(
        DoubleValue(
          StatisticsDistributions.normalPdf(
            x.toDouble(),
            mean.toDouble(),
            sd.toDouble(),
          ),
        ),
        inputs: <EvaluatedValue>[xArgument, meanArgument, sdArgument],
        approximate: true,
        statisticName: 'normalPdf',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateNormalCdf(
    FunctionCallNode node,
    EvaluatedValue xArgument,
    EvaluatedValue meanArgument,
    EvaluatedValue sdArgument,
  ) {
    final x = _requireDimensionlessRealScalar(
      node,
      xArgument,
      functionName: 'normalCdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final mean = _requireDimensionlessRealScalar(
      node,
      meanArgument,
      functionName: 'normalCdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final sd = _requireDimensionlessRealScalar(
      node,
      sdArgument,
      functionName: 'normalCdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    try {
      return _composeValue(
        DoubleValue(
          StatisticsDistributions.normalCdf(
            x.toDouble(),
            mean.toDouble(),
            sd.toDouble(),
          ),
        ),
        inputs: <EvaluatedValue>[xArgument, meanArgument, sdArgument],
        approximate: true,
        statisticName: 'normalCdf',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateZScore(
    FunctionCallNode node,
    EvaluatedValue xArgument,
    EvaluatedValue meanArgument,
    EvaluatedValue sdArgument,
  ) {
    final x = _requireDimensionlessRealScalar(
      node,
      xArgument,
      functionName: 'zscore',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final mean = _requireDimensionlessRealScalar(
      node,
      meanArgument,
      functionName: 'zscore',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final sd = _requireDimensionlessRealScalar(
      node,
      sdArgument,
      functionName: 'zscore',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    try {
      return _composeValue(
        DoubleValue(
          StatisticsDistributions.zScore(
            x.toDouble(),
            mean.toDouble(),
            sd.toDouble(),
          ),
        ),
        inputs: <EvaluatedValue>[xArgument, meanArgument, sdArgument],
        approximate: true,
        statisticName: 'zscore',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateUniformPdf(
    FunctionCallNode node,
    EvaluatedValue xArgument,
    EvaluatedValue aArgument,
    EvaluatedValue bArgument,
  ) {
    final x = _requireDimensionlessRealScalar(
      node,
      xArgument,
      functionName: 'uniformPdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final a = _requireDimensionlessRealScalar(
      node,
      aArgument,
      functionName: 'uniformPdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final b = _requireDimensionlessRealScalar(
      node,
      bArgument,
      functionName: 'uniformPdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    try {
      return _composeValue(
        DoubleValue(
          StatisticsDistributions.uniformPdf(
            x.toDouble(),
            a.toDouble(),
            b.toDouble(),
          ),
        ),
        inputs: <EvaluatedValue>[xArgument, aArgument, bArgument],
        approximate: true,
        statisticName: 'uniformPdf',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateUniformCdf(
    FunctionCallNode node,
    EvaluatedValue xArgument,
    EvaluatedValue aArgument,
    EvaluatedValue bArgument,
  ) {
    final x = _requireDimensionlessRealScalar(
      node,
      xArgument,
      functionName: 'uniformCdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final a = _requireDimensionlessRealScalar(
      node,
      aArgument,
      functionName: 'uniformCdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    final b = _requireDimensionlessRealScalar(
      node,
      bArgument,
      functionName: 'uniformCdf',
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    try {
      return _composeValue(
        DoubleValue(
          StatisticsDistributions.uniformCdf(
            x.toDouble(),
            a.toDouble(),
            b.toDouble(),
          ),
        ),
        inputs: <EvaluatedValue>[xArgument, aArgument, bArgument],
        approximate: true,
        statisticName: 'uniformCdf',
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateCovariance(
    FunctionCallNode node,
    EvaluatedValue xArgument,
    EvaluatedValue yArgument, {
    required bool sample,
  }) {
    final xDataset = _coerceDatasetValue(node, xArgument, functionName: 'cov');
    final yDataset = _coerceDatasetValue(node, yArgument, functionName: 'cov');
    try {
      final value = sample
          ? StatisticsRegression.covarianceSample(xDataset, yDataset)
          : StatisticsRegression.covariancePopulation(xDataset, yDataset);
      return _composeValue(
        value,
        inputs: <EvaluatedValue>[xArgument, yArgument],
        statisticName: sample ? 'covs' : 'covp',
        sampleSize: xDataset.length,
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateCorrelation(
    FunctionCallNode node,
    EvaluatedValue xArgument,
    EvaluatedValue yArgument,
  ) {
    final xDataset = _coerceDatasetValue(node, xArgument, functionName: 'corr');
    final yDataset = _coerceDatasetValue(node, yArgument, functionName: 'corr');
    try {
      return _composeValue(
        StatisticsRegression.correlation(xDataset, yDataset),
        inputs: <EvaluatedValue>[xArgument, yArgument],
        statisticName: 'corr',
        sampleSize: xDataset.length,
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateLinearRegression(
    FunctionCallNode node,
    EvaluatedValue xArgument,
    EvaluatedValue yArgument,
  ) {
    final xDataset = _coerceDatasetValue(
      node,
      xArgument,
      functionName: 'linreg',
    );
    final yDataset = _coerceDatasetValue(
      node,
      yArgument,
      functionName: 'linreg',
    );
    try {
      return _composeValue(
        StatisticsRegression.linearRegression(xDataset, yDataset),
        inputs: <EvaluatedValue>[xArgument, yArgument],
        statisticName: 'linreg',
        sampleSize: xDataset.length,
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateLinearPrediction(
    FunctionCallNode node,
    EvaluatedValue xArgument,
    EvaluatedValue yArgument,
    EvaluatedValue predictArgument,
  ) {
    final xDataset = _coerceDatasetValue(
      node,
      xArgument,
      functionName: 'linpred',
    );
    final yDataset = _coerceDatasetValue(
      node,
      yArgument,
      functionName: 'linpred',
    );
    try {
      final regression = StatisticsRegression.linearRegression(
        xDataset,
        yDataset,
      );
      final xValue = _requireDimensionlessRealScalar(
        node,
        predictArgument,
        functionName: 'linpred',
        errorType: CalculationErrorType.invalidStatisticsArgument,
      );
      return _composeValue(
        StatisticsRegression.predict(regression, xValue),
        inputs: <EvaluatedValue>[xArgument, yArgument, predictArgument],
        statisticName: 'linpred',
        sampleSize: xDataset.length,
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  EvaluatedValue _evaluateAbs(FunctionCallNode node, EvaluatedValue argument) {
    final value = argument.value;
    if (value is VectorValue) {
      return _composeValue(
        LinearAlgebra.norm(value),
        inputs: <EvaluatedValue>[argument],
      );
    }
    if (value is MatrixValue) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'abs matrix degerleri icin bu fazda desteklenmiyor.',
          position: node.position,
        ),
      );
    }
    if (value is ComplexValue) {
      return _composeValue(
        value.magnitude(),
        inputs: <EvaluatedValue>[argument],
      );
    }
    if (value is UnitValue) {
      return _composeValue(
        UnitMath.abs(value),
        inputs: <EvaluatedValue>[argument],
      );
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(value)) {
      return _exactValue(ScalarValueMath.abs(value), node.position);
    }

    return _composeValue(
      DoubleValue(value.toDouble().abs()),
      inputs: <EvaluatedValue>[argument],
      approximate: argument.isApproximate,
    );
  }

  EvaluatedValue _evaluateConjugate(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    final value = argument.value;
    if (_isVectorOrMatrixValue(value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message:
              'conj vector ve matrix degerleri icin bu fazda desteklenmiyor.',
          position: node.position,
        ),
      );
    }
    if (value is ComplexValue) {
      return _composeValue(
        value.conjugate().simplify(),
        inputs: <EvaluatedValue>[argument],
      );
    }
    return _composeValue(value, inputs: <EvaluatedValue>[argument]);
  }

  EvaluatedValue _evaluateRealPart(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    final value = argument.value;
    if (_isVectorOrMatrixValue(value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 're vector ve matrix degerleri icin desteklenmiyor.',
          position: node.position,
        ),
      );
    }
    if (value is ComplexValue) {
      return _composeValue(
        ScalarValueMath.collapse(value.realPart),
        inputs: <EvaluatedValue>[argument],
      );
    }
    return _composeValue(value, inputs: <EvaluatedValue>[argument]);
  }

  EvaluatedValue _evaluateImaginaryPart(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    final value = argument.value;
    if (_isVectorOrMatrixValue(value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'im vector ve matrix degerleri icin desteklenmiyor.',
          position: node.position,
        ),
      );
    }
    if (value is ComplexValue) {
      return _composeValue(
        ScalarValueMath.collapse(value.imaginaryPart),
        inputs: <EvaluatedValue>[argument],
      );
    }
    return EvaluatedValue(value: RationalValue.zero, isApproximate: false);
  }

  EvaluatedValue _evaluateArgument(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    final argumentValue = argument.value is UnitValue
        ? _requireDimensionlessValue(
            argument.value,
            position: node.position,
            functionName: node.name,
          )
        : argument.value;

    if (_isVectorOrMatrixValue(argumentValue)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'arg vector ve matrix degerleri icin desteklenmiyor.',
          position: node.position,
        ),
      );
    }
    final exact = _context.numericMode == NumericMode.exact
        ? _tryExactArgumentValue(argumentValue, node.position)
        : null;
    if (exact != null) {
      return _exactValue(exact, node.position);
    }

    if (_context.numericMode == NumericMode.exact &&
        (_isComplexValue(argumentValue) ||
            _context.calculationDomain == CalculationDomain.complex)) {
      _warnApproximation('arg exact table disinda approximate hesaplandi.');
    }

    final radians = argumentValue is ComplexValue
        ? argumentValue.argumentRadiansApproximate()
        : _approximateScalarArgument(argumentValue);
    return EvaluatedValue(
      value: DoubleValue(_fromRadians(radians)),
      isApproximate: true,
    );
  }

  EvaluatedValue _evaluatePolar(
    FunctionCallNode node,
    EvaluatedValue radius,
    EvaluatedValue angle,
  ) {
    final angleValue = _requireDimensionlessValue(
      angle.value,
      position: node.position,
      functionName: node.name,
    );

    if (_isVectorOrMatrixValue(radius.value) ||
        _isVectorOrMatrixValue(angleValue)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'polar scalar radius ve scalar angle bekler.',
          position: node.position,
        ),
      );
    }
    if (_context.calculationDomain != CalculationDomain.complex) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.domainError,
          message: 'polar fonksiyonu COMPLEX domain gerektirir.',
          position: node.position,
          suggestion: 'REAL/COMPLEX secimini COMPLEX yapin.',
        ),
      );
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(radius.value) &&
        _isExactScalarValue(angleValue)) {
      final exactCis = _tryExactCisValue(
        angleValue,
        node.position,
        angleMode: _context.angleMode,
      );
      if (exactCis != null) {
        return _exactValue(
          _multiplyRawValues(radius.value, exactCis, node.position),
          node.position,
        );
      }
      _warnApproximation('polar exact table disinda approximate hesaplandi.');
    }

    final radians = _toRadians(angleValue.toDouble());
    final r = radius.value.toDouble();
    return _composeValue(
      ComplexValue(
        realPart: DoubleValue(r * math.cos(radians)),
        imaginaryPart: DoubleValue(r * math.sin(radians)),
      ).simplify(),
      inputs: <EvaluatedValue>[radius, angle],
      approximate: true,
    );
  }

  EvaluatedValue _evaluateCis(FunctionCallNode node, EvaluatedValue angle) {
    final angleValue = _requireDimensionlessValue(
      angle.value,
      position: node.position,
      functionName: node.name,
    );

    if (_isVectorOrMatrixValue(angleValue)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'cis scalar bir angle bekler.',
          position: node.position,
        ),
      );
    }
    if (_context.calculationDomain != CalculationDomain.complex) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.domainError,
          message: 'cis fonksiyonu COMPLEX domain gerektirir.',
          position: node.position,
          suggestion: 'REAL/COMPLEX secimini COMPLEX yapin.',
        ),
      );
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(angleValue)) {
      final exact = _tryExactCisValue(
        angleValue,
        node.position,
        angleMode: _context.angleMode,
      );
      if (exact != null) {
        return _exactValue(exact, node.position);
      }
      _warnApproximation('cis exact table disinda approximate hesaplandi.');
    }

    final radians = _toRadians(angleValue.toDouble());
    return _composeValue(
      ComplexValue(
        realPart: DoubleValue(math.cos(radians)),
        imaginaryPart: DoubleValue(math.sin(radians)),
      ).simplify(),
      inputs: <EvaluatedValue>[angle],
      approximate: true,
    );
  }

  EvaluatedValue _evaluateNaturalLog(
    FunctionCallNode node,
    EvaluatedValue argument,
  ) {
    final value = _requireDimensionlessValue(
      argument.value,
      position: node.position,
      functionName: node.name,
    );
    if (_isVectorOrMatrixValue(value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'ln vector ve matrix degerleri icin desteklenmiyor.',
          position: node.position,
        ),
      );
    }
    if (_isComplexValue(value)) {
      return _evaluateComplexNaturalLog(
        node,
        ComplexValue.promote(value),
        argument,
      );
    }

    final numericValue = value.toDouble();
    if (numericValue <= 0) {
      if (_context.calculationDomain == CalculationDomain.real) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.domainError,
            message: 'ln pozitif arguman gerektirir.',
            position: node.position,
            suggestion: 'Sifirdan buyuk bir deger deneyin.',
          ),
        );
      }
      return _evaluateComplexNaturalLog(
        node,
        ComplexValue.fromScalar(value),
        argument,
      );
    }

    _warnApproximation('"ln" exact mode da approximate hesaplandi.');
    return EvaluatedValue(
      value: DoubleValue(math.log(numericValue)),
      isApproximate: true,
    );
  }

  EvaluatedValue _evaluateLogarithm(
    FunctionCallNode node,
    EvaluatedValue argument, {
    required int base,
  }) {
    final naturalLog = _evaluateNaturalLog(node, argument);
    if (_isComplexValue(naturalLog.value)) {
      final divisor = DoubleValue(math.log(base.toDouble()));
      return _composeValue(
        _divideRawValues(naturalLog.value, divisor, node.position),
        inputs: <EvaluatedValue>[argument],
        approximate: true,
      );
    }

    final numericValue = _requireDimensionlessValue(
      argument.value,
      position: node.position,
      functionName: node.name,
    ).toDouble();
    _assertPositive(node, numericValue, node.name);
    _warnApproximation('"${node.name}" exact mode da approximate hesaplandi.');
    return EvaluatedValue(
      value: DoubleValue(math.log(numericValue) / math.log(base.toDouble())),
      isApproximate: true,
    );
  }

  EvaluatedValue _evaluateExp(FunctionCallNode node, EvaluatedValue argument) {
    final value = _requireDimensionlessValue(
      argument.value,
      position: node.position,
      functionName: node.name,
    );
    if (_isVectorOrMatrixValue(value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: 'exp vector ve matrix degerleri icin desteklenmiyor.',
          position: node.position,
        ),
      );
    }
    if (_isComplexValue(value)) {
      final complex = ComplexValue.promote(value);
      if (_context.numericMode == NumericMode.exact &&
          _isZeroValue(complex.realPart) &&
          _isExactScalarValue(complex.imaginaryPart)) {
        final exact = _tryExactCisValue(
          complex.imaginaryPart,
          node.position,
          angleMode: AngleMode.radian,
        );
        if (exact != null) {
          return _exactValue(exact, node.position);
        }
      }
      if (_context.numericMode == NumericMode.exact) {
        _warnApproximation(
          '"exp" complex arguman icin approximate hesaplandi.',
        );
      }
      return _composeValue(
        _approximateComplexExp(value),
        inputs: <EvaluatedValue>[argument],
        approximate: true,
      );
    }

    _warnApproximation('"exp" exact mode da approximate hesaplandi.');
    return EvaluatedValue(
      value: DoubleValue(math.exp(value.toDouble())),
      isApproximate: true,
    );
  }

  EvaluatedValue _evaluateRounding(
    FunctionCallNode node,
    String operation,
    EvaluatedValue argument,
  ) {
    if (_isVectorOrMatrixValue(argument.value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: '$operation vector ve matrix degerleri icin desteklenmiyor.',
          position: node.position,
        ),
      );
    }

    if (argument.value is UnitValue) {
      try {
        return _composeValue(
          UnitMath.round(
            argument.value as UnitValue,
            (value) => _roundScalarValue(operation, value),
          ),
          inputs: <EvaluatedValue>[argument],
        );
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.invalidUnitOperation,
            message:
                error.message ??
                '$operation bu birim ifadesi icin tanimli degil.',
            position: node.position,
          ),
        );
      }
    }

    if (_isComplexValue(argument.value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.domainError,
          message: '$operation complex sayilar icin bu fazda tanimli degil.',
          position: node.position,
        ),
      );
    }

    final rounded = _roundScalarValue(operation, argument.value);
    return _composeValue(
      rounded,
      inputs: <EvaluatedValue>[argument],
      approximate:
          _context.numericMode == NumericMode.exact &&
          argument.value is! RationalValue,
    );
  }

  EvaluatedValue _evaluateComplexNaturalLog(
    FunctionCallNode node,
    ComplexValue value,
    EvaluatedValue source,
  ) {
    if (_isZeroValue(value.realPart) && _isZeroValue(value.imaginaryPart)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.domainError,
          message: 'ln(0) tanimsizdir.',
          position: node.position,
        ),
      );
    }

    if (_context.numericMode == NumericMode.exact) {
      final exact = _tryExactComplexNaturalLog(value);
      if (exact != null) {
        return _exactValue(exact, node.position);
      }
      _warnApproximation('"ln" complex arguman icin approximate hesaplandi.');
    }

    return _composeValue(
      _approximateComplexNaturalLog(value),
      inputs: <EvaluatedValue>[source],
      approximate: true,
    );
  }

  CalculatorValue? _tryExactComplexNaturalLog(ComplexValue value) {
    if (value.isReal && _isNegativeOne(value.realPart)) {
      return _pureImaginary(_piMultiple(RationalValue.one));
    }

    if (value.isPureImaginary && _isOne(value.imaginaryPart)) {
      return _pureImaginary(
        _piMultiple(RationalValue(BigInt.one, BigInt.from(2))),
      );
    }

    if (value.isPureImaginary && _isNegativeOne(value.imaginaryPart)) {
      return _pureImaginary(
        _piMultiple(RationalValue(BigInt.from(-1), BigInt.from(2))),
      );
    }

    return null;
  }

  CalculatorValue _approximateComplexNaturalLog(ComplexValue value) {
    final magnitude = value.toDouble();
    final angle = value.argumentRadiansApproximate();
    return ComplexValue(
      realPart: DoubleValue(math.log(magnitude)),
      imaginaryPart: DoubleValue(angle),
    ).simplify();
  }

  CalculatorValue _approximateComplexExp(CalculatorValue value) {
    final complex = ComplexValue.promote(value);
    final real = complex.realPart.toDouble();
    final imaginary = complex.imaginaryPart.toDouble();
    final scale = math.exp(real);
    return ComplexValue(
      realPart: DoubleValue(scale * math.cos(imaginary)),
      imaginaryPart: DoubleValue(scale * math.sin(imaginary)),
    ).simplify();
  }

  CalculatorValue _approximateComplexPower(
    CalculatorValue base,
    CalculatorValue exponent,
  ) {
    final logarithm = _approximateComplexNaturalLog(ComplexValue.promote(base));
    final product = ComplexValue.promote(exponent).multiplyValue(logarithm);
    return _approximateComplexExp(product);
  }

  CalculatorValue _approximateComplexTrig(
    String functionName,
    ComplexValue value,
  ) {
    final a = value.realPart.toDouble();
    final b = value.imaginaryPart.toDouble();

    switch (functionName) {
      case 'sin':
        return ComplexValue(
          realPart: DoubleValue(math.sin(a) * _cosh(b)),
          imaginaryPart: DoubleValue(math.cos(a) * _sinh(b)),
        ).simplify();
      case 'cos':
        return ComplexValue(
          realPart: DoubleValue(math.cos(a) * _cosh(b)),
          imaginaryPart: DoubleValue(-math.sin(a) * _sinh(b)),
        ).simplify();
      case 'tan':
        final sine = _approximateComplexTrig('sin', value);
        final cosine = _approximateComplexTrig('cos', value);
        return _divideRawValues(sine, cosine, 0);
      default:
        throw StateError('Unsupported trig function: $functionName');
    }
  }

  CalculatorValue _approximateComplexSquareRoot(ComplexValue value) {
    final a = value.realPart.toDouble();
    final b = value.imaginaryPart.toDouble();
    final modulus = math.sqrt(a * a + b * b);
    final realPart = math.sqrt(math.max(0, (modulus + a) / 2));
    final imaginaryMagnitude = math.sqrt(math.max(0, (modulus - a) / 2));
    final imaginaryPart = b < 0 ? -imaginaryMagnitude : imaginaryMagnitude;
    return ComplexValue(
      realPart: DoubleValue(realPart),
      imaginaryPart: DoubleValue(imaginaryPart),
    ).simplify();
  }

  CalculatorValue _complexSquareRootOfNegativeScalar(
    CalculatorValue value,
    int position,
  ) {
    if (_context.numericMode == NumericMode.exact && value is RationalValue) {
      final magnitude = RationalValue(-value.numerator, value.denominator);
      final imaginary = _performExactOperation(
        () => SymbolicSimplifier.fromRadicalRational(magnitude),
        position,
      );
      return _pureImaginary(imaginary);
    }

    if (_context.numericMode == NumericMode.exact) {
      final rational = _tryCollapseToRational(value);
      if (rational != null && rational.numerator.isNegative) {
        final magnitude = RationalValue(
          -rational.numerator,
          rational.denominator,
        );
        final imaginary = _performExactOperation(
          () => SymbolicSimplifier.fromRadicalRational(magnitude),
          position,
        );
        return _pureImaginary(imaginary);
      }
      _warnApproximation('Negatif sqrt complex approximate hesaplandi.');
    }

    return _pureImaginary(DoubleValue(math.sqrt((-value.toDouble()))));
  }

  CalculatorValue? _tryExactArgumentValue(CalculatorValue value, int position) {
    final complex = value is ComplexValue
        ? value
        : ComplexValue.fromScalar(value);

    if (!(complex.isExact)) {
      return null;
    }

    final realSign = _compareScalarWithZero(complex.realPart);
    final imaginarySign = _compareScalarWithZero(complex.imaginaryPart);

    if (realSign == 0 && imaginarySign == 0) {
      return null;
    }
    if (imaginarySign == 0) {
      if (realSign > 0) {
        return RationalValue.zero;
      }
      return _angleFromTurn(
        RationalValue(BigInt.one, BigInt.from(2)),
        position,
      );
    }
    if (realSign == 0) {
      final quarterTurn = _angleFromTurn(
        RationalValue(BigInt.one, BigInt.from(4)),
        position,
      );
      return imaginarySign > 0
          ? quarterTurn
          : _performExactOperation(
              () => ScalarValueMath.negate(quarterTurn),
              position,
            );
    }

    final ratio = _performExactOperation(
      () => ScalarValueMath.divide(
        ScalarValueMath.abs(complex.imaginaryPart),
        ScalarValueMath.abs(complex.realPart),
      ),
      position,
    );
    final baseAngle = _tryExactInverseTrigValue('atan', ratio, position);
    if (baseAngle == null) {
      return null;
    }

    if (realSign > 0 && imaginarySign > 0) {
      return baseAngle;
    }
    if (realSign > 0 && imaginarySign < 0) {
      return _performExactOperation(
        () => ScalarValueMath.negate(baseAngle),
        position,
      );
    }

    final piAngle = _angleFromTurn(
      RationalValue(BigInt.one, BigInt.from(2)),
      position,
    );
    final piMinusBase = _performExactOperation(
      () => ScalarValueMath.subtract(piAngle, baseAngle),
      position,
    );
    if (realSign < 0 && imaginarySign > 0) {
      return piMinusBase;
    }
    return _performExactOperation(
      () => ScalarValueMath.negate(piMinusBase),
      position,
    );
  }

  double _approximateScalarArgument(CalculatorValue value) {
    final numericValue = value.toDouble();
    if (numericValue > 0) {
      return 0;
    }
    if (numericValue < 0) {
      return math.pi;
    }
    throw const CalculatorException(
      CalculationError(
        type: CalculationErrorType.domainError,
        message: 'arg(0) tanimsizdir.',
      ),
    );
  }

  EvaluatedValue _exactValue(
    CalculatorValue value,
    int position, {
    GraphResultMetadata? graphMetadata,
  }) {
    _guardExactValue(value, position);
    return EvaluatedValue(
      value: value,
      isApproximate: false,
      graphMetadata: graphMetadata,
    );
  }

  EvaluatedValue _composeValue(
    CalculatorValue value, {
    Iterable<EvaluatedValue> inputs = const <EvaluatedValue>[],
    bool approximate = false,
    String? statisticName,
    int? sampleSize,
    GraphResultMetadata? graphMetadata,
  }) {
    return EvaluatedValue(
      value: value,
      isApproximate:
          approximate ||
          value.isApproximate ||
          inputs.any((input) => input.isApproximate),
      statisticName: statisticName,
      sampleSize: sampleSize,
      graphMetadata: graphMetadata,
    );
  }

  CalculatorValue _addRawValues(
    CalculatorValue left,
    CalculatorValue right,
    int position,
  ) {
    try {
      if (left is VectorValue && right is VectorValue) {
        return LinearAlgebra.addVectors(left, right);
      }
      if (left is MatrixValue && right is MatrixValue) {
        return LinearAlgebra.addMatrices(left, right);
      }
      if (_isVectorOrMatrixValue(left) || _isVectorOrMatrixValue(right)) {
        throw const LinearAlgebraException(
          LinearAlgebraErrorType.unsupportedOperation,
          'Vector/matrix addition requires matching vector or matrix operands.',
        );
      }
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, position);
    }

    if (left is UnitValue && right is UnitValue) {
      try {
        return UnitMath.add(left, right);
      } on ArgumentError {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.dimensionMismatch,
            message: 'Toplama icin birim boyutlari ayni olmali.',
            position: position,
          ),
        );
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.affineUnitOperation,
            message:
                error.message ??
                'Bu sicaklik birimleri birbiriyle dogrudan toplanamaz.',
            position: position,
          ),
        );
      }
    }

    if (left is UnitValue || right is UnitValue) {
      final unit = left is UnitValue ? left : right as UnitValue;
      final scalar = left is UnitValue ? right : left;
      if (!unit.isUnitExpressionOnly && unit.dimension.isDimensionless) {
        return _addRawValues(unit.displayMagnitude, scalar, position);
      }
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.dimensionMismatch,
          message:
              'Birimli ve birimsiz degerler yalnizca boyutsuz durumda toplanabilir.',
          position: position,
        ),
      );
    }

    if (_isComplexValue(left) || _isComplexValue(right)) {
      return ComplexValue.promote(left).addValue(right);
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(left) &&
        _isExactScalarValue(right)) {
      return _performExactOperation(
        () => ScalarValueMath.add(left, right),
        position,
      );
    }

    return DoubleValue(left.toDouble() + right.toDouble());
  }

  CalculatorValue _subtractRawValues(
    CalculatorValue left,
    CalculatorValue right,
    int position,
  ) {
    try {
      if (left is VectorValue && right is VectorValue) {
        return LinearAlgebra.subtractVectors(left, right);
      }
      if (left is MatrixValue && right is MatrixValue) {
        return LinearAlgebra.subtractMatrices(left, right);
      }
      if (_isVectorOrMatrixValue(left) || _isVectorOrMatrixValue(right)) {
        throw const LinearAlgebraException(
          LinearAlgebraErrorType.unsupportedOperation,
          'Vector/matrix subtraction requires matching vector or matrix operands.',
        );
      }
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, position);
    }

    if (left is UnitValue && right is UnitValue) {
      try {
        return UnitMath.subtract(left, right);
      } on ArgumentError {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.dimensionMismatch,
            message: 'Cikarma icin birim boyutlari ayni olmali.',
            position: position,
          ),
        );
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.affineUnitOperation,
            message:
                error.message ??
                'Bu sicaklik birimleri birbiriyle bu sekilde cikarilamaz.',
            position: position,
          ),
        );
      }
    }

    if (left is UnitValue || right is UnitValue) {
      final unit = left is UnitValue ? left : right as UnitValue;
      final scalar = left is UnitValue ? right : left;
      if (!unit.isUnitExpressionOnly && unit.dimension.isDimensionless) {
        return left is UnitValue
            ? _subtractRawValues(unit.displayMagnitude, scalar, position)
            : _subtractRawValues(scalar, unit.displayMagnitude, position);
      }
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.dimensionMismatch,
          message:
              'Birimli ve birimsiz degerler yalnizca boyutsuz durumda cikarilabilir.',
          position: position,
        ),
      );
    }

    if (_isComplexValue(left) || _isComplexValue(right)) {
      return ComplexValue.promote(left).subtractValue(right);
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(left) &&
        _isExactScalarValue(right)) {
      return _performExactOperation(
        () => ScalarValueMath.subtract(left, right),
        position,
      );
    }

    return DoubleValue(left.toDouble() - right.toDouble());
  }

  CalculatorValue _multiplyRawValues(
    CalculatorValue left,
    CalculatorValue right,
    int position,
  ) {
    try {
      if (left is MatrixValue && right is MatrixValue) {
        return LinearAlgebra.multiplyMatrices(left, right);
      }
      if (left is MatrixValue && right is VectorValue) {
        return LinearAlgebra.multiplyMatrixVector(left, right);
      }
      if (left is VectorValue && !_isVectorOrMatrixValue(right)) {
        return LinearAlgebra.scaleVector(left, right);
      }
      if (right is VectorValue && !_isVectorOrMatrixValue(left)) {
        return LinearAlgebra.scaleVector(right, left);
      }
      if (left is MatrixValue && !_isVectorOrMatrixValue(right)) {
        return LinearAlgebra.scaleMatrix(left, right);
      }
      if (right is MatrixValue && !_isVectorOrMatrixValue(left)) {
        return LinearAlgebra.scaleMatrix(right, left);
      }
      if (_isVectorOrMatrixValue(left) || _isVectorOrMatrixValue(right)) {
        throw const LinearAlgebraException(
          LinearAlgebraErrorType.unsupportedOperation,
          'This vector/matrix multiplication combination is not supported.',
        );
      }
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, position);
    }

    if (left is UnitValue && right is UnitValue) {
      try {
        return UnitMath.multiply(left, right);
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: left.isAffineAbsolute || right.isAffineAbsolute
                ? CalculationErrorType.affineUnitOperation
                : CalculationErrorType.invalidUnitOperation,
            message:
                error.message ??
                'Bu birim carpimi fiziksel olarak desteklenmiyor.',
            position: position,
          ),
        );
      }
    }

    if (left is UnitValue) {
      try {
        return UnitMath.multiplyScalar(right, left);
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: left.isAffineAbsolute
                ? CalculationErrorType.affineUnitOperation
                : CalculationErrorType.invalidUnitOperation,
            message: error.message ?? 'Bu birim scalar ile carpilamaz.',
            position: position,
          ),
        );
      }
    }

    if (right is UnitValue) {
      try {
        return UnitMath.multiplyScalar(left, right);
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: right.isAffineAbsolute
                ? CalculationErrorType.affineUnitOperation
                : CalculationErrorType.invalidUnitOperation,
            message: error.message ?? 'Bu birim scalar ile carpilamaz.',
            position: position,
          ),
        );
      }
    }

    if (_isComplexValue(left) || _isComplexValue(right)) {
      return ComplexValue.promote(left).multiplyValue(right);
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(left) &&
        _isExactScalarValue(right)) {
      return _performExactOperation(
        () => ScalarValueMath.multiply(left, right),
        position,
      );
    }

    return DoubleValue(left.toDouble() * right.toDouble());
  }

  CalculatorValue _divideRawValues(
    CalculatorValue left,
    CalculatorValue right,
    int position,
  ) {
    try {
      if (left is VectorValue && !_isVectorOrMatrixValue(right)) {
        return LinearAlgebra.divideVector(left, right);
      }
      if (left is MatrixValue && !_isVectorOrMatrixValue(right)) {
        return LinearAlgebra.divideMatrix(left, right);
      }
      if (_isVectorOrMatrixValue(left) || _isVectorOrMatrixValue(right)) {
        throw const LinearAlgebraException(
          LinearAlgebraErrorType.unsupportedOperation,
          'Matrix/vector division is only supported by a scalar denominator.',
        );
      }
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, position);
    }

    if (left is UnitValue && right is UnitValue) {
      try {
        return UnitMath.divide(left, right);
      } on ArgumentError {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.divisionByZero,
            message: 'Sifira bolme tanimsizdir.',
            position: position,
          ),
        );
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: left.isAffineAbsolute || right.isAffineAbsolute
                ? CalculationErrorType.affineUnitOperation
                : CalculationErrorType.invalidUnitOperation,
            message:
                error.message ??
                'Bu birim bolme islemi fiziksel olarak desteklenmiyor.',
            position: position,
          ),
        );
      }
    }

    if (left is UnitValue) {
      try {
        return UnitMath.divideByScalar(left, right);
      } on ArgumentError {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.divisionByZero,
            message: 'Sifira bolme tanimsizdir.',
            position: position,
          ),
        );
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: left.isAffineAbsolute
                ? CalculationErrorType.affineUnitOperation
                : CalculationErrorType.invalidUnitOperation,
            message: error.message ?? 'Bu birim scalar ile bolunemez.',
            position: position,
          ),
        );
      }
    }

    if (right is UnitValue) {
      try {
        return UnitMath.divideScalarByUnit(left, right);
      } on ArgumentError {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.divisionByZero,
            message: 'Sifira bolme tanimsizdir.',
            position: position,
          ),
        );
      } on UnsupportedError catch (error) {
        throw CalculatorException(
          CalculationError(
            type: right.isAffineAbsolute
                ? CalculationErrorType.affineUnitOperation
                : CalculationErrorType.invalidUnitOperation,
            message: error.message ?? 'Bu birim paydada kullanilamaz.',
            position: position,
          ),
        );
      }
    }

    if (_isZeroValue(right)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.divisionByZero,
          message: 'Sifira bolme tanimsizdir.',
          position: position,
        ),
      );
    }

    if (_isComplexValue(left) || _isComplexValue(right)) {
      try {
        return ComplexValue.promote(left).divideValue(right);
      } on ArgumentError {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.divisionByZero,
            message: 'Sifira bolme tanimsizdir.',
            position: position,
          ),
        );
      }
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(left) &&
        _isExactScalarValue(right)) {
      try {
        return _performExactOperation(
          () => ScalarValueMath.divide(left, right),
          position,
        );
      } on UnsupportedError {
        _warnApproximation(
          'Desteklenmeyen symbolic bolme approximate hesaplandi.',
        );
      }
    }

    return DoubleValue(left.toDouble() / right.toDouble());
  }

  CalculatorValue _negateRawValue(CalculatorValue value, int position) {
    try {
      if (value is VectorValue) {
        return LinearAlgebra.negateVector(value);
      }
      if (value is MatrixValue) {
        return LinearAlgebra.negateMatrix(value);
      }
    } on LinearAlgebraException catch (error) {
      throw _mapLinearAlgebraException(error, position);
    }

    if (value is UnitValue) {
      return UnitValue.fromBaseMagnitude(
        baseMagnitude: ScalarValueMath.negate(value.baseMagnitude),
        displayUnit: value.displayUnit,
      );
    }

    if (_isComplexValue(value)) {
      return ComplexValue.promote(value).negateValue();
    }

    if (_context.numericMode == NumericMode.exact &&
        _isExactScalarValue(value)) {
      return _performExactOperation(
        () => ScalarValueMath.negate(value),
        position,
      );
    }

    return DoubleValue(-value.toDouble());
  }

  CalculatorValue _performExactOperation(
    CalculatorValue Function() operation,
    int position,
  ) {
    try {
      final value = operation();
      _guardExactValue(value, position);
      return value;
    } on RangeError {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.computationLimit,
          message: 'Exact symbolic hesaplama limiti asildi.',
          position: position,
          suggestion:
              'Ifadeyi daha kucuk exact parcalara bolup tekrar deneyin.',
        ),
      );
    }
  }

  CalculatorValue? _tryExactTrigValue(
    String functionName,
    CalculatorValue value,
    int position, {
    AngleMode? angleMode,
  }) {
    final turn = _tryTurnFraction(
      value,
      angleMode: angleMode ?? _context.angleMode,
    );
    if (turn == null) {
      return null;
    }

    final normalizedTurn = _normalizeTurn(turn);
    final reference = _referenceTurn(normalizedTurn);
    if (reference == null) {
      return null;
    }

    final sinReference = _firstQuadrantSin(reference);
    final cosReference = _firstQuadrantCos(reference);
    if (sinReference == null || cosReference == null) {
      return null;
    }

    final sinValue = _applySign(
      sinReference,
      _sinSign(normalizedTurn),
      position,
    );
    final cosValue = _applySign(
      cosReference,
      _cosSign(normalizedTurn),
      position,
    );

    switch (functionName) {
      case 'sin':
        return sinValue;
      case 'cos':
        return cosValue;
      case 'tan':
        if (_isZeroValue(cosValue)) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.domainError,
              message: 'tan bu aci icin tanimsizdir.',
              position: position,
              suggestion: 'Aci modunu veya ifadeyi kontrol edin.',
            ),
          );
        }
        return _performExactOperation(
          () => _divideRawValues(sinValue, cosValue, position),
          position,
        );
      default:
        return null;
    }
  }

  CalculatorValue? _tryExactInverseTrigValue(
    String functionName,
    CalculatorValue value,
    int position,
  ) {
    final key = _exactKey(value);
    if (key == null) {
      return null;
    }

    RationalValue? angleTurn;
    switch (functionName) {
      case 'asin':
        angleTurn = _asinTurnForKey(key);
      case 'acos':
        angleTurn = _acosTurnForKey(key);
      case 'atan':
        angleTurn = _atanTurnForKey(key);
      default:
        angleTurn = null;
    }

    if (angleTurn == null) {
      return null;
    }
    return _angleFromTurn(angleTurn, position);
  }

  CalculatorValue? _tryExactCisValue(
    CalculatorValue angle,
    int position, {
    required AngleMode angleMode,
  }) {
    final cosine = _tryExactTrigValue(
      'cos',
      angle,
      position,
      angleMode: angleMode,
    );
    final sine = _tryExactTrigValue(
      'sin',
      angle,
      position,
      angleMode: angleMode,
    );
    if (cosine == null || sine == null) {
      return null;
    }
    return ComplexValue(realPart: cosine, imaginaryPart: sine).simplify();
  }

  RationalValue? _tryTurnFraction(
    CalculatorValue angleValue, {
    required AngleMode angleMode,
  }) {
    switch (angleMode) {
      case AngleMode.degree:
        if (angleValue is RationalValue) {
          return angleValue.divide(RationalValue.fromInt(360));
        }
        return null;
      case AngleMode.gradian:
        if (angleValue is RationalValue) {
          return angleValue.divide(RationalValue.fromInt(400));
        }
        return null;
      case AngleMode.radian:
        return _tryRadianTurnFraction(angleValue);
    }
  }

  RationalValue? _tryRadianTurnFraction(CalculatorValue angleValue) {
    if (angleValue is RationalValue) {
      return angleValue.numerator == BigInt.zero ? RationalValue.zero : null;
    }
    if (angleValue is SymbolicValue) {
      final piMultiple = angleValue.tryAsPiMultiple();
      if (piMultiple != null) {
        return piMultiple.divide(RationalValue.fromInt(2));
      }
    }
    return null;
  }

  RationalValue _normalizeTurn(RationalValue turn) {
    final floor = turn.floorToBigInt();
    var normalized = turn.subtract(RationalValue(floor, BigInt.one));
    if (normalized.numerator.isNegative) {
      normalized = normalized.add(RationalValue.one);
    }
    return normalized;
  }

  RationalValue? _referenceTurn(RationalValue turn) {
    final quarter = RationalValue(BigInt.one, BigInt.from(4));
    final half = RationalValue(BigInt.one, BigInt.from(2));
    final threeQuarters = RationalValue(BigInt.from(3), BigInt.from(4));

    if (turn.compareTo(quarter) <= 0) {
      return turn;
    }
    if (turn.compareTo(half) < 0) {
      return half.subtract(turn);
    }
    if (turn.compareTo(threeQuarters) <= 0) {
      return turn.subtract(half);
    }
    if (turn.compareTo(RationalValue.one) < 0) {
      return RationalValue.one.subtract(turn);
    }
    return null;
  }

  int _sinSign(RationalValue turn) {
    final half = RationalValue(BigInt.one, BigInt.from(2));
    return turn.compareTo(half) < 0 ? 1 : -1;
  }

  int _cosSign(RationalValue turn) {
    final quarter = RationalValue(BigInt.one, BigInt.from(4));
    final threeQuarters = RationalValue(BigInt.from(3), BigInt.from(4));
    if (turn.compareTo(quarter) < 0 || turn.compareTo(threeQuarters) > 0) {
      return 1;
    }
    if (turn.compareTo(quarter) == 0 || turn.compareTo(threeQuarters) == 0) {
      return 0;
    }
    return -1;
  }

  CalculatorValue _applySign(CalculatorValue value, int sign, int position) {
    if (sign == 0) {
      return RationalValue.zero;
    }
    if (sign > 0) {
      return value;
    }
    return _performExactOperation(
      () => ScalarValueMath.negate(value),
      position,
    );
  }

  CalculatorValue? _firstQuadrantSin(RationalValue turn) {
    if (_matches(turn, 0, 1)) {
      return RationalValue.zero;
    }
    if (_matches(turn, 1, 12)) {
      return RationalValue(BigInt.one, BigInt.from(2));
    }
    if (_matches(turn, 1, 8)) {
      return _radicalValue(2, denominator: 2);
    }
    if (_matches(turn, 1, 6)) {
      return _radicalValue(3, denominator: 2);
    }
    if (_matches(turn, 1, 4)) {
      return RationalValue.one;
    }
    return null;
  }

  CalculatorValue? _firstQuadrantCos(RationalValue turn) {
    if (_matches(turn, 0, 1)) {
      return RationalValue.one;
    }
    if (_matches(turn, 1, 12)) {
      return _radicalValue(3, denominator: 2);
    }
    if (_matches(turn, 1, 8)) {
      return _radicalValue(2, denominator: 2);
    }
    if (_matches(turn, 1, 6)) {
      return RationalValue(BigInt.one, BigInt.from(2));
    }
    if (_matches(turn, 1, 4)) {
      return RationalValue.zero;
    }
    return null;
  }

  RationalValue? _asinTurnForKey(String key) {
    switch (key) {
      case '0':
        return RationalValue.zero;
      case '1/2':
        return RationalValue(BigInt.one, BigInt.from(12));
      case '\u221A2/2':
        return RationalValue(BigInt.one, BigInt.from(8));
      case '\u221A3/2':
        return RationalValue(BigInt.one, BigInt.from(6));
      case '1':
        return RationalValue(BigInt.one, BigInt.from(4));
      case '-1/2':
        return RationalValue(BigInt.from(-1), BigInt.from(12));
      case '-\u221A2/2':
        return RationalValue(BigInt.from(-1), BigInt.from(8));
      case '-\u221A3/2':
        return RationalValue(BigInt.from(-1), BigInt.from(6));
      case '-1':
        return RationalValue(BigInt.from(-1), BigInt.from(4));
      default:
        return null;
    }
  }

  RationalValue? _acosTurnForKey(String key) {
    switch (key) {
      case '1':
        return RationalValue.zero;
      case '\u221A3/2':
        return RationalValue(BigInt.one, BigInt.from(12));
      case '\u221A2/2':
        return RationalValue(BigInt.one, BigInt.from(8));
      case '1/2':
        return RationalValue(BigInt.one, BigInt.from(6));
      case '0':
        return RationalValue(BigInt.one, BigInt.from(4));
      default:
        return null;
    }
  }

  RationalValue? _atanTurnForKey(String key) {
    switch (key) {
      case '0':
        return RationalValue.zero;
      case '\u221A3/3':
        return RationalValue(BigInt.one, BigInt.from(12));
      case '1':
        return RationalValue(BigInt.one, BigInt.from(8));
      case '\u221A3':
        return RationalValue(BigInt.one, BigInt.from(6));
      case '-\u221A3/3':
        return RationalValue(BigInt.from(-1), BigInt.from(12));
      case '-1':
        return RationalValue(BigInt.from(-1), BigInt.from(8));
      case '-\u221A3':
        return RationalValue(BigInt.from(-1), BigInt.from(6));
      default:
        return null;
    }
  }

  CalculatorValue _angleFromTurn(
    RationalValue turn,
    int position, {
    AngleMode? angleMode,
  }) {
    switch (angleMode ?? _context.angleMode) {
      case AngleMode.degree:
        return turn.multiply(RationalValue.fromInt(360));
      case AngleMode.gradian:
        return turn.multiply(RationalValue.fromInt(400));
      case AngleMode.radian:
        return _performExactOperation(
          () => _piMultiple(turn.multiply(RationalValue.fromInt(2))),
          position,
        );
    }
  }

  CalculatorValue _radicalValue(
    int radicand, {
    int numerator = 1,
    int denominator = 1,
  }) {
    return SymbolicValue(
      <SymbolicTerm>[
        SymbolicTerm(
          coefficient: RationalValue(
            BigInt.from(numerator),
            BigInt.from(denominator),
          ),
          factors: <SymbolicFactor>[RadicalFactor(BigInt.from(radicand))],
          maxFactorCount: SymbolicSimplifier.maxFactorCount,
        ),
      ],
      maxTermCount: SymbolicSimplifier.maxTermCount,
      maxFactorCount: SymbolicSimplifier.maxFactorCount,
    );
  }

  CalculatorValue _piMultiple(RationalValue coefficient) {
    final symbolic = SymbolicValue.fromFactor(
      symbolicPiFactor,
      coefficient: coefficient,
      maxTermCount: SymbolicSimplifier.maxTermCount,
      maxFactorCount: SymbolicSimplifier.maxFactorCount,
    );
    return symbolic.tryCollapseToRational() ?? symbolic;
  }

  CalculatorValue _pureImaginary(CalculatorValue imaginaryPart) {
    return ComplexValue(
      realPart: RationalValue.zero,
      imaginaryPart: imaginaryPart,
    ).simplify();
  }

  bool _matches(RationalValue value, int numerator, int denominator) {
    return value.compareTo(
          RationalValue(BigInt.from(numerator), BigInt.from(denominator)),
        ) ==
        0;
  }

  String? _exactKey(CalculatorValue value) {
    if (value is RationalValue) {
      return value.toFractionString();
    }
    if (value is SymbolicValue) {
      return value.toSymbolicString();
    }
    return null;
  }

  bool _isExactScalarValue(CalculatorValue value) {
    return value is RationalValue || value is SymbolicValue;
  }

  bool _isComplexValue(CalculatorValue value) => value is ComplexValue;

  bool _isUnitValue(CalculatorValue value) => value is UnitValue;

  bool _isDatasetCompatibleValue(CalculatorValue value) {
    return value is DatasetValue || value is VectorValue;
  }

  bool _isVectorOrMatrixValue(CalculatorValue value) {
    return value is VectorValue ||
        value is MatrixValue ||
        value is DatasetValue ||
        value is RegressionValue ||
        value is FunctionValue ||
        value is PlotValue;
  }

  bool _isZeroValue(CalculatorValue value) {
    if (value is ComplexValue) {
      return _isZeroValue(value.realPart) && _isZeroValue(value.imaginaryPart);
    }
    if (value is UnitValue) {
      return ScalarValueMath.isZero(value.baseMagnitude);
    }
    if (value is VectorValue) {
      return value.elements.every(_isZeroValue);
    }
    if (value is MatrixValue) {
      return value.rows.every((row) => row.every(_isZeroValue));
    }
    if (value is DatasetValue) {
      return value.values.every(_isZeroValue);
    }
    return ScalarValueMath.isZero(value);
  }

  int _compareScalars(CalculatorValue left, CalculatorValue right) {
    if (left is UnitValue && right is UnitValue) {
      return UnitMath.compare(left, right);
    }
    return ScalarValueMath.compare(left, right);
  }

  int _compareScalarWithZero(CalculatorValue value) {
    return _compareScalars(value, RationalValue.zero);
  }

  void _requireScalarValue(
    CalculatorValue value, {
    required int position,
    required String message,
  }) {
    if (_isVectorOrMatrixValue(value)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedOperation,
          message: message,
          position: position,
        ),
      );
    }
  }

  int _requirePositiveInteger(
    CalculatorValue value, {
    required int position,
    required String parameterName,
  }) {
    _requireScalarValue(
      value,
      position: position,
      message: '$parameterName scalar bir tam sayi olmali.',
    );
    if (!_isRealIntegerLike(value) || value.toDouble() <= 0) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidArgumentCount,
          message: '$parameterName pozitif tam sayi olmali.',
          position: position,
        ),
      );
    }
    return _integerFromValue(value);
  }

  CalculatorException _mapLinearAlgebraException(
    LinearAlgebraException error,
    int position,
  ) {
    return CalculatorException(
      CalculationError(
        type: switch (error.type) {
          LinearAlgebraErrorType.dimensionMismatch =>
            CalculationErrorType.dimensionMismatch,
          LinearAlgebraErrorType.invalidShape =>
            CalculationErrorType.invalidMatrixShape,
          LinearAlgebraErrorType.singularMatrix =>
            CalculationErrorType.singularMatrix,
          LinearAlgebraErrorType.unsupportedOperation =>
            CalculationErrorType.unsupportedOperation,
          LinearAlgebraErrorType.computationLimit =>
            CalculationErrorType.computationLimit,
          LinearAlgebraErrorType.domainError =>
            CalculationErrorType.domainError,
        },
        message: error.message,
        position: position,
      ),
    );
  }

  CalculatorException _mapStatisticsException(
    StatisticsException error,
    int position,
  ) {
    return CalculatorException(
      CalculationError(
        type: switch (error.type) {
          StatisticsErrorType.invalidDataset =>
            CalculationErrorType.invalidDataset,
          StatisticsErrorType.invalidArgument =>
            CalculationErrorType.invalidStatisticsArgument,
          StatisticsErrorType.invalidProbabilityParameter =>
            CalculationErrorType.invalidProbabilityParameter,
          StatisticsErrorType.insufficientData =>
            CalculationErrorType.insufficientData,
          StatisticsErrorType.dimensionMismatch =>
            CalculationErrorType.dimensionMismatch,
          StatisticsErrorType.unsupportedOperation =>
            CalculationErrorType.unsupportedOperation,
          StatisticsErrorType.domainError => CalculationErrorType.domainError,
          StatisticsErrorType.computationLimit =>
            CalculationErrorType.computationLimit,
        },
        message: error.message,
        position: position,
      ),
    );
  }

  RationalValue? _tryCollapseToRational(CalculatorValue value) {
    if (value is RationalValue) {
      return value;
    }
    if (value is SymbolicValue) {
      return value.tryCollapseToRational();
    }
    return null;
  }

  DatasetValue _coerceDatasetValue(
    FunctionCallNode node,
    EvaluatedValue argument, {
    required String functionName,
  }) {
    try {
      if (argument.value is DatasetValue) {
        return DescriptiveStatistics.normalizeDataset(
          argument.value as DatasetValue,
        );
      }
      if (argument.value is VectorValue) {
        return DescriptiveStatistics.normalizeDataset(
          DatasetValue((argument.value as VectorValue).elements),
        );
      }
      if (argument.value is MatrixValue) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.unsupportedOperation,
            message:
                '$functionName matrix girdileri icin bu fazda desteklenmiyor.',
            position: node.position,
          ),
        );
      }
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidDataset,
          message: '$functionName bir veri kumesi bekler.',
          position: node.position,
          suggestion: 'Ornek: $functionName(data(1, 2, 3))',
        ),
      );
    } on StatisticsException catch (error) {
      throw _mapStatisticsException(error, node.position);
    }
  }

  CalculatorValue _interpolateQuantileExact(
    List<CalculatorValue> sortedValues,
    RationalValue q,
  ) {
    final interpolation = QuantileInterpolation.exact(sortedValues.length, q);
    final lower = sortedValues[interpolation.lowerIndex];
    final upper = sortedValues[interpolation.upperIndex];
    if (!interpolation.isInterpolated || interpolation.exactWeight == null) {
      return lower;
    }
    return DescriptiveStatistics.interpolate(
      lower,
      upper,
      exactWeight: interpolation.exactWeight!,
    );
  }

  CalculatorValue _interpolateQuantileApproximate(
    List<CalculatorValue> sortedValues,
    double q,
  ) {
    final interpolation = QuantileInterpolation.approximate(
      sortedValues.length,
      q,
    );
    final lower = sortedValues[interpolation.lowerIndex];
    final upper = sortedValues[interpolation.upperIndex];
    if (!interpolation.isInterpolated) {
      return lower;
    }
    return DescriptiveStatistics.interpolateApproximate(
      lower,
      upper,
      weight: interpolation.weight,
    );
  }

  CalculatorValue _requireDimensionlessRealScalar(
    FunctionCallNode node,
    EvaluatedValue argument, {
    required String functionName,
    required CalculationErrorType errorType,
  }) {
    _requireScalarValue(
      argument.value,
      position: node.position,
      message: '$functionName scalar bir arguman bekler.',
    );

    final value = argument.value;
    if (value is UnitValue) {
      if (value.isUnitExpressionOnly || !value.dimension.isDimensionless) {
        throw CalculatorException(
          CalculationError(
            type: errorType,
            message: '$functionName boyutsuz bir scalar gerektirir.',
            position: node.position,
          ),
        );
      }
      return value.displayMagnitude;
    }

    if (_isComplexValue(value)) {
      throw CalculatorException(
        CalculationError(
          type: errorType,
          message: '$functionName real bir scalar arguman gerektirir.',
          position: node.position,
        ),
      );
    }

    return value;
  }

  int _requireNonNegativeIntegerArgument(
    FunctionCallNode node,
    EvaluatedValue argument, {
    required String functionName,
  }) {
    final value = _requireDimensionlessRealScalar(
      node,
      argument,
      functionName: functionName,
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    if (!_isRealIntegerLike(value) || value.toDouble() < 0) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidProbabilityParameter,
          message: '$functionName negatif olmayan tam sayi bekler.',
          position: node.position,
        ),
      );
    }
    return _integerFromValue(value);
  }

  int _requirePositiveIntegerArgument(
    FunctionCallNode node,
    EvaluatedValue argument, {
    required String functionName,
  }) {
    final value = _requireDimensionlessRealScalar(
      node,
      argument,
      functionName: functionName,
      errorType: CalculationErrorType.invalidProbabilityParameter,
    );
    if (!_isRealIntegerLike(value) || value.toDouble() <= 0) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidProbabilityParameter,
          message: '$functionName pozitif tam sayi bekler.',
          position: node.position,
        ),
      );
    }
    return _integerFromValue(value);
  }

  bool _isOne(CalculatorValue value) {
    final rational = _tryCollapseToRational(value);
    return rational != null && rational.compareTo(RationalValue.one) == 0;
  }

  bool _isNegativeOne(CalculatorValue value) {
    final rational = _tryCollapseToRational(value);
    return rational != null &&
        rational.compareTo(RationalValue.fromInt(-1)) == 0;
  }

  bool _isHalf(RationalValue value) {
    return value.compareTo(RationalValue(BigInt.one, BigInt.from(2))) == 0;
  }

  bool _isNegativeHalf(RationalValue value) {
    return value.compareTo(RationalValue(BigInt.from(-1), BigInt.from(2))) == 0;
  }

  bool _isHalfLike(CalculatorValue value) {
    if (value is RationalValue) {
      return _isHalf(value);
    }
    return (value.toDouble() - 0.5).abs() < 1e-10;
  }

  bool _isNegativeHalfLike(CalculatorValue value) {
    if (value is RationalValue) {
      return _isNegativeHalf(value);
    }
    return (value.toDouble() + 0.5).abs() < 1e-10;
  }

  bool _isRealIntegerLike(CalculatorValue value) {
    if (value is UnitValue) {
      if (!value.dimension.isDimensionless) {
        return false;
      }
      return _isNearlyInteger(value.displayMagnitude.toDouble());
    }
    if (value is ComplexValue) {
      return value.isReal && _isNearlyInteger(value.realPart.toDouble());
    }
    return _isNearlyInteger(value.toDouble());
  }

  int _integerFromValue(CalculatorValue value) {
    if (value is UnitValue) {
      return value.displayMagnitude.toDouble().round();
    }
    if (value is ComplexValue) {
      return value.realPart.toDouble().round();
    }
    return value.toDouble().round();
  }

  void _guardExactValue(CalculatorValue value, int position) {
    if (value is ComplexValue) {
      _guardExactValue(value.realPart, position);
      _guardExactValue(value.imaginaryPart, position);
      return;
    }

    if (value is UnitValue) {
      _guardExactValue(value.baseMagnitude, position);
      return;
    }

    if (value is VectorValue) {
      if (value.length > LinearAlgebra.maxTotalElements) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.computationLimit,
            message: 'Vector boyutu guvenli limiti asti.',
            position: position,
          ),
        );
      }
      for (final element in value.elements) {
        _guardExactValue(element, position);
      }
      return;
    }

    if (value is MatrixValue) {
      if (value.totalElements > LinearAlgebra.maxTotalElements) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.computationLimit,
            message: 'Matrix boyutu guvenli limiti asti.',
            position: position,
          ),
        );
      }
      for (final row in value.rows) {
        for (final entry in row) {
          _guardExactValue(entry, position);
        }
      }
      return;
    }

    if (value is DatasetValue) {
      if (value.length > DescriptiveStatistics.maxDatasetLength) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.computationLimit,
            message: 'Dataset boyutu guvenli limiti asti.',
            position: position,
          ),
        );
      }
      for (final entry in value.values) {
        _guardExactValue(entry, position);
      }
      return;
    }

    if (value is RegressionValue) {
      _guardExactValue(value.slope, position);
      _guardExactValue(value.intercept, position);
      _guardExactValue(value.r, position);
      _guardExactValue(value.rSquared, position);
      _guardExactValue(value.xMean, position);
      _guardExactValue(value.yMean, position);
      return;
    }

    if (value is RationalValue) {
      _guardExactDigits(value, position);
      return;
    }

    if (value is SymbolicValue) {
      for (final term in value.terms) {
        _guardExactDigits(term.coefficient, position);
        if (term.factors.length > SymbolicSimplifier.maxFactorCount) {
          throw CalculatorException(
            CalculationError(
              type: CalculationErrorType.computationLimit,
              message: 'Symbolic factor limiti asildi.',
              position: position,
              suggestion: 'Daha kucuk bir symbolic ifade deneyin.',
            ),
          );
        }
      }
      if (value.terms.length > SymbolicSimplifier.maxTermCount) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.computationLimit,
            message: 'Symbolic terim limiti asildi.',
            position: position,
            suggestion: 'Ifadeyi daha kucuk exact parcalara bolup deneyin.',
          ),
        );
      }
    }
  }

  CalculatorValue _requireDimensionlessValue(
    CalculatorValue value, {
    required int position,
    required String functionName,
  }) {
    if (value is! UnitValue) {
      return value;
    }
    if (value.isUnitExpressionOnly) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidUnitOperation,
          message:
              '$functionName yalnizca fiziksel buyukluklerde kullanilabilir.',
          position: position,
        ),
      );
    }
    if (!value.dimension.isDimensionless) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.invalidUnitOperation,
          message: '$functionName boyutsuz bir arguman gerektirir.',
          position: position,
          suggestion:
              'Once birimleri sadeleştirip boyutsuz bir deger elde edin.',
        ),
      );
    }
    return value.displayMagnitude;
  }

  CalculatorValue _roundScalarValue(String operation, CalculatorValue value) {
    if (_context.numericMode == NumericMode.exact && value is RationalValue) {
      return switch (operation) {
        'floor' => RationalValue(value.floorToBigInt(), BigInt.one),
        'ceil' => RationalValue(value.ceilToBigInt(), BigInt.one),
        'round' => RationalValue(value.roundToBigInt(), BigInt.one),
        _ => throw StateError('Unsupported rounding operation: $operation'),
      };
    }

    if (_context.numericMode == NumericMode.exact && value is SymbolicValue) {
      _warnApproximation(
        '"$operation" symbolic exact mode da approximate hesaplandi.',
      );
    }

    final numericValue = value.toDouble();
    return switch (operation) {
      'floor' => DoubleValue(numericValue.floorToDouble()),
      'ceil' => DoubleValue(numericValue.ceilToDouble()),
      'round' => DoubleValue(numericValue.roundToDouble()),
      _ => throw StateError('Unsupported rounding operation: $operation'),
    };
  }

  void _guardExactExponent(BigInt exponent, int position) {
    if (exponent.abs() > BigInt.from(_maxExactExponentMagnitude)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.computationLimit,
          message: 'Exact us alma limiti asildi.',
          position: position,
          suggestion: 'Daha kucuk bir tam us deneyin.',
        ),
      );
    }
  }

  void _guardExactDigits(RationalValue value, int position) {
    final numeratorDigits = value.numerator.abs().toString().length;
    final denominatorDigits = value.denominator.toString().length;
    if (numeratorDigits > _maxExactDigits ||
        denominatorDigits > _maxExactDigits) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.computationLimit,
          message: 'Exact rational boyutu guvenli limiti asti.',
          position: position,
          suggestion: 'Daha kucuk tam sayilar veya usler deneyin.',
        ),
      );
    }
  }

  void _warnApproximation(String message) {
    if (_context.numericMode != NumericMode.exact) {
      return;
    }
    warnings.add(message);
  }

  void _assertPositive(
    FunctionCallNode node,
    double value,
    String functionName,
  ) {
    if (value <= 0) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.domainError,
          message: '$functionName pozitif arguman gerektirir.',
          position: node.position,
          suggestion: 'Sifirdan buyuk bir deger deneyin.',
        ),
      );
    }
  }

  void _assertUnitInterval(FunctionCallNode node, double value) {
    if (value < -1 || value > 1) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.domainError,
          message:
              'Ters trigonometrik fonksiyon argumani -1 ile 1 arasinda olmali.',
          position: node.position,
        ),
      );
    }
  }

  double _toRadians(double value) {
    return switch (_context.angleMode) {
      AngleMode.degree => value * math.pi / 180,
      AngleMode.radian => value,
      AngleMode.gradian => value * math.pi / 200,
    };
  }

  double _fromRadians(double value) {
    return switch (_context.angleMode) {
      AngleMode.degree => value * 180 / math.pi,
      AngleMode.radian => value,
      AngleMode.gradian => value * 200 / math.pi,
    };
  }

  bool _isNearlyInteger(double value) {
    return (value - value.roundToDouble()).abs() < 1e-10;
  }

  bool _isStructuredNonNumericValue(CalculatorValue value) {
    switch (value.kind) {
      case CalculatorValueKind.function:
      case CalculatorValueKind.plot:
      case CalculatorValueKind.equation:
      case CalculatorValueKind.solveResult:
      case CalculatorValueKind.expressionTransform:
        return true;
      default:
        return false;
    }
  }

  double _sinh(double value) {
    return (math.exp(value) - math.exp(-value)) / 2;
  }

  double _cosh(double value) {
    return (math.exp(value) + math.exp(-value)) / 2;
  }
}

class EvaluatedValue {
  const EvaluatedValue({
    required this.value,
    required this.isApproximate,
    this.statisticName,
    this.sampleSize,
    this.graphMetadata,
  });

  final CalculatorValue value;
  final bool isApproximate;
  final String? statisticName;
  final int? sampleSize;
  final GraphResultMetadata? graphMetadata;
}

class _CasVariableCollector {
  final Set<String> names = <String>{};

  void visit(ExpressionNode node) {
    if (node is ConstantNode) {
      if (!BuiltInSymbolCatalog.isBuiltInConstant(node.name) &&
          !BuiltInSymbolCatalog.isUnitIdentifier(node.name)) {
        names.add(node.name);
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
        names.add(node.name);
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
