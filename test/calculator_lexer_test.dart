import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  group('CalculatorLexer', () {
    const lexer = CalculatorLexer();

    List<String> lexemes(String expression) {
      return lexer
          .tokenize(expression)
          .where((token) => token.type != CalculationTokenType.eof)
          .map((token) => token.lexeme)
          .toList();
    }

    test('tokenizes simple addition', () {
      expect(lexemes('1 + 2'), ['1', '+', '2']);
    });

    test('tokenizes decimal numbers', () {
      expect(lexemes('1.5'), ['1.5']);
    });

    test('tokenizes scientific notation integers', () {
      expect(lexemes('1e3'), ['1e3']);
    });

    test('tokenizes scientific notation decimals', () {
      expect(lexemes('2.5e-4'), ['2.5e-4']);
    });

    test('tokenizes function calls with constants', () {
      expect(lexemes('sin(pi/2)'), ['sin', '(', 'pi', '/', '2', ')']);
    });

    test('tokenizes unicode sqrt symbol', () {
      expect(lexemes('\u221A4'), ['sqrt', '4']);
    });

    test('inserts implicit multiplication tokens', () {
      expect(lexemes('2\u03C0'), ['2', '*', 'pi']);
    });

    test('tokenizes vector bracket literals', () {
      expect(lexemes('[1,2,3]'), ['[', '1', ',', '2', ',', '3', ']']);
    });

    test('tokenizes matrix bracket literals', () {
      expect(
        lexemes('[[1,2],[3,4]]'),
        ['[', '[', '1', ',', '2', ']', ',', '[', '3', ',', '4', ']', ']'],
      );
    });

    test('tokenizes vec and mat constructors', () {
      expect(
        lexemes('vec(1,2,3)'),
        ['vec', '(', '1', ',', '2', ',', '3', ')'],
      );
      expect(
        lexemes('mat(2,2,1,2,3,4)'),
        ['mat', '(', '2', ',', '2', ',', '1', ',', '2', ',', '3', ',', '4', ')'],
      );
    });

    test('tokenizes unit attachment syntaxes', () {
      expect(lexemes('3 m'), ['3', '*', 'm']);
      expect(lexemes('3m'), ['3', '*', 'm']);
      expect(lexemes('3*m'), ['3', '*', 'm']);
      expect(lexemes('20 cm'), ['20', '*', 'cm']);
    });

    test('tokenizes compound unit expressions', () {
      expect(lexemes('5 km / 2 h'), ['5', '*', 'km', '/', '2', '*', 'h']);
      expect(lexemes('m/s^2'), ['m', '/', 's', '^', '2']);
      expect(lexemes('kg*m/s^2'), ['kg', '*', 'm', '/', 's', '^', '2']);
      expect(lexemes('to(100 cm, m)'), ['to', '(', '100', '*', 'cm', ',', 'm', ')']);
      expect(
        lexemes('to(25 degC, degF)'),
        ['to', '(', '25', '*', 'degc', ',', 'degf', ')'],
      );
    });
  });
}
