import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

RationalValue _r(int numerator, [int denominator = 1]) {
  return RationalValue(BigInt.from(numerator), BigInt.from(denominator));
}

void main() {
  group('SymbolicValue', () {
    test('formats √2 display', () {
      final value = SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2)));

      expect(value.toSymbolicString(), '√2');
    });

    test('formats 2√2 display', () {
      final value = SymbolicValue(
        [
          SymbolicTerm(
            coefficient: _r(2),
            factors: [RadicalFactor(BigInt.from(2))],
          ),
        ],
      );

      expect(value.toSymbolicString(), '2√2');
    });

    test('formats √2/2 display', () {
      final value = SymbolicValue(
        [
          SymbolicTerm(
            coefficient: _r(1, 2),
            factors: [RadicalFactor(BigInt.from(2))],
          ),
        ],
      );

      expect(value.toSymbolicString(), '√2/2');
    });

    test('formats 3√2/2 display', () {
      final value = SymbolicValue(
        [
          SymbolicTerm(
            coefficient: _r(3, 2),
            factors: [RadicalFactor(BigInt.from(2))],
          ),
        ],
      );

      expect(value.toSymbolicString(), '3√2/2');
    });

    test('formats π display variants', () {
      final pi = SymbolicSimplifier.fromPi() as SymbolicValue;
      final halfPi = SymbolicValue(
        [
          SymbolicTerm(
            coefficient: _r(1, 2),
            factors: [symbolicPiFactor],
          ),
        ],
      );
      final twoPi = SymbolicValue(
        [
          SymbolicTerm(
            coefficient: _r(2),
            factors: [symbolicPiFactor],
          ),
        ],
      );

      expect(pi.toSymbolicString(), 'π');
      expect(halfPi.toSymbolicString(), 'π/2');
      expect(twoPi.toSymbolicString(), '2π');
    });

    test('combines like radical terms', () {
      final result = SymbolicSimplifier.add(
        SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
        SymbolicValue(
          [
            SymbolicTerm(
              coefficient: _r(2),
              factors: [RadicalFactor(BigInt.from(2))],
            ),
          ],
        ),
      ) as SymbolicValue;

      expect(result.toSymbolicString(), '3√2');
    });

    test('combines like pi and e terms', () {
      final piResult = SymbolicSimplifier.add(
        SymbolicSimplifier.fromPi(),
        SymbolicSimplifier.fromPi(),
      ) as SymbolicValue;
      final eResult = SymbolicSimplifier.add(
        SymbolicSimplifier.fromE(),
        SymbolicSimplifier.fromE(),
      ) as SymbolicValue;

      expect(piResult.toSymbolicString(), '2π');
      expect(eResult.toSymbolicString(), '2e');
    });

    test('removes zero coefficient terms and collapses to rational zero', () {
      final result = SymbolicSimplifier.subtract(
        SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
        SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
      );

      expect(result, isA<RationalValue>());
      expect((result as RationalValue).toFractionString(), '0');
    });

    test('keeps canonical ordering for rational plus symbolic sum', () {
      final result = SymbolicSimplifier.add(
        _r(1),
        SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
      ) as SymbolicValue;

      expect(result.toSymbolicString(), '1 + √2');
    });

    test('converts symbolic value to approximate double', () {
      final value = SymbolicValue(
        [
          SymbolicTerm(
            coefficient: _r(3, 2),
            factors: [RadicalFactor(BigInt.from(2))],
          ),
        ],
      );

      expect(value.toDouble(), closeTo(3 * math.sqrt(2) / 2, 1e-10));
    });
  });
}
