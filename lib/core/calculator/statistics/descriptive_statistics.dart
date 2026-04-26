import '../values/calculator_value.dart';
import '../values/complex_value.dart';
import '../values/dataset_value.dart';
import '../values/matrix_value.dart';
import '../values/rational_value.dart';
import '../values/regression_value.dart';
import '../values/scalar_value_math.dart';
import '../values/symbolic_value.dart';
import '../values/unit_math.dart';
import '../values/unit_value.dart';
import '../values/vector_value.dart';
import 'statistics_errors.dart';

/// Shared scalar helpers for statistics operations.
class StatisticsScalarMath {
  const StatisticsScalarMath._();

  static CalculatorValue normalizeDatasetValue(CalculatorValue value) {
    if (value is DatasetValue ||
        value is VectorValue ||
        value is MatrixValue ||
        value is RegressionValue) {
      throw const StatisticsException(
        StatisticsErrorType.unsupportedOperation,
        'Nested datasets, vectors and matrices are not supported in statistics datasets.',
      );
    }
    if (value is ComplexValue) {
      throw const StatisticsException(
        StatisticsErrorType.unsupportedOperation,
        'Complex values are not supported by this statistics function.',
      );
    }
    if (value is UnitValue && value.isUnitExpressionOnly) {
      throw const StatisticsException(
        StatisticsErrorType.invalidArgument,
        'Bare unit expressions cannot be used as dataset values.',
      );
    }
    return value;
  }

  static CalculatorValue requirePlainRealScalar(CalculatorValue value) {
    final normalized = normalizeDatasetValue(value);
    if (normalized is UnitValue) {
      throw const StatisticsException(
        StatisticsErrorType.unsupportedOperation,
        'This statistics function only supports plain real scalar values.',
      );
    }
    return normalized;
  }

  static CalculatorValue normalizeWeight(CalculatorValue value) {
    final normalized = normalizeDatasetValue(value);
    if (normalized is UnitValue) {
      if (!normalized.dimension.isDimensionless) {
        throw const StatisticsException(
          StatisticsErrorType.dimensionMismatch,
          'Weights must be dimensionless.',
        );
      }
      return normalized.displayMagnitude;
    }
    return normalized;
  }

  static CalculatorValue add(CalculatorValue left, CalculatorValue right) {
    try {
      if (left is UnitValue && right is UnitValue) {
        return UnitMath.add(left, right);
      }
      return ScalarValueMath.add(left, right);
    } on ArgumentError {
      throw const StatisticsException(
        StatisticsErrorType.dimensionMismatch,
        'Statistics inputs must have compatible dimensions.',
      );
    } on UnsupportedError catch (error) {
      throw StatisticsException(
        StatisticsErrorType.unsupportedOperation,
        error.message ?? 'This statistics operation is not supported.',
      );
    }
  }

  static CalculatorValue subtract(CalculatorValue left, CalculatorValue right) {
    try {
      if (left is UnitValue && right is UnitValue) {
        return UnitMath.subtract(left, right);
      }
      return ScalarValueMath.subtract(left, right);
    } on ArgumentError {
      throw const StatisticsException(
        StatisticsErrorType.dimensionMismatch,
        'Statistics inputs must have compatible dimensions.',
      );
    } on UnsupportedError catch (error) {
      throw StatisticsException(
        StatisticsErrorType.unsupportedOperation,
        error.message ?? 'This statistics operation is not supported.',
      );
    }
  }

  static CalculatorValue multiply(CalculatorValue left, CalculatorValue right) {
    try {
      if (left is UnitValue && right is UnitValue) {
        return UnitMath.multiply(left, right);
      }
      if (left is UnitValue) {
        return UnitMath.multiplyScalar(right, left);
      }
      if (right is UnitValue) {
        return UnitMath.multiplyScalar(left, right);
      }
      return ScalarValueMath.multiply(left, right);
    } on UnsupportedError catch (error) {
      throw StatisticsException(
        StatisticsErrorType.unsupportedOperation,
        error.message ?? 'This statistics operation is not supported.',
      );
    }
  }

  static CalculatorValue divide(CalculatorValue left, CalculatorValue right) {
    try {
      if (left is UnitValue && right is UnitValue) {
        return UnitMath.divide(left, right);
      }
      if (left is UnitValue) {
        return UnitMath.divideByScalar(left, right);
      }
      if (right is UnitValue) {
        return UnitMath.divideScalarByUnit(left, right);
      }
      return ScalarValueMath.divide(left, right);
    } on ArgumentError {
      throw const StatisticsException(
        StatisticsErrorType.domainError,
        'Division by zero is undefined.',
      );
    } on UnsupportedError catch (error) {
      throw StatisticsException(
        StatisticsErrorType.unsupportedOperation,
        error.message ?? 'This statistics operation is not supported.',
      );
    }
  }

  static CalculatorValue abs(CalculatorValue value) {
    try {
      if (value is UnitValue) {
        return UnitMath.abs(value);
      }
      return ScalarValueMath.abs(value);
    } on UnsupportedError catch (error) {
      throw StatisticsException(
        StatisticsErrorType.unsupportedOperation,
        error.message ?? 'This statistics operation is not supported.',
      );
    }
  }

