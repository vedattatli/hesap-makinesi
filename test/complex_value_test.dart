import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/core/calculator/src/result_formatter.dart';

void main() {
  group('ComplexValue', () {
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

    test('formats pure imaginary values', () {
      expect(
        display(
          ComplexValue(
            realPart: RationalValue.zero,
            imaginaryPart: RationalValue.one,
          ),
        ),
        'i',
      );
      expect(
        display(
          ComplexValue(
            realPart: RationalValue.zero,
            imaginaryPart: RationalValue.fromInt(-1),
          ),
        ),
        '-i',
      );
      expect(
        display(
          ComplexValue(
            realPart: RationalValue.zero,
            imaginaryPart: RationalValue.fromInt(2),
          ),
        ),
        '2i',
      );
    });

    test('formats rectangular exact values', () {
      expect(
        display(
          ComplexValue(
            realPart: RationalValue.fromInt(3),
            imaginaryPart: RationalValue.fromInt(4),
          ),
        ),
        '3 + 4i',
      );
    });

    test('conjugate and magnitude stay exact when possible', () {
      final value = ComplexValue(
        realPart: RationalValue.fromInt(3),
        imaginaryPart: RationalValue.fromInt(4),
      );

      expect(display(value.conjugate().simplify()), '3 - 4i');
      expect(display(value.magnitude()), '5');
    });

    test('multiplies exact complex numbers', () {
      final left = ComplexValue(
        realPart: RationalValue.one,
        imaginaryPart: RationalValue.fromInt(2),
      );
      final right = ComplexValue(
        realPart: RationalValue.fromInt(3),
        imaginaryPart: RationalValue.fromInt(4),
      );

      expect(display(left.multiplyValue(right)), '-5 + 10i');
    });

    test('divides exact complex numbers', () {
      final left = ComplexValue(
        realPart: RationalValue.one,
        imaginaryPart: RationalValue.fromInt(2),
      );
      final right = ComplexValue(
        realPart: RationalValue.fromInt(3),
        imaginaryPart: RationalValue.fromInt(4),
      );

      expect(display(left.divideValue(right)), '11/25 + 2i/25');
    });

    test('integer powers simplify correctly', () {
      expect(display(ComplexValue.imaginaryUnit.integerPower(2)), '-1');
      expect(display(ComplexValue.imaginaryUnit.integerPower(3)), '-i');
      expect(display(ComplexValue.imaginaryUnit.integerPower(4)), '1');

      final onePlusI = ComplexValue(
        realPart: RationalValue.one,
        imaginaryPart: RationalValue.one,
      );
      expect(display(onePlusI.integerPower(2)), '2i');
    });
  });
}
