import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/calculator/calculator.dart';
import '../../worksheet/saved_expression_template.dart';
import '../../worksheet/worksheet_block.dart';
import '../../worksheet/worksheet_controller.dart';
import '../../worksheet/worksheet_document.dart';
import '../../worksheet/worksheet_error.dart';
import '../../worksheet/worksheet_export.dart';
import '../../worksheet/worksheet_graph_state.dart';
import '../../worksheet/scope/worksheet_symbol.dart';
import '../design/app_radii.dart';
import '../design/app_shadows.dart';
import '../design/app_spacing.dart';
import '../design/semantic_colors.dart';

class WorksheetPanel extends StatefulWidget {
  const WorksheetPanel({
    super.key,
    required this.controller,
    required this.currentExpression,
    required this.currentOutcome,
    required this.angleMode,
    required this.precision,
    required this.numericMode,
    required this.calculationDomain,
    required this.unitMode,
    required this.resultFormat,
    required this.onRecallExpression,
    required this.onLoadGraphState,
    this.latestGraphState,
    this.onLoadGraphTemplateExpression,
  });

  final WorksheetController controller;
  final String currentExpression;
  final CalculationOutcome? currentOutcome;
  final AngleMode angleMode;
  final int precision;
  final NumericMode numericMode;
  final CalculationDomain calculationDomain;
  final UnitMode unitMode;
  final NumberFormatStyle resultFormat;
  final WorksheetGraphState? latestGraphState;
  final ValueChanged<String> onRecallExpression;
  final ValueChanged<WorksheetGraphState> onLoadGraphState;
  final ValueChanged<String>? onLoadGraphTemplateExpression;

  @override
  State<WorksheetPanel> createState() => _WorksheetPanelState();
}

