import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  group('RationalValue', () {
    test('normalizes by gcd', () {
      final value = RationalValue(BigInt.from(2), BigInt.from(4));

      expect(value.toFractionString(), '1/2');
    });

    test('keeps denominator positive', () {
      final value = RationalValue(BigInt.one, BigInt.from(-2));

      expect(value.toFractionString(), '-1/2');
    });

    test('normalizes negative numerator and denominator', () {
      final value = RationalValue(BigInt.from(-1), BigInt.from(-2));

      expect(value.toFractionString(), '1/2');
    });

    test('normalizes zero to 0', () {
      final value = RationalValue(BigInt.zero, BigInt.from(5));

      expect(value.toFractionString(), '0');
    });

    test('adds rational values', () {
      final result = RationalValue(
        BigInt.one,
        BigInt.from(2),
      ).add(RationalValue(BigInt.one, BigInt.from(3)));

      expect(result.toFractionString(), '5/6');
    });

    test('subtracts rational values', () {
      final result = RationalValue(
        BigInt.one,
        BigInt.from(2),
      ).subtract(RationalValue(BigInt.one, BigInt.from(3)));

      expect(result.toFractionString(), '1/6');
    });

    test('multiplies rational values', () {
      final result = RationalValue(
        BigInt.from(2),
        BigInt.from(3),
      ).multiply(RationalValue(BigInt.from(3), BigInt.from(4)));

      expect(result.toFractionString(), '1/2');
    });

    test('divides rational values', () {
      final result = RationalValue(
        BigInt.one,
        BigInt.from(2),
      ).divide(RationalValue(BigInt.from(3), BigInt.from(4)));

      expect(result.toFractionString(), '2/3');
    });

    test('divide by zero throws', () {
      expect(
        () => RationalValue(
          BigInt.one,
          BigInt.from(2),
        ).divide(RationalValue.zero),
        throwsArgumentError,
      );
    });

    test('computes reciprocal', () {
      final result = RationalValue(BigInt.from(2), BigInt.from(3)).reciprocal();

      expect(result.toFractionString(), '3/2');
    });

    test('computes positive integer power', () {
      final result = RationalValue(
        BigInt.from(2),
        BigInt.from(3),
      ).powInteger(3);

      expect(result.toFractionString(), '8/27');
    });

    test('computes zero power', () {
      final result = RationalValue(
        BigInt.from(5),
        BigInt.from(7),
      ).powInteger(0);

      expect(result.toFractionString(), '1');
    });

    test('computes negative integer power', () {
      final result = RationalValue(BigInt.from(2), BigInt.one).powInteger(-3);

      expect(result.toFractionString(), '1/8');
    });

    test('compares rational values', () {
      final left = RationalValue(BigInt.from(3), BigInt.from(2));
      final right = RationalValue(BigInt.from(4), BigInt.from(3));

      expect(left.compareTo(right), greaterThan(0));
    });

    test('converts to double', () {
      final value = RationalValue(BigInt.one, BigInt.from(2));

      expect(value.toDouble(), closeTo(0.5, 1e-10));
    });

    test('formats to decimal string with precision', () {
      final value = RationalValue(BigInt.one, BigInt.from(3));

      expect(value.toDecimalString(4), '0.3333');
    });

    test('parses 0.1 as 1/10', () {
      expect(RationalValue.parseLiteral('0.1').toFractionString(), '1/10');
    });

    test('parses 0.2 as 1/5', () {
      expect(RationalValue.parseLiteral('0.2').toFractionString(), '1/5');
    });

    test('parses 1.25 as 5/4', () {
      expect(RationalValue.parseLiteral('1.25').toFractionString(), '5/4');
    });

    test('parses .5 as 1/2', () {
      expect(RationalValue.parseLiteral('.5').toFractionString(), '1/2');
    });

    test('parses 1e3 as 1000', () {
      expect(RationalValue.parseLiteral('1e3').toFractionString(), '1000');
    });

    test('parses 2.5e-4 as 1/4000', () {
      expect(RationalValue.parseLiteral('2.5e-4').toFractionString(), '1/4000');
    });

    test('parses 1.2e2 as 120', () {
      expect(RationalValue.parseLiteral('1.2e2').toFractionString(), '120');
    });
  });
}