  static CalculatorValue sqrt(CalculatorValue value) {
    try {
      if (value is UnitValue) {
        return UnitMath.squareRoot(value);
      }
      return ScalarValueMath.squareRoot(value);
    } on UnsupportedError catch (error) {
      throw StatisticsException(
        StatisticsErrorType.unsupportedOperation,
        error.message ?? 'This statistics operation is not supported.',
      );
    }
  }

  static CalculatorValue integerPower(CalculatorValue value, int exponent) {
    try {
      if (value is UnitValue) {
        return UnitMath.integerPower(value, exponent);
      }
      return ScalarValueMath.integerPower(value, exponent);
    } on UnsupportedError catch (error) {
      throw StatisticsException(
        StatisticsErrorType.unsupportedOperation,
        error.message ?? 'This statistics operation is not supported.',
      );
    }
  }

  static int compare(CalculatorValue left, CalculatorValue right) {
    try {
      if (left is UnitValue && right is UnitValue) {
        return UnitMath.compare(left, right);
      }
      return ScalarValueMath.compare(left, right);
    } on ArgumentError {
      throw const StatisticsException(
        StatisticsErrorType.dimensionMismatch,
        'Statistics inputs must have compatible dimensions.',
      );
    }
  }

  static bool isZero(CalculatorValue value) {
    if (value is UnitValue) {
      return ScalarValueMath.isZero(value.baseMagnitude);
    }
    return ScalarValueMath.isZero(value);
  }

  static String canonicalKey(CalculatorValue value) {
    if (value is RationalValue) {
      return 'r:${value.toFractionString()}';
    }
    if (value is SymbolicValue) {
      return 's:${value.toSymbolicString()}';
    }
    if (value is UnitValue) {
      final magnitude = canonicalKey(value.baseMagnitude);
      return 'u:${value.dimension.toDisplayString()}:$magnitude';
    }
    return 'd:${value.toDouble().toStringAsPrecision(12)}';
  }
}

/// Descriptive statistics helpers for scalar datasets.
class DescriptiveStatistics {
  const DescriptiveStatistics._();

  static const maxDatasetLength = 10000;

  static DatasetValue normalizeDataset(DatasetValue dataset) {
    if (dataset.length > maxDatasetLength) {
      throw const StatisticsException(
        StatisticsErrorType.computationLimit,
        'Dataset length exceeds the safe exact statistics limit.',
      );
    }
    return DatasetValue(
      dataset.values.map(StatisticsScalarMath.normalizeDatasetValue),
    );
  }

  static RationalValue count(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    return RationalValue.fromInt(normalized.length);
  }

  static CalculatorValue sum(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    var total = normalized.values.first;
    for (var index = 1; index < normalized.length; index++) {
      total = StatisticsScalarMath.add(total, normalized.values[index]);
    }
    return total;
  }

  static CalculatorValue product(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    var total = RationalValue.one as CalculatorValue;
    for (final value in normalized.values) {
      total = StatisticsScalarMath.multiply(total, value);
    }
    return total;
  }

  static CalculatorValue mean(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    final total = sum(normalized);
    return StatisticsScalarMath.divide(
      total,
      RationalValue.fromInt(normalized.length),
    );
  }

  static CalculatorValue median(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    final sorted = normalized.sortedValues(StatisticsScalarMath.compare);
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return StatisticsScalarMath.divide(
      StatisticsScalarMath.add(sorted[middle - 1], sorted[middle]),
      RationalValue.fromInt(2),
    );
  }

  static CalculatorValue mode(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    final buckets = <String, _ModeBucket>{};
    for (final value in normalized.values) {
      final key = StatisticsScalarMath.canonicalKey(value);
      final bucket = buckets[key];
      if (bucket == null) {
        buckets[key] = _ModeBucket(value: value, count: 1);
      } else {
        buckets[key] = _ModeBucket(value: bucket.value, count: bucket.count + 1);
      }
    }

    var maxCount = 0;
    for (final bucket in buckets.values) {
      if (bucket.count > maxCount) {
        maxCount = bucket.count;
      }
    }

    final winners = buckets.values
        .where((bucket) => bucket.count == maxCount)
        .map((bucket) => bucket.value)
        .toList(growable: false)
      ..sort(StatisticsScalarMath.compare);

    if (winners.length == 1) {
      return winners.first;
    }
    return VectorValue(winners);
  }

  static CalculatorValue min(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    var current = normalized.values.first;
    for (var index = 1; index < normalized.length; index++) {
      if (StatisticsScalarMath.compare(normalized.values[index], current) < 0) {
        current = normalized.values[index];
      }
    }
    return current;
  }

  static CalculatorValue max(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    var current = normalized.values.first;
    for (var index = 1; index < normalized.length; index++) {
      if (StatisticsScalarMath.compare(normalized.values[index], current) > 0) {
        current = normalized.values[index];
      }
    }
    return current;
  }

  static CalculatorValue range(DatasetValue dataset) {
    return StatisticsScalarMath.subtract(max(dataset), min(dataset));
  }

