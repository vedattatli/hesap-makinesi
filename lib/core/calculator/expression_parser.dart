import 'ast_nodes.dart';
import 'calculation_error.dart';
import 'calculation_token.dart';
import 'src/calculator_exception.dart';

/// Builds an AST from calculator tokens using operator precedence rules.
class ExpressionParser {
  /// Creates a stateless parser instance.
  const ExpressionParser();

  /// Parses tokens into an [ExpressionNode] tree.
  ExpressionNode parse(
    List<CalculationToken> tokens, {
    bool allowEquation = false,
  }) {
    return _ParserSession(tokens, allowEquation: allowEquation).parse();
  }
}

class _ParserSession {
  _ParserSession(this._tokens, {required bool allowEquation})
    : _allowEquation = allowEquation;

  final List<CalculationToken> _tokens;
  final bool _allowEquation;
  var _current = 0;

  ExpressionNode parse() {
    final expression = _parseExpression();
    if (!_isAtEnd) {
      final token = _peek;
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unexpectedToken,
          message: 'Beklenmeyen token bulundu: "${token.lexeme}".',
          position: token.position,
          suggestion: 'Ifadenin operator ve parantez dengesini kontrol edin.',
        ),
      );
    }
    return expression;
  }

  ExpressionNode _parseExpression() => _allowEquation
      ? _parseEquation()
      : _parseAddition();

  ExpressionNode _parseEquation() {
    final left = _parseAddition();
    if (!_match(CalculationTokenType.equals)) {
      return left;
    }

    final equals = _previous;
    final right = _parseAddition();
    if (_match(CalculationTokenType.equals)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.syntaxError,
          message: 'Bir ifade icinde yalnizca tek bir "=" operatoru desteklenir.',
          position: _previous.position,
          suggestion: 'Coklu esitlemeler yerine solve(eq(a, b), x) gibi bir form kullanin.',
        ),
      );
    }

    return EquationNode(
      left: left,
      right: right,
      position: equals.position,
    );
  }

  ExpressionNode _parseAddition() {
    var expression = _parseMultiplication();

    while (_matchOperator('+') || _matchOperator('-')) {
      final operator = _previous;
      final right = _parseMultiplication();
      expression = BinaryOperationNode(
        left: expression,
        operator: operator.lexeme,
        right: right,
        position: operator.position,
      );
    }

    return expression;
  }

  ExpressionNode _parseMultiplication() {
    var expression = _parseUnary();

    while (_matchOperator('*') || _matchOperator('/')) {
      final operator = _previous;
      final right = _parseUnary();
      expression = BinaryOperationNode(
        left: expression,
        operator: operator.lexeme,
        right: right,
        position: operator.position,
      );
    }

    return expression;
  }

  ExpressionNode _parseUnary() {
    if (_matchOperator('+') || _matchOperator('-')) {
      final operator = _previous;
      return UnaryOperationNode(
        operator: operator.lexeme,
        operand: _parseUnary(),
        position: operator.position,
      );
    }

    if (_match(CalculationTokenType.unaryFunction)) {
      final function = _previous;
      return FunctionCallNode(
        name: function.lexeme,
        arguments: [_parseUnary()],
        position: function.position,
      );
    }

    return _parsePower();
  }

  ExpressionNode _parsePower() {
    var expression = _parsePrimary();
    if (_matchOperator('^')) {
      final operator = _previous;
      final right = _parseUnary();
      expression = BinaryOperationNode(
        left: expression,
        operator: operator.lexeme,
        right: right,
        position: operator.position,
      );
    }
    return expression;
  }

  ExpressionNode _parsePrimary() {
    if (_match(CalculationTokenType.number)) {
      final token = _previous;
      final node = NumberNode(
        rawValue: token.lexeme,
        value: double.parse(token.lexeme),
        position: token.position,
      );
      return _parseUnitAttachment(node);
    }

    if (_match(CalculationTokenType.identifier)) {
      final token = _previous;
      if (_match(CalculationTokenType.leftParenthesis)) {
        return _parseUnitAttachment(_parseFunctionCall(token));
      }
      return _parseUnitAttachment(
        ConstantNode(name: token.lexeme, position: token.position),
      );
    }

    if (_match(CalculationTokenType.unitIdentifier)) {
      final token = _previous;
      return ConstantNode(name: token.lexeme, position: token.position);
    }

    if (_match(CalculationTokenType.leftParenthesis)) {
      final openParenthesis = _previous;
      final expression = _parseExpression();
      if (!_match(CalculationTokenType.rightParenthesis)) {
        throw CalculatorException(
          CalculationError(
            type: CalculationErrorType.missingParenthesis,
            message: 'Kapanmayan parantez bulundu.',
            position: openParenthesis.position,
            suggestion:
            'Acilan her parantez icin bir kapama parantezi ekleyin.',
          ),
        );
      }
      return _parseUnitAttachment(expression);
    }

    if (_match(CalculationTokenType.leftBracket)) {
      final openingBracket = _previous;
      final literal = _parseListLiteral(openingBracket);
      return _parseUnitAttachment(literal);
    }

    final token = _peek;
    throw CalculatorException(
      CalculationError(
        type: token.type == CalculationTokenType.eof
            ? CalculationErrorType.syntaxError
            : CalculationErrorType.unexpectedToken,
        message: token.type == CalculationTokenType.eof
            ? 'Ifade beklenmedik sekilde sona erdi.'
            : 'Beklenmeyen token bulundu: "${token.lexeme}".',
        position: token.position,
        suggestion:
            'Ifadenin eksik operator veya parantez icermediginden emin olun.',
      ),
    );
  }

  FunctionCallNode _parseFunctionCall(CalculationToken identifier) {
    final arguments = <ExpressionNode>[];

    if (!_check(CalculationTokenType.rightParenthesis)) {
      do {
        arguments.add(_parseExpression());
      } while (_match(CalculationTokenType.comma));
    }

    if (!_match(CalculationTokenType.rightParenthesis)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.missingParenthesis,
          message: 'Fonksiyon cagrisi kapanmadi.',
          position: identifier.position,
          suggestion: 'Fonksiyon argumanlarini ")" ile kapatin.',
        ),
      );
    }

    return FunctionCallNode(
      name: identifier.lexeme,
      arguments: arguments,
      position: identifier.position,
    );
  }

  ListLiteralNode _parseListLiteral(CalculationToken openingBracket) {
    final elements = <ExpressionNode>[];

    if (!_check(CalculationTokenType.rightBracket)) {
      do {
        elements.add(_parseExpression());
      } while (_match(CalculationTokenType.comma));
    }

    if (!_match(CalculationTokenType.rightBracket)) {
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.missingParenthesis,
          message: 'Liste literali kapanmadi.',
          position: openingBracket.position,
          suggestion: 'Acilan her "[" icin bir "]" ekleyin.',
        ),
      );
    }

    return ListLiteralNode(elements: elements, position: openingBracket.position);
  }

  ExpressionNode _parseUnitAttachment(ExpressionNode base) {
    if (_check(CalculationTokenType.operator) &&
        _peek.lexeme == '*' &&
        _checkNext(CalculationTokenType.unitIdentifier)) {
      _advance();
      final unitExpression = _parseUnitExpression();
      return UnitAttachmentNode(
        valueExpression: base,
        unitExpression: unitExpression,
        position: base.position,
      );
    }

    if (!_check(CalculationTokenType.unitIdentifier)) {
      return base;
    }

    final unitExpression = _parseUnitExpression();
    return UnitAttachmentNode(
      valueExpression: base,
      unitExpression: unitExpression,
      position: base.position,
    );
  }

  ExpressionNode _parseUnitExpression() {
    var expression = _parseUnitFactor();

    while (true) {
      if (_check(CalculationTokenType.operator) &&
          _peek.lexeme == '*' &&
          _checkNext(CalculationTokenType.unitIdentifier)) {
        _advance();
        final operator = _previous;
        final right = _parseUnitFactor();
        expression = BinaryOperationNode(
          left: expression,
          operator: operator.lexeme,
          right: right,
          position: operator.position,
        );
        continue;
      }

      if (_check(CalculationTokenType.operator) &&
          _peek.lexeme == '/' &&
          _checkNext(CalculationTokenType.unitIdentifier)) {
        _advance();
        final operator = _previous;
        final right = _parseUnitFactor();
        expression = BinaryOperationNode(
          left: expression,
          operator: operator.lexeme,
          right: right,
          position: operator.position,
        );
        continue;
      }

      break;
    }

    return expression;
  }

  ExpressionNode _parseUnitFactor() {
    if (!_match(CalculationTokenType.unitIdentifier)) {
      final token = _peek;
      throw CalculatorException(
        CalculationError(
          type: CalculationErrorType.unexpectedToken,
          message: 'Birim ifadesi bekleniyordu.',
          position: token.position,
          suggestion: 'm, cm, kg veya m/s^2 gibi gecerli bir birim yazin.',
        ),
      );
    }

    final token = _previous;
    ExpressionNode expression = ConstantNode(
      name: token.lexeme,
      position: token.position,
    );

    if (_matchOperator('^')) {
      final operator = _previous;
      final exponent = _parseUnary();
      expression = BinaryOperationNode(
        left: expression,
        operator: operator.lexeme,
        right: exponent,
        position: operator.position,
      );
    }

    return expression;
  }

  bool _match(CalculationTokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _matchOperator(String operator) {
    if (_check(CalculationTokenType.operator) && _peek.lexeme == operator) {
      _advance();
      return true;
    }
    return false;
  }

  bool _check(CalculationTokenType type) {
    if (_isAtEnd) {
      return type == CalculationTokenType.eof;
    }
    return _peek.type == type;
  }

  bool _checkNext(CalculationTokenType type) {
    if (_current + 1 >= _tokens.length) {
      return false;
    }
    return _tokens[_current + 1].type == type;
  }

  CalculationToken _advance() {
    if (!_isAtEnd) {
      _current++;
    }
    return _previous;
  }

  bool get _isAtEnd => _peek.type == CalculationTokenType.eof;

  CalculationToken get _peek => _tokens[_current];

  CalculationToken get _previous => _tokens[_current - 1];
}
