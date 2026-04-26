import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/calculator/calculator.dart';
import 'dependency/worksheet_dependency_graph.dart';
import 'execution/worksheet_execution_result.dart';
import 'execution/worksheet_executor.dart';
import 'graph_data_csv_exporter.dart';
import 'graph_svg_exporter.dart';
import 'saved_expression_template.dart';
import 'scope/worksheet_symbol.dart';
import 'scope/worksheet_symbol_rules.dart';
import 'worksheet_block.dart';
import 'worksheet_block_result.dart';
import 'worksheet_document.dart';
import 'worksheet_error.dart';
import 'worksheet_export.dart';
import 'worksheet_export_service.dart';
import 'worksheet_graph_state.dart';
import 'worksheet_state.dart';
import 'worksheet_storage.dart';

class WorksheetController extends ChangeNotifier {
  WorksheetController({
    required WorksheetStorage storage,
    CalculatorEngine engine = const CalculatorEngine(),
    WorksheetExecutor? executor,
    WorksheetExportService exportService = const WorksheetExportService(),
    GraphSvgExporter svgExporter = const GraphSvgExporter(),
    GraphDataCsvExporter csvExporter = const GraphDataCsvExporter(),
    int maxWorksheets = 50,
    int maxBlocksPerWorksheet = 500,
    int maxTemplates = 200,
    int maxTextLength = 20000,
  }) : _storage = storage,
       _executor = executor ?? WorksheetExecutor(engine: engine),
       _exportService = exportService,
       _svgExporter = svgExporter,
       _csvExporter = csvExporter,
       _maxWorksheets = maxWorksheets,
       _maxBlocksPerWorksheet = maxBlocksPerWorksheet,
       _maxTemplates = maxTemplates,
       _maxTextLength = maxTextLength;

  final WorksheetStorage _storage;
  final WorksheetExecutor _executor;
  final WorksheetExportService _exportService;
  final GraphSvgExporter _svgExporter;
  final GraphDataCsvExporter _csvExporter;
  final int _maxWorksheets;
  final int _maxBlocksPerWorksheet;
  final int _maxTemplates;
  final int _maxTextLength;

  WorksheetState _state = WorksheetState.initial();
  bool _initialized = false;
  static int _idCounter = 0;

