import 'dart:convert';

/// Saved calculator or graph template that can be inserted into the UI.
enum SavedExpressionTemplateType { expression, function, graphFunction }

class SavedExpressionTemplate {
  const SavedExpressionTemplate({
    required this.id,
    required this.label,
    required this.expression,
    required this.type,
    required this.variableName,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String label;
  final String expression;
  final SavedExpressionTemplateType type;
  final String variableName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;

  SavedExpressionTemplate copyWith({
    String? id,
    String? label,
    String? expression,
    SavedExpressionTemplateType? type,
    String? variableName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return SavedExpressionTemplate(
      id: id ?? this.id,
      label: label ?? this.label,
      expression: expression ?? this.expression,
      type: type ?? this.type,
      variableName: variableName ?? this.variableName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'expression': expression,
      'type': type.name,
      'variableName': variableName,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'description': description,
    };
  }

  factory SavedExpressionTemplate.fromJson(Map<String, dynamic> json) {
    final label = json['label']?.toString().trim();
    final expression = json['expression']?.toString().trim();
    if (label == null ||
        label.isEmpty ||
        expression == null ||
        expression.isEmpty) {
      throw const FormatException('Invalid saved expression template.');
    }

    final type = SavedExpressionTemplateType.values
        .cast<SavedExpressionTemplateType?>()
        .firstWhere(
          (value) => value?.name == json['type'],
          orElse: () => SavedExpressionTemplateType.expression,
        )!;
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final updatedAt =
        DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toUtc() ??
        createdAt;

    return SavedExpressionTemplate(
      id: json['id']?.toString().trim().isNotEmpty == true
          ? json['id'].toString()
          : '${createdAt.microsecondsSinceEpoch}-$label',
      label: label,
      expression: expression,
      type: type,
      variableName: json['variableName']?.toString().trim().isNotEmpty == true
          ? json['variableName'].toString()
          : 'x',
      createdAt: createdAt,
      updatedAt: updatedAt,
      description: json['description'] as String?,
    );
  }

  static List<SavedExpressionTemplate> listFromStoredString(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const <SavedExpressionTemplate>[];
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is! List<dynamic>) {
        return const <SavedExpressionTemplate>[];
      }
      return List<SavedExpressionTemplate>.unmodifiable(
        decoded.whereType<Map<String, dynamic>>().map((item) {
          try {
            return SavedExpressionTemplate.fromJson(item);
          } catch (_) {
            return null;
          }
        }).whereType<SavedExpressionTemplate>(),
      );
    } catch (_) {
      return const <SavedExpressionTemplate>[];
    }
  }
}
