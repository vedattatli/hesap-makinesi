import '../values/calculator_value.dart';
import '../values/dataset_value.dart';
import '../values/rational_value.dart';
import '../values/regression_value.dart';
import 'descriptive_statistics.dart';
import 'statistics_errors.dart';

/// Regression and correlation helpers for paired datasets.
class StatisticsRegression {
  const StatisticsRegression._();

  static DatasetValue normalizePlainDataset(DatasetValue dataset) {
    final normalized = DescriptiveStatistics.normalizeDataset(dataset);
    return DatasetValue(
      normalized.values.map(StatisticsScalarMath.requirePlainRealScalar),
    );
  }

  static CalculatorValue covariancePopulation(
    DatasetValue xDataset,
    DatasetValue yDataset,
  ) {
    final datasets = _normalizePairedDatasets(xDataset, yDataset);
    final xValues = datasets.$1;
    final yValues = datasets.$2;
    final xMean = DescriptiveStatistics.mean(xValues);
    final yMean = DescriptiveStatistics.mean(yValues);
    var total = RationalValue.zero as CalculatorValue;
    for (var index = 0; index < xValues.length; index++) {
      final xDeviation = StatisticsScalarMath.subtract(
        xValues.values[index],
        xMean,
      );
      final yDeviation = StatisticsScalarMath.subtract(
        yValues.values[index],
        yMean,
      );
      total = StatisticsScalarMath.add(
        total,
        StatisticsScalarMath.multiply(xDeviation, yDeviation),
      );
    }
    return StatisticsScalarMath.divide(
      total,
      RationalValue.fromInt(xValues.length),
    );
  }

  static CalculatorValue covarianceSample(
    DatasetValue xDataset,
    DatasetValue yDataset,
  ) {
    final datasets = _normalizePairedDatasets(xDataset, yDataset);
    final xValues = datasets.$1;
    final yValues = datasets.$2;
    if (xValues.length < 2) {
      throw const StatisticsException(
        StatisticsErrorType.insufficientData,
        'Sample covariance requires at least two paired values.',
      );
    }

    final xMean = DescriptiveStatistics.mean(xValues);
    final yMean = DescriptiveStatistics.mean(yValues);
    var total = RationalValue.zero as CalculatorValue;
    for (var index = 0; index < xValues.length; index++) {
      final xDeviation = StatisticsScalarMath.subtract(
        xValues.values[index],
        xMean,
      );
      final yDeviation = StatisticsScalarMath.subtract(
        yValues.values[index],
        yMean,
      );
      total = StatisticsScalarMath.add(
        total,
        StatisticsScalarMath.multiply(xDeviation, yDeviation),
      );
    }
    return StatisticsScalarMath.divide(
      total,
      RationalValue.fromInt(xValues.length - 1),
    );
  }

  static CalculatorValue correlation(DatasetValue xDataset, DatasetValue yDataset) {
    final datasets = _normalizePairedDatasets(xDataset, yDataset);
    final xValues = datasets.$1;
    final yValues = datasets.$2;
    if (xValues.length < 2) {
      throw const StatisticsException(
        StatisticsErrorType.insufficientData,
        'Correlation requires at least two paired values.',
      );
    }

    final xMean = DescriptiveStatistics.mean(xValues);
    final yMean = DescriptiveStatistics.mean(yValues);
    var sxx = RationalValue.zero as CalculatorValue;
    var syy = RationalValue.zero as CalculatorValue;
    var sxy = RationalValue.zero as CalculatorValue;

    for (var index = 0; index < xValues.length; index++) {
      final xDeviation = StatisticsScalarMath.subtract(
        xValues.values[index],
        xMean,
      );
      final yDeviation = StatisticsScalarMath.subtract(
        yValues.values[index],
        yMean,
      );
      sxx = StatisticsScalarMath.add(
        sxx,
        StatisticsScalarMath.multiply(xDeviation, xDeviation),
      );
      syy = StatisticsScalarMath.add(
        syy,
        StatisticsScalarMath.multiply(yDeviation, yDeviation),
      );
      sxy = StatisticsScalarMath.add(
        sxy,
        StatisticsScalarMath.multiply(xDeviation, yDeviation),
      );
    }

    if (StatisticsScalarMath.isZero(sxx) || StatisticsScalarMath.isZero(syy)) {
      throw const StatisticsException(
        StatisticsErrorType.invalidArgument,
        'Correlation requires non-zero variance in both datasets.',
      );
    }

    final denominator = StatisticsScalarMath.sqrt(
      StatisticsScalarMath.multiply(sxx, syy),
    );
    return StatisticsScalarMath.divide(sxy, denominator);
  }

