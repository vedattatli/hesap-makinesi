import 'dart:convert';

import '../data/calculator_history_item.dart';
import '../data/calculator_settings.dart';
import '../worksheet/worksheet_document.dart';
import '../worksheet/worksheet_export.dart';

class CalculatorBackupData {
  const CalculatorBackupData({
    required this.settings,
    required this.history,
    required this.worksheets,
    required this.activeWorksheetId,
  });

  final CalculatorSettings settings;
  final List<CalculatorHistoryItem> history;
  final List<WorksheetDocument> worksheets;
  final String? activeWorksheetId;
}

class CalculatorBackupException implements Exception {
  const CalculatorBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalDataBackupService {
  const LocalDataBackupService({
    this.maxBackupChars = 4000000,
    this.maxHistoryItems = 1000,
    this.maxWorksheets = 50,
  });

  static const schemaVersion = 1;

  final int maxBackupChars;
  final int maxHistoryItems;
  final int maxWorksheets;

  WorksheetExportResult exportBackup({
    required CalculatorSettings settings,
    required List<CalculatorHistoryItem> history,
    required List<WorksheetDocument> worksheets,
    required String? activeWorksheetId,
    DateTime? exportedAt,
  }) {
    final now = (exportedAt ?? DateTime.now().toUtc()).toUtc();
    final payload = <String, dynamic>{
      'schema': 'hesap_makinesi.local_backup',
      'schemaVersion': schemaVersion,
      'exportedAt': now.toIso8601String(),
      'privacy': 'Local-first backup. No cloud sync or external API.',
      'settings': settings.toJson(),
      'history': history.map((item) => item.toJson()).toList(growable: false),
      'worksheets': worksheets
          .map((item) => item.toJson())
          .toList(growable: false),
      'activeWorksheetId': activeWorksheetId,
    };
    final content = const JsonEncoder.withIndent('  ').convert(payload);
    if (content.length > maxBackupChars) {
      throw const CalculatorBackupException(
        'Backup export is too large. Clear old history or reduce worksheets.',
      );
    }
    return WorksheetExportResult(
      fileName: 'hesap_makinesi_backup',
      mimeType: 'application/json',
      contentText: content,
      extension: 'json',
      createdAt: now,
    );
  }

  CalculatorBackupData parseBackup(String source) {
    if (source.trim().isEmpty) {
      throw const CalculatorBackupException('Backup JSON is empty.');
    }
    if (source.length > maxBackupChars) {
      throw const CalculatorBackupException('Backup JSON is too large.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      throw const CalculatorBackupException('Backup JSON is not valid.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CalculatorBackupException('Backup root must be an object.');
    }
    if (decoded['schema'] != 'hesap_makinesi.local_backup') {
      throw const CalculatorBackupException('Backup schema is not supported.');
    }
    if ((decoded['schemaVersion'] as num?)?.toInt() != schemaVersion) {
      throw const CalculatorBackupException(
        'Backup schema version is not supported.',
      );
    }

    final rawSettings = decoded['settings'];
    if (rawSettings is! Map<String, dynamic>) {
      throw const CalculatorBackupException('Backup settings are missing.');
    }
    final settings = CalculatorSettings.fromJson(rawSettings);

    final rawHistory = decoded['history'];
    final history = rawHistory is List<dynamic>
        ? rawHistory
              .take(maxHistoryItems)
              .whereType<Map<String, dynamic>>()
              .map((item) {
                try {
                  return CalculatorHistoryItem.fromJson(item);
                } catch (_) {
                  return null;
                }
              })
              .whereType<CalculatorHistoryItem>()
              .toList(growable: false)
        : const <CalculatorHistoryItem>[];

    final rawWorksheets = decoded['worksheets'];
    final worksheets = rawWorksheets is List<dynamic>
        ? rawWorksheets
              .take(maxWorksheets)
              .whereType<Map<String, dynamic>>()
              .map((item) {
                try {
                  return WorksheetDocument.fromJson(item);
                } catch (_) {
                  return null;
                }
              })
              .whereType<WorksheetDocument>()
              .toList(growable: false)
        : const <WorksheetDocument>[];

    final rawActive = decoded['activeWorksheetId'];
    final activeWorksheetId = rawActive is String && rawActive.trim().isNotEmpty
        ? rawActive.trim()
        : null;
    return CalculatorBackupData(
      settings: settings,
      history: history,
      worksheets: worksheets,
      activeWorksheetId: activeWorksheetId,
    );
  }
}
