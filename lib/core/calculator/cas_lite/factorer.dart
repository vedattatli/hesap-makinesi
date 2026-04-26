import '../ast_nodes.dart';
import '../calculation_context.dart';
import '../calculation_error.dart';
import '../scope/evaluation_scope.dart';
import '../solve/expression_transformer.dart';
import '../solve/polynomial.dart';
import '../solve/polynomial_detector.dart';
import '../solve/polynomial_solver.dart';
import '../src/calculator_exception.dart';
import '../src/expression_printer.dart';
import '../values/calculator_value.dart';
import '../values/expression_transform_value.dart';
import '../values/rational_value.dart';
import '../values/scalar_value_math.dart';
import 'cas_step.dart';

class CasFactorer {
  const CasFactorer({
    this.maxDegree = 6,
    PolynomialSolver solver = const PolynomialSolver(),
  }) : _solver = solver;

  final int maxDegree;
  final PolynomialSolver _solver;

  ExpressionTransformValue factor(
    ExpressionNode expression, {
    required String variableName,
    required CalculationContext context,
    EvaluationScope scope = const EvaluationScope(),
  }) {
    final polynomial =
        PolynomialDetector(maxSupportedExpansionDegree: maxDegree).detect(
          expression,
          variableName: variableName,
          context: context,
          scope: scope,
        );
    if (polynomial == null) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedCasTransform,
          message: 'CAS-lite factor supports polynomial expressions only.',
        ),
      );
    }
    if (polynomial.degree > maxDegree) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.factorizationLimit,
          message: 'Factorization degree limit exceeded.',
          suggestion: 'This phase factors polynomials up to degree $maxDegree.',
        ),
      );
    }

    final common = _commonMonomialFactor(polynomial);
    if (common != null) {
      return _result(
        expression,
        _multiplyFactors(<ExpressionNode>[
          common.factorAst,
          common.remainingAst,
        ]),
        <CasStep>[const CasStep(title: 'Extracted common monomial factor')],
      );
    }

    final quadratic = _factorQuadraticSpecials(polynomial);
    if (quadratic != null) {
      return _result(expression, quadratic, const <CasStep>[
        CasStep(title: 'Detected quadratic factor pattern'),
      ]);
    }

    final roots = _solver.solve(polynomial, domain: context.calculationDomain);
    final rationalRoots = roots.solutions.whereType<RationalValue>().toList();
    if (rationalRoots.length == polynomial.degree && rationalRoots.isNotEmpty) {
      final factors = <ExpressionNode>[];
      final leading = polynomial.coefficientOf(polynomial.degree);
      if (leading is! RationalValue) {
        throw const CalculatorException(
          CalculationError(
            type: CalculationErrorType.factorizationLimit,
            message:
                'Rational-root factorization requires rational coefficients.',
          ),
        );
      }
      if (!_isOne(leading)) {
        factors.add(_valueToAst(leading));
      }
      factors.addAll(
        rationalRoots.map((root) => _linearFactor(variableName, root)),
      );
      return _result(expression, _multiplyFactors(factors), <CasStep>[
        const CasStep(title: 'Applied rational-root factorization'),
        CasStep(
          title: 'Roots',
          detail: rationalRoots
              .map((root) => root.toFractionString())
              .join(', '),
        ),
      ]);
    }

    throw const CalculatorException(
      CalculationError(
        type: CalculationErrorType.factorizationLimit,
        message:
            'No supported CAS-lite factorization pattern was found for this polynomial.',
      ),
    );
  }

  ExpressionTransformValue _result(
    ExpressionNode input,
    ExpressionNode output,
    List<CasStep> steps,
  ) {
    return ExpressionTransformValue(
      kindLabel: ExpressionTransformKind.factor,
      originalExpression: ExpressionPrinter().print(input),
      normalizedExpression: ExpressionPrinter().print(output),
      expressionAst: output,
      steps: List<CasStep>.unmodifiable(steps),
    );
  }

  _CommonFactor? _commonMonomialFactor(Polynomial polynomial) {
    final rationals = polynomial.rationalCoefficientsDescending();
    if (rationals == null || rationals.length < 2) {
      return null;
    }
    final degrees = polynomial.coefficients.keys.toList(growable: false);
    final minDegree = degrees.reduce((a, b) => a < b ? a : b);
    var gcdNumerator = BigInt.zero;
    for (final coefficient in polynomial.coefficients.values) {
      if (coefficient is! RationalValue ||
          coefficient.denominator != BigInt.one) {
        return null;
      }
      gcdNumerator = gcdNumerator == BigInt.zero
          ? coefficient.numerator.abs()
          : gcdNumerator.gcd(coefficient.numerator.abs());
    }
    if (gcdNumerator <= BigInt.one && minDegree == 0) {
      return null;
    }
    final factorCoefficient = RationalValue(gcdNumerator, BigInt.one);
    final remaining = <int, CalculatorValue>{};
    for (final entry in polynomial.coefficients.entries) {
      remaining[entry.key - minDegree] = ScalarValueMath.divide(
        entry.value,
        factorCoefficient,
      );
    }
    final factorAst = _monomialFactor(
      polynomial.variableName,
      minDegree,
      factorCoefficient,
    );
    final remainingAst = _polynomialAst(
      Polynomial(
        variableName: polynomial.variableName,
        coefficients: remaining,
      ),
    );
    return _CommonFactor(factorAst: factorAst, remainingAst: remainingAst);
  }

  ExpressionNode? _factorQuadraticSpecials(Polynomial polynomial) {
    if (polynomial.degree != 2) {
      return null;
    }
    final a = polynomial.coefficientOf(2);
    final b = polynomial.coefficientOf(1);
    final c = polynomial.coefficientOf(0);
    if (a is! RationalValue || b is! RationalValue || c is! RationalValue) {
      return null;
    }
    if (_rationalEquals(a, RationalValue.one)) {
      final root = c.tryExactSquareRoot();
      if (root != null &&
          _rationalEquals(b, RationalValue.fromInt(2).multiply(root))) {
        return ExpressionTransformer.power(
          ExpressionTransformer.add(
            ConstantNode(name: polynomial.variableName, position: 0),
            _valueToAst(root),
          ),
          ExpressionTransformer.integer(2),
        );
      }
      if (root != null &&
          _rationalEquals(b, RationalValue.fromInt(-2).multiply(root))) {
        return ExpressionTransformer.power(
          ExpressionTransformer.subtract(
            ConstantNode(name: polynomial.variableName, position: 0),
            _valueToAst(root),
          ),
          ExpressionTransformer.integer(2),
        );
      }
      if (ScalarValueMath.isZero(b) && c.toDouble() < 0) {
        final magnitude = c.negate().tryExactSquareRoot();
        if (magnitude != null) {
          return _multiplyFactors(<ExpressionNode>[
            ExpressionTransformer.subtract(
              ConstantNode(name: polynomial.variableName, position: 0),
              _valueToAst(magnitude),
            ),
            ExpressionTransformer.add(
              ConstantNode(name: polynomial.variableName, position: 0),
              _valueToAst(magnitude),
            ),
          ]);
        }
      }
    }
    return null;
  }

  ExpressionNode _linearFactor(String variableName, RationalValue root) {
    final variable = ConstantNode(name: variableName, position: 0);
    if (root == RationalValue.zero) {
      return variable;
    }
    if (root.numerator.isNegative) {
      return ExpressionTransformer.add(variable, _valueToAst(root.negate()));
    }
    return ExpressionTransformer.subtract(variable, _valueToAst(root));
  }

  ExpressionNode _monomialFactor(
    String variableName,
    int degree,
    RationalValue coefficient,
  ) {
    ExpressionNode? factor;
    if (!_isOne(coefficient)) {
      factor = _valueToAst(coefficient);
    }
    if (degree > 0) {
      final variable = degree == 1
          ? ConstantNode(name: variableName, position: 0)
          : ExpressionTransformer.power(
              ConstantNode(name: variableName, position: 0),
              ExpressionTransformer.integer(degree),
            );
      factor = factor == null
          ? variable
          : ExpressionTransformer.multiply(factor, variable);
    }
    return factor ?? ExpressionTransformer.one();
  }

  ExpressionNode _polynomialAst(Polynomial polynomial) {
    final degrees = polynomial.coefficients.keys.toList(growable: false)
      ..sort((left, right) => right.compareTo(left));
    ExpressionNode? expression;
    for (final degree in degrees) {
      final coefficient = polynomial.coefficientOf(degree);
      if (ScalarValueMath.isZero(coefficient)) {
        continue;
      }
      final term = _monomialFactor(
        polynomial.variableName,
        degree,
        ScalarValueMath.abs(coefficient) as RationalValue,
      );
      final negative = coefficient.toDouble() < 0;
      expression = expression == null
          ? (negative ? ExpressionTransformer.negate(term) : term)
          : negative
          ? ExpressionTransformer.subtract(expression, term)
          : ExpressionTransformer.add(expression, term);
    }
    return expression ?? ExpressionTransformer.zero();
  }

  ExpressionNode _multiplyFactors(List<ExpressionNode> factors) {
    if (factors.isEmpty) {
      return ExpressionTransformer.one();
    }
    return factors.reduce(ExpressionTransformer.multiply);
  }

  ExpressionNode _valueToAst(RationalValue value) {
    if (value.denominator == BigInt.one) {
      return ExpressionTransformer.integer(value.numerator.toInt());
    }
    return ExpressionTransformer.divide(
      ExpressionTransformer.integer(value.numerator.toInt()),
      ExpressionTransformer.integer(value.denominator.toInt()),
    );
  }

  bool _isOne(CalculatorValue value) =>
      value is RationalValue &&
      value.numerator == BigInt.one &&
      value.denominator == BigInt.one;

  bool _rationalEquals(RationalValue left, RationalValue right) =>
      left.compareTo(right) == 0;
}

class _CommonFactor {
  const _CommonFactor({required this.factorAst, required this.remainingAst});

  final ExpressionNode factorAst;
  final ExpressionNode remainingAst;
}
