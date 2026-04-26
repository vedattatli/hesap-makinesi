import 'calculator_history_item.dart';
import 'calculator_settings.dart';
import 'calculator_storage.dart';

/// Deterministic in-memory storage used by tests and previews.
class MemoryCalculatorStorage implements CalculatorStorage {
  MemoryCalculatorStorage({
    CalculatorSettings? settings,
    List<CalculatorHistoryItem>? history,
  }) : _settings = settings,
       _history = List<CalculatorHistoryItem>.from(history ?? const []);

  CalculatorSettings? _settings;
  List<CalculatorHistoryItem> _history;

  @override
  Future<List<CalculatorHistoryItem>> loadHistory() async {
    return List<CalculatorHistoryItem>.unmodifiable(_history);
  }

  @override
  Future<CalculatorSettings?> loadSettings() async {
    return _settings;
  }

  @override
  Future<void> saveHistory(List<CalculatorHistoryItem> history) async {
    _history = List<CalculatorHistoryItem>.from(history);
  }

  @override
  Future<void> saveSettings(CalculatorSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> clearHistory() async {
    _history = <CalculatorHistoryItem>[];
  }
}
