import 'dart:math' as math;

import 'calculator_value.dart';
import 'scalar_value_math.dart';

/// Immutable vector value with scalar calculator entries.
class VectorValue extends CalculatorValue {
  factory VectorValue(Iterable<CalculatorValue> elements) {
    final normalized = elements
        .map(ScalarValueMath.collapse)
        .toList(growable: false);
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        elements,
        'elements',
        'Vector must contain at least one element.',
      );
    }
    return VectorValue._(List<CalculatorValue>.unmodifiable(normalized));
  }

  const VectorValue._(this.elements);

  final List<CalculatorValue> elements;

  int get length => elements.length;

  @override
  CalculatorValueKind get kind => CalculatorValueKind.vector;

  @override
  bool get isExact => elements.every((element) => element.isExact);

  VectorValue simplify() => VectorValue(elements);

  @override
  double toDouble() {
    var sumSquares = 0.0;
    for (final element in elements) {
      final value = element.toDouble();
      sumSquares += value * value;
    }
    return math.sqrt(sumSquares);
  }
}
