import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  group('DimensionVector', () {
    test('supports zero dimension and dimensionless detection', () {
      expect(DimensionVector.dimensionless.isDimensionless, isTrue);
      expect(DimensionVector.dimensionless.toDisplayString(), 'dimensionless');
    });

    test('supports base dimensions and arithmetic', () {
      const length = DimensionVector(length: 1);
      const time = DimensionVector(time: 1);
      final velocity = length.subtract(time);
      final acceleration = velocity.subtract(time);

      expect(length.toDisplayString(), 'L');
      expect(time.toDisplayString(), 'T');
      expect(velocity, const DimensionVector(length: 1, time: -1));
      expect(acceleration, const DimensionVector(length: 1, time: -2));
    });

    test('supports exponent arithmetic and equality', () {
      const force = DimensionVector(length: 1, mass: 1, time: -2);
      final energy = force.add(const DimensionVector(length: 1));
      final power = energy.subtract(const DimensionVector(time: 1));

      expect(energy, const DimensionVector(length: 2, mass: 1, time: -2));
      expect(power, const DimensionVector(length: 2, mass: 1, time: -3));
      expect(force.multiplyByExponent(2), const DimensionVector(length: 2, mass: 2, time: -4));
      expect(force.hashCode, const DimensionVector(length: 1, mass: 1, time: -2).hashCode);
    });
  });
}
