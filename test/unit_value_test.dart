import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  group('UnitValue and UnitMath', () {
    final registry = UnitRegistry.instance;

    UnitExpression unit(String symbol) =>
        UnitExpression.fromDefinition(registry.lookup(symbol)!);

    test('creates quantities from display magnitudes', () {
      final meters = UnitValue.fromDisplayMagnitude(
        displayMagnitude: RationalValue.fromInt(3),
        displayUnit: unit('m'),
      );

      expect((meters.displayMagnitude as RationalValue).toFractionString(), '3');
      expect(meters.displayUnit.toDisplayString(), 'm');
      expect(meters.dimension, const DimensionVector(length: 1));
      expect(meters.isExact, isTrue);
    });

    test('converts between compatible units', () {
      final centimeters = UnitValue.fromDisplayMagnitude(
        displayMagnitude: RationalValue.fromInt(100),
        displayUnit: unit('cm'),
      );
      final converted = UnitMath.convert(centimeters, unit('m')) as UnitValue;

      expect(
        (converted.displayMagnitude as RationalValue).toFractionString(),
        '1',
      );
      expect(converted.displayUnit.toDisplayString(), 'm');
    });

    test('adds compatible dimensions and rejects incompatible ones', () {
      final meters = UnitValue.fromDisplayMagnitude(
        displayMagnitude: RationalValue.fromInt(3),
        displayUnit: unit('m'),
      );
      final centimeters = UnitValue.fromDisplayMagnitude(
        displayMagnitude: RationalValue.fromInt(20),
        displayUnit: unit('cm'),
      );
      final seconds = UnitValue.fromDisplayMagnitude(
        displayMagnitude: RationalValue.fromInt(2),
        displayUnit: unit('s'),
      );

      final sum = UnitMath.add(meters, centimeters) as UnitValue;

      expect((sum.displayMagnitude as RationalValue).toFractionString(), '16/5');
      expect(sum.displayUnit.toDisplayString(), 'm');
      expect(() => UnitMath.add(meters, seconds), throwsArgumentError);
    });

    test('multiplies and divides units with dimension cancellation', () {
      final meters = UnitValue.fromDisplayMagnitude(
        displayMagnitude: RationalValue.fromInt(10),
        displayUnit: unit('m'),
      );
      final seconds = UnitValue.fromDisplayMagnitude(
        displayMagnitude: RationalValue.fromInt(2),
        displayUnit: unit('s'),
      );

      final velocity = UnitMath.divide(meters, seconds) as UnitValue;
      final area = UnitMath.multiply(
        UnitValue.fromDisplayMagnitude(
          displayMagnitude: RationalValue.fromInt(2),
          displayUnit: unit('m'),
        ),
        UnitValue.fromDisplayMagnitude(
          displayMagnitude: RationalValue.fromInt(3),
          displayUnit: unit('m'),
        ),
      ) as UnitValue;
      final dimensionless = UnitMath.divide(meters, meters);

      expect(velocity.displayUnit.toDisplayString(), 'm/s');
      expect((velocity.displayMagnitude as RationalValue).toFractionString(), '5');
      expect(area.displayUnit.toDisplayString(), 'm²');
      expect((area.displayMagnitude as RationalValue).toFractionString(), '6');
      expect(dimensionless, isA<RationalValue>());
      expect((dimensionless as RationalValue).toFractionString(), '1');
    });

    test('keeps symbolic magnitudes exact', () {
      final value = UnitValue.fromDisplayMagnitude(
        displayMagnitude: SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
        displayUnit: unit('m'),
      );

      expect(value.isExact, isTrue);
      expect(
        (value.displayMagnitude as SymbolicValue).toSymbolicString(),
        '\u221A2',
      );
    });

    test('enforces affine temperature arithmetic rules', () {
      final celsius = UnitValue.fromDisplayMagnitude(
        displayMagnitude: RationalValue.fromInt(25),
        displayUnit: unit('degC'),
      );
      final delta = UnitValue.fromDisplayMagnitude(
        displayMagnitude: RationalValue.fromInt(10),
        displayUnit: unit('deltaC'),
      );

      final adjusted = UnitMath.add(celsius, delta) as UnitValue;

      expect(
        (adjusted.displayMagnitude as RationalValue).toFractionString(),
        '35',
      );
      expect(adjusted.displayUnit.toDisplayString(), 'degC');
      expect(() => UnitMath.add(celsius, celsius), throwsUnsupportedError);
    });
  });
}
