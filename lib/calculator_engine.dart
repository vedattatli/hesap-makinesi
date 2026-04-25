import 'dart:math' as math;

const _multiplySymbol = '\u00D7';
const _divideSymbol = '\u00F7';
const _piSymbol = '\u03C0';

enum AngleMode { degree, radian }

class CalculatorEngine {
  double evaluate(String expression, {AngleMode angleMode = AngleMode.degree}) {
    final trimmedExpression = expression.trim();
    if (trimmedExpression.isEmpty) {
      throw const FormatException('Expression cannot be empty.');
    }

    final tokens = _tokenize(trimmedExpression);
    final rpn = _toReversePolishNotation(tokens);
    final result = _evaluateRpn(rpn, angleMode);

    if (!result.isFinite) {
      throw const FormatException('Result is not finite.');
    }

    return result == -0.0 ? 0.0 : result;
  }

  List<_Token> _tokenize(String expression) {
    final tokens = <_Token>[];
    var index = 0;

    while (index < expression.length) {
      final character = expression[index];

      if (character.trim().isEmpty) {
        index++;
        continue;
      }

      if (_isDigit(character) || character == '.') {
        final start = index;
        var hasDecimalPoint = character == '.';
        index++;

        while (index < expression.length) {
          final next = expression[index];
          if (_isDigit(next)) {
            index++;
            continue;
          }
          if (next == '.') {
            if (hasDecimalPoint) {
              throw const FormatException('Malformed decimal number.');
            }
            hasDecimalPoint = true;
            index++;
            continue;
          }
          break;
        }

        final value = expression.substring(start, index);
        if (value == '.') {
          throw const FormatException('Malformed decimal number.');
        }

        tokens.add(_Token.number(value));
        continue;
      }

      if (_isLetter(character) || character == _piSymbol) {
        if (character == _piSymbol) {
          tokens.add(_Token.constant('pi'));
          index++;
          continue;
        }

        final start = index;
        index++;
        while (index < expression.length && _isLetter(expression[index])) {
          index++;
        }

        final value = expression.substring(start, index).toLowerCase();
        if (_constants.contains(value)) {
          tokens.add(_Token.constant(value));
          continue;
        }

        if (_functions.contains(value)) {
          tokens.add(_Token.function(value));
          continue;
        }

        throw FormatException('Unknown symbol: $value');
      }

      if (character == '(') {
        tokens.add(_Token.leftParenthesis());
        index++;
        continue;
      }

      if (character == ')') {
        tokens.add(_Token.rightParenthesis());
        index++;
        continue;
      }

      final normalizedOperator = switch (character) {
        _multiplySymbol => '*',
        _divideSymbol => '/',
        _ => character,
      };

      if (_operators.contains(normalizedOperator)) {
        final previous = tokens.isEmpty ? null : tokens.last;
        final isUnaryMinus = normalizedOperator == '-' &&
            (previous == null ||
                previous.type == _TokenType.operator ||
                previous.type == _TokenType.leftParenthesis ||
                previous.type == _TokenType.function);

        tokens.add(
          isUnaryMinus
              ? _Token.function('neg')
              : _Token.operator(normalizedOperator),
        );
        index++;
        continue;
      }

      throw FormatException('Unexpected character: $character');
    }

    return tokens;
  }

  List<_Token> _toReversePolishNotation(List<_Token> tokens) {
    final output = <_Token>[];
    final stack = <_Token>[];

    for (final token in tokens) {
      switch (token.type) {
        case _TokenType.number:
        case _TokenType.constant:
          output.add(token);
        case _TokenType.function:
          stack.add(token);
        case _TokenType.operator:
          while (stack.isNotEmpty) {
            final top = stack.last;

            final shouldPopFunction = top.type == _TokenType.function;
            final shouldPopOperator = top.type == _TokenType.operator &&
                (_precedence(top.value) > _precedence(token.value) ||
                    (_precedence(top.value) == _precedence(token.value) &&
                        !_isRightAssociative(token.value)));

            if (!shouldPopFunction && !shouldPopOperator) {
              break;
            }

            output.add(stack.removeLast());
          }

          stack.add(token);
        case _TokenType.leftParenthesis:
          stack.add(token);
        case _TokenType.rightParenthesis:
          var foundOpeningParenthesis = false;

          while (stack.isNotEmpty) {
            final top = stack.removeLast();
            if (top.type == _TokenType.leftParenthesis) {
              foundOpeningParenthesis = true;
              break;
            }
            output.add(top);
          }

          if (!foundOpeningParenthesis) {
            throw const FormatException('Mismatched parentheses.');
          }

          if (stack.isNotEmpty && stack.last.type == _TokenType.function) {
            output.add(stack.removeLast());
          }
      }
    }

    while (stack.isNotEmpty) {
      final token = stack.removeLast();
      if (token.type == _TokenType.leftParenthesis ||
          token.type == _TokenType.rightParenthesis) {
        throw const FormatException('Mismatched parentheses.');
      }
      output.add(token);
    }

    return output;
  }

