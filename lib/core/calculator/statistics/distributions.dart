import 'dart:math' as math;

import '../values/rational_value.dart';
import 'combinatorics.dart';
import 'statistics_errors.dart';

/// Probability distribution helpers for phase 8.
class StatisticsDistributions {
  const StatisticsDistributions._();

  static const maxSummationIterations = 100000;

  static RationalValue binomialPmfExact(int n, RationalValue p, int k) {
    _validateBinomialParameters(n, p.toDouble(), k);
    if (k < 0 || k > n) {
      return RationalValue.zero;
    }
    final combinations = StatisticsCombinatorics.combinations(n, k);
    final left = p.powInteger(k);
    final right = RationalValue.one.subtract(p).powInteger(n - k);
    return RationalValue(combinations, BigInt.one).multiply(left).multiply(right);
  }

  static RationalValue binomialCdfExact(int n, RationalValue p, int k) {
    _validateBinomialParameters(n, p.toDouble(), k);
    if (k < 0) {
      return RationalValue.zero;
    }
    if (k >= n) {
      return RationalValue.one;
    }
    var total = RationalValue.zero;
    for (var index = 0; index <= k; index++) {
      total = total.add(binomialPmfExact(n, p, index));
    }
    return total;
  }

  static double binomialPmf(int n, double p, int k) {
    _validateBinomialParameters(n, p, k);
    if (k < 0 || k > n) {
      return 0.0;
    }
    final logValue =
        _logCombination(n, k) + k * math.log(p) + (n - k) * math.log(1 - p);
    return math.exp(logValue);
  }

  static double binomialCdf(int n, double p, int k) {
    _validateBinomialParameters(n, p, k);
    if (k < 0) {
      return 0.0;
    }
    if (k >= n) {
      return 1.0;
    }
    final limit = k + 1;
    if (limit > maxSummationIterations) {
      throw const StatisticsException(
        StatisticsErrorType.computationLimit,
        'Binomial cumulative summation exceeds the safe iteration limit.',
      );
    }
    var total = 0.0;
    for (var index = 0; index <= k; index++) {
      total += binomialPmf(n, p, index);
    }
    return total.clamp(0.0, 1.0);
  }

  static RationalValue geometricPmfExact(RationalValue p, int k) {
    _validateGeometricParameters(p.toDouble(), k);
    return RationalValue.one.subtract(p).powInteger(k - 1).multiply(p);
  }

  static RationalValue geometricCdfExact(RationalValue p, int k) {
    _validateGeometricParameters(p.toDouble(), k);
    return RationalValue.one.subtract(
      RationalValue.one.subtract(p).powInteger(k),
    );
  }

  static double geometricPmf(double p, int k) {
    _validateGeometricParameters(p, k);
    return math.pow(1 - p, k - 1).toDouble() * p;
  }

  static double geometricCdf(double p, int k) {
    _validateGeometricParameters(p, k);
    return 1 - math.pow(1 - p, k).toDouble();
  }

  static double poissonPmf(int k, double lambda) {
    _validatePoissonParameters(k, lambda);
    final logValue = k * math.log(lambda) - lambda - _logFactorial(k);
    return math.exp(logValue);
  }

  static double poissonCdf(int k, double lambda) {
    _validatePoissonParameters(k, lambda);
    final iterations = k + 1;
    if (iterations > maxSummationIterations) {
      throw const StatisticsException(
        StatisticsErrorType.computationLimit,
        'Poisson cumulative summation exceeds the safe iteration limit.',
      );
    }
    var total = 0.0;
    for (var index = 0; index <= k; index++) {
      total += poissonPmf(index, lambda);
    }
    return total.clamp(0.0, 1.0);
  }

  static double normalPdf(double x, double mean, double standardDeviation) {
    _validateStandardDeviation(standardDeviation, functionName: 'normalPdf');
    final z = (x - mean) / standardDeviation;
    final coefficient = 1 / (standardDeviation * math.sqrt(2 * math.pi));
    return coefficient * math.exp(-0.5 * z * z);
  }

  static double normalCdf(double x, double mean, double standardDeviation) {
    _validateStandardDeviation(standardDeviation, functionName: 'normalCdf');
    final z = (x - mean) / standardDeviation;
    if (z == 0) {
      return 0.5;
    }
    return 0.5 * (1 + _erf(z / math.sqrt(2)));
  }

  static double zScore(double x, double mean, double standardDeviation) {
    _validateStandardDeviation(standardDeviation, functionName: 'zscore');
    return (x - mean) / standardDeviation;
  }

  static double uniformPdf(double x, double a, double b) {
    _validateUniformParameters(a, b);
    if (x < a || x > b) {
      return 0.0;
    }
    return 1 / (b - a);
  }

  static double uniformCdf(double x, double a, double b) {
    _validateUniformParameters(a, b);
    if (x <= a) {
      return 0.0;
    }
    if (x >= b) {
      return 1.0;
    }
    return (x - a) / (b - a);
  }

  static void _validateBinomialParameters(int n, double p, int k) {
    if (n < 0 || k < 0 || k > n || p < 0 || p > 1) {
      throw const StatisticsException(
        StatisticsErrorType.invalidProbabilityParameter,
        'Binomial parameters require n >= 0, 0 <= k <= n and p in [0, 1].',
      );
    }
  }

  static void _validatePoissonParameters(int k, double lambda) {
    if (k < 0 || lambda <= 0) {
      throw const StatisticsException(
        StatisticsErrorType.invalidProbabilityParameter,
        'Poisson parameters require k >= 0 and lambda > 0.',
      );
    }
  }

  static void _validateGeometricParameters(double p, int k) {
    if (p < 0 || p > 1 || k < 1) {
      throw const StatisticsException(
        StatisticsErrorType.invalidProbabilityParameter,
        'Geometric parameters require p in [0, 1] and trial k >= 1.',
      );
    }
  }

  static void _validateStandardDeviation(
    double standardDeviation, {
    required String functionName,
  }) {
    if (standardDeviation <= 0) {
      throw StatisticsException(
        StatisticsErrorType.invalidProbabilityParameter,
        '$functionName requires a positive standard deviation.',
      );
    }
  }

  static void _validateUniformParameters(double a, double b) {
    if (b <= a) {
      throw const StatisticsException(
        StatisticsErrorType.invalidProbabilityParameter,
        'Uniform distribution requires b > a.',
      );
    }
  }

  static double _logFactorial(int value) {
    var total = 0.0;
    for (var index = 2; index <= value; index++) {
      total += math.log(index);
    }
    return total;
  }

  static double _logCombination(int n, int k) {
    return _logFactorial(n) - _logFactorial(k) - _logFactorial(n - k);
  }

  static double _erf(double value) {
    final sign = value < 0 ? -1.0 : 1.0;
    final absolute = value.abs();
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;
    final t = 1 / (1 + p * absolute);
    final polynomial =
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t;
    return sign * (1 - polynomial * math.exp(-(absolute * absolute)));
  }
}
