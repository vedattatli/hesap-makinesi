import '../ast_nodes.dart';

/// Scoped user-defined function available only inside an evaluation scope.
class ScopedFunctionDefinition {
  const ScopedFunctionDefinition({
    required this.name,
    required this.parameters,
    required this.bodyExpression,
    required this.normalizedBodyExpression,
    required this.bodyAst,
    this.sourceId,
  });

  final String name;
  final List<String> parameters;
  final String bodyExpression;
  final String normalizedBodyExpression;
  final ExpressionNode bodyAst;
  final String? sourceId;

  String get identityToken => sourceId == null ? name : '$name@$sourceId';
}
