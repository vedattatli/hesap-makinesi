import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/local_worksheet_storage.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/memory_worksheet_storage.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_block.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WorksheetDocument sampleWorksheet() {
    return WorksheetDocument(
      id: 'worksheet-1',
      title: 'Storage Test',
      blocks: const <WorksheetBlock>[],
      createdAt: DateTime.utc(2026, 4, 26, 12),
      updatedAt: DateTime.utc(2026, 4, 26, 12),
      version: WorksheetDocument.currentVersion,
    );
  }

  test('memory worksheet storage loads and saves data', () async {
    final storage = MemoryWorksheetStorage();

    await storage.saveWorksheets(<WorksheetDocument>[sampleWorksheet()]);
    await storage.saveActiveWorksheetId('worksheet-1');

    final worksheets = await storage.loadWorksheets();
    final activeId = await storage.loadActiveWorksheetId();

    expect(worksheets, hasLength(1));
    expect(worksheets.single.title, 'Storage Test');
    expect(activeId, 'worksheet-1');

    await storage.clearWorksheets();
    expect(await storage.loadWorksheets(), isEmpty);
    expect(await storage.loadActiveWorksheetId(), isNull);
  });

  test('local worksheet storage loads and saves data', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'worksheet-storage-test',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final storage = LocalWorksheetStorage(rootDirectory: tempDirectory);
    await storage.saveWorksheets(<WorksheetDocument>[sampleWorksheet()]);
    await storage.saveActiveWorksheetId('worksheet-1');

    final worksheets = await storage.loadWorksheets();
    final activeId = await storage.loadActiveWorksheetId();

    expect(worksheets, hasLength(1));
    expect(worksheets.single.id, 'worksheet-1');
    expect(activeId, 'worksheet-1');
  });

  test('missing worksheet files return empty and null safely', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'worksheet-storage-missing',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final storage = LocalWorksheetStorage(rootDirectory: tempDirectory);

    expect(await storage.loadWorksheets(), isEmpty);
    expect(await storage.loadActiveWorksheetId(), isNull);
  });

  test('corrupt worksheet json returns empty list safely', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'worksheet-storage-corrupt',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final storage = LocalWorksheetStorage(rootDirectory: tempDirectory);
    final corruptFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}${LocalWorksheetStorage.worksheetsStorageKey}.json',
    );
    await corruptFile.writeAsString('{oops');

    expect(await storage.loadWorksheets(), isEmpty);
  });
}
