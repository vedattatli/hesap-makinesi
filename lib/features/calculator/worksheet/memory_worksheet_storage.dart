import 'worksheet_document.dart';
import 'worksheet_storage.dart';

class MemoryWorksheetStorage implements WorksheetStorage {
  MemoryWorksheetStorage({
    List<WorksheetDocument>? worksheets,
    String? activeWorksheetId,
  }) : _worksheets = List<WorksheetDocument>.from(worksheets ?? const []),
       _activeWorksheetId = activeWorksheetId;

  List<WorksheetDocument> _worksheets;
  String? _activeWorksheetId;

  @override
  Future<void> clearWorksheets() async {
    _worksheets = <WorksheetDocument>[];
    _activeWorksheetId = null;
  }

  @override
  Future<String?> loadActiveWorksheetId() async => _activeWorksheetId;

  @override
  Future<List<WorksheetDocument>> loadWorksheets() async {
    return List<WorksheetDocument>.unmodifiable(_worksheets);
  }

  @override
  Future<void> saveActiveWorksheetId(String? worksheetId) async {
    _activeWorksheetId = worksheetId;
  }

  @override
  Future<void> saveWorksheets(List<WorksheetDocument> worksheets) async {
    _worksheets = List<WorksheetDocument>.from(worksheets);
  }
}
