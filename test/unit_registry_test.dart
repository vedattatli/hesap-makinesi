import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  group('UnitRegistry', () {
    final registry = UnitRegistry.instance;

    test('looks up base units and aliases', () {
      expect(registry.lookup('m')?.displaySymbol, 'm');
      expect(registry.lookup('cm')?.displaySymbol, 'cm');
      expect(registry.lookup('hr')?.displaySymbol, 'h');
      expect(registry.lookup('L')?.displaySymbol, 'L');
    });

    test('exposes exact scale factors for common units', () {
      expect(
        registry.lookup('cm')?.factorToBase.toFractionString(),
        '1/100',
      );
      expect(registry.lookup('km')?.factorToBase.toFractionString(), '1000');
      expect(registry.lookup('h')?.factorToBase.toFractionString(), '3600');
    });

    test('defines derived SI units with expected dimensions', () {
      expect(
        registry.lookup('N')?.dimension,
        const DimensionVector(length: 1, mass: 1, time: -2),
      );
      expect(
        registry.lookup('J')?.dimension,
        const DimensionVector(length: 2, mass: 1, time: -2),
      );
      expect(
        registry.lookup('W')?.dimension,
        const DimensionVector(length: 2, mass: 1, time: -3),
      );
      expect(
        registry.lookup('Pa')?.dimension,
        const DimensionVector(length: -1, mass: 1, time: -2),
      );
    });

    test('returns null for unknown units', () {
      expect(registry.lookup('parsecish'), isNull);
    });
  });
}
