import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  group('UnitExpression', () {
    final registry = UnitRegistry.instance;

    UnitExpression unit(String symbol) =>
        UnitExpression.fromDefinition(registry.lookup(symbol)!);

    test('formats simple and compound unit expressions', () {
      expect(unit('m').toDisplayString(), 'm');
      expect(unit('km').divide(unit('h')).toDisplayString(), 'km/h');
      expect(unit('m').divide(unit('s').integerPower(2)).toDisplayString(), 'm/s²');
      expect(
        unit('kg').multiply(unit('m')).divide(unit('s').integerPower(2)).toDisplayString(),
        'kg*m/s²',
      );
    });

    test('tracks factor to base and dimensions', () {
      final velocity = unit('km').divide(unit('h'));

      expect(velocity.factorToBase.toFractionString(), '5/18');
      expect(velocity.dimension, const DimensionVector(length: 1, time: -1));
    });

    test('supports derived unit recognition through canonicalization', () {
      final newtonMeter = unit('N').multiply(unit('m'));
      final wattFromDivision = unit('J').divide(unit('s'));
      final pascalFromDivision = unit('N').divide(unit('m').integerPower(2));

      expect(UnitRegistry.instance.canonicalize(newtonMeter).toDisplayString(), 'J');
      expect(UnitRegistry.instance.canonicalize(wattFromDivision).toDisplayString(), 'W');
      expect(UnitRegistry.instance.canonicalize(pascalFromDivision).toDisplayString(), 'Pa');
    });

    test('supports unit powers and square roots when dimensions stay integral', () {
      final area = unit('m').integerPower(2);
      final root = area.squareRoot();

      expect(area.toDisplayString(), 'm²');
      expect(root, isNotNull);
      expect(root!.toDisplayString(), 'm');
    });
  });
}