  WorksheetState get state => _state;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _updateState(_state.copyWith(isLoading: true));
    try {
      final worksheets = await _storage.loadWorksheets();
      final activeWorksheetId = await _storage.loadActiveWorksheetId();
      final hydrated = worksheets
          .map(_safeValidateWorksheet)
          .toList(growable: false);
      final activeWorksheet = _resolveActiveWorksheet(
        hydrated,
        activeWorksheetId,
      );
      final validation = activeWorksheet == null
          ? null
          : _executor.validate(activeWorksheet);
      _updateState(
        _state.copyWith(
          worksheets: hydrated,
          activeWorksheetId: activeWorksheetId,
          activeSymbols:
              validation?.symbolTable.symbols ?? const <WorksheetSymbol>[],
          lastRunSummary: validation?.summary,
          isLoading: false,
          clearLastErrorMessage: true,
        ),
      );
    } catch (_) {
      _updateState(
        _state.copyWith(
          worksheets: const <WorksheetDocument>[],
          activeSymbols: const <WorksheetSymbol>[],
          isLoading: false,
          lastErrorMessage: 'Worksheet verileri yuklenemedi.',
        ),
      );
    }
  }

  Future<WorksheetDocument> createWorksheet([String? title]) async {
    _guardWorksheetLimit();
    final now = DateTime.now().toUtc();
    final worksheet = WorksheetDocument(
      id: _nextId('worksheet'),
      title: _normalizeTitle(title),
      blocks: const <WorksheetBlock>[],
      createdAt: now,
      updatedAt: now,
      version: WorksheetDocument.currentVersion,
    );
    final worksheets = <WorksheetDocument>[..._state.worksheets, worksheet];
    await _persist(
      worksheets,
      activeWorksheetId: worksheet.id,
      activeSymbols: const <WorksheetSymbol>[],
      lastRunSummary: 'Created worksheet "${worksheet.title}".',
    );
    return worksheet;
  }

  Future<void> renameWorksheet(String worksheetId, String title) async {
    final worksheet = _requireWorksheet(worksheetId);
    final updated = worksheet.copyWith(
      title: _normalizeTitle(title),
      updatedAt: DateTime.now().toUtc(),
    );
    await _replaceWorksheet(updated);
  }

  Future<void> deleteWorksheet(String worksheetId) async {
    final worksheets = _state.worksheets
        .where((worksheet) => worksheet.id != worksheetId)
        .toList(growable: false);
    final nextActiveId = worksheets.isEmpty
        ? null
        : (_state.activeWorksheetId == worksheetId
              ? worksheets.first.id
              : _state.activeWorksheetId);
    final activeWorksheet = _resolveActiveWorksheet(worksheets, nextActiveId);
    await _persist(
      worksheets,
      activeWorksheetId: nextActiveId,
      activeSymbols: const <WorksheetSymbol>[],
      lastRunSummary: activeWorksheet == null
          ? 'No worksheet selected.'
          : 'Active worksheet: ${activeWorksheet.title}',
    );
  }

  Future<void> selectWorksheet(String worksheetId) async {
    final worksheet = _requireWorksheet(worksheetId);
    final validation = _executor.validate(worksheet);
    await _persist(
      _replaceWorksheetInCollection(validation.worksheet),
      activeWorksheetId: worksheetId,
      activeSymbols: validation.symbolTable.symbols,
      lastRunSummary: validation.summary,
    );
  }

  Future<WorksheetBlock> addCalculationBlock({
    String expression = '',
    String? title,
    AngleMode angleMode = AngleMode.degree,
    int precision = 10,
    NumericMode numericMode = NumericMode.approximate,
    CalculationDomain calculationDomain = CalculationDomain.real,
    UnitMode unitMode = UnitMode.disabled,
    NumberFormatStyle resultFormat = NumberFormatStyle.auto,
    WorksheetBlockResult? result,
  }) async {
    final worksheet = await _ensureActiveWorksheet();
    _guardBlockLimit(worksheet);
    final now = DateTime.now().toUtc();
    final block = WorksheetBlock.calculation(
      id: _nextId('block'),
      orderIndex: worksheet.blocks.length,
      expression: expression,
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      createdAt: now,
      updatedAt: now,
      title: title,
      result: result,
      isStale: true,
    );
    final updated = worksheet.copyWith(
      blocks: _reindexBlocks(<WorksheetBlock>[...worksheet.blocks, block]),
      updatedAt: now,
    );
    await _persistEditedWorksheet(
      updated,
      changedBlockId: block.id,
      definitionChanged: false,
    );
    return block;
  }

  Future<WorksheetBlock> addVariableDefinitionBlock(
    String name,
    String expression, {
    String? title,
    AngleMode angleMode = AngleMode.degree,
    int precision = 10,
    NumericMode numericMode = NumericMode.approximate,
    CalculationDomain calculationDomain = CalculationDomain.real,
    UnitMode unitMode = UnitMode.disabled,
    NumberFormatStyle resultFormat = NumberFormatStyle.auto,
  }) async {
    final worksheet = await _ensureActiveWorksheet();
    _guardBlockLimit(worksheet);
    _validateSymbolAvailability(worksheet, name);
    final now = DateTime.now().toUtc();
    final block = WorksheetBlock.variableDefinition(
      id: _nextId('block'),
      orderIndex: worksheet.blocks.length,
      name: name.trim(),
      expression: expression,
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      createdAt: now,
      updatedAt: now,
      title: title,
      isStale: true,
    );
    final updated = worksheet.copyWith(
      blocks: _reindexBlocks(<WorksheetBlock>[...worksheet.blocks, block]),
      updatedAt: now,
    );
    await _persistEditedWorksheet(
      updated,
      changedBlockId: block.id,
      definitionChanged: true,
    );
    return block;
  }

  Future<WorksheetBlock> addFunctionDefinitionBlock(
    String name,
    List<String> parameters,
    String bodyExpression, {
    String? title,
    AngleMode angleMode = AngleMode.degree,
    int precision = 10,
    NumericMode numericMode = NumericMode.approximate,
    CalculationDomain calculationDomain = CalculationDomain.real,
    UnitMode unitMode = UnitMode.disabled,
    NumberFormatStyle resultFormat = NumberFormatStyle.auto,
  }) async {
    final worksheet = await _ensureActiveWorksheet();
    _guardBlockLimit(worksheet);
    _validateSymbolAvailability(worksheet, name);
    for (final parameter in parameters) {
      final error = WorksheetSymbolRules.validateDefinitionName(
        parameter,
        kindLabel: 'Parameter',
        allowGraphVariableName: true,
      );
      if (error != null) {
        throw WorksheetException(error);
      }
    }
    if (parameters.toSet().length != parameters.length) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.invalidFunctionDefinition,
          message: 'Function parameters must be unique.',
        ),
      );
    }
    final now = DateTime.now().toUtc();
    final block = WorksheetBlock.functionDefinition(
      id: _nextId('block'),
      orderIndex: worksheet.blocks.length,
      name: name.trim(),
      parameters: List<String>.unmodifiable(parameters),
      bodyExpression: bodyExpression,
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      createdAt: now,
      updatedAt: now,
      title: title,
      isStale: true,
    );
    final updated = worksheet.copyWith(
      blocks: _reindexBlocks(<WorksheetBlock>[...worksheet.blocks, block]),
      updatedAt: now,
    );
    await _persistEditedWorksheet(
      updated,
      changedBlockId: block.id,
      definitionChanged: true,
    );
    return block;
  }

  Future<WorksheetBlock> addTextBlock({
    String text = '',
    WorksheetTextFormat format = WorksheetTextFormat.plain,
    String? title,
  }) async {
    final worksheet = await _ensureActiveWorksheet();
    _guardBlockLimit(worksheet);
    if (text.length > _maxTextLength) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.limitExceeded,
          message: 'Text block is too large.',
        ),
      );
    }
    final now = DateTime.now().toUtc();
    final block = WorksheetBlock.text(
      id: _nextId('block'),
      orderIndex: worksheet.blocks.length,
      text: text,
      format: format,
      createdAt: now,
      updatedAt: now,
      title: title,
    );
    final updated = worksheet.copyWith(
      blocks: _reindexBlocks(<WorksheetBlock>[...worksheet.blocks, block]),
      updatedAt: now,
    );
    await _replaceWorksheet(updated);
    return block;
  }

  Future<WorksheetBlock> addGraphBlock(
    WorksheetGraphState graphState, {
    String? title,
  }) async {
    final worksheet = await _ensureActiveWorksheet();
    _guardBlockLimit(worksheet);
    final now = DateTime.now().toUtc();
    final block = WorksheetBlock.graph(
      id: _nextId('block'),
      orderIndex: worksheet.blocks.length,
      graphState: graphState,
      createdAt: now,
      updatedAt: now,
      title: title ?? graphState.title,
      isStale: false,
    );
    final savedStates = _mergeSavedGraphStates(
      worksheet.savedGraphStates,
      graphState,
    );
    final updated = worksheet.copyWith(
      blocks: _reindexBlocks(<WorksheetBlock>[...worksheet.blocks, block]),
      savedGraphStates: savedStates,
      activeGraphState: graphState,
      updatedAt: now,
    );
    final validated = _executor.validate(updated);
    await _applyExecutionResult(validated);
    return block;
  }

  Future<WorksheetBlock> addSolveBlock({
    String equationExpression = '',
    String variableName = 'x',
    String? intervalMinExpression,
    String? intervalMaxExpression,
    WorksheetSolveMethodPreference methodPreference =
        WorksheetSolveMethodPreference.auto,
    String? title,
    AngleMode angleMode = AngleMode.degree,
    int precision = 10,
    NumericMode numericMode = NumericMode.approximate,
    CalculationDomain calculationDomain = CalculationDomain.real,
    UnitMode unitMode = UnitMode.disabled,
    NumberFormatStyle resultFormat = NumberFormatStyle.auto,
  }) async {
    final worksheet = await _ensureActiveWorksheet();
    _guardBlockLimit(worksheet);
    final now = DateTime.now().toUtc();
    final block = WorksheetBlock.solve(
      id: _nextId('block'),
      orderIndex: worksheet.blocks.length,
      equationExpression: equationExpression,
      variableName: variableName.trim().isEmpty ? 'x' : variableName.trim(),
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      createdAt: now,
      updatedAt: now,
      title: title,
      isStale: true,
      intervalMinExpression: intervalMinExpression,
      intervalMaxExpression: intervalMaxExpression,
      methodPreference: methodPreference,
    );
    final updated = worksheet.copyWith(
      blocks: _reindexBlocks(<WorksheetBlock>[...worksheet.blocks, block]),
      updatedAt: now,
    );
    await _persistEditedWorksheet(
      updated,
      changedBlockId: block.id,
      definitionChanged: false,
    );
    return block;
  }

  Future<WorksheetBlock> addCasTransformBlock({
    String expression = '',
    WorksheetCasTransformType transformType =
        WorksheetCasTransformType.simplify,
    String? title,
    AngleMode angleMode = AngleMode.degree,
    int precision = 10,
    NumericMode numericMode = NumericMode.approximate,
    CalculationDomain calculationDomain = CalculationDomain.real,
    UnitMode unitMode = UnitMode.disabled,
    NumberFormatStyle resultFormat = NumberFormatStyle.auto,
  }) async {
    final worksheet = await _ensureActiveWorksheet();
    _guardBlockLimit(worksheet);
    final now = DateTime.now().toUtc();
    final block = WorksheetBlock.casTransform(
      id: _nextId('block'),
      orderIndex: worksheet.blocks.length,
      expression: expression,
      transformType: transformType,
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      createdAt: now,
      updatedAt: now,
      title: title,
      isStale: true,
    );
    final updated = worksheet.copyWith(
      blocks: _reindexBlocks(<WorksheetBlock>[...worksheet.blocks, block]),
      updatedAt: now,
    );
    await _persistEditedWorksheet(
      updated,
      changedBlockId: block.id,
      definitionChanged: false,
    );
    return block;
  }

  Future<void> updateCalculationBlockExpression(
    String blockId,
    String expression,
  ) async {
    final block = _requireBlock(blockId);
    if (!block.isCalculation) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.invalidBlock,
          message: 'Not a calculation block.',
        ),
      );
    }
    await _replaceEditedBlock(
      block.copyWith(
        expression: expression,
        updatedAt: DateTime.now().toUtc(),
        isStale: true,
        clearResult: true,
        clearLastEvaluatedAt: true,
        clearWorksheetError: true,
      ),
      definitionChanged: false,
    );
  }

  Future<void> updateVariableDefinitionBlock(
    String blockId,
    String name,
    String expression,
  ) async {
    final block = _requireBlock(blockId);
    if (!block.isVariableDefinition) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.invalidBlock,
          message: 'Not a variable definition block.',
        ),
      );
    }
    _validateSymbolAvailability(
      _requireActiveWorksheet(),
      name,
      excludingBlockId: blockId,
    );
    await _replaceEditedBlock(
      block.copyWith(
        symbolName: name.trim(),
        expression: expression,
        updatedAt: DateTime.now().toUtc(),
        isStale: true,
        clearResult: true,
        clearLastEvaluatedAt: true,
        clearWorksheetError: true,
      ),
      definitionChanged: true,
    );
  }

  Future<void> updateFunctionDefinitionBlock(
    String blockId,
    String name,
    List<String> parameters,
    String bodyExpression,
  ) async {
    final block = _requireBlock(blockId);
    if (!block.isFunctionDefinition) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.invalidBlock,
          message: 'Not a function definition block.',
        ),
      );
    }
    _validateSymbolAvailability(
      _requireActiveWorksheet(),
      name,
      excludingBlockId: blockId,
    );
    if (parameters.toSet().length != parameters.length) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.invalidFunctionDefinition,
          message: 'Function parameters must be unique.',
        ),
      );
    }
    for (final parameter in parameters) {
      final error = WorksheetSymbolRules.validateDefinitionName(
        parameter,
        kindLabel: 'Parameter',
        allowGraphVariableName: true,
      );
      if (error != null) {
        throw WorksheetException(error);
      }
    }
    await _replaceEditedBlock(
      block.copyWith(
        symbolName: name.trim(),
        parameters: List<String>.unmodifiable(parameters),
        bodyExpression: bodyExpression,
        updatedAt: DateTime.now().toUtc(),
        isStale: true,
        clearResult: true,
        clearLastEvaluatedAt: true,
        clearWorksheetError: true,
      ),
      definitionChanged: true,
    );
  }

  Future<void> updateTextBlock(
    String blockId,
    String text, {
    WorksheetTextFormat? format,
  }) async {
    final block = _requireBlock(blockId);
    if (!block.isText) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.invalidBlock,
          message: 'Not a text block.',
        ),
      );
    }
    if (text.length > _maxTextLength) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.limitExceeded,
          message: 'Text block is too large.',
        ),
      );
    }
    await _replaceBlock(
      block.copyWith(
        text: text,
        textFormat: format ?? block.textFormat,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> updateSolveBlock(
    String blockId, {
    required String equationExpression,
    required String variableName,
    String? intervalMinExpression,
    String? intervalMaxExpression,
    WorksheetSolveMethodPreference? methodPreference,
  }) async {
    final block = _requireBlock(blockId);
    if (!block.isSolve) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.invalidBlock,
          message: 'Not a solve block.',
        ),
      );
    }
    await _replaceEditedBlock(
      block.copyWith(
        expression: equationExpression,
        solveVariableName: variableName.trim().isEmpty
            ? 'x'
            : variableName.trim(),
        intervalMinExpression: intervalMinExpression,
        intervalMaxExpression: intervalMaxExpression,
        solveMethodPreference: methodPreference ?? block.solveMethodPreference,
        updatedAt: DateTime.now().toUtc(),
        isStale: true,
        clearResult: true,
        clearLastEvaluatedAt: true,
        clearWorksheetError: true,
      ),
      definitionChanged: false,
    );
  }

  Future<void> updateCasTransformBlock(
    String blockId, {
    required String expression,
    required WorksheetCasTransformType transformType,
  }) async {
    final block = _requireBlock(blockId);
    if (!block.isCasTransform) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.invalidBlock,
          message: 'Not a CAS transform block.',
        ),
      );
    }
    await _replaceEditedBlock(
      block.copyWith(
        expression: expression,
        casTransformType: transformType,
        updatedAt: DateTime.now().toUtc(),
        isStale: true,
        clearResult: true,
        clearLastEvaluatedAt: true,
        clearWorksheetError: true,
      ),
      definitionChanged: false,
    );
  }

  Future<void> deleteBlock(String blockId) async {
    final worksheet = _requireActiveWorksheet();
    final blocks = worksheet.blocks
        .where((block) => block.id != blockId)
        .toList(growable: false);
    final updated = worksheet.copyWith(
      blocks: _reindexBlocks(blocks),
      updatedAt: DateTime.now().toUtc(),
    );
    final validation = _executor.validate(updated);
    await _applyExecutionResult(validation);
  }

  Future<void> moveBlock(String blockId, int newIndex) async {
    final worksheet = _requireActiveWorksheet();
    final blocks = worksheet.blocks.toList(growable: true);
    final currentIndex = blocks.indexWhere((block) => block.id == blockId);
    if (currentIndex == -1) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.blockNotFound,
          message: 'Worksheet block was not found.',
        ),
      );
    }
    final targetIndex = newIndex.clamp(0, blocks.length - 1);
    final block = blocks.removeAt(currentIndex);
    blocks.insert(targetIndex, block);
    final updated = worksheet.copyWith(
      blocks: _reindexBlocks(blocks),
      updatedAt: DateTime.now().toUtc(),
    );
    final validation = _executor.validate(updated);
    await _applyExecutionResult(validation);
  }

  Future<void> runBlock(String blockId) async {
    final worksheet = _requireActiveWorksheet();
    final execution = _executor.runBlock(worksheet, blockId);
    await _applyExecutionResult(execution);
  }

  Future<void> runAllBlocks() async {
    final worksheet = _requireActiveWorksheet();
    _updateState(_state.copyWith(isLoading: true, clearLastErrorMessage: true));
    try {
      final execution = _executor.runAll(worksheet);
      await _applyExecutionResult(execution);
    } on WorksheetException catch (error) {
      _updateState(
        _state.copyWith(
          isLoading: false,
          lastErrorMessage: error.error.message,
        ),
      );
      rethrow;
    } catch (error) {
      _updateState(
        _state.copyWith(
          isLoading: false,
          lastErrorMessage: 'Worksheet run failed: $error',
        ),
      );
      rethrow;
    }
  }

  Future<void> runAffectedBlocks(String blockId) async {
    final worksheet = _requireActiveWorksheet();
    final staged = _executor.markDependentsStale(worksheet, blockId);
    final execution = _executor.runAffected(staged.worksheet, blockId);
    await _applyExecutionResult(execution);
  }

  Future<void> validateActiveWorksheet() async {
    final worksheet = _requireActiveWorksheet();
    final validation = _executor.validate(worksheet);
    await _applyExecutionResult(validation);
  }

  Future<void> markDependentsStale(String blockId) async {
    final worksheet = _requireActiveWorksheet();
    final staged = _executor.markDependentsStale(worksheet, blockId);
    await _applyExecutionResult(staged);
  }

  String getDependencySummary(String blockId) {
    final block = _requireBlock(blockId);
    return block.dependencies.isEmpty
        ? 'No dependencies'
        : block.dependencies.join(', ');
  }

  List<WorksheetSymbol> getSymbolsForActiveWorksheet() => state.activeSymbols;

  String insertSymbolIntoCalculator(String name) => name;

  String insertFunctionCallIntoCalculator(String functionName) {
    final worksheet = _state.activeWorksheet;
    if (worksheet == null) {
      return '$functionName(';
    }
    final block = worksheet.blocks.cast<WorksheetBlock?>().firstWhere(
      (item) =>
          item?.isFunctionDefinition == true &&
          item?.symbolName == functionName,
      orElse: () => null,
    );
    if (block == null) {
      return '$functionName(';
    }
    return '${block.symbolName}(${List<String>.filled(block.parameters.length, '').join(', ')})';
  }

  Future<WorksheetBlock> saveCurrentCalculationResultAsBlock({
    required String expression,
    required CalculationOutcome? outcome,
    required AngleMode angleMode,
    required int precision,
    required NumericMode numericMode,
    required CalculationDomain calculationDomain,
    required UnitMode unitMode,
    required NumberFormatStyle resultFormat,
    String? title,
  }) async {
    final result = outcome?.isSuccess == true
        ? WorksheetBlockResult.fromCalculationResult(outcome!.result!)
        : outcome?.error != null
        ? WorksheetBlockResult.fromCalculationError(outcome!.error!)
        : null;
    return addCalculationBlock(
      expression: expression,
      title: title,
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      result: result?.copyWith(
        normalizedExpression: result.normalizedExpression ?? expression,
      ),
    );
  }

  Future<WorksheetBlock> saveCurrentGraphAsBlock(
    WorksheetGraphState graphState, {
    String? title,
  }) {
    return addGraphBlock(graphState, title: title);
  }

  Future<void> addSavedExpressionTemplate({
    required String label,
    required String expression,
    required SavedExpressionTemplateType type,
    String variableName = 'x',
    String? description,
  }) async {
    final worksheet = await _ensureActiveWorksheet();
    if (worksheet.savedExpressionTemplates.length >= _maxTemplates) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.limitExceeded,
          message: 'Template limit reached.',
        ),
      );
    }
    final now = DateTime.now().toUtc();
    final template = SavedExpressionTemplate(
      id: _nextId('template'),
      label: label.trim().isEmpty ? 'Template' : label.trim(),
      expression: expression,
      type: type,
      variableName: variableName,
      createdAt: now,
      updatedAt: now,
      description: description,
    );
    await _replaceWorksheet(
      worksheet.copyWith(
        savedExpressionTemplates: <SavedExpressionTemplate>[
          ...worksheet.savedExpressionTemplates,
          template,
        ],
        updatedAt: now,
      ),
    );
  }

  Future<void> deleteSavedExpressionTemplate(String templateId) async {
    final worksheet = _requireActiveWorksheet();
    await _replaceWorksheet(
      worksheet.copyWith(
        savedExpressionTemplates: worksheet.savedExpressionTemplates
            .where((template) => template.id != templateId)
            .toList(growable: false),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  SavedExpressionTemplate? templateById(String templateId) {
    final worksheet = _state.activeWorksheet;
    if (worksheet == null) {
      return null;
    }
    for (final template in worksheet.savedExpressionTemplates) {
      if (template.id == templateId) {
        return template;
      }
    }
    return null;
  }

  Future<WorksheetExportResult> exportWorksheetMarkdown(
    String worksheetId,
  ) async {
    final worksheet = _requireWorksheet(worksheetId);
    final export = _exportService.exportMarkdown(worksheet);
    _updateState(
      _state.copyWith(exportPreview: export, clearLastErrorMessage: true),
    );
    return export;
  }

  Future<WorksheetExportResult> exportWorksheetCsv(String worksheetId) async {
    final worksheet = _requireWorksheet(worksheetId);
    final export = _exportService.exportWorksheetCsv(worksheet);
    _updateState(
      _state.copyWith(exportPreview: export, clearLastErrorMessage: true),
    );
    return export;
  }

  Future<WorksheetExportResult> exportGraphSvg(String blockId) async {
    final worksheet = _requireActiveWorksheet();
    final execution = _executor.runBlock(worksheet, blockId);
    final graphBlock = execution.worksheet.blocks
        .cast<WorksheetBlock?>()
        .firstWhere((item) => item?.id == blockId, orElse: () => null);
    if (graphBlock?.graphState == null) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.graphExportFailed,
          message:
              'Graph block cannot be exported because it has no graph state.',
        ),
      );
    }
    final resolvedGraphBlock = graphBlock!;
    final plot = execution.generatedPlots[blockId];
    if (plot == null) {
      throw WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.graphExportFailed,
          message:
              resolvedGraphBlock.worksheetErrorMessage ??
              'Graph block cannot be exported because it has no valid plot result.',
        ),
      );
    }
    final svg = _svgExporter.export(plot, resolvedGraphBlock.graphState!);
    final export = WorksheetExportResult(
      fileName: _safeFileStem(resolvedGraphBlock.graphState!.title),
      mimeType: 'image/svg+xml',
      contentText: svg,
      extension: 'svg',
      createdAt: DateTime.now().toUtc(),
    );
    await _applyExecutionResult(
      WorksheetExecutionResult(
        worksheet: execution.worksheet,
        symbolTable: execution.symbolTable,
        runOrder: execution.runOrder,
        summary: execution.summary,
        generatedPlots: execution.generatedPlots,
      ),
      exportPreview: export,
    );
    return export;
  }

  Future<WorksheetExportResult> exportGraphDataCsv(String blockId) async {
    final worksheet = _requireActiveWorksheet();
    final execution = _executor.runBlock(worksheet, blockId);
    final plot = execution.generatedPlots[blockId];
    if (plot == null) {
      final block = _requireBlock(blockId);
      throw WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.graphExportFailed,
          message:
              block.worksheetErrorMessage ??
              'Graph data cannot be exported because plot evaluation failed.',
        ),
      );
    }
    final csv = _csvExporter.export(plot);
    final graphTitle =
        execution.worksheet.blocks
            .where((block) => block.id == blockId)
            .map((block) => block.graphState?.title)
            .whereType<String>()
            .firstOrNull ??
        'graph';
    final export = WorksheetExportResult(
      fileName: '${_safeFileStem(graphTitle)}_data',
      mimeType: 'text/csv',
      contentText: csv,
      extension: 'csv',
      createdAt: DateTime.now().toUtc(),
    );
    await _applyExecutionResult(execution, exportPreview: export);
    return export;
  }

  void clearExportPreview() {
    _updateState(_state.copyWith(clearExportPreview: true));
  }

  Future<void> clearAllWorksheets() async {
    await _storage.clearWorksheets();
    _updateState(
      _state.copyWith(
        worksheets: const <WorksheetDocument>[],
        clearActiveWorksheetId: true,
        activeSymbols: const <WorksheetSymbol>[],
        clearExportPreview: true,
        lastRunSummary: 'All worksheets cleared.',
        clearLastErrorMessage: true,
        isLoading: false,
      ),
    );
  }

  Future<void> restoreSnapshot({
    required List<WorksheetDocument> worksheets,
    required String? activeWorksheetId,
  }) async {
    final hydrated = worksheets
        .map(_safeValidateWorksheet)
        .toList(growable: false);
    final activeWorksheet = _resolveActiveWorksheet(
      hydrated,
      activeWorksheetId,
    );
    final validation = activeWorksheet == null
        ? null
        : _executor.validate(activeWorksheet);
    await _persist(
      validation == null
          ? hydrated
          : hydrated
                .map(
                  (worksheet) => worksheet.id == validation.worksheet.id
                      ? validation.worksheet
                      : worksheet,
                )
                .toList(growable: false),
      activeWorksheetId: activeWorksheet?.id,
      activeSymbols:
          validation?.symbolTable.symbols ?? const <WorksheetSymbol>[],
      lastRunSummary: 'Local backup restored.',
    );
  }

  Future<void> addSampleWorksheets(List<WorksheetDocument> samples) async {
    if (samples.isEmpty) {
      return;
    }
    final existingIds = _state.worksheets.map((item) => item.id).toSet();
    final additions = samples
        .where((sample) => !existingIds.contains(sample.id))
        .toList(growable: false);
    if (additions.isEmpty) {
      _updateState(
        _state.copyWith(
          lastRunSummary: 'Sample worksheets are already installed.',
          clearLastErrorMessage: true,
        ),
      );
      return;
    }
    if (_state.worksheets.length + additions.length > _maxWorksheets) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.limitExceeded,
          message:
              'Sample worksheets cannot be added because the worksheet limit would be exceeded.',
        ),
      );
    }
    final worksheets = <WorksheetDocument>[..._state.worksheets, ...additions];
    await _persist(
      worksheets,
      activeWorksheetId: additions.first.id,
      activeSymbols: const <WorksheetSymbol>[],
      lastRunSummary: 'Sample worksheets added.',
    );
  }

  String? recallCalculationExpression(String blockId) {
    final block = _requireBlock(blockId);
    if (block.isFunctionDefinition) {
      return '${block.symbolName}(${block.parameters.join(', ')})';
    }
    if (block.isVariableDefinition) {
      return block.symbolName;
    }
    if (block.isSolve) {
      final builder = StringBuffer('solve(');
      builder.write(block.expression ?? '');
      builder.write(', ${block.solveVariableName ?? 'x'}');
      final min = block.intervalMinExpression?.trim() ?? '';
      final max = block.intervalMaxExpression?.trim() ?? '';
      if (min.isNotEmpty && max.isNotEmpty) {
        builder.write(', $min, $max');
      }
      builder.write(')');
      return builder.toString();
    }
    if (block.isCasTransform) {
      final transform =
          block.casTransformType ?? WorksheetCasTransformType.simplify;
      return '${transform.name}(${block.expression ?? ''})';
    }
    return block.expression;
  }

  WorksheetGraphState? recallGraphState(String blockId) {
    final block = _requireBlock(blockId);
    return block.graphState;
  }

  Future<void> _replaceEditedBlock(
    WorksheetBlock block, {
    required bool definitionChanged,
  }) async {
    final worksheet = _requireActiveWorksheet();
    final updated = _worksheetWithReplacedBlock(
      worksheet,
      block,
      activeGraphState: block.graphState ?? worksheet.activeGraphState,
    );
    await _persistEditedWorksheet(
      updated,
      changedBlockId: block.id,
      definitionChanged: definitionChanged,
    );
  }

  Future<void> _persistEditedWorksheet(
    WorksheetDocument worksheet, {
    required String changedBlockId,
    required bool definitionChanged,
  }) async {
    final validated = _executor.validate(worksheet);
    final staged = definitionChanged
        ? _executor.markDependentsStale(validated.worksheet, changedBlockId)
        : _executor.markDependentsStale(validated.worksheet, changedBlockId);
    await _applyExecutionResult(staged);
  }

  Future<void> _replaceBlock(WorksheetBlock block) async {
    final worksheet = _requireActiveWorksheet();
    await _replaceWorksheet(
      _worksheetWithReplacedBlock(
        worksheet,
        block,
        activeGraphState: block.graphState ?? worksheet.activeGraphState,
      ),
    );
  }

  Future<void> _replaceWorksheet(WorksheetDocument updatedWorksheet) async {
    final validation = _executor.validate(updatedWorksheet);
    await _applyExecutionResult(validation);
  }

  WorksheetDocument _worksheetWithReplacedBlock(
    WorksheetDocument worksheet,
    WorksheetBlock block, {
    WorksheetGraphState? activeGraphState,
  }) {
    final blocks = worksheet.blocks
        .map((current) => current.id == block.id ? block : current)
        .toList(growable: false);
    return worksheet.copyWith(
      blocks: _reindexBlocks(blocks),
      updatedAt: DateTime.now().toUtc(),
      activeGraphState: activeGraphState,
    );
  }

  Future<void> _applyExecutionResult(
    WorksheetExecutionResult execution, {
    WorksheetExportResult? exportPreview,
  }) async {
    await _persist(
      _replaceWorksheetInCollection(execution.worksheet),
      activeWorksheetId: _state.activeWorksheetId ?? execution.worksheet.id,
      activeSymbols: execution.symbolTable.symbols,
      lastRunSummary: execution.summary,
      exportPreview: exportPreview,
    );
  }

  Future<void> _persist(
    List<WorksheetDocument> worksheets, {
    required String? activeWorksheetId,
    List<WorksheetSymbol>? activeSymbols,
    String? lastRunSummary,
    WorksheetExportResult? exportPreview,
  }) async {
    await _storage.saveWorksheets(worksheets);
    await _storage.saveActiveWorksheetId(activeWorksheetId);
    _updateState(
      _state.copyWith(
        worksheets: List<WorksheetDocument>.unmodifiable(worksheets),
        activeWorksheetId: activeWorksheetId,
        activeSymbols: activeSymbols ?? _state.activeSymbols,
        lastRunSummary: lastRunSummary ?? _state.lastRunSummary,
        exportPreview: exportPreview,
        clearLastErrorMessage: true,
        isLoading: false,
      ),
    );
  }

  WorksheetDocument _safeValidateWorksheet(WorksheetDocument worksheet) {
    try {
      return _executor.validate(worksheet).worksheet;
    } catch (_) {
      return worksheet;
    }
  }

  WorksheetDocument? _resolveActiveWorksheet(
    List<WorksheetDocument> worksheets,
    String? activeWorksheetId,
  ) {
    if (worksheets.isEmpty) {
      return null;
    }
    if (activeWorksheetId == null) {
      return worksheets.first;
    }
    for (final worksheet in worksheets) {
      if (worksheet.id == activeWorksheetId) {
        return worksheet;
      }
    }
    return worksheets.first;
  }

  Future<WorksheetDocument> _ensureActiveWorksheet() async {
    final worksheet = _state.activeWorksheet;
    if (worksheet != null) {
      return worksheet;
    }
    return createWorksheet();
  }

  WorksheetDocument _requireActiveWorksheet() {
    final worksheet = _state.activeWorksheet;
    if (worksheet == null) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.worksheetNotFound,
          message: 'No active worksheet selected.',
        ),
      );
    }
    return worksheet;
  }

  WorksheetDocument _requireWorksheet(String worksheetId) {
    for (final worksheet in _state.worksheets) {
      if (worksheet.id == worksheetId) {
        return worksheet;
      }
    }
    throw const WorksheetException(
      WorksheetError(
        code: WorksheetErrorCode.worksheetNotFound,
        message: 'Worksheet was not found.',
      ),
    );
  }

  WorksheetBlock _requireBlock(String blockId) {
    final worksheet = _requireActiveWorksheet();
    for (final block in worksheet.blocks) {
      if (block.id == blockId) {
        return block;
      }
    }
    throw const WorksheetException(
      WorksheetError(
        code: WorksheetErrorCode.blockNotFound,
        message: 'Worksheet block was not found.',
      ),
    );
  }

  WorksheetDependencyGraph activeDependencyGraph() {
    return _executor.dependencyGraphFor(_requireActiveWorksheet());
  }

  List<WorksheetDocument> _replaceWorksheetInCollection(
    WorksheetDocument updatedWorksheet,
  ) {
    return _state.worksheets
        .map(
          (worksheet) => worksheet.id == updatedWorksheet.id
              ? updatedWorksheet
              : worksheet,
        )
        .toList(growable: false);
  }

  List<WorksheetBlock> _reindexBlocks(List<WorksheetBlock> blocks) {
    return List<WorksheetBlock>.unmodifiable(
      blocks.asMap().entries.map(
        (entry) => entry.value.copyWith(
          orderIndex: entry.key,
          updatedAt: entry.value.updatedAt,
        ),
      ),
    );
  }

  void _validateSymbolAvailability(
    WorksheetDocument worksheet,
    String rawName, {
    String? excludingBlockId,
  }) {
    final error = WorksheetSymbolRules.validateDefinitionName(
      rawName,
      kindLabel: 'Symbol',
    );
    if (error != null) {
      throw WorksheetException(error);
    }
    final name = rawName.trim();
    final duplicate = worksheet.blocks.any(
      (block) =>
          block.definesSymbol &&
          block.id != excludingBlockId &&
          block.symbolName == name,
    );
    if (duplicate) {
      throw WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.duplicateSymbol,
          message:
              'Symbol "$name" is defined more than once in this worksheet.',
        ),
      );
    }
  }

  List<WorksheetGraphState> _mergeSavedGraphStates(
    List<WorksheetGraphState> current,
    WorksheetGraphState state,
  ) {
    final withoutSameId = current
        .where((item) => item.id != state.id)
        .toList(growable: false);
    return List<WorksheetGraphState>.unmodifiable(<WorksheetGraphState>[
      ...withoutSameId,
      state,
    ]);
  }

  void _guardWorksheetLimit() {
    if (_state.worksheets.length >= _maxWorksheets) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.limitExceeded,
          message: 'Worksheet limit reached.',
        ),
      );
    }
  }

  void _guardBlockLimit(WorksheetDocument worksheet) {
    if (worksheet.blocks.length >= _maxBlocksPerWorksheet) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.limitExceeded,
          message: 'Block limit reached for this worksheet.',
        ),
      );
    }
  }

  String _normalizeTitle(String? title) {
    final trimmed = title?.trim() ?? '';
    return trimmed.isEmpty ? 'Untitled Worksheet' : trimmed;
  }

  String _safeFileStem(String title) {
    final safe = title
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return safe.isEmpty ? 'worksheet_graph' : safe;
  }

  static String _nextId(String prefix) {
    _idCounter += 1;
    final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
    return '$prefix-$micros-$_idCounter';
  }

  void _updateState(WorksheetState state) {
    _state = state;
    notifyListeners();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
