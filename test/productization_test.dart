import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/features/calculator/data/calculator_settings.dart';
import 'package:hesap_makinesi/features/calculator/productization/examples_library.dart';
import 'package:hesap_makinesi/features/calculator/productization/local_data_backup.dart';

void main() {
  group('CalculatorExamplesLibrary', () {
    test('contains product examples for major feature areas', () {
      final categories = CalculatorExamplesLibrary.examples
          .map((example) => example.category)
          .toSet();

      expect(
        categories,
        containsAll(<String>{
          'Basic',
          'Exact',
          'Complex',
          'Matrix',
          'Units',
          'Stats',
          'Graph',
          'Worksheet',
          'CAS-lite',
        }),
      );
    });
  });

  group('SampleWorksheetFactory', () {
    test('builds deterministic sample worksheet set', () {
      final samples = SampleWorksheetFactory.buildSamples(
        timestamp: DateTime.utc(2026, 4, 26),
      );

      expect(samples, hasLength(5));
      expect(samples.map((item) => item.id), contains('sample-trig-graph'));
      expect(samples.every((item) => item.blocks.isNotEmpty), isTrue);
    });
  });

  group('LocalDataBackupService', () {
    test('exports and parses settings and worksheets', () {
      const service = LocalDataBackupService();
      final samples = SampleWorksheetFactory.buildSamples(
        timestamp: DateTime.utc(2026, 4, 26),
      );
      final settings = CalculatorSettings.defaults.copyWith(
        highContrast: true,
        onboardingCompleted: true,
      );

      final export = service.exportBackup(
        settings: settings,
        history: const [],
        worksheets: samples,
        activeWorksheetId: samples.first.id,
        exportedAt: DateTime.utc(2026, 4, 26),
      );
      final restored = service.parseBackup(export.contentText);

      expect(export.extension, 'json');
      expect(restored.settings.highContrast, isTrue);
      expect(restored.settings.onboardingCompleted, isTrue);
      expect(restored.worksheets, hasLength(samples.length));
      expect(restored.activeWorksheetId, samples.first.id);
    });

    test('rejects corrupt imports safely', () {
      const service = LocalDataBackupService();

      expect(
        () => service.parseBackup('{oops'),
        throwsA(isA<CalculatorBackupException>()),
      );
      expect(
        () => service.parseBackup('[]'),
        throwsA(isA<CalculatorBackupException>()),
      );
    });
  });
}
