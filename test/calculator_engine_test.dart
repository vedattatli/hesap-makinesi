import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/calculator_engine.dart';

void main() {
  group('CalculatorEngine', () {
    final engine = CalculatorEngine();

    test('respects operator precedence', () {
      expect(engine.evaluate('1+2*3'), closeTo(7, 0.000001));
    });

    test('supports nested parentheses', () {
      expect(engine.evaluate('(7+3)/2'), closeTo(5, 0.000001));
    });

    test('supports scientific functions', () {
      expect(engine.evaluate('sqrt(81)+log(100)'), closeTo(11, 0.000001));
    });

    test('evaluates trigonometry in degree mode', () {
      expect(
        engine.evaluate('sin(30)', angleMode: AngleMode.degree),
        closeTo(0.5, 0.000001),
      );
    });

    test('handles right-associative powers', () {
      expect(engine.evaluate('2^3^2'), closeTo(512, 0.000001));
    });

    test('supports unary minus', () {
      expect(engine.evaluate('-(5+2)'), closeTo(-7, 0.000001));
    });
  });
}
