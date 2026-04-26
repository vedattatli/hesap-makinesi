import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  group('DatasetValue', () {
    test('creation rejects empty datasets', () {
      expect(() => DatasetValue(const <CalculatorValue>[]), throwsArgumentError);
    });

    test('tracks exact and approximate flags from values', () {
      final exact = DatasetValue(<CalculatorValue>[
        RationalValue.one,
        RationalValue.fromInt(2),
      ]);
      final approximate = DatasetValue(<CalculatorValue>[
        RationalValue.one,
        const DoubleValue(2.5),
      ]);

      expect(exact.kind, CalculatorValueKind.dataset);
      expect(exact.isExact, isTrue);
      expect(exact.isApproximate, isFalse);
      expect(approximate.isExact, isFalse);
      expect(approximate.isApproximate, isTrue);
    });

    test('sortedValues does not mutate original ordering', () {
      final dataset = DatasetValue(<CalculatorValue>[
        RationalValue.fromInt(3),
        RationalValue.one,
        RationalValue.fromInt(2),
      ]);

      final sorted = dataset.sortedValues(ScalarValueMath.compare);

      expect(
        dataset.values.map((value) => value.toDouble()).toList(),
        <double>[3, 1, 2],
      );
      expect(
        sorted.map((value) => value.toDouble()).toList(),
        <double>[1, 2, 3],
      );
    });

    test('toDouble falls back to dataset average when meaningful', () {
      final dataset = DatasetValue(<CalculatorValue>[
        RationalValue.one,
        RationalValue.fromInt(2),
        RationalValue.fromInt(3),
        RationalValue.fromInt(4),
      ]);

      expect(dataset.toDouble(), closeTo(2.5, 1e-10));
    });
  });
}