  double _evaluateRpn(List<_Token> tokens, AngleMode angleMode) {
    final stack = <double>[];

    for (final token in tokens) {
      switch (token.type) {
        case _TokenType.number:
          stack.add(double.parse(token.value));
        case _TokenType.constant:
          stack.add(_constantValue(token.value));
        case _TokenType.function:
          if (stack.isEmpty) {
            throw const FormatException('Function is missing an argument.');
          }
          final value = stack.removeLast();
          stack.add(_applyFunction(token.value, value, angleMode));
        case _TokenType.operator:
          if (stack.length < 2) {
            throw const FormatException('Operator is missing an argument.');
          }
          final right = stack.removeLast();
          final left = stack.removeLast();
          stack.add(_applyOperator(token.value, left, right));
        case _TokenType.leftParenthesis:
        case _TokenType.rightParenthesis:
          throw const FormatException('Unexpected parser state.');
      }
    }

    if (stack.length != 1) {
      throw const FormatException('Invalid expression.');
    }

    return stack.single;
  }

  double _applyFunction(String function, double value, AngleMode angleMode) {
    final trigValue = angleMode == AngleMode.degree
        ? value * math.pi / 180
        : value;

    return switch (function) {
      'neg' => -value,
      'sin' => math.sin(trigValue),
      'cos' => math.cos(trigValue),
      'tan' => math.tan(trigValue),
      'sqrt' => value < 0
          ? throw const FormatException('Cannot take sqrt of a negative value.')
          : math.sqrt(value),
      'log' => value <= 0
          ? throw const FormatException('Logarithm requires a positive value.')
          : math.log(value) / math.ln10,
      'ln' => value <= 0
          ? throw const FormatException('Natural log requires a positive value.')
          : math.log(value),
      _ => throw FormatException('Unknown function: $function'),
    };
  }

  double _applyOperator(String operator, double left, double right) {
    return switch (operator) {
      '+' => left + right,
      '-' => left - right,
      '*' => left * right,
      '/' => right == 0
          ? throw const FormatException('Division by zero is undefined.')
          : left / right,
      '^' => math.pow(left, right).toDouble(),
      _ => throw FormatException('Unknown operator: $operator'),
    };
  }

  double _constantValue(String constant) {
    return switch (constant) {
      'pi' => math.pi,
      'e' => math.e,
      _ => throw FormatException('Unknown constant: $constant'),
    };
  }

  int _precedence(String operator) {
    return switch (operator) {
      '+' || '-' => 1,
      '*' || '/' => 2,
      '^' => 3,
      _ => throw FormatException('Unknown operator: $operator'),
    };
  }

  bool _isRightAssociative(String operator) => operator == '^';

  bool _isDigit(String value) => '0123456789'.contains(value);

  bool _isLetter(String value) {
    final codeUnit = value.codeUnitAt(0);
    final isUppercase = codeUnit >= 65 && codeUnit <= 90;
    final isLowercase = codeUnit >= 97 && codeUnit <= 122;
    return isUppercase || isLowercase;
  }
}

const Set<String> _functions = {
  'sin',
  'cos',
  'tan',
  'sqrt',
  'log',
  'ln',
};

const Set<String> _constants = {'pi', 'e'};

const Set<String> _operators = {'+', '-', '*', '/', '^'};

class _Token {
  const _Token(this.type, this.value);

  const _Token.number(this.value) : type = _TokenType.number;

  const _Token.constant(this.value) : type = _TokenType.constant;

  const _Token.function(this.value) : type = _TokenType.function;

  const _Token.operator(this.value) : type = _TokenType.operator;

  const _Token.leftParenthesis()
      : type = _TokenType.leftParenthesis,
        value = '(';

  const _Token.rightParenthesis()
      : type = _TokenType.rightParenthesis,
        value = ')';

  final _TokenType type;
  final String value;
}

enum _TokenType {
  number,
  constant,
  function,
  operator,
  leftParenthesis,
  rightParenthesis,
}
