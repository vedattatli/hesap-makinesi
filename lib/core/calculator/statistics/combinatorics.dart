import 'dart:math' as math;

import 'statistics_errors.dart';

/// Exact combinatorics helpers backed by [BigInt].
class StatisticsCombinatorics {
  const StatisticsCombinatorics._();

  static const maxFactorialInput = 5000;

  static BigInt factorial(int n) {
    if (n < 0) {
      throw const StatisticsException(
        StatisticsErrorType.invalidProbabilityParameter,
        'Factorial requires a non-negative integer.',
      );
    }
    if (n > maxFactorialInput) {
      throw const StatisticsException(
        StatisticsErrorType.computationLimit,
        'Factorial input exceeds the safe computation limit.',
      );
    }

    var result = BigInt.one;
    for (var value = 2; value <= n; value++) {
      result *= BigInt.from(value);
    }
    return result;
  }

  static BigInt combinations(int n, int r) {
    _validateSelection(n, r);
    final normalizedR = math.min(r, n - r);
    if (normalizedR == 0) {
      return BigInt.one;
    }

    var result = BigInt.one;
    for (var step = 1; step <= normalizedR; step++) {
      result =
          (result * BigInt.from(n - normalizedR + step)) ~/ BigInt.from(step);
    }
    return result;
  }

  static BigInt permutations(int n, int r) {
    _validateSelection(n, r);
    if (r == 0) {
      return BigInt.one;
    }

    var result = BigInt.one;
    for (var value = n - r + 1; value <= n; value++) {
      result *= BigInt.from(value);
    }
    return result;
  }

  static void _validateSelection(int n, int r) {
    if (n < 0 || r < 0) {
      throw const StatisticsException(
        StatisticsErrorType.invalidProbabilityParameter,
        'Combinatorics inputs must be non-negative integers.',
      );
    }
    if (r > n) {
      throw const StatisticsException(
        StatisticsErrorType.invalidProbabilityParameter,
        'Selection count cannot be greater than the population size.',
      );
    }
    if (n > maxFactorialInput) {
      throw const StatisticsException(
        StatisticsErrorType.computationLimit,
        'Combinatorics input exceeds the safe computation limit.',
      );
    }
  }
}