class _WorksheetPanelState extends State<WorksheetPanel> {
  final Map<String, TextEditingController> _calculationControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _variableNameControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _variableExpressionControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _functionNameControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _functionParametersControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _functionBodyControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _solveEquationControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _solveVariableControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _solveIntervalMinControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _solveIntervalMaxControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _casExpressionControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _textControllers =
      <String, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _calculationControllers.values) {
      controller.dispose();
    }
    for (final controller in _variableNameControllers.values) {
      controller.dispose();
    }
    for (final controller in _variableExpressionControllers.values) {
      controller.dispose();
    }
    for (final controller in _functionNameControllers.values) {
      controller.dispose();
    }
    for (final controller in _functionParametersControllers.values) {
      controller.dispose();
    }
    for (final controller in _functionBodyControllers.values) {
      controller.dispose();
    }
    for (final controller in _solveEquationControllers.values) {
      controller.dispose();
    }
    for (final controller in _solveVariableControllers.values) {
      controller.dispose();
    }
    for (final controller in _solveIntervalMinControllers.values) {
      controller.dispose();
    }
    for (final controller in _solveIntervalMaxControllers.values) {
      controller.dispose();
    }
    for (final controller in _casExpressionControllers.values) {
      controller.dispose();
    }
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final state = widget.controller.state;
        final worksheet = state.activeWorksheet;
        _syncControllers(worksheet?.blocks ?? const <WorksheetBlock>[]);
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          key: const Key('worksheet-panel'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: AppRadii.panel,
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
            boxShadow: AppShadows.panel(colorScheme),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Worksheet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calculation, variable, function, note and graph blocks with worksheet scope',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('worksheet-create-button'),
                    onPressed: () => _createWorksheet(context),
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('New'),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    key: const Key('worksheet-rename-button'),
                    tooltip: 'Rename worksheet',
                    onPressed: worksheet == null
                        ? null
                        : () => _renameWorksheet(
                            context,
                            worksheet.id,
                            worksheet.title,
                          ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    key: const Key('worksheet-delete-button'),
                    tooltip: 'Delete worksheet',
                    onPressed: worksheet == null
                        ? null
                        : () => _deleteWorksheet(context, worksheet.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('worksheet-selector'),
                initialValue: worksheet?.id,
                decoration: const InputDecoration(
                  labelText: 'Active worksheet',
                  border: OutlineInputBorder(),
                ),
                items: state.worksheets
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.title),
                      ),
                    )
                    .toList(growable: false),
                onChanged: state.worksheets.isEmpty
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        unawaited(
                          _runTask(
                            context,
                            () => widget.controller.selectWorksheet(value),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    key: const Key('worksheet-add-variable-button'),
                    onPressed: worksheet == null
                        ? null
                        : () => _createVariableBlock(context, worksheet),
                    icon: const Icon(Icons.tag_outlined),
                    label: const Text('Variable'),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('worksheet-add-function-button'),
                    onPressed: worksheet == null
                        ? null
                        : () => _createFunctionBlock(context, worksheet),
                    icon: const Icon(Icons.functions_outlined),
                    label: const Text('Function'),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('worksheet-add-calculation-button'),
                    onPressed: () => unawaited(
                      _runTask(
                        context,
                        () => widget.controller.addCalculationBlock(
                          expression: widget.currentExpression,
                          angleMode: widget.angleMode,
                          precision: widget.precision,
                          numericMode: widget.numericMode,
                          calculationDomain: widget.calculationDomain,
                          unitMode: widget.unitMode,
                          resultFormat: widget.resultFormat,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Calc block'),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('worksheet-add-text-button'),
                    onPressed: () => unawaited(
                      _runTask(context, () => widget.controller.addTextBlock()),
                    ),
                    icon: const Icon(Icons.notes_outlined),
                    label: const Text('Text block'),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('worksheet-add-graph-button'),
                    onPressed: widget.latestGraphState == null
                        ? null
                        : () => unawaited(
                            _runTask(
                              context,
                              () => widget.controller.saveCurrentGraphAsBlock(
                                widget.latestGraphState!,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.area_chart_outlined),
                    label: const Text('Graph block'),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('worksheet-add-solve-button'),
                    onPressed: worksheet == null
                        ? null
                        : () => _createSolveBlock(context),
                    icon: const Icon(Icons.hub_outlined),
                    label: const Text('Solve block'),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('worksheet-add-cas-button'),
                    onPressed: worksheet == null
                        ? null
                        : () => _createCasBlock(context),
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: const Text('CAS block'),
                  ),
                  FilledButton.icon(
                    key: const Key('worksheet-run-all-button'),
                    onPressed: worksheet == null
                        ? null
                        : () => unawaited(
                            _runTask(context, widget.controller.runAllBlocks),
                          ),
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: const Text('Run all'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('worksheet-validate-button'),
                    onPressed: worksheet == null
                        ? null
                        : () => unawaited(
                            _runTask(
                              context,
                              widget.controller.validateActiveWorksheet,
                            ),
                          ),
                    icon: const Icon(Icons.rule_folder_outlined),
                    label: const Text('Validate'),
                  ),
                ],
              ),
              if (worksheet != null) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: colorScheme.surfaceContainerLow,
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Worksheet Scope',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stale blocks: ${state.staleBlockCount}${state.lastRunSummary == null ? '' : '  |  ${state.lastRunSummary}'}',
                        key: const Key('worksheet-run-summary'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (state.activeSymbols.isEmpty)
                        Text(
                          'No validated worksheet symbols yet.',
                          key: const Key('worksheet-symbol-empty'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.activeSymbols
                              .map(
                                (symbol) => ActionChip(
                                  key: Key('worksheet-symbol-${symbol.name}'),
                                  label: Text(
                                    symbol.type == WorksheetSymbolType.function
                                        ? '${symbol.signature}${symbol.displayValue == null ? '' : ' -> ${symbol.displayValue}'}'
                                        : '${symbol.name}${symbol.displayValue == null ? '' : ' = ${symbol.displayValue}'}',
                                  ),
                                  avatar: Icon(
                                    symbol.type == WorksheetSymbolType.function
                                        ? Icons.functions
                                        : Icons.tag,
                                    size: 16,
                                  ),
                                  onPressed: () => widget.onRecallExpression(
                                    symbol.type == WorksheetSymbolType.function
                                        ? widget.controller
                                              .insertFunctionCallIntoCalculator(
                                                symbol.name,
                                              )
                                        : widget.controller
                                              .insertSymbolIntoCalculator(
                                                symbol.name,
                                              ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    key: const Key('worksheet-save-template-button'),
                    onPressed: widget.currentExpression.trim().isEmpty
                        ? null
                        : () => _saveExpressionTemplate(
                            context,
                            expression: widget.currentExpression,
                            type: SavedExpressionTemplateType.expression,
                          ),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Save expr template'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('worksheet-save-graph-template-button'),
                    onPressed:
                        widget.latestGraphState == null ||
                            widget.latestGraphState!.expressions.isEmpty
                        ? null
                        : () => _saveExpressionTemplate(
                            context,
                            expression:
                                widget.latestGraphState!.expressions.first,
                            type: SavedExpressionTemplateType.graphFunction,
                            variableName: 'x',
                          ),
                    icon: const Icon(Icons.functions_outlined),
                    label: const Text('Save graph template'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('worksheet-export-markdown-button'),
                    onPressed: worksheet == null
                        ? null
                        : () => unawaited(
                            _runTask(
                              context,
                              () => widget.controller.exportWorksheetMarkdown(
                                worksheet.id,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Markdown'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('worksheet-export-csv-button'),
                    onPressed: worksheet == null
                        ? null
                        : () => unawaited(
                            _runTask(
                              context,
                              () => widget.controller.exportWorksheetCsv(
                                worksheet.id,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('CSV'),
                  ),
                ],
              ),
              if (worksheet?.savedExpressionTemplates.isNotEmpty ==
                  true) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  'Templates',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: worksheet!.savedExpressionTemplates
                      .map(
                        (template) => _TemplateChip(
                          template: template,
                          onInsert: () => _useTemplate(template),
                          onDelete: () => unawaited(
                            _runTask(
                              context,
                              () => widget.controller
                                  .deleteSavedExpressionTemplate(template.id),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 18),
              if (worksheet == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Henüz aktif worksheet yok.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: worksheet.blocks
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildBlockCard(
                            context,
                            block: entry.value,
                            index: entry.key,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              if (state.exportPreview != null) ...<Widget>[
                const SizedBox(height: 18),
                _ExportPreviewCard(
                  export: state.exportPreview!,
                  onCopy: () => _copyExport(context, state.exportPreview!),
                  onClose: widget.controller.clearExportPreview,
                ),
              ],
              if (state.lastErrorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  state.lastErrorMessage!,
                  key: const Key('worksheet-error-text'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockCard(
    BuildContext context, {
    required WorksheetBlock block,
    required int index,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canMoveUp = index > 0;
    final canMoveDown =
        index <
        (widget.controller.state.activeWorksheet?.blocks.length ?? 0) - 1;
    final accentColor = _blockAccentColor(block.type, colorScheme);

    return AnimatedContainer(
      key: Key('worksheet-block-$index'),
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: AppRadii.panel,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorScheme.surfaceContainerLow,
            SemanticColors.containerFor(accentColor, theme.brightness),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
        boxShadow: AppShadows.control(colorScheme),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.panel,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 6, color: accentColor.withValues(alpha: 0.78)),
              Expanded(
                child: Padding(
                  padding: AppSpacing.compactCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            _blockIcon(block.type),
                            color: accentColor,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              switch (block.type) {
                                WorksheetBlockType.calculation =>
                                  'Calculation #${index + 1}',
                                WorksheetBlockType.variableDefinition =>
                                  'Variable #${index + 1}',
                                WorksheetBlockType.functionDefinition =>
                                  'Function #${index + 1}',
                                WorksheetBlockType.graph =>
                                  'Graph #${index + 1}',
                                WorksheetBlockType.solve =>
                                  'Solve #${index + 1}',
                                WorksheetBlockType.casTransform =>
                                  'CAS #${index + 1}',
                                WorksheetBlockType.text => 'Text #${index + 1}',
                              },
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            key: Key('worksheet-edit-block-$index'),
                            tooltip: 'Open block editor',
                            onPressed: () => _openBlockEditor(
                              context,
                              block: block,
                              index: index,
                            ),
                            icon: const Icon(Icons.edit_note_outlined),
                          ),
                          IconButton(
                            tooltip: 'Move up',
                            onPressed: canMoveUp
                                ? () => unawaited(
                                    _runTask(
                                      context,
                                      () => widget.controller.moveBlock(
                                        block.id,
                                        index - 1,
                                      ),
                                    ),
                                  )
                                : null,
                            icon: const Icon(Icons.arrow_upward),
                          ),
                          IconButton(
                            tooltip: 'Move down',
                            onPressed: canMoveDown
                                ? () => unawaited(
                                    _runTask(
                                      context,
                                      () => widget.controller.moveBlock(
                                        block.id,
                                        index + 1,
                                      ),
                                    ),
                                  )
                                : null,
                            icon: const Icon(Icons.arrow_downward),
                          ),
                          IconButton(
                            tooltip: 'Delete block',
                            onPressed: () => unawaited(
                              _runTask(
                                context,
                                () => widget.controller.deleteBlock(block.id),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      switch (block.type) {
                        WorksheetBlockType.calculation => _CalculationBlockCard(
                          index: index,
                          block: block,
                          controller: _calculationControllers[block.id]!,
                          onChanged: (value) => unawaited(
                            _runTask(
                              context,
                              () => widget.controller
                                  .updateCalculationBlockExpression(
                                    block.id,
                                    value,
                                  ),
                            ),
                          ),
                          onRun: () => unawaited(
                            _runTask(
                              context,
                              () => widget.controller.runBlock(block.id),
                            ),
                          ),
                          onRecall: () {
                            final expression = widget.controller
                                .recallCalculationExpression(block.id);
                            if (expression != null) {
                              widget.onRecallExpression(expression);
                            }
                          },
                        ),
                        WorksheetBlockType.variableDefinition =>
                          _VariableBlockCard(
                            index: index,
                            block: block,
                            nameController: _variableNameControllers[block.id]!,
                            expressionController:
                                _variableExpressionControllers[block.id]!,
                            onSave: () => unawaited(
                              _runTask(
                                context,
                                () => widget.controller
                                    .updateVariableDefinitionBlock(
                                      block.id,
                                      _variableNameControllers[block.id]!.text,
                                      _variableExpressionControllers[block.id]!
                                          .text,
                                    ),
                              ),
                            ),
                            onRun: () => unawaited(
                              _runTask(
                                context,
                                () => widget.controller.runBlock(block.id),
                              ),
                            ),
                            onInsert: () => widget.onRecallExpression(
                              widget.controller.insertSymbolIntoCalculator(
                                block.symbolName ?? '',
                              ),
                            ),
                          ),
                        WorksheetBlockType.functionDefinition =>
                          _FunctionBlockCard(
                            index: index,
                            block: block,
                            nameController: _functionNameControllers[block.id]!,
                            parametersController:
                                _functionParametersControllers[block.id]!,
                            bodyController: _functionBodyControllers[block.id]!,
                            onSave: () => unawaited(
                              _runTask(
                                context,
                                () => widget.controller
                                    .updateFunctionDefinitionBlock(
                                      block.id,
                                      _functionNameControllers[block.id]!.text,
                                      _parseParameters(
                                        _functionParametersControllers[block
                                                .id]!
                                            .text,
                                      ),
                                      _functionBodyControllers[block.id]!.text,
                                    ),
                              ),
                            ),
                            onRun: () => unawaited(
                              _runTask(
                                context,
                                () => widget.controller.runBlock(block.id),
                              ),
                            ),
                            onInsert: () => widget.onRecallExpression(
                              widget.controller
                                  .insertFunctionCallIntoCalculator(
                                    block.symbolName ?? '',
                                  ),
                            ),
                          ),
                        WorksheetBlockType.graph => _GraphBlockCard(
                          index: index,
                          block: block,
                          onRun: () => unawaited(
                            _runTask(
                              context,
                              () => widget.controller.runBlock(block.id),
                            ),
                          ),
                          onLoadIntoGraph: () {
                            final graphState = widget.controller
                                .recallGraphState(block.id);
                            if (graphState != null) {
                              widget.onLoadGraphState(graphState);
                            }
                          },
                          onExportSvg: () => unawaited(
                            _runTask(
                              context,
                              () => widget.controller.exportGraphSvg(block.id),
                            ),
                          ),
                          onExportCsv: () => unawaited(
                            _runTask(
                              context,
                              () => widget.controller.exportGraphDataCsv(
                                block.id,
                              ),
                            ),
                          ),
                        ),
                        WorksheetBlockType.solve => _SolveBlockCard(
                          index: index,
                          block: block,
                          equationController:
                              _solveEquationControllers[block.id]!,
                          variableController:
                              _solveVariableControllers[block.id]!,
                          intervalMinController:
                              _solveIntervalMinControllers[block.id]!,
                          intervalMaxController:
                              _solveIntervalMaxControllers[block.id]!,
                          onSave: (methodPreference) => unawaited(
                            _runTask(
                              context,
                              () => widget.controller.updateSolveBlock(
                                block.id,
                                equationExpression:
                                    _solveEquationControllers[block.id]!.text,
                                variableName:
                                    _solveVariableControllers[block.id]!.text,
                                intervalMinExpression:
                                    _solveIntervalMinControllers[block.id]!
                                        .text,
                                intervalMaxExpression:
                                    _solveIntervalMaxControllers[block.id]!
                                        .text,
                                methodPreference: methodPreference,
                              ),
                            ),
                          ),
                          onRun: () => unawaited(
                            _runTask(
                              context,
                              () => widget.controller.runBlock(block.id),
                            ),
                          ),
                          onRecall: () {
                            final expression = widget.controller
                                .recallCalculationExpression(block.id);
                            if (expression != null) {
                              widget.onRecallExpression(expression);
                            }
                          },
                        ),
                        WorksheetBlockType.casTransform =>
                          _CasTransformBlockCard(
                            index: index,
                            block: block,
                            expressionController:
                                _casExpressionControllers[block.id]!,
                            onSave: (transformType) => unawaited(
                              _runTask(
                                context,
                                () => widget.controller.updateCasTransformBlock(
                                  block.id,
                                  expression:
                                      _casExpressionControllers[block.id]!.text,
                                  transformType: transformType,
                                ),
                              ),
                            ),
                            onRun: () => unawaited(
                              _runTask(
                                context,
                                () => widget.controller.runBlock(block.id),
                              ),
                            ),
                            onRecall: () {
                              final expression = widget.controller
                                  .recallCalculationExpression(block.id);
                              if (expression != null) {
                                widget.onRecallExpression(expression);
                              }
                            },
                          ),
                        WorksheetBlockType.text => _TextBlockCard(
                          index: index,
                          controller: _textControllers[block.id]!,
                          block: block,
                          onChanged: (value) => unawaited(
                            _runTask(
                              context,
                              () => widget.controller.updateTextBlock(
                                block.id,
                                value,
                              ),
                            ),
                          ),
                        ),
                      },
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _blockAccentColor(WorksheetBlockType type, ColorScheme colorScheme) {
    return switch (type) {
      WorksheetBlockType.calculation => colorScheme.primary,
      WorksheetBlockType.variableDefinition => SemanticColors.unit(colorScheme),
      WorksheetBlockType.functionDefinition => SemanticColors.symbolic(
        colorScheme,
      ),
      WorksheetBlockType.graph => SemanticColors.graph(colorScheme),
      WorksheetBlockType.solve => SemanticColors.cas(colorScheme),
      WorksheetBlockType.casTransform => SemanticColors.cas(colorScheme),
      WorksheetBlockType.text => colorScheme.tertiary,
    };
  }

  IconData _blockIcon(WorksheetBlockType type) {
    return switch (type) {
      WorksheetBlockType.calculation => Icons.calculate_outlined,
      WorksheetBlockType.variableDefinition => Icons.tag_outlined,
      WorksheetBlockType.functionDefinition => Icons.functions_outlined,
      WorksheetBlockType.graph => Icons.area_chart_outlined,
      WorksheetBlockType.solve => Icons.hub_outlined,
      WorksheetBlockType.casTransform => Icons.auto_fix_high_outlined,
      WorksheetBlockType.text => Icons.notes_outlined,
    };
  }

  Future<void> _openBlockEditor(
    BuildContext context, {
    required WorksheetBlock block,
    required int index,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final title = switch (block.type) {
          WorksheetBlockType.calculation => 'Calculation block editor',
          WorksheetBlockType.variableDefinition => 'Variable block editor',
          WorksheetBlockType.functionDefinition => 'Function block editor',
          WorksheetBlockType.graph => 'Graph block editor',
          WorksheetBlockType.solve => 'Solve block editor',
          WorksheetBlockType.casTransform => 'CAS block editor',
          WorksheetBlockType.text => 'Text block editor',
        };
        final expression =
            block.expression ?? block.bodyExpression ?? block.text ?? '';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              key: Key('worksheet-block-editor-$index'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Inline fields remain the source of truth; this sheet gives focused run, validation and dependency context.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (expression.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(
                    expression,
                    key: Key('worksheet-block-editor-expression-$index'),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _BlockStatusSummary(block: block),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    FilledButton.icon(
                      key: Key('worksheet-block-editor-run-$index'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        unawaited(
                          _runTask(
                            context,
                            () => widget.controller.runBlock(block.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_outlined),
                      label: const Text('Run block'),
                    ),
                    OutlinedButton.icon(
                      key: Key('worksheet-block-editor-validate-$index'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        unawaited(
                          _runTask(
                            context,
                            widget.controller.validateActiveWorksheet,
                          ),
                        );
                      },
                      icon: const Icon(Icons.rule_folder_outlined),
                      label: const Text('Validate worksheet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _syncControllers(List<WorksheetBlock> blocks) {
    final blockIds = blocks.map((block) => block.id).toSet();

    final removedCalculationIds = _calculationControllers.keys
        .where((id) => !blockIds.contains(id))
        .toList(growable: false);
    for (final id in removedCalculationIds) {
      _calculationControllers.remove(id)?.dispose();
    }

    final removedVariableNameIds = _variableNameControllers.keys
        .where((id) => !blockIds.contains(id))
        .toList(growable: false);
    for (final id in removedVariableNameIds) {
      _variableNameControllers.remove(id)?.dispose();
      _variableExpressionControllers.remove(id)?.dispose();
    }

    final removedFunctionNameIds = _functionNameControllers.keys
        .where((id) => !blockIds.contains(id))
        .toList(growable: false);
    for (final id in removedFunctionNameIds) {
      _functionNameControllers.remove(id)?.dispose();
      _functionParametersControllers.remove(id)?.dispose();
      _functionBodyControllers.remove(id)?.dispose();
    }

    final removedSolveIds = _solveEquationControllers.keys
        .where((id) => !blockIds.contains(id))
        .toList(growable: false);
    for (final id in removedSolveIds) {
      _solveEquationControllers.remove(id)?.dispose();
      _solveVariableControllers.remove(id)?.dispose();
      _solveIntervalMinControllers.remove(id)?.dispose();
      _solveIntervalMaxControllers.remove(id)?.dispose();
    }

    final removedCasIds = _casExpressionControllers.keys
        .where((id) => !blockIds.contains(id))
        .toList(growable: false);
    for (final id in removedCasIds) {
      _casExpressionControllers.remove(id)?.dispose();
    }

    final removedTextIds = _textControllers.keys
        .where((id) => !blockIds.contains(id))
        .toList(growable: false);
    for (final id in removedTextIds) {
      _textControllers.remove(id)?.dispose();
    }

    for (final block in blocks) {
      if (block.isCalculation) {
        final controller = _calculationControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.expression ?? ''),
        );
        if (controller.text != (block.expression ?? '')) {
          controller.text = block.expression ?? '';
        }
      } else if (block.isVariableDefinition) {
        final nameController = _variableNameControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.symbolName ?? ''),
        );
        if (nameController.text != (block.symbolName ?? '')) {
          nameController.text = block.symbolName ?? '';
        }
        final expressionController = _variableExpressionControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.expression ?? ''),
        );
        if (expressionController.text != (block.expression ?? '')) {
          expressionController.text = block.expression ?? '';
        }
      } else if (block.isFunctionDefinition) {
        final nameController = _functionNameControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.symbolName ?? ''),
        );
        if (nameController.text != (block.symbolName ?? '')) {
          nameController.text = block.symbolName ?? '';
        }
        final parametersController = _functionParametersControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.parameters.join(',')),
        );
        final parameterText = block.parameters.join(',');
        if (parametersController.text != parameterText) {
          parametersController.text = parameterText;
        }
        final bodyController = _functionBodyControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.bodyExpression ?? ''),
        );
        if (bodyController.text != (block.bodyExpression ?? '')) {
          bodyController.text = block.bodyExpression ?? '';
        }
      } else if (block.isSolve) {
        final equationController = _solveEquationControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.expression ?? ''),
        );
        if (equationController.text != (block.expression ?? '')) {
          equationController.text = block.expression ?? '';
        }
        final variableController = _solveVariableControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.solveVariableName ?? 'x'),
        );
        if (variableController.text != (block.solveVariableName ?? 'x')) {
          variableController.text = block.solveVariableName ?? 'x';
        }
        final intervalMinController = _solveIntervalMinControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.intervalMinExpression ?? ''),
        );
        if (intervalMinController.text != (block.intervalMinExpression ?? '')) {
          intervalMinController.text = block.intervalMinExpression ?? '';
        }
        final intervalMaxController = _solveIntervalMaxControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.intervalMaxExpression ?? ''),
        );
        if (intervalMaxController.text != (block.intervalMaxExpression ?? '')) {
          intervalMaxController.text = block.intervalMaxExpression ?? '';
        }
      } else if (block.isCasTransform) {
        final expressionController = _casExpressionControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.expression ?? ''),
        );
        if (expressionController.text != (block.expression ?? '')) {
          expressionController.text = block.expression ?? '';
        }
      } else if (block.isText) {
        final controller = _textControllers.putIfAbsent(
          block.id,
          () => TextEditingController(text: block.text ?? ''),
        );
        if (controller.text != (block.text ?? '')) {
          controller.text = block.text ?? '';
        }
      }
    }
  }

  List<String> _parseParameters(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _createVariableBlock(
    BuildContext context,
    WorksheetDocument worksheet,
  ) async {
    var index = 1;
    while (worksheet.blocks.any((block) => block.symbolName == 'var$index')) {
      index++;
    }
    await _runTask(
      context,
      () => widget.controller.addVariableDefinitionBlock(
        'var$index',
        widget.currentExpression.trim().isEmpty
            ? '0'
            : widget.currentExpression,
      ),
    );
  }

  Future<void> _createFunctionBlock(
    BuildContext context,
    WorksheetDocument worksheet,
  ) async {
    var index = 1;
    while (worksheet.blocks.any((block) => block.symbolName == 'f$index')) {
      index++;
    }
    await _runTask(
      context,
      () => widget.controller.addFunctionDefinitionBlock(
        'f$index',
        const <String>['x'],
        widget.currentExpression.trim().isEmpty
            ? 'x'
            : widget.currentExpression,
      ),
    );
  }

  Future<void> _createSolveBlock(BuildContext context) async {
    await _runTask(
      context,
      () => widget.controller.addSolveBlock(
        equationExpression: widget.currentExpression.trim().isEmpty
            ? 'x^2 - 4 = 0'
            : widget.currentExpression,
        variableName: 'x',
      ),
    );
  }

  Future<void> _createCasBlock(BuildContext context) async {
    await _runTask(
      context,
      () => widget.controller.addCasTransformBlock(
        expression: widget.currentExpression.trim().isEmpty
            ? 'x + x'
            : widget.currentExpression,
        transformType: WorksheetCasTransformType.simplify,
        angleMode: widget.angleMode,
        precision: widget.precision,
        numericMode: widget.numericMode,
        calculationDomain: widget.calculationDomain,
        unitMode: widget.unitMode,
        resultFormat: widget.resultFormat,
      ),
    );
  }

  Future<void> _createWorksheet(BuildContext context) async {
    final title = await _promptForText(
      context,
      title: 'New Worksheet',
      initialValue: 'Untitled Worksheet',
      confirmLabel: 'Create',
    );
    if (!context.mounted) {
      return;
    }
    if (title == null) {
      return;
    }
    await _runTask(context, () => widget.controller.createWorksheet(title));
  }

  Future<void> _renameWorksheet(
    BuildContext context,
    String worksheetId,
    String currentTitle,
  ) async {
    final title = await _promptForText(
      context,
      title: 'Rename Worksheet',
      initialValue: currentTitle,
      confirmLabel: 'Save',
    );
    if (!context.mounted) {
      return;
    }
    if (title == null) {
      return;
    }
    await _runTask(
      context,
      () => widget.controller.renameWorksheet(worksheetId, title),
    );
  }

  Future<void> _deleteWorksheet(
    BuildContext context,
    String worksheetId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete worksheet'),
        content: const Text('This worksheet will be removed permanently.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!context.mounted) {
      return;
    }
    if (confirmed != true) {
      return;
    }
    await _runTask(
      context,
      () => widget.controller.deleteWorksheet(worksheetId),
    );
  }

  Future<void> _saveExpressionTemplate(
    BuildContext context, {
    required String expression,
    required SavedExpressionTemplateType type,
    String variableName = 'x',
  }) async {
    final label = await _promptForText(
      context,
      title: 'Save Template',
      initialValue: type == SavedExpressionTemplateType.graphFunction
          ? 'Graph Template'
          : 'Expression Template',
      confirmLabel: 'Save',
    );
    if (!context.mounted) {
      return;
    }
    if (label == null) {
      return;
    }
    await _runTask(
      context,
      () => widget.controller.addSavedExpressionTemplate(
        label: label,
        expression: expression,
        type: type,
        variableName: variableName,
      ),
    );
  }

  void _useTemplate(SavedExpressionTemplate template) {
    switch (template.type) {
      case SavedExpressionTemplateType.expression:
      case SavedExpressionTemplateType.function:
        widget.onRecallExpression(template.expression);
      case SavedExpressionTemplateType.graphFunction:
        if (widget.onLoadGraphTemplateExpression != null) {
          widget.onLoadGraphTemplateExpression!(template.expression);
        } else {
          widget.onRecallExpression(template.expression);
        }
    }
  }

  Future<String?> _promptForText(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String confirmLabel,
  }) async {
    var currentValue = initialValue;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initialValue,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onChanged: (value) => currentValue = value,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(currentValue),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<T?> _runTask<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on WorksheetException catch (error) {
      if (!context.mounted) {
        return null;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.error.message)));
      return null;
    } catch (_) {
      if (!context.mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worksheet islemi tamamlanamadi.')),
      );
      return null;
    }
  }

  Future<void> _copyExport(
    BuildContext context,
    WorksheetExportResult export,
  ) async {
    await Clipboard.setData(ClipboardData(text: export.contentText));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export content copied to clipboard.')),
    );
  }
}

class _CalculationBlockCard extends StatelessWidget {
  const _CalculationBlockCard({
    required this.index,
    required this.block,
    required this.controller,
    required this.onChanged,
    required this.onRun,
    required this.onRecall,
  });

  final int index;
  final WorksheetBlock block;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onRun;
  final VoidCallback onRecall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = block.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          key: Key('worksheet-calc-expression-$index'),
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Expression',
            border: OutlineInputBorder(),
          ),
          onSubmitted: onChanged,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: Key('worksheet-run-block-$index'),
              onPressed: onRun,
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Run'),
            ),
            OutlinedButton.icon(
              key: Key('worksheet-recall-block-$index'),
              onPressed: onRecall,
              icon: const Icon(Icons.undo_outlined),
              label: const Text('Recall'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BlockStatusSummary(block: block),
        if (result != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            result.displayResult,
            key: Key('worksheet-block-result-$index'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: result.hasError ? colorScheme.error : colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              block.numericMode?.name.toUpperCase() ?? 'APPROXIMATE',
              block.angleMode?.name.toUpperCase() ?? 'DEGREE',
              'P${block.precision ?? 10}',
            ].join(' | '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (result.errorMessage != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              result.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (result.warnings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              result.warnings.join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _VariableBlockCard extends StatelessWidget {
  const _VariableBlockCard({
    required this.index,
    required this.block,
    required this.nameController,
    required this.expressionController,
    required this.onSave,
    required this.onRun,
    required this.onInsert,
  });

  final int index;
  final WorksheetBlock block;
  final TextEditingController nameController;
  final TextEditingController expressionController;
  final VoidCallback onSave;
  final VoidCallback onRun;
  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          key: Key('worksheet-variable-name-$index'),
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Variable name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: 8),
        TextField(
          key: Key('worksheet-variable-expression-$index'),
          controller: expressionController,
          decoration: const InputDecoration(
            labelText: 'Expression',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: Key('worksheet-save-variable-$index'),
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
            FilledButton.tonalIcon(
              key: Key('worksheet-run-variable-$index'),
              onPressed: onRun,
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Run'),
            ),
            OutlinedButton.icon(
              key: Key('worksheet-insert-variable-$index'),
              onPressed: onInsert,
              icon: const Icon(Icons.keyboard_outlined),
              label: const Text('Insert'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BlockStatusSummary(block: block),
        if (block.result != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            block.result!.displayResult,
            key: Key('worksheet-variable-result-$index'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: block.result!.hasError
                  ? colorScheme.error
                  : colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _FunctionBlockCard extends StatelessWidget {
  const _FunctionBlockCard({
    required this.index,
    required this.block,
    required this.nameController,
    required this.parametersController,
    required this.bodyController,
    required this.onSave,
    required this.onRun,
    required this.onInsert,
  });

  final int index;
  final WorksheetBlock block;
  final TextEditingController nameController;
  final TextEditingController parametersController;
  final TextEditingController bodyController;
  final VoidCallback onSave;
  final VoidCallback onRun;
  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          key: Key('worksheet-function-name-$index'),
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Function name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: 8),
        TextField(
          key: Key('worksheet-function-parameters-$index'),
          controller: parametersController,
          decoration: const InputDecoration(
            labelText: 'Parameters (comma separated)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: 8),
        TextField(
          key: Key('worksheet-function-body-$index'),
          controller: bodyController,
          decoration: const InputDecoration(
            labelText: 'Body expression',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: Key('worksheet-save-function-$index'),
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
            FilledButton.tonalIcon(
              key: Key('worksheet-run-function-$index'),
              onPressed: onRun,
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Validate'),
            ),
            OutlinedButton.icon(
              key: Key('worksheet-insert-function-$index'),
              onPressed: onInsert,
              icon: const Icon(Icons.keyboard_outlined),
              label: const Text('Insert'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BlockStatusSummary(block: block),
        if (block.result != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            block.result!.displayResult,
            key: Key('worksheet-function-result-$index'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: block.worksheetErrorCode != null
                  ? colorScheme.error
                  : colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _SolveBlockCard extends StatefulWidget {
  const _SolveBlockCard({
    required this.index,
    required this.block,
    required this.equationController,
    required this.variableController,
    required this.intervalMinController,
    required this.intervalMaxController,
    required this.onSave,
    required this.onRun,
    required this.onRecall,
  });

  final int index;
  final WorksheetBlock block;
  final TextEditingController equationController;
  final TextEditingController variableController;
  final TextEditingController intervalMinController;
  final TextEditingController intervalMaxController;
  final ValueChanged<WorksheetSolveMethodPreference> onSave;
  final VoidCallback onRun;
  final VoidCallback onRecall;

  @override
  State<_SolveBlockCard> createState() => _SolveBlockCardState();
}

class _SolveBlockCardState extends State<_SolveBlockCard> {
  late WorksheetSolveMethodPreference _methodPreference;

  @override
  void initState() {
    super.initState();
    _methodPreference =
        widget.block.solveMethodPreference ??
        WorksheetSolveMethodPreference.auto;
  }

  @override
  void didUpdateWidget(covariant _SolveBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPreference =
        widget.block.solveMethodPreference ??
        WorksheetSolveMethodPreference.auto;
    if (nextPreference != _methodPreference) {
      _methodPreference = nextPreference;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = widget.block.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          key: Key('worksheet-solve-equation-${widget.index}'),
          controller: widget.equationController,
          decoration: const InputDecoration(
            labelText: 'Equation / expression',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                key: Key('worksheet-solve-variable-${widget.index}'),
                controller: widget.variableController,
                decoration: const InputDecoration(
                  labelText: 'Variable',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<WorksheetSolveMethodPreference>(
                key: Key('worksheet-solve-method-${widget.index}'),
                initialValue: _methodPreference,
                decoration: const InputDecoration(
                  labelText: 'Method',
                  border: OutlineInputBorder(),
                ),
                items: WorksheetSolveMethodPreference.values
                    .map(
                      (value) =>
                          DropdownMenuItem<WorksheetSolveMethodPreference>(
                            value: value,
                            child: Text(value.name),
                          ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _methodPreference = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                key: Key('worksheet-solve-interval-min-${widget.index}'),
                controller: widget.intervalMinController,
                decoration: const InputDecoration(
                  labelText: 'Interval min (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: Key('worksheet-solve-interval-max-${widget.index}'),
                controller: widget.intervalMaxController,
                decoration: const InputDecoration(
                  labelText: 'Interval max (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: Key('worksheet-save-solve-${widget.index}'),
              onPressed: () => widget.onSave(_methodPreference),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
            FilledButton.tonalIcon(
              key: Key('worksheet-run-solve-${widget.index}'),
              onPressed: widget.onRun,
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Run'),
            ),
            OutlinedButton.icon(
              key: Key('worksheet-recall-solve-${widget.index}'),
              onPressed: widget.onRecall,
              icon: const Icon(Icons.undo_outlined),
              label: const Text('Recall'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BlockStatusSummary(block: widget.block),
        if (result != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            result.displayResult,
            key: Key('worksheet-solve-result-${widget.index}'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: result.hasError ? colorScheme.error : colorScheme.primary,
            ),
          ),
          if ((result.solveDisplayResult ?? '').isNotEmpty &&
              result.solveDisplayResult != result.displayResult) ...<Widget>[
            const SizedBox(height: 4),
            Text(result.solveDisplayResult!, style: theme.textTheme.bodySmall),
          ],
          if (result.errorMessage != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              result.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (result.warnings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              result.warnings.join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _CasTransformBlockCard extends StatefulWidget {
  const _CasTransformBlockCard({
    required this.index,
    required this.block,
    required this.expressionController,
    required this.onSave,
    required this.onRun,
    required this.onRecall,
  });

  final int index;
  final WorksheetBlock block;
  final TextEditingController expressionController;
  final ValueChanged<WorksheetCasTransformType> onSave;
  final VoidCallback onRun;
  final VoidCallback onRecall;

  @override
  State<_CasTransformBlockCard> createState() => _CasTransformBlockCardState();
}

class _CasTransformBlockCardState extends State<_CasTransformBlockCard> {
  late WorksheetCasTransformType _transformType;

  @override
  void initState() {
    super.initState();
    _transformType =
        widget.block.casTransformType ?? WorksheetCasTransformType.simplify;
  }

  @override
  void didUpdateWidget(covariant _CasTransformBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.casTransformType != widget.block.casTransformType) {
      _transformType =
          widget.block.casTransformType ?? WorksheetCasTransformType.simplify;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = widget.block.result;
    final steps = result?.alternativeResults['steps'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<WorksheetCasTransformType>(
          key: Key('worksheet-cas-transform-type-${widget.index}'),
          initialValue: _transformType,
          decoration: const InputDecoration(
            labelText: 'Transform',
            border: OutlineInputBorder(),
          ),
          items: WorksheetCasTransformType.values
              .map(
                (value) => DropdownMenuItem<WorksheetCasTransformType>(
                  value: value,
                  child: Text(value.name),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _transformType = value;
            });
          },
        ),
        const SizedBox(height: 8),
        TextField(
          key: Key('worksheet-cas-expression-${widget.index}'),
          controller: widget.expressionController,
          decoration: const InputDecoration(
            labelText: 'Expression',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => widget.onSave(_transformType),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: Key('worksheet-save-cas-${widget.index}'),
              onPressed: () => widget.onSave(_transformType),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
            FilledButton.tonalIcon(
              key: Key('worksheet-run-cas-${widget.index}'),
              onPressed: widget.onRun,
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Run'),
            ),
            OutlinedButton.icon(
              key: Key('worksheet-recall-cas-${widget.index}'),
              onPressed: widget.onRecall,
              icon: const Icon(Icons.undo_outlined),
              label: const Text('Recall'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BlockStatusSummary(block: widget.block),
        if (result != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            result.displayResult,
            key: Key('worksheet-cas-result-${widget.index}'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: result.hasError ? colorScheme.error : colorScheme.primary,
            ),
          ),
          if (steps != null && steps.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              steps,
              key: Key('worksheet-cas-steps-${widget.index}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (result.errorMessage != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              result.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _GraphBlockCard extends StatelessWidget {
  const _GraphBlockCard({
    required this.index,
    required this.block,
    required this.onRun,
    required this.onLoadIntoGraph,
    required this.onExportSvg,
    required this.onExportCsv,
  });

  final int index;
  final WorksheetBlock block;
  final VoidCallback onRun;
  final VoidCallback onLoadIntoGraph;
  final VoidCallback onExportSvg;
  final VoidCallback onExportCsv;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final graph = block.graphState;
    if (graph == null) {
      return Text('Graph state is missing.', style: theme.textTheme.bodyMedium);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ...graph.expressions.map(
          (expression) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              expression,
              key: Key('worksheet-graph-expression-$index-$expression'),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          graph.viewport.toDisplayString(),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        _BlockStatusSummary(block: block),
        if (graph.lastPlotSummary != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            graph.lastPlotSummary!,
            key: Key('worksheet-graph-summary-$index'),
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (graph.warnings.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(graph.warnings.join('\n'), style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: Key('worksheet-run-graph-block-$index'),
              onPressed: onRun,
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Run'),
            ),
            OutlinedButton.icon(
              key: Key('worksheet-load-graph-block-$index'),
              onPressed: onLoadIntoGraph,
              icon: const Icon(Icons.open_in_new_outlined),
              label: const Text('Load graph'),
            ),
            OutlinedButton.icon(
              key: Key('worksheet-export-graph-svg-$index'),
              onPressed: onExportSvg,
              icon: const Icon(Icons.image_outlined),
              label: const Text('SVG'),
            ),
            OutlinedButton.icon(
              key: Key('worksheet-export-graph-csv-$index'),
              onPressed: onExportCsv,
              icon: const Icon(Icons.table_rows_outlined),
              label: const Text('Data CSV'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BlockStatusSummary extends StatelessWidget {
  const _BlockStatusSummary({required this.block});

  final WorksheetBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chips = <Widget>[];
    if (block.isStale) {
      chips.add(
        const _StatusChip(label: 'STALE', icon: Icons.schedule_outlined),
      );
    }
    if (block.worksheetErrorCode != null) {
      final label = switch (block.worksheetErrorCode) {
        WorksheetErrorCode.dependencyCycle => 'CYCLE',
        WorksheetErrorCode.undefinedSymbol => 'UNDEFINED',
        _ => 'ERROR',
      };
      chips.add(
        _StatusChip(label: label, icon: Icons.error_outline, isError: true),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (chips.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: chips),
        if (block.dependencies.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            'Dependencies: ${block.dependencies.join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (block.worksheetErrorMessage != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            block.worksheetErrorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    this.isError = false,
  });

  final String label;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      backgroundColor: isError
          ? colorScheme.errorContainer
          : colorScheme.secondaryContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TextBlockCard extends StatelessWidget {
  const _TextBlockCard({
    required this.index,
    required this.controller,
    required this.block,
    required this.onChanged,
  });

  final int index;
  final TextEditingController controller;
  final WorksheetBlock block;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: Key('worksheet-text-block-$index'),
      controller: controller,
      minLines: 2,
      maxLines: 6,
      decoration: InputDecoration(
        labelText: block.textFormat == WorksheetTextFormat.markdownLite
            ? 'Markdown-lite note'
            : 'Note',
        border: const OutlineInputBorder(),
      ),
      onSubmitted: onChanged,
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.template,
    required this.onInsert,
    required this.onDelete,
  });

  final SavedExpressionTemplate template;
  final VoidCallback onInsert;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(template.label),
      onPressed: onInsert,
      onDeleted: onDelete,
      avatar: Icon(switch (template.type) {
        SavedExpressionTemplateType.expression => Icons.calculate_outlined,
        SavedExpressionTemplateType.function => Icons.functions_outlined,
        SavedExpressionTemplateType.graphFunction => Icons.show_chart_outlined,
      }, size: 18),
    );
  }
}

class _ExportPreviewCard extends StatelessWidget {
  const _ExportPreviewCard({
    required this.export,
    required this.onCopy,
    required this.onClose,
  });

  final WorksheetExportResult export;
  final VoidCallback onCopy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const Key('worksheet-export-preview'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${export.fileName}.${export.extension}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('worksheet-copy-export-button'),
                onPressed: onCopy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy'),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            export.mimeType,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            export.contentText,
            key: const Key('worksheet-export-preview-text'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
