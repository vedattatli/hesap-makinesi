/// Token produced by the calculator lexer.
class CalculationToken {
  /// Creates a token.
  const CalculationToken({
    required this.type,
    required this.lexeme,
    required this.position,
    this.synthetic = false,
  });

  /// Creates a synthetic multiplication token for implicit multiplication.
  const CalculationToken.syntheticMultiply({required int position})
    : this(
        type: CalculationTokenType.operator,
        lexeme: '*',
        position: position,
        synthetic: true,
      );

  /// Type of the token.
  final CalculationTokenType type;

  /// Exact or normalized textual form of the token.
  final String lexeme;

  /// Start offset in the original expression.
  final int position;

  /// Whether the token was inserted by the lexer.
  final bool synthetic;

  @override
  String toString() => '$type($lexeme @ $position)';
}

/// Kinds of lexical tokens recognized by the calculator engine.
enum CalculationTokenType {
  number,
  identifier,
  unitIdentifier,
  unaryFunction,
  operator,
  equals,
  leftParenthesis,
  rightParenthesis,
  leftBracket,
  rightBracket,
  comma,
  eof,
}
