import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/calculator/calculator.dart';
import '../application/calculator_controller.dart';
import '../application/calculator_state.dart';
import '../data/calculator_history_item.dart';
import '../productization/examples_library.dart';
import '../productization/local_data_backup.dart';
import '../worksheet/worksheet_block_result.dart';
import '../worksheet/worksheet_controller.dart';
import '../worksheet/worksheet_graph_state.dart';
import 'app_localizations.dart';
import 'design/app_breakpoints.dart';
import 'design/app_motion.dart';
import 'design/app_radii.dart';
import 'design/app_shadows.dart';
import 'design/app_spacing.dart';
import 'design/calculator_icons.dart';
import 'design/semantic_colors.dart';
import 'widgets/calculator_display_card.dart';
import 'widgets/calculator_history_panel.dart';
import 'widgets/calculator_keypad.dart';
import 'widgets/calculator_settings_sheet.dart';
import 'widgets/expression_input_tools.dart';
import 'widgets/graph_panel.dart';
import 'widgets/productization_panels.dart';
import 'widgets/worksheet_panel.dart';

enum _ScreenMode {
  calculator,
  graph,
  worksheet,
  cas,
  stats,
  matrix,
  units,
  history,
}

extension _ScreenModeDetails on _ScreenMode {
  String get label => switch (this) {
    _ScreenMode.calculator => 'CALC',
    _ScreenMode.graph => 'GRAPH',
    _ScreenMode.worksheet => 'WORKSHEET',
    _ScreenMode.cas => 'CAS',
    _ScreenMode.stats => 'STATS',
    _ScreenMode.matrix => 'MATRIX',
    _ScreenMode.units => 'UNITS',
    _ScreenMode.history => 'HISTORY',
  };

  IconData get icon => switch (this) {
    _ScreenMode.calculator => CalculatorIcons.calculator,
    _ScreenMode.graph => CalculatorIcons.graph,
    _ScreenMode.worksheet => CalculatorIcons.worksheet,
    _ScreenMode.cas => CalculatorIcons.cas,
    _ScreenMode.stats => CalculatorIcons.stats,
    _ScreenMode.matrix => CalculatorIcons.matrix,
    _ScreenMode.units => CalculatorIcons.units,
    _ScreenMode.history => CalculatorIcons.history,
  };

  String localizedLabel(CalculatorStrings strings) {
    return strings.modeLabel(name);
  }
}

