import 'dart:io';

import 'calculator_history_item.dart';
import 'calculator_settings.dart';
import 'calculator_storage.dart';

/// Local JSON file based persistence for calculator settings and history.
class LocalCalculatorStorage implements CalculatorStorage {
  static const settingsStorageKey = 'calculator.settings.v1';
  static const historyStorageKey = 'calculator.history.v1';

  LocalCalculatorStorage({Directory? rootDirectory})
    : _rootDirectory = rootDirectory;

  final Directory? _rootDirectory;

  @override
  Future<List<CalculatorHistoryItem>> loadHistory() async {
    final file = await _historyFile;
    if (!await file.exists()) {
      return const <CalculatorHistoryItem>[];
    }

    try {
      final rawHistory = await file.readAsString();
      return CalculatorHistoryItem.listFromStoredString(rawHistory);
    } catch (_) {
      return const <CalculatorHistoryItem>[];
    }
  }

  @override
  Future<CalculatorSettings?> loadSettings() async {
    final file = await _settingsFile;
    if (!await file.exists()) {
      return null;
    }

    try {
      final rawSettings = await file.readAsString();
      return CalculatorSettings.fromStoredString(rawSettings);
    } catch (_) {
      return CalculatorSettings.defaults;
    }
  }

  @override
  Future<void> saveHistory(List<CalculatorHistoryItem> history) async {
    final file = await _historyFile;
    await file.writeAsString(CalculatorHistoryItem.listToStoredString(history));
  }

  @override
  Future<void> saveSettings(CalculatorSettings settings) async {
    final file = await _settingsFile;
    await file.writeAsString(settings.toStoredString());
  }

  @override
  Future<void> clearHistory() async {
    final file = await _historyFile;
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> get _storageDirectory async {
    final directory = _rootDirectory ?? _defaultStorageDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> get _settingsFile async {
    return File(
      _joinPath((await _storageDirectory).path, '$settingsStorageKey.json'),
    );
  }

  Future<File> get _historyFile async {
    return File(
      _joinPath((await _storageDirectory).path, '$historyStorageKey.json'),
    );
  }

  Directory _defaultStorageDirectory() {
    final basePath =
        Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['APPDATA'] ??
        Directory.current.path;
    return Directory(_joinPath(basePath, 'Hesap_Makinesi'));
  }

  String _joinPath(String left, String right) {
    if (left.endsWith(Platform.pathSeparator)) {
      return '$left$right';
    }
    return '$left${Platform.pathSeparator}$right';
  }
}
