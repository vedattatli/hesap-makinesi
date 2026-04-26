import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/core/calculator/src/result_formatter.dart';

void main() {
  group('VectorValue', () {
    final formatter = ResultFormatter();
    const exactContext = CalculationContext(
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.complex,
      numberFormatStyle: NumberFormatStyle.symbolic,
      precision: 10,
    );

    String display(CalculatorValue value) {
      return formatter.format(value, exactContext).displayResult;
    }

    test('creation keeps length and exact flags', () {
      final vector = VectorValue(
        <CalculatorValue>[RationalValue.one, RationalValue.fromInt(2)],
      );
      final approximate = VectorValue(
        <CalculatorValue>[DoubleValue(1.2), RationalValue.one],
      );

      expect(vector.length, 2);
      expect(vector.isExact, isTrue);
      expect(approximate.isApproximate, isTrue);
    });

    test('elements are immutable', () {
      final vector = VectorValue(
        <CalculatorValue>[RationalValue.one, RationalValue.fromInt(2)],
      );

      expect(
        () => vector.elements[0] = RationalValue.fromInt(9),
        throwsUnsupportedError,
      );
    });

    test('display formats as bracket list', () {
      final vector = VectorValue(
        <CalculatorValue>[
          RationalValue.one,
          RationalValue.fromInt(2),
          RationalValue.fromInt(3),
        ],
      );

      expect(display(vector), '[1, 2, 3]');
    });

    test('adds and subtracts same-length vectors', () {
      final left = VectorValue(
        <CalculatorValue>[
          RationalValue.one,
          RationalValue.fromInt(2),
          RationalValue.fromInt(3),
        ],
      );
      final right = VectorValue(
        <CalculatorValue>[
          RationalValue.fromInt(4),
          RationalValue.fromInt(5),
          RationalValue.fromInt(6),
        ],
      );

      expect(display(LinearAlgebra.addVectors(left, right)), '[5, 7, 9]');
      expect(display(LinearAlgebra.subtractVectors(right, left)), '[3, 3, 3]');
    });

    test('vector dimension mismatch throws', () {
      final left = VectorValue(<CalculatorValue>[RationalValue.one]);
      final right = VectorValue(
        <CalculatorValue>[RationalValue.one, RationalValue.one],
      );

      expect(
        () => LinearAlgebra.addVectors(left, right),
        throwsA(isA<LinearAlgebraException>()),
      );
    });

    test('supports scalar multiply divide and negation', () {
      final vector = VectorValue(
        <CalculatorValue>[
          RationalValue.one,
          RationalValue.fromInt(2),
          RationalValue.fromInt(3),
        ],
      );

      expect(
        display(LinearAlgebra.scaleVector(vector, RationalValue.fromInt(2))),
        '[2, 4, 6]',
      );
      expect(
        display(LinearAlgebra.divideVector(vector, RationalValue.fromInt(2))),
        '[1/2, 1, 3/2]',
      );
      expect(display(LinearAlgebra.negateVector(vector)), '[-1, -2, -3]');
    });

    test('computes dot and cross products', () {
      final left = VectorValue(
        <CalculatorValue>[
          RationalValue.one,
          RationalValue.fromInt(2),
          RationalValue.fromInt(3),
        ],
      );
      final right = VectorValue(
        <CalculatorValue>[
          RationalValue.fromInt(4),
          RationalValue.fromInt(5),
          RationalValue.fromInt(6),
        ],
      );
      final x = VectorValue(
        <CalculatorValue>[
          RationalValue.one,
          RationalValue.zero,
          RationalValue.zero,
        ],
      );
      final y = VectorValue(
        <CalculatorValue>[
          RationalValue.zero,
          RationalValue.one,
          RationalValue.zero,
        ],
      );

      expect(display(LinearAlgebra.dot(left, right)), '32');
      expect(display(LinearAlgebra.cross(x, y)), '[0, 0, 1]');
    });

    test('computes norm and unit vector exactly when possible', () {
      final vector = VectorValue(
        <CalculatorValue>[RationalValue.fromInt(3), RationalValue.fromInt(4)],
      );

      expect(display(LinearAlgebra.norm(vector)), '5');
      expect(display(LinearAlgebra.unit(vector)), '[3/5, 4/5]');
    });

    test('zero vector unit throws', () {
      final zeroVector = VectorValue(
        <CalculatorValue>[RationalValue.zero, RationalValue.zero],
      );

      expect(
        () => LinearAlgebra.unit(zeroVector),
        throwsA(isA<LinearAlgebraException>()),
      );
    });
  });
}
