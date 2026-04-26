import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/calculator/calculator.dart';
import '../data/calculator_history_item.dart';
import '../data/calculator_settings.dart';
import '../data/calculator_storage.dart';
import 'calculator_state.dart';

const _multiplySymbol = '\u00D7';
const _precisionMin = 2;
const _precisionMax = 16;

/// Coordinates calculator editing, evaluation, settings and history flows.
class CalculatorController extends ChangeNotifier {
  CalculatorController({
    required CalculatorStorage storage,
    CalculatorEngine engine = const CalculatorEngine(),
    int historyLimit = 100,
  }) : _storage = storage,
       _engine = engine,
       _historyLimit = historyLimit,
       _state = CalculatorState.initial();

  final CalculatorStorage _storage;
  final CalculatorEngine _engine;
  final int _historyLimit;

  CalculatorState _state;
  bool _initialized = false;

  CalculatorState get state => _state;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _updateState(_state.copyWith(isLoading: true));

    final settings =
        await _storage.loadSettings() ?? CalculatorSettings.defaults;
    final history = _sanitizeHistory(await _storage.loadHistory());

    _updateState(
      _state.copyWith(
        settings: settings,
        angleMode: settings.angleMode,
        precision: settings.precision,
        numericMode: settings.numericMode,
        calculationDomain: settings.calculationDomain,
        unitMode: settings.unitMode,
        resultFormat: settings.resultFormat,
        history: history,
        isLoading: false,
        clearLastErrorMessage: true,
      ),
    );
  }

  void insertText(String text) {
    if (text.isEmpty) {
      return;
    }

    final nextExpression = _state.expression.replaceRange(
      _state.cursorPosition,
      _state.cursorPosition,
      text,
    );
    final nextCursor = _state.cursorPosition + text.length;
    _applyEditedExpression(nextExpression, nextCursor);
  }

  void insertFunction(String functionName) {
    final valuePrefix = _shouldImplicitlyMultiplyBeforeCursor()
        ? _multiplySymbol
        : '';
    insertText('$valuePrefix$functionName(');
  }

  void insertOperator(String operatorText) {
    final expression = _state.expression;
    final cursor = _state.cursorPosition;

    if (expression.isEmpty || cursor == 0) {
      if (operatorText == '-') {
        insertText(operatorText);
      }
      return;
    }

    final previousCharacter = expression[cursor - 1];
    if (previousCharacter == '(' && operatorText != '-') {
      return;
    }

    if (_isOperator(previousCharacter)) {
      final nextExpression = expression.replaceRange(
        cursor - 1,
        cursor,
        operatorText,
      );
      _applyEditedExpression(nextExpression, cursor);
      return;
    }

    if (previousCharacter == '.') {
      return;
    }

    insertText(operatorText);
  }

  void backspace() {
    if (!state.canBackspace) {
      return;
    }

    final nextExpression = _state.expression.replaceRange(
      _state.cursorPosition - 1,
      _state.cursorPosition,
      '',
    );
    _applyEditedExpression(nextExpression, _state.cursorPosition - 1);
  }

  void clearExpression() {
    _updateState(
      _state.copyWith(
        expression: '',
        cursorPosition: 0,
        clearOutcome: _state.outcome?.isFailure ?? false,
        clearLastErrorMessage: true,
      ),
    );
  }

  void clearAll() {
    _updateState(
      _state.copyWith(
        expression: '',
        cursorPosition: 0,
        clearOutcome: true,
        clearLastErrorMessage: true,
      ),
    );
  }

  void moveCursorLeft() {
    if (_state.cursorPosition == 0) {
      return;
    }

    _updateState(_state.copyWith(cursorPosition: _state.cursorPosition - 1));
  }

  void moveCursorRight() {
    if (_state.cursorPosition >= _state.expression.length) {
      return;
    }

    _updateState(_state.copyWith(cursorPosition: _state.cursorPosition + 1));
  }

  void setExpression(String expression, {int? cursorPosition}) {
    final safeCursor = (cursorPosition ?? expression.length).clamp(
      0,
      expression.length,
    );
    _applyEditedExpression(expression, safeCursor);
  }

  Future<void> evaluate() async {
    if (!state.canEvaluate) {
      return;
    }

    await _evaluateCurrentExpression(recordHistory: true);
  }

  Future<void> setAngleMode(AngleMode mode) async {
    if (_state.angleMode == mode) {
      return;
    }

    final settings = _state.settings.copyWith(
      angleMode: mode,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(
        angleMode: mode,
        settings: settings,
        clearLastErrorMessage: true,
      ),
    );
    await _storage.saveSettings(settings);

    if (_state.canEvaluate) {
      await _evaluateCurrentExpression(recordHistory: false);
    }
  }

  Future<void> setPrecision(int precision) async {
    final safePrecision = precision.clamp(_precisionMin, _precisionMax);
    if (_state.precision == safePrecision) {
      return;
    }

    final settings = _state.settings.copyWith(
      precision: safePrecision,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(
        precision: safePrecision,
        settings: settings,
        clearLastErrorMessage: true,
      ),
    );
    await _storage.saveSettings(settings);

    if (_state.canEvaluate) {
      await _evaluateCurrentExpression(recordHistory: false);
    }
  }

  Future<void> setNumericMode(NumericMode mode) async {
    if (_state.numericMode == mode) {
      return;
    }

    final settings = _state.settings.copyWith(
      numericMode: mode,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(
        numericMode: mode,
        settings: settings,
        clearLastErrorMessage: true,
      ),
    );
    await _storage.saveSettings(settings);

    if (_state.canEvaluate) {
      await _evaluateCurrentExpression(recordHistory: false);
    }
  }

  Future<void> setCalculationDomain(CalculationDomain domain) async {
    if (_state.calculationDomain == domain) {
      return;
    }

    final settings = _state.settings.copyWith(
      calculationDomain: domain,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(
        calculationDomain: domain,
        settings: settings,
        clearLastErrorMessage: true,
      ),
    );
    await _storage.saveSettings(settings);

    if (_state.canEvaluate) {
      await _evaluateCurrentExpression(recordHistory: false);
    }
  }

  Future<void> setUnitMode(UnitMode mode) async {
    if (_state.unitMode == mode) {
      return;
    }

    final settings = _state.settings.copyWith(
      unitMode: mode,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(
        unitMode: mode,
        settings: settings,
        clearLastErrorMessage: true,
      ),
    );
    await _storage.saveSettings(settings);

    if (_state.canEvaluate) {
      await _evaluateCurrentExpression(recordHistory: false);
    }
  }

  Future<void> setResultFormat(NumberFormatStyle format) async {
    if (_state.resultFormat == format) {
      return;
    }

    final settings = _state.settings.copyWith(
      resultFormat: format,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(
        resultFormat: format,
        settings: settings,
        clearLastErrorMessage: true,
      ),
    );
    await _storage.saveSettings(settings);

    if (_state.canEvaluate) {
      await _evaluateCurrentExpression(recordHistory: false);
    }
  }

  Future<void> setThemePreference(
    CalculatorThemePreference themePreference,
  ) async {
    if (_state.settings.themePreference == themePreference) {
      return;
    }

    final settings = _state.settings.copyWith(
      themePreference: themePreference,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(settings: settings, clearLastErrorMessage: true),
    );
    await _storage.saveSettings(settings);
  }

  Future<void> setReduceMotion(bool reduceMotion) async {
    if (_state.settings.reduceMotion == reduceMotion) {
      return;
    }

    final settings = _state.settings.copyWith(
      reduceMotion: reduceMotion,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(settings: settings, clearLastErrorMessage: true),
    );
    await _storage.saveSettings(settings);
  }

  Future<void> setHighContrast(bool highContrast) async {
    if (_state.settings.highContrast == highContrast) {
      return;
    }

    final settings = _state.settings.copyWith(
      highContrast: highContrast,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(settings: settings, clearLastErrorMessage: true),
    );
    await _storage.saveSettings(settings);
  }

  Future<void> setLanguage(CalculatorAppLanguage language) async {
    if (_state.settings.language == language) {
      return;
    }

    final settings = _state.settings.copyWith(
      language: language,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(settings: settings, clearLastErrorMessage: true),
    );
    await _storage.saveSettings(settings);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    if (_state.settings.onboardingCompleted == completed) {
      return;
    }

    final settings = _state.settings.copyWith(
      onboardingCompleted: completed,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(settings: settings, clearLastErrorMessage: true),
    );
    await _storage.saveSettings(settings);
  }

  Future<void> resetSettings({bool preserveOnboarding = true}) async {
    final settings = CalculatorSettings.defaults.copyWith(
      onboardingCompleted: preserveOnboarding
          ? _state.settings.onboardingCompleted
          : CalculatorSettings.defaults.onboardingCompleted,
      updatedAt: DateTime.now().toUtc(),
    );
    _updateState(
      _state.copyWith(
        angleMode: settings.angleMode,
        precision: settings.precision,
        numericMode: settings.numericMode,
        calculationDomain: settings.calculationDomain,
        unitMode: settings.unitMode,
        resultFormat: settings.resultFormat,
        settings: settings,
        clearLastErrorMessage: true,
      ),
    );
    await _storage.saveSettings(settings);
  }

  Future<void> restoreSnapshot({
    required CalculatorSettings settings,
    required List<CalculatorHistoryItem> history,
  }) async {
    final sanitizedHistory = _sanitizeHistory(history);
    _updateState(
      _state.copyWith(
        angleMode: settings.angleMode,
        precision: settings.precision,
        numericMode: settings.numericMode,
        calculationDomain: settings.calculationDomain,
        unitMode: settings.unitMode,
        resultFormat: settings.resultFormat,
        settings: settings.copyWith(updatedAt: DateTime.now().toUtc()),
        history: sanitizedHistory,
        clearLastErrorMessage: true,
      ),
    );
    await _storage.saveSettings(_state.settings);
    await _storage.saveHistory(sanitizedHistory);
  }

  void recallHistoryItem(CalculatorHistoryItem item) {
    final nextSettings = _state.settings.copyWith(
      angleMode: item.angleMode,
      precision: item.precision,
      numericMode: item.numericMode,
      calculationDomain: item.calculationDomain,
      unitMode: item.unitMode,
      resultFormat: item.resultFormat,
    );
    _updateState(
      _state.copyWith(
        expression: item.expression,
        cursorPosition: item.expression.length,
        outcome: item.toOutcome(),
        angleMode: item.angleMode,
        precision: item.precision,
        numericMode: item.numericMode,
        calculationDomain: item.calculationDomain,
        unitMode: item.unitMode,
        resultFormat: item.resultFormat,
        settings: nextSettings,
        clearLastErrorMessage: true,
      ),
    );
  }

  Future<void> deleteHistoryItem(CalculatorHistoryItem item) async {
    final nextHistory = _state.history
        .where((historyItem) => historyItem.id != item.id)
        .toList(growable: false);
    _updateState(_state.copyWith(history: nextHistory));
    await _storage.saveHistory(nextHistory);
  }

  Future<void> clearHistory() async {
    _updateState(_state.copyWith(history: const <CalculatorHistoryItem>[]));
    await _storage.clearHistory();
  }

  Future<void> _evaluateCurrentExpression({required bool recordHistory}) async {
    final outcome = _engine.evaluate(
      _state.expression,
      context: _buildContext(),
    );

    if (outcome.isSuccess) {
      var nextHistory = _state.history;
      if (recordHistory) {
        nextHistory = _recordHistory(outcome.result!);
        await _storage.saveHistory(nextHistory);
      }

      _updateState(
        _state.copyWith(
          outcome: outcome,
          history: nextHistory,
          clearLastErrorMessage: true,
        ),
      );
      return;
    }

    _updateState(
      _state.copyWith(
        outcome: outcome,
        lastErrorMessage: outcome.error?.message,
      ),
    );
  }

  CalculationContext _buildContext() {
    return CalculationContext(
      angleMode: _state.angleMode,
      precision: _state.precision,
      preferExactResult: _state.numericMode == NumericMode.exact,
      numericMode: _state.numericMode,
      calculationDomain: _state.calculationDomain,
      unitMode: _state.unitMode,
      numberFormatStyle: _state.resultFormat,
    );
  }

  List<CalculatorHistoryItem> _recordHistory(CalculationResult result) {
    final timestamp = DateTime.now().toUtc();
    final nextItem = CalculatorHistoryItem(
      id: '${timestamp.microsecondsSinceEpoch}-${_state.history.length}-${_state.numericMode.name}-${result.displayResult}',
      expression: _state.expression,
      normalizedExpression: result.normalizedExpression,
      displayResult: result.displayResult,
      numericValue: result.numericValue,
      angleMode: _state.angleMode,
      precision: _state.precision,
      isApproximate: result.isApproximate,
      numericMode: _state.numericMode,
      calculationDomain: _state.calculationDomain,
      unitMode: _state.unitMode,
      resultFormat: _state.resultFormat,
      valueKind: result.valueKind,
      warnings: List<String>.from(result.warnings),
      createdAt: timestamp,
      exactDisplayResult: result.exactDisplayResult,
      symbolicDisplayResult: result.symbolicDisplayResult,
      decimalDisplayResult: result.decimalDisplayResult,
      fractionDisplayResult: result.fractionDisplayResult,
      complexDisplayResult: result.complexDisplayResult,
      rectangularDisplayResult: result.rectangularDisplayResult,
      polarDisplayResult: result.polarDisplayResult,
      magnitudeDisplayResult: result.magnitudeDisplayResult,
      argumentDisplayResult: result.argumentDisplayResult,
      functionDisplayResult: result.functionDisplayResult,
      plotDisplayResult: result.plotDisplayResult,
      graphDisplayResult: result.graphDisplayResult,
      equationDisplayResult: result.equationDisplayResult,
      solveDisplayResult: result.solveDisplayResult,
      solutionsDisplayResult: result.solutionsDisplayResult,
      derivativeDisplayResult: result.derivativeDisplayResult,
      integralDisplayResult: result.integralDisplayResult,
      transformDisplayResult: result.transformDisplayResult,
      traceDisplayResult: result.traceDisplayResult,
      rootDisplayResult: result.rootDisplayResult,
      intersectionDisplayResult: result.intersectionDisplayResult,
      datasetDisplayResult: result.datasetDisplayResult,
      statisticsDisplayResult: result.statisticsDisplayResult,
      regressionDisplayResult: result.regressionDisplayResult,
      probabilityDisplayResult: result.probabilityDisplayResult,
      summaryDisplayResult: result.summaryDisplayResult,
      vectorDisplayResult: result.vectorDisplayResult,
      matrixDisplayResult: result.matrixDisplayResult,
      unitDisplayResult: result.unitDisplayResult,
      baseUnitDisplayResult: result.baseUnitDisplayResult,
      dimensionDisplayResult: result.dimensionDisplayResult,
      conversionDisplayResult: result.conversionDisplayResult,
      shapeDisplayResult: result.shapeDisplayResult,
      rowCount: result.rowCount,
      columnCount: result.columnCount,
      sampleSize: result.sampleSize,
      statisticName: result.statisticName,
      plotSeriesCount: result.plotSeriesCount,
      plotPointCount: result.plotPointCount,
      plotSegmentCount: result.plotSegmentCount,
      solutionCount: result.solutionCount,
      solveVariable: result.solveVariable,
      solveMethod: result.solveMethod,
      solveDomain: result.solveDomain,
      viewportDisplayResult: result.viewportDisplayResult,
      graphWarnings: List<String>.from(result.graphWarnings),
    );

    final history = <CalculatorHistoryItem>[nextItem];
    for (final existing in _state.history) {
      if (existing.id == nextItem.id) {
        continue;
      }
      if (nextItem.isDuplicateOf(existing)) {
        continue;
      }
      history.add(existing);
      if (history.length >= _historyLimit) {
        break;
      }
    }

    return List<CalculatorHistoryItem>.unmodifiable(history);
  }

  List<CalculatorHistoryItem> _sanitizeHistory(
    List<CalculatorHistoryItem> history,
  ) {
    final sanitized = List<CalculatorHistoryItem>.from(history)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    if (sanitized.length > _historyLimit) {
      sanitized.removeRange(_historyLimit, sanitized.length);
    }
    return List<CalculatorHistoryItem>.unmodifiable(sanitized);
  }

  void _applyEditedExpression(String expression, int cursorPosition) {
    _updateState(
      _state.copyWith(
        expression: expression,
        cursorPosition: cursorPosition.clamp(0, expression.length),
        clearOutcome: _state.outcome?.isFailure ?? false,
        clearLastErrorMessage: true,
      ),
    );
  }

  bool _shouldImplicitlyMultiplyBeforeCursor() {
    if (_state.cursorPosition == 0 || _state.expression.isEmpty) {
      return false;
    }

    final previousCharacter = _state.expression[_state.cursorPosition - 1];
    return _isDigit(previousCharacter) ||
        previousCharacter == ')' ||
        previousCharacter == 'e' ||
        previousCharacter == 'π' ||
        previousCharacter == 'i';
  }

  bool _isDigit(String value) => '0123456789'.contains(value);

  bool _isOperator(String value) {
    return value == '+' ||
        value == '-' ||
        value == '*' ||
        value == '/' ||
        value == _multiplySymbol ||
        value == '\u00F7' ||
        value == '^';
  }

  void _updateState(CalculatorState nextState) {
    _state = nextState;
    notifyListeners();
  }
}