  static RegressionValue linearRegression(
    DatasetValue xDataset,
    DatasetValue yDataset,
  ) {
    final datasets = _normalizePairedDatasets(xDataset, yDataset);
    final xValues = datasets.$1;
    final yValues = datasets.$2;
    if (xValues.length < 2) {
      throw const StatisticsException(
        StatisticsErrorType.insufficientData,
        'Linear regression requires at least two paired values.',
      );
    }

    final xMean = DescriptiveStatistics.mean(xValues);
    final yMean = DescriptiveStatistics.mean(yValues);
    var sxx = RationalValue.zero as CalculatorValue;
    var syy = RationalValue.zero as CalculatorValue;
    var sxy = RationalValue.zero as CalculatorValue;

    for (var index = 0; index < xValues.length; index++) {
      final xDeviation = StatisticsScalarMath.subtract(
        xValues.values[index],
        xMean,
      );
      final yDeviation = StatisticsScalarMath.subtract(
        yValues.values[index],
        yMean,
      );
      sxx = StatisticsScalarMath.add(
        sxx,
        StatisticsScalarMath.multiply(xDeviation, xDeviation),
      );
      syy = StatisticsScalarMath.add(
        syy,
        StatisticsScalarMath.multiply(yDeviation, yDeviation),
      );
      sxy = StatisticsScalarMath.add(
        sxy,
        StatisticsScalarMath.multiply(xDeviation, yDeviation),
      );
    }

    if (StatisticsScalarMath.isZero(sxx)) {
      throw const StatisticsException(
        StatisticsErrorType.invalidArgument,
        'Linear regression requires non-zero variance in x data.',
      );
    }
    if (StatisticsScalarMath.isZero(syy)) {
      throw const StatisticsException(
        StatisticsErrorType.invalidArgument,
        'Linear regression requires non-zero variance in y data.',
      );
    }

    final slope = StatisticsScalarMath.divide(sxy, sxx);
    final intercept = StatisticsScalarMath.subtract(
      yMean,
      StatisticsScalarMath.multiply(slope, xMean),
    );
    final r = StatisticsScalarMath.divide(
      sxy,
      StatisticsScalarMath.sqrt(
        StatisticsScalarMath.multiply(sxx, syy),
      ),
    );
    final rSquared = StatisticsScalarMath.multiply(r, r);

    return RegressionValue(
      slope: slope,
      intercept: intercept,
      r: r,
      rSquared: rSquared,
      sampleSize: xValues.length,
      xMean: xMean,
      yMean: yMean,
    );
  }

  static CalculatorValue predict(RegressionValue regression, CalculatorValue xValue) {
    final scalar = StatisticsScalarMath.requirePlainRealScalar(xValue);
    return StatisticsScalarMath.add(
      StatisticsScalarMath.multiply(regression.slope, scalar),
      regression.intercept,
    );
  }

  static (DatasetValue, DatasetValue) _normalizePairedDatasets(
    DatasetValue xDataset,
    DatasetValue yDataset,
  ) {
    final normalizedX = normalizePlainDataset(xDataset);
    final normalizedY = normalizePlainDataset(yDataset);
    if (normalizedX.length != normalizedY.length) {
      throw const StatisticsException(
        StatisticsErrorType.dimensionMismatch,
        'Paired statistics require datasets of the same length.',
      );
    }
    return (normalizedX, normalizedY);
  }
}
