import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/core/calculator/src/calculator_exception.dart';
import 'package:hesap_makinesi/core/calculator/src/expression_printer.dart';

void main() {
  group('Equation parser', () {
    const lexer = CalculatorLexer();
    const parser = ExpressionParser();
    final printer = ExpressionPrinter();

    test('parses equation syntax when allowEquation is enabled', () {
      final tokens = lexer.tokenize('x^2 - 4 = 0');
      final ast = parser.parse(tokens, allowEquation: true);

      expect(ast, isA<EquationNode>());
      expect(printer.print(ast), 'x ^ 2 - 4 = 0');
    });

    test('normal parser still rejects equation syntax by default', () {
      final tokens = lexer.tokenize('x^2 = 4');

      expect(
        () => parser.parse(tokens),
        throwsA(
          isA<CalculatorException>().having(
            (CalculatorException error) => error.error.type,
            'type',
            CalculationErrorType.unexpectedToken,
          ),
        ),
      );
    });

    test('multiple equals signs are rejected', () {
      final tokens = lexer.tokenize('a = b = c');

      expect(
        () => parser.parse(tokens, allowEquation: true),
        throwsA(
          isA<CalculatorException>().having(
            (CalculatorException error) => error.error.type,
            'type',
            CalculationErrorType.syntaxError,
          ),
        ),
      );
    });

    test('eq function builds an equation value lazily', () {
      const engine = CalculatorEngine();
      final outcome = engine.evaluate('eq(x^2, 4)');

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.valueKind, CalculatorValueKind.equation);
      expect(outcome.result!.displayResult, 'x ^ 2 = 4');
      expect(outcome.result!.equationDisplayResult, 'x ^ 2 = 4');
    });
  });
}