/// Main scientific calculator screen wired to the phase 2 controller.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    required this.controller,
    required this.worksheetController,
  });

  final CalculatorController controller;
  final WorksheetController worksheetController;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _editorController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LocalDataBackupService _backupService = const LocalDataBackupService();

  bool _isSyncingEditor = false;
  _ScreenMode _screenMode = _ScreenMode.calculator;
  WorksheetGraphState? _latestGraphState;

  @override
  void initState() {
    super.initState();
    _editorController.addListener(_handleEditorChanged);
    widget.controller.addListener(_syncEditorWithController);
    widget.worksheetController.addListener(_handleWorksheetChanges);
    unawaited(widget.controller.initialize());
    unawaited(widget.worksheetController.initialize());
    _syncEditorWithController();
  }

  @override
  void didUpdateWidget(covariant CalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeListener(_syncEditorWithController);
    widget.controller.addListener(_syncEditorWithController);
    oldWidget.worksheetController.removeListener(_handleWorksheetChanges);
    widget.worksheetController.addListener(_handleWorksheetChanges);
    unawaited(widget.controller.initialize());
    unawaited(widget.worksheetController.initialize());
    _syncEditorWithController();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncEditorWithController);
    widget.worksheetController.removeListener(_handleWorksheetChanges);
    _editorController.removeListener(_handleEditorChanged);
    _editorController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.controller,
        widget.worksheetController,
      ]),
      builder: (context, child) {
        final state = widget.controller.state;
        final reduceMotion = state.settings.reduceMotion;
        return Container(
          decoration: BoxDecoration(
            gradient: _backgroundGradient(Theme.of(context).brightness),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.keyK, control: true):
                    _openCommandPalette,
                const SingleActivator(LogicalKeyboardKey.keyL, control: true):
                    _clearExpressionShortcut,
                const SingleActivator(LogicalKeyboardKey.keyS, control: true):
                    _saveCurrentResultShortcut,
                const SingleActivator(
                  LogicalKeyboardKey.keyG,
                  control: true,
                ): () =>
                    _selectMode(_ScreenMode.graph),
                const SingleActivator(
                  LogicalKeyboardKey.keyW,
                  control: true,
                ): () =>
                    _selectMode(_ScreenMode.worksheet),
                const SingleActivator(
                  LogicalKeyboardKey.keyH,
                  control: true,
                ): () =>
                    _selectMode(_ScreenMode.history),
                const SingleActivator(LogicalKeyboardKey.escape):
                    _closeOverlayOrPanel,
                const SingleActivator(LogicalKeyboardKey.enter, control: true):
                    _saveOrEvaluateShortcut,
                const SingleActivator(LogicalKeyboardKey.enter): _evaluate,
              },
              child: Focus(
                autofocus: true,
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide =
                          constraints.maxWidth >= AppBreakpoints.wide;
                      final historyPanel = CalculatorHistoryPanel(
                        items: state.history,
                        onRecall: widget.controller.recallHistoryItem,
                        onDelete: (item) {
                          unawaited(widget.controller.deleteHistoryItem(item));
                        },
                        onClearHistory: () {
                          unawaited(widget.controller.clearHistory());
                        },
                        onSaveToWorksheet: (item) {
                          unawaited(_saveHistoryItemToWorksheet(item));
                        },
                      );
                      final mainContent = SingleChildScrollView(
                        padding: AppSpacing.screen,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isWide ? 860 : 780,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TopToolbar(
                                  state: state,
                                  screenMode: _screenMode,
                                  showHistoryButton: !isWide,
                                  onAngleModeChanged: (mode) {
                                    unawaited(
                                      widget.controller.setAngleMode(mode),
                                    );
                                  },
                                  onNumericModeChanged: (mode) {
                                    unawaited(
                                      widget.controller.setNumericMode(mode),
                                    );
                                  },
                                  onCalculationDomainChanged: (domain) {
                                    unawaited(
                                      widget.controller.setCalculationDomain(
                                        domain,
                                      ),
                                    );
                                  },
                                  onUnitModeChanged: (mode) {
                                    unawaited(
                                      widget.controller.setUnitMode(mode),
                                    );
                                  },
                                  onSelectScreenMode: _selectMode,
                                  onOpenSettings: _openSettingsSheet,
                                  onOpenHistory: _openHistorySheet,
                                  onOpenCommandPalette: _openCommandPalette,
                                  onOpenExamples: _openExamplesLibrary,
                                  onOpenHelp: _openHelpReference,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                if (!state.settings.onboardingCompleted) ...[
                                  ProductOnboardingCard(
                                    onFinish: () {
                                      unawaited(
                                        widget.controller
                                            .setOnboardingCompleted(true),
                                      );
                                    },
                                    onReduceMotion: () {
                                      unawaited(
                                        widget.controller.setReduceMotion(true),
                                      );
                                    },
                                    onOpenExamples: _openExamplesLibrary,
                                    onOpenHelp: _openHelpReference,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                AnimatedSwitcher(
                                  duration: AppMotion.duration(
                                    AppMotion.normal,
                                    reduceMotion: reduceMotion,
                                  ),
                                  switchInCurve: AppMotion.standard,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: _ModePanel(
                                    key: ValueKey<_ScreenMode>(_screenMode),
                                    screenMode: _screenMode,
                                    isWide: isWide,
                                    state: state,
                                    latestGraphState: _latestGraphState,
                                    worksheetController:
                                        widget.worksheetController,
                                    historyPanel: historyPanel,
                                    buildContext: _buildContext,
                                    onCommitPlotExpression:
                                        _commitPlotExpression,
                                    onGraphStateChanged: (graphState) {
                                      if (_graphStateEquivalent(
                                        _latestGraphState,
                                        graphState,
                                      )) {
                                        return;
                                      }
                                      setState(
                                        () => _latestGraphState = graphState,
                                      );
                                    },
                                    onSaveGraphState: (graphState) {
                                      unawaited(
                                        _saveGraphStateToWorksheet(graphState),
                                      );
                                    },
                                    onRecallExpression: (expression) {
                                      widget.controller.setExpression(
                                        expression,
                                      );
                                      setState(
                                        () => _screenMode =
                                            _ScreenMode.calculator,
                                      );
                                    },
                                    onLoadGraphState: _loadGraphState,
                                    onLoadGraphTemplateExpression:
                                        _loadGraphTemplateExpression,
                                  ),
                                ),
                                CalculatorDisplayCard(
                                  editorController: _editorController,
                                  focusNode: _focusNode,
                                  outcome: state.outcome,
                                  lastErrorMessage: state.lastErrorMessage,
                                  precision: state.precision,
                                  reduceMotion: reduceMotion,
                                  worksheetSuggestions:
                                      _activeWorksheetSuggestions(),
                                  onSuggestionSelected: _insertSuggestion,
                                  onOpenFunctionPalette: _openFunctionPalette,
                                  onOpenMatrixEditor: _openMatrixEditor,
                                  onOpenVectorEditor: _openVectorEditor,
                                  onOpenUnitConverter: _openUnitConverter,
                                  onOpenDatasetEditor: _openDatasetEditor,
                                  onOpenSolveCasEditor: _openSolveCasEditor,
                                  onSubmitted: (_) => _evaluate(),
                                  onSaveResultToWorksheet: state.outcome == null
                                      ? null
                                      : () => unawaited(
                                          _saveCurrentResultToWorksheet(),
                                        ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                CalculatorKeypad(
                                  reduceMotion: reduceMotion,
                                  onTextPressed: _insertText,
                                  onFunctionPressed: _insertFunction,
                                  onOperatorPressed: _insertOperator,
                                  onBackspacePressed: _backspace,
                                  onClearExpressionPressed:
                                      widget.controller.clearExpression,
                                  onClearAllPressed: widget.controller.clearAll,
                                  onMoveCursorLeft:
                                      widget.controller.moveCursorLeft,
                                  onMoveCursorRight:
                                      widget.controller.moveCursorRight,
                                  onEvaluatePressed: _evaluate,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      if (!isWide) {
                        return Column(
                          children: [
                            Expanded(child: mainContent),
                            _ModeBottomBar(
                              selectedMode: _screenMode,
                              onSelected: _selectMode,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          SizedBox(
                            width: 132,
                            child: _ModeRail(
                              selectedMode: _screenMode,
                              onSelected: _selectMode,
                            ),
                          ),
                          Expanded(child: mainContent),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            child: SizedBox(width: 360, child: historyPanel),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _backgroundGradient(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4F7FB), Color(0xFFE8F2F6), Color(0xFFF8FBFF)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF07131E), Color(0xFF0E2231), Color(0xFF143A45)],
    );
  }

  void _handleEditorChanged() {
    if (_isSyncingEditor) {
      return;
    }

    final selection = _editorController.selection;
    widget.controller.setExpression(
      _editorController.text,
      cursorPosition: selection.isValid
          ? selection.extentOffset.clamp(0, _editorController.text.length)
          : _editorController.text.length,
    );
  }

  void _syncEditorWithController() {
    final state = widget.controller.state;
    final safeCursor = state.cursorPosition.clamp(0, state.expression.length);
    final nextValue = TextEditingValue(
      text: state.expression,
      selection: TextSelection.collapsed(offset: safeCursor),
    );

    if (_editorController.value == nextValue) {
      return;
    }

    _isSyncingEditor = true;
    _editorController.value = nextValue;
    _isSyncingEditor = false;
  }

  void _insertText(String text) {
    _focusNode.requestFocus();
    if (_replaceSelection(text)) {
      return;
    }
    widget.controller.insertText(text);
  }

  void _insertFunction(String functionName) {
    _focusNode.requestFocus();
    final selection = _editorController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start.clamp(0, _editorController.text.length);
      final end = selection.end.clamp(0, _editorController.text.length);
      final selectedText = _editorController.text.substring(start, end);
      final replacement = '$functionName($selectedText)';
      widget.controller.setExpression(
        _editorController.text.replaceRange(start, end, replacement),
        cursorPosition: start + replacement.length,
      );
      return;
    }
    widget.controller.insertFunction(functionName);
  }

  void _insertOperator(String operatorText) {
    _focusNode.requestFocus();
    if (_replaceSelection(operatorText)) {
      return;
    }
    widget.controller.insertOperator(operatorText);
  }

  bool _replaceSelection(String text) {
    final selection = _editorController.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return false;
    }
    final start = selection.start.clamp(0, _editorController.text.length);
    final end = selection.end.clamp(0, _editorController.text.length);
    widget.controller.setExpression(
      _editorController.text.replaceRange(start, end, text),
      cursorPosition: start + text.length,
    );
    return true;
  }

  void _insertSuggestion(ExpressionSuggestion suggestion) {
    _focusNode.requestFocus();
    final text = _editorController.text;
    final selection = _editorController.selection;
    final cursor = selection.isValid
        ? selection.extentOffset.clamp(0, text.length)
        : text.length;
    var start = cursor;
    while (start > 0 && RegExp(r'[A-Za-z0-9_]').hasMatch(text[start - 1])) {
      start--;
    }
    widget.controller.setExpression(
      text.replaceRange(start, cursor, suggestion.insertText),
      cursorPosition: start + suggestion.insertText.length,
    );
  }

  List<ExpressionSuggestion> _activeWorksheetSuggestions() {
    return worksheetSymbolSuggestions(
      widget.worksheetController.state.activeSymbols,
    );
  }

  void _backspace() {
    _focusNode.requestFocus();
    widget.controller.backspace();
  }

  void _evaluate() {
    _focusNode.requestFocus();
    unawaited(widget.controller.evaluate());
  }

  void _clearExpressionShortcut() {
    _focusNode.requestFocus();
    widget.controller.clearExpression();
  }

  void _selectMode(_ScreenMode mode) {
    if (!mounted) {
      return;
    }
    setState(() => _screenMode = mode);
  }

  void _saveCurrentResultShortcut() {
    if (widget.controller.state.outcome == null) {
      return;
    }
    unawaited(_saveCurrentResultToWorksheet());
  }

  void _saveOrEvaluateShortcut() {
    if (widget.controller.state.outcome != null) {
      unawaited(_saveCurrentResultToWorksheet());
      return;
    }
    _evaluate();
  }

  void _closeOverlayOrPanel() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      unawaited(navigator.maybePop());
      return;
    }
    if (_screenMode != _ScreenMode.calculator) {
      setState(() => _screenMode = _ScreenMode.calculator);
    }
  }

  Future<void> _openFunctionPalette() async {
    final suggestion = await showModalBottomSheet<ExpressionSuggestion>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FunctionSymbolPalette(
          worksheetSuggestions: _activeWorksheetSuggestions(),
          onInsert: (suggestion) => Navigator.of(context).pop(suggestion),
        );
      },
    );
    if (suggestion != null) {
      _insertSuggestion(suggestion);
    }
  }

  Future<void> _openMatrixEditor() async {
    await _openExpressionBuilderSheet(const MatrixEditorSheet());
  }

  Future<void> _openVectorEditor() async {
    await _openExpressionBuilderSheet(const VectorEditorSheet());
  }

  Future<void> _openUnitConverter() async {
    await _openExpressionBuilderSheet(const UnitConverterSheet());
  }

  Future<void> _openDatasetEditor() async {
    await _openExpressionBuilderSheet(const DatasetEditorSheet());
  }

  Future<void> _openSolveCasEditor() async {
    await _openExpressionBuilderSheet(const SolveCasEditorSheet());
  }

  Future<void> _openExpressionBuilderSheet(Widget sheet) async {
    final expression = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => sheet,
    );
    if (expression == null || expression.trim().isEmpty) {
      return;
    }
    _insertText(expression);
  }

  void _commitPlotExpression(String expression) {
    widget.controller.setExpression(expression);
    unawaited(widget.controller.evaluate());
  }

  Future<void> _saveCurrentResultToWorksheet() async {
    final state = widget.controller.state;
    if (state.outcome == null) {
      return;
    }
    await widget.worksheetController.saveCurrentCalculationResultAsBlock(
      expression: state.expression,
      outcome: state.outcome,
      angleMode: state.angleMode,
      precision: state.precision,
      numericMode: state.numericMode,
      calculationDomain: state.calculationDomain,
      unitMode: state.unitMode,
      resultFormat: state.resultFormat,
    );
    if (!mounted) {
      return;
    }
    final strings = CalculatorLocalization.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.t('snackbar.resultSaved'))));
  }

  Future<void> _saveGraphStateToWorksheet(
    WorksheetGraphState graphState,
  ) async {
    await widget.worksheetController.saveCurrentGraphAsBlock(graphState);
    if (!mounted) {
      return;
    }
    final strings = CalculatorLocalization.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.t('snackbar.graphSaved'))));
  }

  Future<void> _saveHistoryItemToWorksheet(CalculatorHistoryItem item) async {
    final outcome = item.toOutcome();
    await widget.worksheetController.addCalculationBlock(
      expression: item.expression,
      angleMode: item.angleMode,
      precision: item.precision,
      numericMode: item.numericMode,
      calculationDomain: item.calculationDomain,
      unitMode: item.unitMode,
      resultFormat: item.resultFormat,
      result: WorksheetBlockResult.fromCalculationResult(outcome.result!),
    );
    if (!mounted) {
      return;
    }
    final strings = CalculatorLocalization.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.t('snackbar.historySaved'))));
  }

  void _loadGraphState(WorksheetGraphState graphState) {
    widget.controller.setExpression(graphState.buildPlotExpression());
    setState(() {
      _latestGraphState = graphState;
      _screenMode = _ScreenMode.graph;
    });
  }

  void _loadGraphTemplateExpression(String expression) {
    final state = widget.controller.state;
    final graphState = (_latestGraphState ?? _defaultGraphState(state))
        .copyWith(
          expressions: List<String>.unmodifiable(<String>[expression]),
          updatedAt: DateTime.now().toUtc(),
        );
    _loadGraphState(graphState);
  }

  CalculationContext _buildContext(CalculatorState state) {
    return CalculationContext(
      angleMode: state.angleMode,
      precision: state.precision,
      preferExactResult: state.numericMode == NumericMode.exact,
      numericMode: state.numericMode,
      calculationDomain: state.calculationDomain,
      unitMode: state.unitMode,
      numberFormatStyle: state.resultFormat,
    );
  }

  WorksheetGraphState _defaultGraphState(CalculatorState state) {
    final now = DateTime.now().toUtc();
    return WorksheetGraphState(
      id: 'graph-$now',
      title: 'Saved Graph',
      expressions: const <String>['sin(x)'],
      viewport: GraphViewport.defaultViewport(),
      autoY: true,
      showGrid: true,
      showAxes: true,
      initialSamples: 512,
      maxSamples: 4096,
      adaptiveDepth: 6,
      discontinuityThreshold: 6.0,
      minStep: 1e-4,
      angleMode: state.angleMode,
      numericMode: state.numericMode,
      calculationDomain: state.calculationDomain,
      unitMode: state.unitMode,
      resultFormat: state.resultFormat,
      precision: state.precision,
      createdAt: now,
      updatedAt: now,
    );
  }

  void _handleWorksheetChanges() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  bool _graphStateEquivalent(
    WorksheetGraphState? left,
    WorksheetGraphState right,
  ) {
    if (left == null) {
      return false;
    }
    return left.title == right.title &&
        _stringListEquals(left.expressions, right.expressions) &&
        left.viewport.xMin == right.viewport.xMin &&
        left.viewport.xMax == right.viewport.xMax &&
        left.viewport.yMin == right.viewport.yMin &&
        left.viewport.yMax == right.viewport.yMax &&
        left.autoY == right.autoY &&
        left.showGrid == right.showGrid &&
        left.showAxes == right.showAxes &&
        left.plotSeriesCount == right.plotSeriesCount &&
        left.plotPointCount == right.plotPointCount &&
        left.plotSegmentCount == right.plotSegmentCount &&
        left.lastPlotSummary == right.lastPlotSummary &&
        _stringListEquals(left.warnings, right.warnings);
  }

  bool _stringListEquals(List<String> left, List<String> right) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _openHistorySheet() async {
    final state = widget.controller.state;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          height: 460,
          child: CalculatorHistoryPanel(
            compact: true,
            items: state.history,
            onRecall: (item) {
              widget.controller.recallHistoryItem(item);
              Navigator.of(context).pop();
            },
            onDelete: (item) {
              unawaited(widget.controller.deleteHistoryItem(item));
            },
            onClearHistory: () {
              unawaited(widget.controller.clearHistory());
            },
            onSaveToWorksheet: (item) {
              unawaited(_saveHistoryItemToWorksheet(item));
            },
          ),
        );
      },
    );
  }

  Future<void> _openSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            final state = widget.controller.state;
            return CalculatorSettingsSheet(
              angleMode: state.angleMode,
              numericMode: state.numericMode,
              calculationDomain: state.calculationDomain,
              unitMode: state.unitMode,
              resultFormat: state.resultFormat,
              precision: state.precision,
              themePreference: state.settings.themePreference,
              reduceMotion: state.settings.reduceMotion,
              highContrast: state.settings.highContrast,
              language: state.settings.language,
              onAngleModeChanged: (mode) {
                unawaited(widget.controller.setAngleMode(mode));
              },
              onNumericModeChanged: (mode) {
                unawaited(widget.controller.setNumericMode(mode));
              },
              onCalculationDomainChanged: (domain) {
                unawaited(widget.controller.setCalculationDomain(domain));
              },
              onUnitModeChanged: (mode) {
                unawaited(widget.controller.setUnitMode(mode));
              },
              onResultFormatChanged: (format) {
                unawaited(widget.controller.setResultFormat(format));
              },
              onPrecisionChanged: (precision) {
                unawaited(widget.controller.setPrecision(precision));
              },
              onThemePreferenceChanged: (themePreference) {
                unawaited(
                  widget.controller.setThemePreference(themePreference),
                );
              },
              onReduceMotionChanged: (reduceMotion) {
                unawaited(widget.controller.setReduceMotion(reduceMotion));
              },
              onHighContrastChanged: (highContrast) {
                unawaited(widget.controller.setHighContrast(highContrast));
              },
              onLanguageChanged: (language) {
                unawaited(widget.controller.setLanguage(language));
              },
              onResetSettings: () {
                unawaited(widget.controller.resetSettings());
              },
              onClearWorksheets: () {
                unawaited(widget.worksheetController.clearAllWorksheets());
              },
              onLoadSampleWorksheets: () {
                unawaited(
                  widget.worksheetController.addSampleWorksheets(
                    SampleWorksheetFactory.buildSamples(),
                  ),
                );
              },
              onExportBackup: _openBackupExport,
              onRestoreBackup: _openBackupRestore,
              onOpenExamples: _openExamplesLibrary,
              onOpenHelp: _openHelpReference,
              onOpenPrivacy: _openPrivacyNotice,
              onClearHistory: () {
                unawaited(widget.controller.clearHistory());
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openCommandPalette() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final state = widget.controller.state;
        final strings = CalculatorLocalization.of(context);
        return AlertDialog(
          key: const Key('command-palette-dialog'),
          title: Text(strings.t('command.title')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _CommandTile(
                  label: strings.t('command.insertSin'),
                  icon: Icons.functions_outlined,
                  onTap: () {
                    Navigator.of(context).pop();
                    _insertFunction('sin');
                  },
                ),
                _CommandTile(
                  label: strings.t('command.insertSolve'),
                  icon: Icons.hub_outlined,
                  onTap: () {
                    Navigator.of(context).pop();
                    _insertFunction('solve');
                  },
                ),
                _CommandTile(
                  label: state.numericMode == NumericMode.exact
                      ? strings.t('command.switchApprox')
                      : strings.t('command.switchExact'),
                  icon: Icons.tune_outlined,
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(
                      widget.controller.setNumericMode(
                        state.numericMode == NumericMode.exact
                            ? NumericMode.approximate
                            : NumericMode.exact,
                      ),
                    );
                  },
                ),
                _CommandTile(
                  label: strings.t('command.openGraph'),
                  icon: CalculatorIcons.graph,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _screenMode = _ScreenMode.graph);
                  },
                ),
                _CommandTile(
                  label: strings.t('command.openWorksheet'),
                  icon: CalculatorIcons.worksheet,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _screenMode = _ScreenMode.worksheet);
                  },
                ),
                _CommandTile(
                  label: strings.t('command.openHistory'),
                  icon: CalculatorIcons.history,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _screenMode = _ScreenMode.history);
                  },
                ),
                _CommandTile(
                  label: 'Open examples',
                  icon: Icons.auto_awesome_outlined,
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(_openExamplesLibrary());
                  },
                ),
                _CommandTile(
                  label: 'Open help',
                  icon: Icons.help_outline,
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(_openHelpReference());
                  },
                ),
                _CommandTile(
                  label: strings.t('command.saveResult'),
                  icon: Icons.save_outlined,
                  onTap: state.outcome == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          unawaited(_saveCurrentResultToWorksheet());
                        },
                ),
                _CommandTile(
                  label: strings.t('command.copyResult'),
                  icon: Icons.copy_outlined,
                  onTap: state.outcome?.result == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          unawaited(
                            Clipboard.setData(
                              ClipboardData(
                                text: state.outcome!.result!.displayResult,
                              ),
                            ),
                          );
                        },
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter: evaluate   Ctrl+L: clear   Ctrl+G: graph   Ctrl+W: worksheet',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openExamplesLibrary() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return ExamplesLibraryDialog(onSelect: _applyExample);
      },
    );
  }

  void _applyExample(CalculatorExample example) {
    switch (example.target) {
      case CalculatorExampleTarget.calculator:
        widget.controller.setExpression(example.expression);
        _selectMode(_ScreenMode.calculator);
        return;
      case CalculatorExampleTarget.graph:
        widget.controller.setExpression(example.expression);
        final graphState = _defaultGraphState(widget.controller.state).copyWith(
          expressions: <String>[example.expression],
          title: example.title,
          updatedAt: DateTime.now().toUtc(),
        );
        setState(() {
          _latestGraphState = graphState;
          _screenMode = _ScreenMode.graph;
        });
        return;
      case CalculatorExampleTarget.worksheet:
        widget.controller.setExpression(example.expression);
        _selectMode(_ScreenMode.worksheet);
        return;
    }
  }

  Future<void> _openHelpReference() async {
    await showDialog<void>(
      context: context,
      builder: (context) => const HelpReferenceDialog(),
    );
  }

  Future<void> _openPrivacyNotice() async {
    await showDialog<void>(
      context: context,
      builder: (context) => const LocalDataPrivacyDialog(),
    );
  }

  Future<void> _openBackupExport() async {
    final export = _backupService.exportBackup(
      settings: widget.controller.state.settings,
      history: widget.controller.state.history,
      worksheets: widget.worksheetController.state.worksheets,
      activeWorksheetId: widget.worksheetController.state.activeWorksheetId,
    );
    await showDialog<void>(
      context: context,
      builder: (context) => BackupExportDialog(export: export),
    );
  }

  Future<void> _openBackupRestore() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return BackupRestoreDialog(
          onImport: (source) async {
            try {
              final backup = _backupService.parseBackup(source);
              await widget.controller.restoreSnapshot(
                settings: backup.settings,
                history: backup.history,
              );
              await widget.worksheetController.restoreSnapshot(
                worksheets: backup.worksheets,
                activeWorksheetId: backup.activeWorksheetId,
              );
              return null;
            } on CalculatorBackupException catch (error) {
              return error.message;
            } catch (error) {
              return 'Backup restore failed: $error';
            }
          },
        );
      },
    );
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({
    super.key,
    required this.screenMode,
    required this.isWide,
    required this.state,
    required this.latestGraphState,
    required this.worksheetController,
    required this.historyPanel,
    required this.buildContext,
    required this.onCommitPlotExpression,
    required this.onGraphStateChanged,
    required this.onSaveGraphState,
    required this.onRecallExpression,
    required this.onLoadGraphState,
    required this.onLoadGraphTemplateExpression,
  });

  final _ScreenMode screenMode;
  final bool isWide;
  final CalculatorState state;
  final WorksheetGraphState? latestGraphState;
  final WorksheetController worksheetController;
  final Widget historyPanel;
  final CalculationContext Function(CalculatorState state) buildContext;
  final ValueChanged<String> onCommitPlotExpression;
  final ValueChanged<WorksheetGraphState> onGraphStateChanged;
  final ValueChanged<WorksheetGraphState> onSaveGraphState;
  final ValueChanged<String> onRecallExpression;
  final ValueChanged<WorksheetGraphState> onLoadGraphState;
  final ValueChanged<String> onLoadGraphTemplateExpression;

  @override
  Widget build(BuildContext context) {
    return switch (screenMode) {
      _ScreenMode.calculator => const SizedBox.shrink(),
      _ScreenMode.graph => _PanelWithGap(
        child: GraphPanel(
          calculationContext: buildContext(state),
          seedExpression: state.expression,
          seedGraphState: latestGraphState,
          onCommitPlotExpression: onCommitPlotExpression,
          onGraphStateChanged: onGraphStateChanged,
          onSaveGraphState: onSaveGraphState,
        ),
      ),
      _ScreenMode.worksheet => _PanelWithGap(
        child: WorksheetPanel(
          controller: worksheetController,
          currentExpression: state.expression,
          currentOutcome: state.outcome,
          angleMode: state.angleMode,
          precision: state.precision,
          numericMode: state.numericMode,
          calculationDomain: state.calculationDomain,
          unitMode: state.unitMode,
          resultFormat: state.resultFormat,
          latestGraphState: latestGraphState,
          onRecallExpression: onRecallExpression,
          onLoadGraphState: onLoadGraphState,
          onLoadGraphTemplateExpression: onLoadGraphTemplateExpression,
        ),
      ),
      _ScreenMode.history =>
        isWide
            ? _PanelWithGap(
                child: const _ModeAssistCard(
                  icon: CalculatorIcons.history,
                  label: 'History',
                  title: 'History is pinned on the right',
                  description:
                      'Desktop history stays visible as an inspector. On compact layouts, this mode opens the same history panel inline.',
                  examples: <String>[
                    'Recall previous calculations',
                    'Save history items to worksheet',
                    'Clear old experiments safely',
                  ],
                ),
              )
            : _PanelWithGap(child: historyPanel),
      _ScreenMode.cas => const _PanelWithGap(
        child: _ModeAssistCard(
          icon: CalculatorIcons.cas,
          label: 'CAS Lite',
          title: 'Symbolic tools without leaving the calculator',
          description:
              'Use the CAS keypad category or command palette for solve, simplify, expand, factor, derivative and integral helpers.',
          examples: <String>[
            'solve(x^2 - 4 = 0, x)',
            'simplify(x + x)',
            'factor(x^2 - 4)',
          ],
        ),
      ),
      _ScreenMode.stats => const _PanelWithGap(
        child: _ModeAssistCard(
          icon: CalculatorIcons.stats,
          label: 'Statistics',
          title: 'Datasets, probability and regression',
          description:
              'The stats tools remain core-backed and now sit inside a dedicated discovery surface.',
          examples: <String>[
            'mean(data(1,2,3,4))',
            'normalCdf(1.96, 0, 1)',
            'linreg(data(1,2,3), data(2,4,6))',
          ],
        ),
      ),
      _ScreenMode.matrix => const _PanelWithGap(
        child: _ModeAssistCard(
          icon: CalculatorIcons.matrix,
          label: 'Matrix',
          title: 'Linear algebra shortcuts',
          description:
              'Matrix and vector functions keep their exact behavior while gaining a clearer mode entry point.',
          examples: <String>[
            'det([[1,2],[3,4]])',
            'inv([[1,2],[3,4]])',
            'dot(vec(1,2), vec(3,4))',
          ],
        ),
      ),
      _ScreenMode.units => const _PanelWithGap(
        child: _ModeAssistCard(
          icon: CalculatorIcons.units,
          label: 'Units',
          title: 'Unit-aware calculations',
          description:
              'Unit mode, conversions and temperature handling stay controlled by the top toolbar and settings.',
          examples: <String>[
            '3 m + 20 cm',
            'to(72 km/h, m/s)',
            'to(68 degF, degC)',
          ],
        ),
      ),
    };
  }
}

