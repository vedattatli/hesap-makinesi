import 'dart:convert';

import 'saved_expression_template.dart';
import 'worksheet_block.dart';
import 'worksheet_graph_state.dart';

class WorksheetDocument {
  const WorksheetDocument({
    required this.id,
    required this.title,
    required this.blocks,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.isArchived = false,
    this.activeGraphState,
    this.savedExpressionTemplates = const <SavedExpressionTemplate>[],
    this.savedGraphStates = const <WorksheetGraphState>[],
  });

  static const currentVersion = 2;

  final String id;
  final String title;
  final List<WorksheetBlock> blocks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isArchived;
  final WorksheetGraphState? activeGraphState;
  final List<SavedExpressionTemplate> savedExpressionTemplates;
  final List<WorksheetGraphState> savedGraphStates;

  WorksheetDocument copyWith({
    String? id,
    String? title,
    List<WorksheetBlock>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    bool? isArchived,
    WorksheetGraphState? activeGraphState,
    bool clearActiveGraphState = false,
    List<SavedExpressionTemplate>? savedExpressionTemplates,
    List<WorksheetGraphState>? savedGraphStates,
  }) {
    return WorksheetDocument(
      id: id ?? this.id,
      title: _normalizeTitle(title ?? this.title),
      blocks: List<WorksheetBlock>.unmodifiable(blocks ?? this.blocks),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isArchived: isArchived ?? this.isArchived,
      activeGraphState: clearActiveGraphState
          ? null
          : (activeGraphState ?? this.activeGraphState),
      savedExpressionTemplates: List<SavedExpressionTemplate>.unmodifiable(
        savedExpressionTemplates ?? this.savedExpressionTemplates,
      ),
      savedGraphStates: List<WorksheetGraphState>.unmodifiable(
        savedGraphStates ?? this.savedGraphStates,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'blocks': blocks.map((block) => block.toJson()).toList(growable: false),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'version': version,
      'isArchived': isArchived,
      'activeGraphState': activeGraphState?.toJson(),
      'savedExpressionTemplates': savedExpressionTemplates
          .map((item) => item.toJson())
          .toList(growable: false),
      'savedGraphStates': savedGraphStates
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }

  factory WorksheetDocument.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final updatedAt =
        DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toUtc() ??
        createdAt;
    final rawBlocks =
        (json['blocks'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(WorksheetBlock.tryFromJson)
            .whereType<WorksheetBlock>()
            .toList(growable: false)
          ..sort((left, right) => left.orderIndex.compareTo(right.orderIndex));

    WorksheetGraphState? activeGraphState;
    final rawActive = json['activeGraphState'];
    if (rawActive is Map<String, dynamic>) {
      try {
        activeGraphState = WorksheetGraphState.fromJson(rawActive);
      } catch (_) {
        activeGraphState = null;
      }
    }

    final savedTemplates =
        (json['savedExpressionTemplates'] as List<dynamic>? ??
                const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map((item) {
              try {
                return SavedExpressionTemplate.fromJson(item);
              } catch (_) {
                return null;
              }
            })
            .whereType<SavedExpressionTemplate>()
            .toList(growable: false);

    final savedGraphStates =
        (json['savedGraphStates'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map((item) {
              try {
                return WorksheetGraphState.fromJson(item);
              } catch (_) {
                return null;
              }
            })
            .whereType<WorksheetGraphState>()
            .toList(growable: false);

    return WorksheetDocument(
      id: json['id']?.toString().trim().isNotEmpty == true
          ? json['id'].toString()
          : '${createdAt.microsecondsSinceEpoch}-worksheet',
      title: _normalizeTitle(json['title']?.toString()),
      blocks: List<WorksheetBlock>.unmodifiable(rawBlocks),
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: (json['version'] as num?)?.toInt() ?? currentVersion,
      isArchived: json['isArchived'] == true,
      activeGraphState: activeGraphState,
      savedExpressionTemplates: List<SavedExpressionTemplate>.unmodifiable(
        savedTemplates,
      ),
      savedGraphStates: List<WorksheetGraphState>.unmodifiable(
        savedGraphStates,
      ),
    );
  }

  String toStoredString() => jsonEncode(toJson());

  static List<WorksheetDocument> listFromStoredString(String? source) {
    if (source == null || source.trim().isEmpty) {
      return const <WorksheetDocument>[];
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is! List<dynamic>) {
        return const <WorksheetDocument>[];
      }
      return List<WorksheetDocument>.unmodifiable(
        decoded.whereType<Map<String, dynamic>>().map((item) {
          try {
            return WorksheetDocument.fromJson(item);
          } catch (_) {
            return null;
          }
        }).whereType<WorksheetDocument>(),
      );
    } catch (_) {
      return const <WorksheetDocument>[];
    }
  }

  static String listToStoredString(List<WorksheetDocument> documents) {
    return jsonEncode(
      documents.map((item) => item.toJson()).toList(growable: false),
    );
  }

  static String _normalizeTitle(String? title) {
    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Untitled Worksheet';
    }
    return trimmed;
  }
}
