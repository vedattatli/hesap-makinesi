import '../../../core/calculator/calculator.dart';
import '../data/calculator_history_item.dart';
import '../data/calculator_settings.dart';

/// Immutable UI-facing snapshot owned by the calculator controller.
class CalculatorState {
  const CalculatorState({
    required this.expression,
    required this.cursorPosition,
    required this.outcome,
    required this.angleMode,
    required this.precision,
    required this.numericMode,
    required this.calculationDomain,
    required this.unitMode,
    required this.resultFormat,
    required this.history,
    required this.settings,
    required this.isLoading,
    required this.lastErrorMessage,
  });

  factory CalculatorState.initial() {
    return const CalculatorState(
      expression: '',
      cursorPosition: 0,
      outcome: null,
      angleMode: AngleMode.degree,
      precision: 10,
      numericMode: NumericMode.approximate,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.disabled,
      resultFormat: NumberFormatStyle.auto,
      history: <CalculatorHistoryItem>[],
      settings: CalculatorSettings.defaults,
      isLoading: false,
      lastErrorMessage: null,
    );
  }

  final String expression;
  final int cursorPosition;
  final CalculationOutcome? outcome;
  final AngleMode angleMode;
  final int precision;
  final NumericMode numericMode;
  final CalculationDomain calculationDomain;
  final UnitMode unitMode;
  final NumberFormatStyle resultFormat;
  final List<CalculatorHistoryItem> history;
  final CalculatorSettings settings;
  final bool isLoading;
  final String? lastErrorMessage;

  bool get canEvaluate => expression.trim().isNotEmpty && !isLoading;

  bool get canBackspace =>
      cursorPosition > 0 && expression.isNotEmpty && !isLoading;

  CalculationResult? get result => outcome?.result;

  CalculationError? get error => outcome?.error;

  List<String> get warnings => result?.warnings ?? const <String>[];

  CalculatorState copyWith({
    String? expression,
    int? cursorPosition,
    CalculationOutcome? outcome,
    bool clearOutcome = false,
    AngleMode? angleMode,
    int? precision,
    NumericMode? numericMode,
    CalculationDomain? calculationDomain,
    UnitMode? unitMode,
    NumberFormatStyle? resultFormat,
    List<CalculatorHistoryItem>? history,
    CalculatorSettings? settings,
    bool? isLoading,
    String? lastErrorMessage,
    bool clearLastErrorMessage = false,
  }) {
    return CalculatorState(
      expression: expression ?? this.expression,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
      angleMode: angleMode ?? this.angleMode,
      precision: precision ?? this.precision,
      numericMode: numericMode ?? this.numericMode,
      calculationDomain: calculationDomain ?? this.calculationDomain,
      unitMode: unitMode ?? this.unitMode,
      resultFormat: resultFormat ?? this.resultFormat,
      history: history ?? this.history,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      lastErrorMessage: clearLastErrorMessage
          ? null
          : (lastErrorMessage ?? this.lastErrorMessage),
    );
  }
}
