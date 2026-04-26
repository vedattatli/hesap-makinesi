import 'dart:math' as math;

import '../calculation_domain.dart';
import '../calculation_error.dart';
import '../src/calculator_exception.dart';
import '../values/calculator_value.dart';
import '../values/complex_value.dart';
import '../values/rational_value.dart';
import '../values/scalar_value_math.dart';
import '../values/symbolic_simplifier.dart';
import 'polynomial.dart';
import 'solve_method.dart';

class PolynomialSolveOutcome {
  const PolynomialSolveOutcome({
    required this.solutions,
    required this.method,
    required this.exact,
    this.noSolutionReason,
    this.infiniteSolutions = false,
  });

  final List<CalculatorValue> solutions;
  final SolveMethod method;
  final bool exact;
  final String? noSolutionReason;
  final bool infiniteSolutions;
}

class PolynomialSolver {
  const PolynomialSolver({
    this.maxClosedFormDegree = 2,
    this.maxRationalRootDegree = 6,
    this.maxRationalRootCandidates = 5000,
  });

  final int maxClosedFormDegree;
  final int maxRationalRootDegree;
  final int maxRationalRootCandidates;

  PolynomialSolveOutcome solve(
    Polynomial polynomial, {
    required CalculationDomain domain,
  }) {
    if (polynomial.isZero || polynomial.degree == 0) {
      return _solveDegreeZero(polynomial);
    }
    if (polynomial.degree == 1) {
      return _solveLinear(polynomial);
    }
    if (polynomial.degree == 2) {
      return _solveQuadratic(polynomial, domain: domain);
    }
    if (polynomial.degree > maxRationalRootDegree) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.polynomialDegreeLimit,
          message: 'Exact polynomial solving is limited in this phase.',
          suggestion: 'Provide an interval for numeric solving.',
        ),
      );
    }
    return _solveByRationalRoots(polynomial, domain: domain);
  }

  PolynomialSolveOutcome _solveDegreeZero(Polynomial polynomial) {
    final constant = polynomial.coefficientOf(0);
    if (ScalarValueMath.isZero(constant)) {
      return const PolynomialSolveOutcome(
        solutions: <CalculatorValue>[],
        method: SolveMethod.exactDegreeZero,
        exact: true,
        infiniteSolutions: true,
      );
    }
    return const PolynomialSolveOutcome(
      solutions: <CalculatorValue>[],
      method: SolveMethod.exactDegreeZero,
      exact: true,
      noSolutionReason: 'No solution',
    );
  }

  PolynomialSolveOutcome _solveLinear(Polynomial polynomial) {
    final a = polynomial.coefficientOf(1);
    final b = polynomial.coefficientOf(0);
    if (ScalarValueMath.isZero(a)) {
      return _solveDegreeZero(
        Polynomial(
          variableName: polynomial.variableName,
          coefficients: <int, CalculatorValue>{0: b},
        ),
      );
    }
    final solution = ScalarValueMath.divide(ScalarValueMath.negate(b), a);
    return PolynomialSolveOutcome(
      solutions: _dedupeAndSort(<CalculatorValue>[solution]),
      method: SolveMethod.exactLinear,
      exact: solution.isExact,
    );
  }

  PolynomialSolveOutcome _solveQuadratic(
    Polynomial polynomial, {
    required CalculationDomain domain,
  }) {
    final a = polynomial.coefficientOf(2);
    final b = polynomial.coefficientOf(1);
    final c = polynomial.coefficientOf(0);
    if (ScalarValueMath.isZero(a)) {
      return _solveLinear(
        Polynomial(
          variableName: polynomial.variableName,
          coefficients: <int, CalculatorValue>{1: b, 0: c},
        ),
      );
    }

    final fourAC = ScalarValueMath.multiply(
      RationalValue.fromInt(4),
      ScalarValueMath.multiply(a, c),
    );
    final discriminant = ScalarValueMath.subtract(
      ScalarValueMath.integerPower(b, 2),
      fourAC,
    );
    final discriminantDouble = discriminant.toDouble();
    if (domain == CalculationDomain.real && discriminantDouble < -1e-12) {
      return const PolynomialSolveOutcome(
        solutions: <CalculatorValue>[],
        method: SolveMethod.exactQuadratic,
        exact: true,
        noSolutionReason: 'No real solution',
      );
    }

    final twoA = ScalarValueMath.multiply(RationalValue.fromInt(2), a);
    if (discriminantDouble.abs() < 1e-12) {
      final repeated = ScalarValueMath.divide(ScalarValueMath.negate(b), twoA);
      return PolynomialSolveOutcome(
        solutions: <CalculatorValue>[repeated],
        method: SolveMethod.exactQuadratic,
        exact: repeated.isExact,
      );
    }

    if (discriminantDouble < 0) {
      final negated = ScalarValueMath.negate(discriminant);
      final sqrtMagnitude = _squareRootExactOrApprox(negated);
      final realPart = ScalarValueMath.divide(ScalarValueMath.negate(b), twoA);
      final imagPart = ScalarValueMath.divide(sqrtMagnitude, twoA);
      final left = ComplexValue(
        realPart: _promoteComplexScalar(realPart),
        imaginaryPart: _promoteComplexScalar(ScalarValueMath.negate(imagPart)),
      );
      final right = ComplexValue(
        realPart: _promoteComplexScalar(realPart),
        imaginaryPart: _promoteComplexScalar(imagPart),
      );
      return PolynomialSolveOutcome(
        solutions: _dedupeAndSort(<CalculatorValue>[left, right]),
        method: SolveMethod.exactQuadratic,
        exact: left.isExact && right.isExact,
      );
    }

    final sqrtDiscriminant = _squareRootExactOrApprox(discriminant);
    final minusB = ScalarValueMath.negate(b);
    final first = ScalarValueMath.divide(
      ScalarValueMath.subtract(minusB, sqrtDiscriminant),
      twoA,
    );
    final second = ScalarValueMath.divide(
      ScalarValueMath.add(minusB, sqrtDiscriminant),
      twoA,
    );
    final exact = first.isExact && second.isExact;
    return PolynomialSolveOutcome(
      solutions: _dedupeAndSort(<CalculatorValue>[first, second]),
      method: SolveMethod.exactQuadratic,
      exact: exact,
    );
  }

  PolynomialSolveOutcome _solveByRationalRoots(
    Polynomial polynomial, {
    required CalculationDomain domain,
  }) {
    final rationals = polynomial.rationalCoefficientsDescending();
    if (rationals == null) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.unsupportedSolveForm,
          message: 'Exact solving is only available for rational-coefficient polynomials in this phase.',
          suggestion: 'Provide an interval for numeric solving.',
        ),
      );
    }

    var current = rationals;
    final roots = <CalculatorValue>[];
    while (current.length > 3) {
      final candidate = _findRationalRoot(current);
      if (candidate == null) {
        break;
      }
      roots.add(candidate);
      current = _deflate(current, candidate);
    }

    final remainingPolynomial = Polynomial(
      variableName: polynomial.variableName,
      coefficients: <int, CalculatorValue>{
        for (var index = 0; index < current.length; index++)
          current.length - index - 1: current[index],
      },
    );

    if (remainingPolynomial.degree >= 1) {
      final tail = solve(remainingPolynomial, domain: domain);
      roots.addAll(tail.solutions);
      return PolynomialSolveOutcome(
        solutions: _dedupeAndSort(roots),
        method: SolveMethod.rationalRootPolynomial,
        exact: roots.every((value) => value.isExact),
        noSolutionReason: roots.isEmpty ? tail.noSolutionReason : null,
        infiniteSolutions: tail.infiniteSolutions,
      );
    }

    if (roots.isEmpty) {
      return const PolynomialSolveOutcome(
        solutions: <CalculatorValue>[],
        method: SolveMethod.rationalRootPolynomial,
        exact: true,
        noSolutionReason: 'No solution',
      );
    }

    return PolynomialSolveOutcome(
      solutions: _dedupeAndSort(roots),
      method: SolveMethod.rationalRootPolynomial,
      exact: roots.every((value) => value.isExact),
    );
  }

  RationalValue? _findRationalRoot(List<RationalValue> descendingCoefficients) {
    final lcm = descendingCoefficients.fold<BigInt>(
      BigInt.one,
      (current, coefficient) => _lcm(current, coefficient.denominator),
    );
    final integerCoefficients = descendingCoefficients
        .map((coefficient) => coefficient.numerator * (lcm ~/ coefficient.denominator))
        .toList(growable: false);
    final leading = integerCoefficients.first.abs();
    final constant = integerCoefficients.last.abs();

    final candidates = <RationalValue>{};
    if (constant == BigInt.zero) {
      candidates.add(RationalValue.zero);
    }
    final pFactors = _divisors(constant);
    final qFactors = _divisors(leading);
    if (pFactors.length * qFactors.length * 2 > maxRationalRootCandidates) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.computationLimit,
          message: 'Rational-root candidate limit was exceeded.',
          suggestion: 'Provide an interval for numeric solving.',
        ),
      );
    }
    for (final p in pFactors) {
      for (final q in qFactors) {
        candidates.add(RationalValue(p, q));
        candidates.add(RationalValue(-p, q));
      }
    }

    final ordered = candidates.toList(growable: false)
      ..sort((left, right) => left.compareTo(right));
    for (final candidate in ordered) {
      if (_evaluateDescending(descendingCoefficients, candidate).numerator == BigInt.zero) {
        return candidate;
      }
    }
    return null;
  }

  List<RationalValue> _deflate(
    List<RationalValue> descendingCoefficients,
    RationalValue root,
  ) {
    final synthetic = <RationalValue>[descendingCoefficients.first];
    for (var index = 1; index < descendingCoefficients.length - 1; index++) {
      synthetic.add(
        descendingCoefficients[index].add(
          synthetic.last.multiply(root),
        ),
      );
    }
    return List<RationalValue>.unmodifiable(synthetic);
  }

  RationalValue _evaluateDescending(
    List<RationalValue> descendingCoefficients,
    RationalValue x,
  ) {
    var total = descendingCoefficients.first;
    for (var index = 1; index < descendingCoefficients.length; index++) {
      total = total.multiply(x).add(descendingCoefficients[index]);
    }
    return total;
  }

  List<BigInt> _divisors(BigInt value) {
    final absolute = value.abs();
    if (absolute == BigInt.zero) {
      return <BigInt>[BigInt.zero];
    }
    final numeric = int.tryParse(absolute.toString());
    if (numeric == null || numeric > 1000000) {
      throw const CalculatorException(
        CalculationError(
          type: CalculationErrorType.computationLimit,
          message: 'Polynomial factor search exceeded the safe integer range.',
          suggestion: 'Provide an interval for numeric solving.',
        ),
      );
    }
    final divisors = <BigInt>{};
    final limit = math.sqrt(numeric).floor();
    for (var candidate = 1; candidate <= limit; candidate++) {
      if (numeric % candidate != 0) {
        continue;
      }
      divisors.add(BigInt.from(candidate));
      divisors.add(BigInt.from(numeric ~/ candidate));
    }
    return divisors.toList(growable: false)..sort();
  }

  BigInt _lcm(BigInt left, BigInt right) {
    if (left == BigInt.zero || right == BigInt.zero) {
      return BigInt.zero;
    }
    return (left ~/ left.gcd(right)) * right;
  }

  CalculatorValue _squareRootExactOrApprox(CalculatorValue value) {
    if (value is RationalValue) {
      return SymbolicSimplifier.fromRadicalRational(value);
    }
    return ScalarValueMath.squareRoot(value);
  }

  CalculatorValue _promoteComplexScalar(CalculatorValue value) {
    return value is RationalValue ? value : value;
  }

  List<CalculatorValue> _dedupeAndSort(List<CalculatorValue> values) {
    final unique = <CalculatorValue>[];
    for (final value in values) {
      if (unique.any((existing) => (existing.toDouble() - value.toDouble()).abs() < 1e-10)) {
        continue;
      }
      unique.add(value);
    }
    unique.sort((left, right) {
      final leftComplex = left is ComplexValue;
      final rightComplex = right is ComplexValue;
      if (!leftComplex && !rightComplex) {
        return left.toDouble().compareTo(right.toDouble());
      }
      final leftReal = leftComplex ? left.realPart.toDouble() : left.toDouble();
      final rightReal = rightComplex ? right.realPart.toDouble() : right.toDouble();
      final realCompare = leftReal.compareTo(rightReal);
      if (realCompare != 0) {
        return realCompare;
      }
      final leftImag = leftComplex ? left.imaginaryPart.toDouble() : 0.0;
      final rightImag = rightComplex ? right.imaginaryPart.toDouble() : 0.0;
      return leftImag.compareTo(rightImag);
    });
    return List<CalculatorValue>.unmodifiable(unique);
  }
}
