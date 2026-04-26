import 'worksheet_document.dart';
import 'worksheet_export.dart';
import 'scope/worksheet_symbol.dart';

class WorksheetState {
  const WorksheetState({
    required this.worksheets,
    required this.activeWorksheetId,
    required this.selectedBlockId,
    required this.isLoading,
    required this.lastErrorMessage,
    required this.exportPreview,
    required this.activeSymbols,
    required this.lastRunSummary,
  });

  factory WorksheetState.initial() {
    return const WorksheetState(
      worksheets: <WorksheetDocument>[],
      activeWorksheetId: null,
      selectedBlockId: null,
      isLoading: false,
      lastErrorMessage: null,
      exportPreview: null,
      activeSymbols: <WorksheetSymbol>[],
      lastRunSummary: null,
    );
  }

  final List<WorksheetDocument> worksheets;
  final String? activeWorksheetId;
  final String? selectedBlockId;
  final bool isLoading;
  final String? lastErrorMessage;
  final WorksheetExportResult? exportPreview;
  final List<WorksheetSymbol> activeSymbols;
  final String? lastRunSummary;

  WorksheetDocument? get activeWorksheet {
    if (activeWorksheetId == null) {
      return worksheets.isEmpty ? null : worksheets.first;
    }
    for (final worksheet in worksheets) {
      if (worksheet.id == activeWorksheetId) {
        return worksheet;
      }
    }
    return worksheets.isEmpty ? null : worksheets.first;
  }

  WorksheetState copyWith({
    List<WorksheetDocument>? worksheets,
    String? activeWorksheetId,
    bool clearActiveWorksheetId = false,
    String? selectedBlockId,
    bool clearSelectedBlockId = false,
    bool? isLoading,
    String? lastErrorMessage,
    bool clearLastErrorMessage = false,
    WorksheetExportResult? exportPreview,
    bool clearExportPreview = false,
    List<WorksheetSymbol>? activeSymbols,
    String? lastRunSummary,
    bool clearLastRunSummary = false,
  }) {
    return WorksheetState(
      worksheets: worksheets ?? this.worksheets,
      activeWorksheetId: clearActiveWorksheetId
          ? null
          : (activeWorksheetId ?? this.activeWorksheetId),
      selectedBlockId: clearSelectedBlockId
          ? null
          : (selectedBlockId ?? this.selectedBlockId),
      isLoading: isLoading ?? this.isLoading,
      lastErrorMessage: clearLastErrorMessage
          ? null
          : (lastErrorMessage ?? this.lastErrorMessage),
      exportPreview: clearExportPreview
          ? null
          : (exportPreview ?? this.exportPreview),
      activeSymbols: activeSymbols ?? this.activeSymbols,
      lastRunSummary: clearLastRunSummary
          ? null
          : (lastRunSummary ?? this.lastRunSummary),
    );
  }

  int get staleBlockCount =>
      activeWorksheet?.blocks.where((block) => block.isStale).length ?? 0;
}
