import '../../../../core/calculator/calculator.dart';
import '../scope/worksheet_symbol_table.dart';
import '../worksheet_document.dart';

class WorksheetExecutionResult {
  const WorksheetExecutionResult({
    required this.worksheet,
    required this.symbolTable,
    required this.runOrder,
    required this.summary,
    this.generatedPlots = const <String, PlotValue>{},
    this.executedBlockIds = const <String>[],
    this.skippedBlockIds = const <String>[],
    this.elapsed = Duration.zero,
  });

  final WorksheetDocument worksheet;
  final WorksheetSymbolTable symbolTable;
  final List<String> runOrder;
  final String summary;
  final Map<String, PlotValue> generatedPlots;
  final List<String> executedBlockIds;
  final List<String> skippedBlockIds;
  final Duration elapsed;
}