class _PanelWithGap extends StatelessWidget {
  const _PanelWithGap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        child,
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _ModeAssistCard extends StatelessWidget {
  const _ModeAssistCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.description,
    required this.examples,
  });

  final IconData icon;
  final String label;
  final String title;
  final String description;
  final List<String> examples;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = label == 'CAS Lite'
        ? SemanticColors.cas(colorScheme)
        : label == 'Statistics'
        ? SemanticColors.graph(colorScheme)
        : colorScheme.primary;

    return Semantics(
      label: '$label mode. $title',
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          borderRadius: AppRadii.card,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
              SemanticColors.containerFor(accent, theme.brightness),
            ],
          ),
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
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.16),
                  foregroundColor: accent,
                  child: Icon(icon),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: accent),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: examples
                  .map(
                    (example) => InputChip(
                      label: Text(example),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeRail extends StatelessWidget {
  const _ModeRail({required this.selectedMode, required this.onSelected});

  final _ScreenMode selectedMode;
  final ValueChanged<_ScreenMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = CalculatorLocalization.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.panel,
        child: DecoratedBox(
          key: const Key('mode-navigation-rail'),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.74),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.24),
            ),
          ),
          child: NavigationRail(
            selectedIndex: _ScreenMode.values.indexOf(selectedMode),
            onDestinationSelected: (index) {
              onSelected(_ScreenMode.values[index]);
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Icon(
                Icons.bolt_rounded,
                color: colorScheme.primary,
                semanticLabel: strings.t('semantics.modeNavigation'),
              ),
            ),
            destinations: _ScreenMode.values
                .map(
                  (mode) => NavigationRailDestination(
                    icon: Icon(mode.icon, key: Key('mode-icon-${mode.label}')),
                    selectedIcon: Icon(mode.icon),
                    label: Text(mode.localizedLabel(strings)),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _ModeBottomBar extends StatelessWidget {
  const _ModeBottomBar({required this.selectedMode, required this.onSelected});

  final _ScreenMode selectedMode;
  final ValueChanged<_ScreenMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = CalculatorLocalization.of(context);
    return SafeArea(
      top: false,
      child: Container(
        key: const Key('mode-bottom-bar'),
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadii.panel,
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.96),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
          boxShadow: AppShadows.control(colorScheme),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _ScreenMode.values
                .map(
                  (mode) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      key: Key('mode-chip-${mode.label}'),
                      avatar: Icon(mode.icon, size: 18),
                      label: Text(mode.localizedLabel(strings)),
                      selected: selectedMode == mode,
                      onSelected: (_) => onSelected(mode),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
    );
  }
}

class _TopToolbar extends StatelessWidget {
  const _TopToolbar({
    required this.state,
    required this.screenMode,
    required this.showHistoryButton,
    required this.onAngleModeChanged,
    required this.onNumericModeChanged,
    required this.onCalculationDomainChanged,
    required this.onUnitModeChanged,
    required this.onSelectScreenMode,
    required this.onOpenSettings,
    required this.onOpenHistory,
    required this.onOpenCommandPalette,
    required this.onOpenExamples,
    required this.onOpenHelp,
  });

  final CalculatorState state;
  final _ScreenMode screenMode;
  final bool showHistoryButton;
  final ValueChanged<AngleMode> onAngleModeChanged;
  final ValueChanged<NumericMode> onNumericModeChanged;
  final ValueChanged<CalculationDomain> onCalculationDomainChanged;
  final ValueChanged<UnitMode> onUnitModeChanged;
  final ValueChanged<_ScreenMode> onSelectScreenMode;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenCommandPalette;
  final VoidCallback onOpenExamples;
  final VoidCallback onOpenHelp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = CalculatorLocalization.of(context);

    return Container(
      padding: AppSpacing.compactCard,
      decoration: BoxDecoration(
        borderRadius: AppRadii.panel,
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.82),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.26),
        ),
        boxShadow: AppShadows.control(colorScheme),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<AngleMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<AngleMode>(
                value: AngleMode.degree,
                label: Text('DEG'),
              ),
              ButtonSegment<AngleMode>(
                value: AngleMode.radian,
                label: Text('RAD'),
              ),
              ButtonSegment<AngleMode>(
                value: AngleMode.gradian,
                label: Text('GRAD'),
              ),
            ],
            selected: {state.angleMode},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) {
                return;
              }
              onAngleModeChanged(selection.first);
            },
            style: ButtonStyle(
              side: WidgetStatePropertyAll(
                BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          SegmentedButton<NumericMode>(
            key: const Key('numeric-mode-toggle'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<NumericMode>(
                value: NumericMode.approximate,
                label: Text('APPROX'),
              ),
              ButtonSegment<NumericMode>(
                value: NumericMode.exact,
                label: Text('EXACT'),
              ),
            ],
            selected: {state.numericMode},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) {
                return;
              }
              onNumericModeChanged(selection.first);
            },
            style: ButtonStyle(
              side: WidgetStatePropertyAll(
                BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          SegmentedButton<CalculationDomain>(
            key: const Key('calculation-domain-toggle'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<CalculationDomain>(
                value: CalculationDomain.real,
                label: Text('REAL'),
              ),
              ButtonSegment<CalculationDomain>(
                value: CalculationDomain.complex,
                label: Text('COMPLEX'),
              ),
            ],
            selected: {state.calculationDomain},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) {
                return;
              }
              onCalculationDomainChanged(selection.first);
            },
            style: ButtonStyle(
              side: WidgetStatePropertyAll(
                BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          SegmentedButton<UnitMode>(
            key: const Key('unit-mode-toggle'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<UnitMode>(
                value: UnitMode.disabled,
                label: Text('UNITS OFF'),
              ),
              ButtonSegment<UnitMode>(
                value: UnitMode.enabled,
                label: Text('UNITS ON'),
              ),
            ],
            selected: {state.unitMode},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) {
                return;
              }
              onUnitModeChanged(selection.first);
            },
            style: ButtonStyle(
              side: WidgetStatePropertyAll(
                BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.88,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${strings.t('toolbar.precision')} ${state.precision}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.tonalIcon(
                key: const Key('graph-mode-button'),
                onPressed: () => onSelectScreenMode(
                  screenMode == _ScreenMode.graph
                      ? _ScreenMode.calculator
                      : _ScreenMode.graph,
                ),
                icon: Icon(
                  screenMode == _ScreenMode.graph
                      ? Icons.show_chart
                      : Icons.area_chart,
                ),
                label: Text(_ScreenMode.graph.localizedLabel(strings)),
              ),
              FilledButton.tonalIcon(
                key: const Key('worksheet-mode-button'),
                onPressed: () => onSelectScreenMode(
                  screenMode == _ScreenMode.worksheet
                      ? _ScreenMode.calculator
                      : _ScreenMode.worksheet,
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(_ScreenMode.worksheet.localizedLabel(strings)),
              ),
              IconButton.filledTonal(
                key: const Key('open-command-palette-button'),
                tooltip: strings.t('toolbar.openCommandPalette'),
                onPressed: onOpenCommandPalette,
                icon: const Icon(Icons.manage_search_outlined),
              ),
              IconButton.filledTonal(
                key: const Key('open-examples-button'),
                tooltip: 'Open examples',
                onPressed: onOpenExamples,
                icon: const Icon(Icons.auto_awesome_outlined),
              ),
              IconButton.filledTonal(
                key: const Key('open-help-button'),
                tooltip: 'Open help',
                onPressed: onOpenHelp,
                icon: const Icon(Icons.help_outline),
              ),
              IconButton.filledTonal(
                key: const Key('open-settings-button'),
                tooltip: strings.t('toolbar.openSettings'),
                onPressed: onOpenSettings,
                icon: const Icon(Icons.tune),
              ),
              if (showHistoryButton) ...[
                IconButton.filledTonal(
                  key: const Key('open-history-button'),
                  tooltip: strings.t('toolbar.openHistory'),
                  onPressed: onOpenHistory,
                  icon: const Icon(Icons.history),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
