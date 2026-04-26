import 'dart:io';

import 'worksheet_document.dart';
import 'worksheet_storage.dart';

class LocalWorksheetStorage implements WorksheetStorage {
  static const worksheetsStorageKey = 'calculator.worksheets.v1';
  static const activeWorksheetStorageKey = 'calculator.active_worksheet.v1';

  LocalWorksheetStorage({Directory? rootDirectory})
    : _rootDirectory = rootDirectory;

  final Directory? _rootDirectory;

  @override
  Future<void> clearWorksheets() async {
    final worksheetsFile = await _worksheetsFile;
    final activeFile = await _activeWorksheetFile;
    if (await worksheetsFile.exists()) {
      await worksheetsFile.delete();
    }
    if (await activeFile.exists()) {
      await activeFile.delete();
    }
  }

  @override
  Future<String?> loadActiveWorksheetId() async {
    final file = await _activeWorksheetFile;
    if (!await file.exists()) {
      return null;
    }

    try {
      final contents = (await file.readAsString()).trim();
      return contents.isEmpty ? null : contents;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WorksheetDocument>> loadWorksheets() async {
    final file = await _worksheetsFile;
    if (!await file.exists()) {
      return const <WorksheetDocument>[];
    }

    try {
      return WorksheetDocument.listFromStoredString(await file.readAsString());
    } catch (_) {
      return const <WorksheetDocument>[];
    }
  }

  @override
  Future<void> saveActiveWorksheetId(String? worksheetId) async {
    final file = await _activeWorksheetFile;
    if (worksheetId == null || worksheetId.trim().isEmpty) {
      if (await file.exists()) {
        await file.delete();
      }
      return;
    }
    await file.writeAsString(worksheetId);
  }

  @override
  Future<void> saveWorksheets(List<WorksheetDocument> worksheets) async {
    final file = await _worksheetsFile;
    await file.writeAsString(WorksheetDocument.listToStoredString(worksheets));
  }

  Future<Directory> get _storageDirectory async {
    final directory = _rootDirectory ?? _defaultStorageDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> get _worksheetsFile async {
    return File(
      _joinPath((await _storageDirectory).path, '$worksheetsStorageKey.json'),
    );
  }

  Future<File> get _activeWorksheetFile async {
    return File(
      _joinPath(
        (await _storageDirectory).path,
        '$activeWorksheetStorageKey.json',
      ),
    );
  }

  String _joinPath(String left, String right) {
    if (left.endsWith(Platform.pathSeparator)) {
      return '$left$right';
    }
    return '$left${Platform.pathSeparator}$right';
  }

  Directory _defaultStorageDirectory() {
    final basePath =
        Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['APPDATA'] ??
        Directory.current.path;
    return Directory(_joinPath(basePath, 'Hesap_Makinesi'));
  }
}