  static CalculatorValue variancePopulation(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    final meanValue = mean(normalized);
    CalculatorValue? total;
    for (final value in normalized.values) {
      final deviation = StatisticsScalarMath.subtract(value, meanValue);
      final squaredDeviation = StatisticsScalarMath.multiply(
        deviation,
        deviation,
      );
      total = total == null
          ? squaredDeviation
          : StatisticsScalarMath.add(total, squaredDeviation);
    }
    return StatisticsScalarMath.divide(
      total ?? RationalValue.zero,
      RationalValue.fromInt(normalized.length),
    );
  }

  static CalculatorValue varianceSample(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    if (normalized.length < 2) {
      throw const StatisticsException(
        StatisticsErrorType.insufficientData,
        'Sample variance requires at least two data points.',
      );
    }
    final meanValue = mean(normalized);
    CalculatorValue? total;
    for (final value in normalized.values) {
      final deviation = StatisticsScalarMath.subtract(value, meanValue);
      final squaredDeviation = StatisticsScalarMath.multiply(
        deviation,
        deviation,
      );
      total = total == null
          ? squaredDeviation
          : StatisticsScalarMath.add(total, squaredDeviation);
    }
    return StatisticsScalarMath.divide(
      total ?? RationalValue.zero,
      RationalValue.fromInt(normalized.length - 1),
    );
  }

  static CalculatorValue standardDeviationPopulation(DatasetValue dataset) {
    return StatisticsScalarMath.sqrt(variancePopulation(dataset));
  }

  static CalculatorValue standardDeviationSample(DatasetValue dataset) {
    return StatisticsScalarMath.sqrt(varianceSample(dataset));
  }

  static CalculatorValue meanAbsoluteDeviation(DatasetValue dataset) {
    final normalized = normalizeDataset(dataset);
    final meanValue = mean(normalized);
    var total = _zeroLike(normalized.values.first);
    for (final value in normalized.values) {
      total = StatisticsScalarMath.add(
        total,
        StatisticsScalarMath.abs(
          StatisticsScalarMath.subtract(value, meanValue),
        ),
      );
    }
    return StatisticsScalarMath.divide(
      total,
      RationalValue.fromInt(normalized.length),
    );
  }

  static CalculatorValue weightedMean(DatasetValue values, DatasetValue weights) {
    final normalizedValues = normalizeDataset(values);
    final normalizedWeights = normalizeDataset(weights);
    if (normalizedValues.length != normalizedWeights.length) {
      throw const StatisticsException(
        StatisticsErrorType.dimensionMismatch,
        'Weighted statistics require values and weights of the same length.',
      );
    }

    var weightedTotal = _zeroLike(normalizedValues.values.first);
    var weightTotal = RationalValue.zero as CalculatorValue;
    for (var index = 0; index < normalizedValues.length; index++) {
      final weight = StatisticsScalarMath.normalizeWeight(
        normalizedWeights.values[index],
      );
      if (StatisticsScalarMath.compare(weight, RationalValue.zero) < 0) {
        throw const StatisticsException(
          StatisticsErrorType.invalidArgument,
          'Weights must be non-negative.',
        );
      }
      weightedTotal = StatisticsScalarMath.add(
        weightedTotal,
        StatisticsScalarMath.multiply(normalizedValues.values[index], weight),
      );
      weightTotal = StatisticsScalarMath.add(weightTotal, weight);
    }

    if (StatisticsScalarMath.isZero(weightTotal)) {
      throw const StatisticsException(
        StatisticsErrorType.invalidArgument,
        'Weights must sum to a value greater than zero.',
      );
    }
    return StatisticsScalarMath.divide(weightedTotal, weightTotal);
  }

  static CalculatorValue interpolate(
    CalculatorValue lower,
    CalculatorValue upper, {
    required RationalValue exactWeight,
  }) {
    if (exactWeight.compareTo(RationalValue.zero) == 0) {
      return lower;
    }
    if (exactWeight.compareTo(RationalValue.one) == 0) {
      return upper;
    }
    final difference = StatisticsScalarMath.subtract(upper, lower);
    final offset = StatisticsScalarMath.multiply(difference, exactWeight);
    return StatisticsScalarMath.add(lower, offset);
  }

  static CalculatorValue interpolateApproximate(
    CalculatorValue lower,
    CalculatorValue upper, {
    required double weight,
  }) {
    if (weight <= 0) {
      return lower;
    }
    if (weight >= 1) {
      return upper;
    }
    return StatisticsScalarMath.add(
      lower,
      StatisticsScalarMath.multiply(
        StatisticsScalarMath.subtract(upper, lower),
        RationalValue.parseLiteral(weight.toString()),
      ),
    );
  }

  static CalculatorValue _zeroLike(CalculatorValue seed) {
    if (seed is UnitValue) {
      return UnitValue.fromBaseMagnitude(
        baseMagnitude: RationalValue.zero,
        displayUnit: seed.displayUnit,
      );
    }
    return RationalValue.zero;
  }
}

class _ModeBucket {
  const _ModeBucket({required this.value, required this.count});

  final CalculatorValue value;
  final int count;
}
