import 'calculator_value.dart';
import 'scalar_value_math.dart';

/// Immutable statistical dataset wrapper used by phase 8 functions.
class DatasetValue extends CalculatorValue {
  factory DatasetValue(Iterable<CalculatorValue> values) {
    final normalized = values
        .map(ScalarValueMath.collapse)
        .toList(growable: false);
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        values,
        'values',
        'Dataset must contain at least one value.',
      );
    }
    return DatasetValue._(List<CalculatorValue>.unmodifiable(normalized));
  }

  const DatasetValue._(this.values);

  final List<CalculatorValue> values;

  int get length => values.length;

  List<CalculatorValue> sortedValues(
    int Function(CalculatorValue left, CalculatorValue right) compare,
  ) {
    final sorted = List<CalculatorValue>.from(values, growable: false);
    sorted.sort(compare);
    return List<CalculatorValue>.unmodifiable(sorted);
  }

  @override
  CalculatorValueKind get kind => CalculatorValueKind.dataset;

  @override
  bool get isExact => values.every((value) => value.isExact);

  @override
  double toDouble() {
    var total = 0.0;
    var count = 0;
    for (final value in values) {
      final numeric = value.toDouble();
      if (!numeric.isFinite) {
        continue;
      }
      total += numeric;
      count++;
    }
    if (count == 0) {
      return length.toDouble();
    }
    return total / count;
  }
}
