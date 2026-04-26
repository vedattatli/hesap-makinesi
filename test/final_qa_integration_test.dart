import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/features/calculator/application/calculator_controller.dart';
import 'package:hesap_makinesi/features/calculator/data/memory_calculator_storage.dart';
import 'package:hesap_makinesi/features/calculator/productization/local_data_backup.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/memory_worksheet_storage.dart';
import 'package:hesap_makinesi/features/calculator/worksheet/worksheet_controller.dart';

void main() {
  group('Final QA integration flows', () {
    test('calculate save solve export backup flow remains coherent', () async {
      final calculator = CalculatorController(
        storage: MemoryCalculatorStorage(),
      );
      final worksheet = WorksheetController(storage: MemoryWorksheetStorage());
      const backup = LocalDataBackupService();

      await calculator.initialize();
      await worksheet.initialize();
      await calculator.setNumericMode(NumericMode.exact);
      calculator.setExpression('1/3 + 1/6');
      await calculator.evaluate();

      expect(calculator.state.outcome?.result?.displayResult, '1/2');

      await worksheet.createWorksheet('Release QA');
      final saved = await worksheet.saveCurrentCalculationResultAsBlock(
        expression: calculator.state.expression,
        outcome: calculator.state.outcome!,
        angleMode: calculator.state.settings.angleMode,
        precision: calculator.state.settings.precision,
        numericMode: calculator.state.settings.numericMode,
        calculationDomain: calculator.state.settings.calculationDomain,
        unitMode: calculator.state.settings.unitMode,
        resultFormat: calculator.state.settings.resultFormat,
      );
      await worksheet.addVariableDefinitionBlock(
        'a',
        '2',
        numericMode: NumericMode.exact,
      );
      await worksheet.addSolveBlock(
        equationExpression: 'a*x + 4 = 0',
        variableName: 'x',
        numericMode: NumericMode.exact,
      );

      await worksheet.runAllBlocks();

      final blocks = worksheet.state.activeWorksheet!.blocks;
      expect(blocks.first.id, saved.id);
      expect(blocks.first.result?.displayResult, '1/2');
      expect(blocks[1].result?.displayResult, '2');
      expect(blocks[2].result?.displayResult, 'x = -2');

      final markdown = await worksheet.exportWorksheetMarkdown(
        worksheet.state.activeWorksheet!.id,
      );
      expect(markdown.contentText, contains('# Release QA'));
      expect(markdown.contentText, contains('a = 2'));
      expect(markdown.contentText, contains('x = -2'));

      final backupExport = backup.exportBackup(
        settings: calculator.state.settings,
        history: calculator.state.history,
        worksheets: worksheet.state.worksheets,
        activeWorksheetId: worksheet.state.activeWorksheetId,
        exportedAt: DateTime.utc(2026, 4, 26),
      );
      final restored = backup.parseBackup(backupExport.contentText);

      expect(restored.settings.numericMode, NumericMode.exact);
      expect(restored.worksheets.single.title, 'Release QA');
      expect(restored.worksheets.single.blocks, hasLength(3));

      final globalOutcome = const CalculatorEngine().evaluate('a + 1');
      expect(globalOutcome.error, isNotNull);
      expect(
        globalOutcome.error?.type,
        isNot(CalculationErrorType.internalError),
      );
    });
  });
}
