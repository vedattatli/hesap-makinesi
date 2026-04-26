import 'calculator_history_item.dart';
import 'calculator_settings.dart';

/// Persistence boundary used by the calculator controller.
abstract class CalculatorStorage {
  Future<CalculatorSettings?> loadSettings();

  Future<void> saveSettings(CalculatorSettings settings);

  Future<List<CalculatorHistoryItem>> loadHistory();

  Future<void> saveHistory(List<CalculatorHistoryItem> history);

  Future<void> clearHistory();
}
