import 'worksheet_document.dart';

abstract class WorksheetStorage {
  Future<List<WorksheetDocument>> loadWorksheets();

  Future<void> saveWorksheets(List<WorksheetDocument> worksheets);

  Future<String?> loadActiveWorksheetId();

  Future<void> saveActiveWorksheetId(String? worksheetId);

  Future<void> clearWorksheets();
}
