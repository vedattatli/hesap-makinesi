import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/features/calculator/data/calculator_history_item.dart';
import 'package:hesap_makinesi/features/calculator/data/calculator_settings.dart';

void main() {
  group('CalculatorHistoryItem', () {
    final item = CalculatorHistoryItem(
      id: 'history-1',
      expression: 'sqrt(2)',
      normalizedExpression: 'sqrt(2)',
      displayResult: '\u221A2',
      numericValue: 1.41421356237,
      angleMode: AngleMode.degree,
      precision: 4,
      isApproximate: false,
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.real,
      unitMode: UnitMode.disabled,
      resultFormat: NumberFormatStyle.symbolic,
      valueKind: CalculatorValueKind.symbolic,
      warnings: const <String>[],
      createdAt: DateTime.utc(2026, 4, 25, 18, 0),
      exactDisplayResult: '\u221A2',
      symbolicDisplayResult: '\u221A2',
      decimalDisplayResult: '1.4142',
    );

    test('serializes toJson and restores fromJson', () {
      final restored = CalculatorHistoryItem.fromJson(item.toJson());

      expect(restored.expression, item.expression);
      expect(restored.displayResult, item.displayResult);
      expect(restored.numericMode, NumericMode.exact);
      expect(restored.calculationDomain, CalculationDomain.real);
      expect(restored.valueKind, CalculatorValueKind.symbolic);
      expect(restored.symbolicDisplayResult, '\u221A2');
      expect(restored.decimalDisplayResult, '1.4142');
    });

    test('serializes complex history fields', () {
      final complexItem = item.copyWith(
        displayResult: 'i',
        calculationDomain: CalculationDomain.complex,
        valueKind: CalculatorValueKind.complex,
        complexDisplayResult: 'i',
        rectangularDisplayResult: 'i',
        polarDisplayResult: '1\u22201.5708 rad',
        magnitudeDisplayResult: '1',
        argumentDisplayResult: '\u03C0/2',
      );

      final restored = CalculatorHistoryItem.fromJson(complexItem.toJson());

      expect(restored.calculationDomain, CalculationDomain.complex);
      expect(restored.valueKind, CalculatorValueKind.complex);
      expect(restored.complexDisplayResult, 'i');
      expect(restored.polarDisplayResult, '1\u22201.5708 rad');
      expect(restored.argumentDisplayResult, '\u03C0/2');
    });

    test('serializes vector and matrix history fields', () {
      final vectorItem = item.copyWith(
        displayResult: '[1, 2, 3]',
        valueKind: CalculatorValueKind.vector,
        vectorDisplayResult: '[1, 2, 3]',
        shapeDisplayResult: '3 \u00D7 1',
        rowCount: 3,
        columnCount: 1,
      );
      final matrixItem = item.copyWith(
        displayResult: '[[1, 2], [3, 4]]',
        valueKind: CalculatorValueKind.matrix,
        matrixDisplayResult: '[[1, 2], [3, 4]]',
        shapeDisplayResult: '2 \u00D7 2',
        rowCount: 2,
        columnCount: 2,
      );

      final restoredVector = CalculatorHistoryItem.fromJson(
        vectorItem.toJson(),
      );
      final restoredMatrix = CalculatorHistoryItem.fromJson(
        matrixItem.toJson(),
      );

      expect(restoredVector.valueKind, CalculatorValueKind.vector);
      expect(restoredVector.vectorDisplayResult, '[1, 2, 3]');
      expect(restoredVector.shapeDisplayResult, '3 \u00D7 1');
      expect(restoredMatrix.valueKind, CalculatorValueKind.matrix);
      expect(restoredMatrix.matrixDisplayResult, '[[1, 2], [3, 4]]');
      expect(restoredMatrix.rowCount, 2);
      expect(restoredMatrix.columnCount, 2);
    });

    test('serializes unit history fields', () {
      final unitItem = item.copyWith(
        displayResult: '16/5 m',
        unitMode: UnitMode.enabled,
        valueKind: CalculatorValueKind.unit,
        unitDisplayResult: '16/5 m',
        baseUnitDisplayResult: '16/5 m',
        dimensionDisplayResult: 'L',
        conversionDisplayResult: '16/5 m',
      );

      final restored = CalculatorHistoryItem.fromJson(unitItem.toJson());

      expect(restored.unitMode, UnitMode.enabled);
      expect(restored.valueKind, CalculatorValueKind.unit);
      expect(restored.unitDisplayResult, '16/5 m');
      expect(restored.baseUnitDisplayResult, '16/5 m');
      expect(restored.dimensionDisplayResult, 'L');
      expect(restored.conversionDisplayResult, '16/5 m');
    });

    test('serializes dataset history fields', () {
      final datasetItem = item.copyWith(
        displayResult: 'data(1, 2, 3, 4)',
        valueKind: CalculatorValueKind.dataset,
        datasetDisplayResult: 'data(1, 2, 3, 4)',
        statisticsDisplayResult: 'Dataset | n = 4',
        summaryDisplayResult: 'n = 4',
        sampleSize: 4,
        statisticName: 'data',
      );

      final restored = CalculatorHistoryItem.fromJson(datasetItem.toJson());

      expect(restored.valueKind, CalculatorValueKind.dataset);
      expect(restored.datasetDisplayResult, 'data(1, 2, 3, 4)');
      expect(restored.statisticsDisplayResult, contains('Dataset'));
      expect(restored.sampleSize, 4);
      expect(restored.statisticName, 'data');
    });

    test('serializes regression and probability history fields', () {
      final regressionItem = item.copyWith(
        displayResult: 'y = 2x + 0',
        valueKind: CalculatorValueKind.regression,
        regressionDisplayResult: 'y = 2x + 0',
        summaryDisplayResult: 'r = 1, R^2 = 1, n = 3',
        sampleSize: 3,
        statisticName: 'linreg',
      );
      final probabilityItem = item.copyWith(
        displayResult: '15/128',
        probabilityDisplayResult: 'Binomial PMF',
        statisticName: 'binomPmf',
      );

      final restoredRegression = CalculatorHistoryItem.fromJson(
        regressionItem.toJson(),
      );
      final restoredProbability = CalculatorHistoryItem.fromJson(
        probabilityItem.toJson(),
      );

      expect(restoredRegression.valueKind, CalculatorValueKind.regression);
      expect(restoredRegression.regressionDisplayResult, 'y = 2x + 0');
      expect(restoredRegression.summaryDisplayResult, contains('r = 1'));
      expect(restoredRegression.sampleSize, 3);
      expect(restoredRegression.statisticName, 'linreg');

      expect(restoredProbability.probabilityDisplayResult, 'Binomial PMF');
      expect(restoredProbability.statisticName, 'binomPmf');
    });

    test('supports older json payloads with missing exact fields', () {
      final restored = CalculatorHistoryItem.fromJson(<String, dynamic>{
        'id': 'legacy-1',
        'expression': '7+8',
        'normalizedExpression': '7 + 8',
        'displayResult': '15',
        'numericValue': 15,
        'angleMode': 'degree',
        'precision': 10,
        'isApproximate': false,
        'warnings': const <String>[],
        'createdAt': '2026-04-25T18:00:00.000Z',
      });

      expect(restored.numericMode, NumericMode.approximate);
      expect(restored.calculationDomain, CalculationDomain.real);
      expect(restored.unitMode, UnitMode.disabled);
      expect(restored.resultFormat, NumberFormatStyle.auto);
      expect(restored.valueKind, CalculatorValueKind.doubleValue);
    });

    test('invalid stored JSON falls back to empty history', () {
      final restored = CalculatorHistoryItem.listFromStoredString('{oops');

      expect(restored, isEmpty);
    });

    test('history decoding stays newest first and trims to max limit', () {
      final entries = List.generate(
        105,
        (index) => item.copyWith(
          id: 'history-$index',
          createdAt: DateTime.utc(
            2026,
            4,
            25,
            18,
            0,
          ).add(Duration(minutes: index)),
        ),
      );

      final encoded = jsonEncode(
        entries.map((history) => history.toJson()).toList(growable: false),
      );
      final restored = CalculatorHistoryItem.listFromStoredString(encoded);

      expect(restored, hasLength(100));
      expect(restored.first.id, 'history-104');
      expect(restored.last.id, 'history-5');
    });

    test('serializes graph history fields', () {
      final graphItem = item.copyWith(
        valueKind: CalculatorValueKind.plot,
        displayResult: 'Plot: y = x ^ 2',
        plotDisplayResult: 'Plot: y = x ^ 2',
        graphDisplayResult: '1 series, 512 points, 2 segments',
        viewportDisplayResult: 'x ∈ [-5, 5], y ∈ [-1, 25] (autoY)',
        plotSeriesCount: 1,
        plotPointCount: 512,
        plotSegmentCount: 2,
        graphWarnings: const <String>[
          'Discontinuity detected; segments were split.',
        ],
      );

      final restored = CalculatorHistoryItem.fromJson(graphItem.toJson());

      expect(restored.valueKind, CalculatorValueKind.plot);
      expect(restored.plotDisplayResult, 'Plot: y = x ^ 2');
      expect(restored.graphDisplayResult, contains('512 points'));
      expect(restored.viewportDisplayResult, contains('x ∈'));
      expect(restored.plotSeriesCount, 1);
      expect(restored.plotPointCount, 512);
      expect(restored.plotSegmentCount, 2);
      expect(restored.graphWarnings, isNotEmpty);
    });
  });

  group('CalculatorSettings', () {
    test('serializes toJson and restores fromJson', () {
      final settings = CalculatorSettings(
        angleMode: AngleMode.gradian,
        precision: 12,
        numericMode: NumericMode.exact,
        calculationDomain: CalculationDomain.complex,
        unitMode: UnitMode.enabled,
        themePreference: CalculatorThemePreference.dark,
        resultFormat: NumberFormatStyle.symbolic,
        reduceMotion: true,
        highContrast: true,
        language: CalculatorAppLanguage.tr,
        onboardingCompleted: true,
        updatedAt: DateTime.utc(2026, 4, 25, 18, 30),
      );

      final restored = CalculatorSettings.fromJson(settings.toJson());

      expect(restored.angleMode, AngleMode.gradian);
      expect(restored.precision, 12);
      expect(restored.numericMode, NumericMode.exact);
      expect(restored.calculationDomain, CalculationDomain.complex);
      expect(restored.unitMode, UnitMode.enabled);
      expect(restored.resultFormat, NumberFormatStyle.symbolic);
      expect(restored.themePreference, CalculatorThemePreference.dark);
      expect(restored.reduceMotion, isTrue);
      expect(restored.highContrast, isTrue);
      expect(restored.language, CalculatorAppLanguage.tr);
      expect(restored.onboardingCompleted, isTrue);
    });

    test('fills defaults for missing fields in older json', () {
      final restored = CalculatorSettings.fromJson(<String, dynamic>{
        'angleMode': 'degree',
        'precision': 8,
        'themePreference': 'system',
      });

      expect(restored.numericMode, NumericMode.approximate);
      expect(restored.calculationDomain, CalculationDomain.real);
      expect(restored.unitMode, UnitMode.disabled);
      expect(restored.resultFormat, NumberFormatStyle.auto);
      expect(restored.reduceMotion, isFalse);
      expect(restored.highContrast, isFalse);
      expect(restored.language, CalculatorAppLanguage.en);
      expect(restored.onboardingCompleted, isFalse);
    });

    test('exposes default settings', () {
      expect(CalculatorSettings.defaults.angleMode, AngleMode.degree);
      expect(CalculatorSettings.defaults.precision, 10);
      expect(CalculatorSettings.defaults.numericMode, NumericMode.approximate);
      expect(
        CalculatorSettings.defaults.calculationDomain,
        CalculationDomain.real,
      );
      expect(CalculatorSettings.defaults.unitMode, UnitMode.disabled);
      expect(CalculatorSettings.defaults.resultFormat, NumberFormatStyle.auto);
      expect(
        CalculatorSettings.defaults.themePreference,
        CalculatorThemePreference.system,
      );
      expect(CalculatorSettings.defaults.reduceMotion, isFalse);
      expect(CalculatorSettings.defaults.highContrast, isFalse);
      expect(CalculatorSettings.defaults.language, CalculatorAppLanguage.en);
      expect(CalculatorSettings.defaults.onboardingCompleted, isFalse);
    });

    test('invalid stored JSON falls back to defaults', () {
      final restored = CalculatorSettings.fromStoredString('{oops');

      expect(restored.angleMode, CalculatorSettings.defaults.angleMode);
      expect(restored.precision, CalculatorSettings.defaults.precision);
      expect(restored.numericMode, CalculatorSettings.defaults.numericMode);
      expect(
        restored.calculationDomain,
        CalculatorSettings.defaults.calculationDomain,
      );
      expect(restored.unitMode, CalculatorSettings.defaults.unitMode);
      expect(restored.resultFormat, CalculatorSettings.defaults.resultFormat);
      expect(
        restored.themePreference,
        CalculatorSettings.defaults.themePreference,
      );
      expect(restored.reduceMotion, CalculatorSettings.defaults.reduceMotion);
      expect(restored.highContrast, CalculatorSettings.defaults.highContrast);
      expect(restored.language, CalculatorSettings.defaults.language);
      expect(
        restored.onboardingCompleted,
        CalculatorSettings.defaults.onboardingCompleted,
      );
    });
  });
}
