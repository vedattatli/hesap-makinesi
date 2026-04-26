import '../values/rational_value.dart';
import 'statistics_errors.dart';

class QuantileInterpolation {
  const QuantileInterpolation._({
    required this.lowerIndex,
    required this.upperIndex,
    this.exactWeight,
    this.approximateWeight,
  });

  final int lowerIndex;
  final int upperIndex;
  final RationalValue? exactWeight;
  final double? approximateWeight;

  bool get isInterpolated => lowerIndex != upperIndex;

  double get weight => exactWeight?.toDouble() ?? approximateWeight ?? 0.0;

  factory QuantileInterpolation.exact(int length, RationalValue q) {
    final clamped = _assertUnitIntervalExact(q);
    final h = RationalValue.one.add(
      clamped.multiply(RationalValue.fromInt(length - 1)),
    );
    final lower = h.floorToBigInt().toInt();
    final upper = h.ceilToBigInt().toInt();
    final lowerWeight = h.subtract(RationalValue.fromInt(lower));
    return QuantileInterpolation._(
      lowerIndex: lower - 1,
      upperIndex: upper - 1,
      exactWeight: lowerWeight,
    );
  }

  factory QuantileInterpolation.approximate(int length, double q) {
    _assertUnitIntervalApprox(q);
    final h = 1 + (length - 1) * q;
    final lower = h.floor();
    final upper = h.ceil();
    return QuantileInterpolation._(
      lowerIndex: lower - 1,
      upperIndex: upper - 1,
      approximateWeight: h - lower,
    );
  }

  static RationalValue _assertUnitIntervalExact(RationalValue q) {
    if (q.compareTo(RationalValue.zero) < 0 || q.compareTo(RationalValue.one) > 0) {
      throw const StatisticsException(
        StatisticsErrorType.invalidArgument,
        'Quantile must be between 0 and 1.',
      );
    }
    return q;
  }

  static void _assertUnitIntervalApprox(double q) {
    if (q < 0 || q > 1) {
      throw const StatisticsException(
        StatisticsErrorType.invalidArgument,
        'Quantile must be between 0 and 1.',
      );
    }
  }
}
