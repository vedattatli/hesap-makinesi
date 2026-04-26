import 'calculation_error.dart';
import 'calculation_token.dart';
import 'units/unit_registry.dart';
import 'src/calculator_exception.dart';

/// Tokenizes calculator expressions without depending on Flutter.
class CalculatorLexer {
  /// Creates a stateless lexer instance.
  const CalculatorLexer();

  /// Converts a raw expression into normalized calculator tokens.
  List<CalculationToken> tokenize(
    String expression, {
    int maxTokenCount = 512,
  }) {
    final rawTokens = <CalculationToken>[];
    var index = 0;

    while (index < expression.length) {
      final character = expression[index];

      if (_isWhitespace(character)) {
        index++;
        continue;
      }

      if (_isNumberStart(expression, index)) {
        final token = _readNumber(expression, index);
        rawTokens.add(token);
        index = token.position + token.lexeme.length;
        continue;
      }

      if (character == '\u03C0') {
        rawTokens.add(
          CalculationToken(
            type: CalculationTokenType.identifier,
            lexeme: 'pi',
            position: index,
          ),
        );
        index++;
        continue;
      }

      if (character == '\u221A') {
        rawTokens.add(
          CalculationToken(
            type: CalculationTokenType.unaryFunction,
            lexeme: 'sqrt',
            position: index,
          ),
        );
        index++;
        continue;
      }

      if (_isIdentifierStart(character)) {
        final token = _readIdentifier(expression, index);
        rawTokens.add(token);
        index = token.position + token.lexeme.length;
        continue;
      }

      switch (character) {
        case '(':
          rawTokens.add(
            CalculationToken(
              type: CalculationTokenType.leftParenthesis,
              lexeme: '(',
              position: index,
            ),
          );
          index++;
          continue;
        case ')':
          rawTokens.add(
            CalculationToken(
              type: CalculationTokenType.rightParenthesis,
              lexeme: ')',
              position: index,
            ),
          );
          index++;
          continue;
        case '[':
          rawTokens.add(
            CalculationToken(
              type: CalculationTokenType.leftBracket,
              lexeme: '[',
              position: index,
            ),
          );
          index++;
          continue;
        case ']':
          rawTokens.add(
            CalculationToken(
              type: CalculationTokenType.rightBracket,
              lexeme: ']',
              position: index,
            ),
          );
          index++;
          continue;
        case ',':
          rawTokens.add(
            CalculationToken(
              type: CalculationTokenType.comma,
              lexeme: ',',
              position: index,
            ),
          );
          index++;
          continue;
        case '=':
          rawTokens.add(
            CalculationToken(
              type: CalculationTokenType.equals,
              lexeme: '=',
              position: index,
            ),
          );
          index++;
          continue;
        case '+':
        case '-':
        case '*':
        case '/':
        case '^':
          rawTokens.add(
            CalculationToken(
              type: CalculationTokenType.operator,
              lexeme: character,
              position: index,
            ),
          );
          index++;
          continue;
        case '\u00D7':
          rawTokens.add(
            CalculationToken(
              type: CalculationTokenType.operator,
              lexeme: '*',
              position: index,
            ),
          );
          index++;
          continue;
        case '\u00F7':
          rawTokens.add(
            CalculationToken(
              type: CalculationTokenType.operator,
              lexeme: '/',
              position: index,
            ),
          );
          index++;
          continue;
      }

      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.syntaxError,
          message: 'Gecersiz karakter bulundu: "$character".',
          position: index,
          suggestion:
              'Yalnizca desteklenen operator ve fonksiyonlari kullanin.',
        ),
      );
    }

    final tokens = _insertImplicitMultiplication(rawTokens);
    if (tokens.length > maxTokenCount) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.computationLimit,
          message: 'Ifade bu faz icin cok uzun.',
          suggestion: 'Ifadeyi daha kucuk parcalara bolup tekrar deneyin.',
        ),
      );
    }

    return [
      ...tokens,
      CalculationToken(
        type: CalculationTokenType.eof,
        lexeme: '',
        position: expression.length,
      ),
    ];
  }

  CalculationToken _readNumber(String source, int start) {
    var index = start;
    var sawDigitsBeforeDecimal = false;
    var sawDigitsAfterDecimal = false;

    while (index < source.length && _isDigit(source[index])) {
      sawDigitsBeforeDecimal = true;
      index++;
    }

    if (index < source.length && source[index] == '.') {
      index++;
      while (index < source.length && _isDigit(source[index])) {
        sawDigitsAfterDecimal = true;
        index++;
      }
    }

    if (!sawDigitsBeforeDecimal && !sawDigitsAfterDecimal) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.syntaxError,
          message: 'Hatali sayi formati.',
          position: start,
          suggestion: 'Ondalik sayilar icin en az bir rakam girin.',
        ),
      );
    }

    if (index < source.length &&
        (source[index] == 'e' || source[index] == 'E')) {
      final exponentPosition = index;
      index++;
      if (index < source.length &&
          (source[index] == '+' || source[index] == '-')) {
        index++;
      }

      final exponentDigitStart = index;
      while (index < source.length && _isDigit(source[index])) {
        index++;
      }

      if (exponentDigitStart == index) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.syntaxError,
            message: 'Bilimsel gosterim ussu eksik.',
            position: exponentPosition,
            suggestion: 'Ornek: 1e3 veya 2.5e-4.',
          ),
        );
      }
    }

    return CalculationToken(
      type: CalculationTokenType.number,
      lexeme: source.substring(start, index),
      position: start,
    );
  }

  CalculationToken _readIdentifier(String source, int start) {
    var index = start;
    while (index < source.length && _isIdentifierPart(source[index])) {
      index++;
    }

    final lexeme = source.substring(start, index).toLowerCase();
    final nextIndex = _nextNonWhitespaceIndex(source, index);
    final isFunctionCall =
        nextIndex < source.length && source[nextIndex] == '(';
    final tokenType =
        !isFunctionCall && UnitRegistry.instance.lookup(lexeme) != null
        ? CalculationTokenType.unitIdentifier
        : CalculationTokenType.identifier;

    return CalculationToken(
      type: tokenType,
      lexeme: lexeme,
      position: start,
    );
  }

  List<CalculationToken> _insertImplicitMultiplication(
    List<CalculationToken> tokens,
  ) {
    if (tokens.isEmpty) {
      return const [];
    }

    final normalized = <CalculationToken>[];
    for (final token in tokens) {
      if (normalized.isNotEmpty &&
          _shouldInsertMultiplication(normalized.last, token)) {
        normalized.add(
          CalculationToken.syntheticMultiply(position: token.position),
        );
      }
      normalized.add(token);
    }
    return normalized;
  }

  bool _shouldInsertMultiplication(
    CalculationToken left,
    CalculationToken right,
  ) {
    if (!_canEndImplicitValue(left) || !_canStartImplicitValue(right)) {
      return false;
    }

    if (left.type == CalculationTokenType.identifier &&
        right.type == CalculationTokenType.leftParenthesis) {
      return false;
    }

    return true;
  }

  bool _canEndImplicitValue(CalculationToken token) {
    return token.type == CalculationTokenType.number ||
        token.type == CalculationTokenType.identifier ||
        token.type == CalculationTokenType.unitIdentifier ||
        token.type == CalculationTokenType.rightParenthesis ||
        token.type == CalculationTokenType.rightBracket;
  }

  bool _canStartImplicitValue(CalculationToken token) {
    return token.type == CalculationTokenType.number ||
        token.type == CalculationTokenType.identifier ||
        token.type == CalculationTokenType.unitIdentifier ||
        token.type == CalculationTokenType.unaryFunction ||
        token.type == CalculationTokenType.leftParenthesis ||
        token.type == CalculationTokenType.leftBracket;
  }

  bool _isNumberStart(String source, int index) {
    final character = source[index];
    if (_isDigit(character)) {
      return true;
    }

    return character == '.' &&
        index + 1 < source.length &&
        _isDigit(source[index + 1]);
  }

  bool _isDigit(String character) => '0123456789'.contains(character);

  bool _isWhitespace(String character) => character.trim().isEmpty;

  int _nextNonWhitespaceIndex(String source, int start) {
    var index = start;
    while (index < source.length && _isWhitespace(source[index])) {
      index++;
    }
    return index;
  }

  bool _isIdentifierStart(String character) {
    return _isAsciiLetter(character) ||
        character == '_' ||
        character == 'µ' ||
        character == 'μ' ||
        character == '°';
  }

  bool _isIdentifierPart(String character) {
    return _isAsciiLetter(character) ||
        _isDigit(character) ||
        character == '_' ||
        character == 'µ' ||
        character == 'μ' ||
        character == '°';
  }

  bool _isAsciiLetter(String character) {
    final codeUnit = character.codeUnitAt(0);
    final isUppercase = codeUnit >= 65 && codeUnit <= 90;
    final isLowercase = codeUnit >= 97 && codeUnit <= 122;
    return isUppercase || isLowercase;
  }
}
