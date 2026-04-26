import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/features/calculator/data/calculator_history_item.dart';
import 'package:hesap_makinesi/features/calculator/data/calculator_settings.dart';
import 'package:hesap_makinesi/features/calculator/data/local_calculator_storage.dart';
import 'package:hesap_makinesi/features/calculator/data/memory_calculator_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleSettings = CalculatorSettings(
    angleMode: AngleMode.gradian,
    precision: 8,
    numericMode: NumericMode.exact,
    calculationDomain: CalculationDomain.real,
    unitMode: UnitMode.disabled,
    themePreference: CalculatorThemePreference.dark,
    resultFormat: NumberFormatStyle.symbolic,
    updatedAt: DateTime.utc(2026, 4, 25, 18, 45),
  );
  final sampleHistory = CalculatorHistoryItem(
    id: 'history-1',
    expression: 'sqrt(2)',
    normalizedExpression: 'sqrt(2)',
    displayResult: '√2',
    numericValue: 1.41421356237,
    angleMode: AngleMode.degree,
    precision: 10,
    isApproximate: false,
    numericMode: NumericMode.exact,
    calculationDomain: CalculationDomain.real,
    unitMode: UnitMode.disabled,
    resultFormat: NumberFormatStyle.symbolic,
    valueKind: CalculatorValueKind.symbolic,
    warnings: const <String>[],
    createdAt: DateTime.utc(2026, 4, 25, 18, 45),
    exactDisplayResult: '√2',
    symbolicDisplayResult: '√2',
    decimalDisplayResult: '1.4142135624',
  );

  test('memory storage loads and saves calculator data', () async {
    final storage = MemoryCalculatorStorage();

    await storage.saveSettings(sampleSettings);
    await storage.saveHistory([sampleHistory]);

    final restoredSettings = await storage.loadSettings();
    final restoredHistory = await storage.loadHistory();

    expect(restoredSettings?.precision, 8);
    expect(restoredSettings?.numericMode, NumericMode.exact);
    expect(restoredHistory, hasLength(1));
    expect(restoredHistory.first.valueKind, CalculatorValueKind.symbolic);
  });

  test('local file storage loads and saves calculator data', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'calculator-storage-test',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final storage = LocalCalculatorStorage(rootDirectory: tempDirectory);

    await storage.saveSettings(sampleSettings);
    await storage.saveHistory([sampleHistory]);

    final restoredSettings = await storage.loadSettings();
    final restoredHistory = await storage.loadHistory();

    expect(restoredSettings?.angleMode, AngleMode.gradian);
    expect(restoredSettings?.resultFormat, NumberFormatStyle.symbolic);
    expect(restoredHistory, hasLength(1));
    expect(restoredHistory.first.expression, 'sqrt(2)');

    await storage.clearHistory();
    expect(await storage.loadHistory(), isEmpty);
  });
}
