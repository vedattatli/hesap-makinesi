import 'dart:convert';

import '../../../core/calculator/calculator.dart';

/// Serialized representation of a successful calculation history entry.
class CalculatorHistoryItem {
  const CalculatorHistoryItem({
    required this.id,
    required this.expression,
    required this.normalizedExpression,
    required this.displayResult,
    required this.numericValue,
    required this.angleMode,
    required this.precision,
    required this.isApproximate,
    required this.numericMode,
    required this.calculationDomain,
    required this.unitMode,
    required this.resultFormat,
    required this.valueKind,
    required this.warnings,
    required this.createdAt,
    this.exactDisplayResult,
    this.symbolicDisplayResult,
    this.decimalDisplayResult,
    this.fractionDisplayResult,
    this.complexDisplayResult,
    this.rectangularDisplayResult,
    this.polarDisplayResult,
    this.magnitudeDisplayResult,
    this.argumentDisplayResult,
    this.functionDisplayResult,
    this.plotDisplayResult,
    this.graphDisplayResult,
    this.equationDisplayResult,
    this.solveDisplayResult,
    this.solutionsDisplayResult,
    this.derivativeDisplayResult,
    this.integralDisplayResult,
    this.transformDisplayResult,
    this.traceDisplayResult,
    this.rootDisplayResult,
    this.intersectionDisplayResult,
    this.datasetDisplayResult,
    this.statisticsDisplayResult,
    this.regressionDisplayResult,
    this.probabilityDisplayResult,
    this.summaryDisplayResult,
    this.vectorDisplayResult,
    this.matrixDisplayResult,
    this.unitDisplayResult,
    this.baseUnitDisplayResult,
    this.dimensionDisplayResult,
    this.conversionDisplayResult,
    this.shapeDisplayResult,
    this.rowCount,
    this.columnCount,
    this.sampleSize,
    this.statisticName,
    this.plotSeriesCount,
    this.plotPointCount,
    this.plotSegmentCount,
    this.solutionCount,
    this.solveVariable,
    this.solveMethod,
    this.solveDomain,
    this.viewportDisplayResult,
    this.graphWarnings = const <String>[],
    this.isFavorite = false,
  });

  final String id;
  final String expression;
  final String normalizedExpression;
  final String displayResult;
  final double? numericValue;
  final AngleMode angleMode;
  final int precision;
  final bool isApproximate;
  final NumericMode numericMode;
  final CalculationDomain calculationDomain;
  final UnitMode unitMode;
  final NumberFormatStyle resultFormat;
  final CalculatorValueKind valueKind;
  final List<String> warnings;
  final DateTime createdAt;
  final String? exactDisplayResult;
  final String? symbolicDisplayResult;
  final String? decimalDisplayResult;
  final String? fractionDisplayResult;
  final String? complexDisplayResult;
  final String? rectangularDisplayResult;
  final String? polarDisplayResult;
  final String? magnitudeDisplayResult;
  final String? argumentDisplayResult;
  final String? functionDisplayResult;
  final String? plotDisplayResult;
  final String? graphDisplayResult;
  final String? equationDisplayResult;
  final String? solveDisplayResult;
  final String? solutionsDisplayResult;
  final String? derivativeDisplayResult;
  final String? integralDisplayResult;
  final String? transformDisplayResult;
  final String? traceDisplayResult;
  final String? rootDisplayResult;
  final String? intersectionDisplayResult;
  final String? datasetDisplayResult;
  final String? statisticsDisplayResult;
  final String? regressionDisplayResult;
  final String? probabilityDisplayResult;
  final String? summaryDisplayResult;
  final String? vectorDisplayResult;
  final String? matrixDisplayResult;
  final String? unitDisplayResult;
  final String? baseUnitDisplayResult;
  final String? dimensionDisplayResult;
  final String? conversionDisplayResult;
  final String? shapeDisplayResult;
  final int? rowCount;
  final int? columnCount;
  final int? sampleSize;
  final String? statisticName;
  final int? plotSeriesCount;
  final int? plotPointCount;
  final int? plotSegmentCount;
  final int? solutionCount;
  final String? solveVariable;
  final String? solveMethod;
  final String? solveDomain;
  final String? viewportDisplayResult;
  final List<String> graphWarnings;
  final bool isFavorite;

  CalculatorHistoryItem copyWith({
    String? id,
    String? expression,
    String? normalizedExpression,
    String? displayResult,
    double? numericValue,
    AngleMode? angleMode,
    int? precision,
    bool? isApproximate,
    NumericMode? numericMode,
    CalculationDomain? calculationDomain,
    UnitMode? unitMode,
    NumberFormatStyle? resultFormat,
    CalculatorValueKind? valueKind,
    List<String>? warnings,
    DateTime? createdAt,
    String? exactDisplayResult,
    String? symbolicDisplayResult,
    String? decimalDisplayResult,
    String? fractionDisplayResult,
    String? complexDisplayResult,
    String? rectangularDisplayResult,
    String? polarDisplayResult,
    String? magnitudeDisplayResult,
    String? argumentDisplayResult,
    String? functionDisplayResult,
    String? plotDisplayResult,
    String? graphDisplayResult,
    String? equationDisplayResult,
    String? solveDisplayResult,
    String? solutionsDisplayResult,
    String? derivativeDisplayResult,
    String? integralDisplayResult,
    String? transformDisplayResult,
    String? traceDisplayResult,
    String? rootDisplayResult,
    String? intersectionDisplayResult,
    String? datasetDisplayResult,
    String? statisticsDisplayResult,
    String? regressionDisplayResult,
    String? probabilityDisplayResult,
    String? summaryDisplayResult,
    String? vectorDisplayResult,
    String? matrixDisplayResult,
    String? unitDisplayResult,
    String? baseUnitDisplayResult,
    String? dimensionDisplayResult,
    String? conversionDisplayResult,
    String? shapeDisplayResult,
    int? rowCount,
    int? columnCount,
    int? sampleSize,
    String? statisticName,
    int? plotSeriesCount,
    int? plotPointCount,
    int? plotSegmentCount,
    int? solutionCount,
    String? solveVariable,
    String? solveMethod,
    String? solveDomain,
    String? viewportDisplayResult,
    List<String>? graphWarnings,
    bool? isFavorite,
  }) {
    return CalculatorHistoryItem(
      id: id ?? this.id,
      expression: expression ?? this.expression,
      normalizedExpression: normalizedExpression ?? this.normalizedExpression,
      displayResult: displayResult ?? this.displayResult,
      numericValue: numericValue ?? this.numericValue,
      angleMode: angleMode ?? this.angleMode,
      precision: precision ?? this.precision,
      isApproximate: isApproximate ?? this.isApproximate,
      numericMode: numericMode ?? this.numericMode,
      calculationDomain: calculationDomain ?? this.calculationDomain,
      unitMode: unitMode ?? this.unitMode,
      resultFormat: resultFormat ?? this.resultFormat,
      valueKind: valueKind ?? this.valueKind,
      warnings: warnings ?? this.warnings,
      createdAt: createdAt ?? this.createdAt,
      exactDisplayResult: exactDisplayResult ?? this.exactDisplayResult,
      symbolicDisplayResult:
          symbolicDisplayResult ?? this.symbolicDisplayResult,
      decimalDisplayResult: decimalDisplayResult ?? this.decimalDisplayResult,
      fractionDisplayResult:
          fractionDisplayResult ?? this.fractionDisplayResult,
      complexDisplayResult: complexDisplayResult ?? this.complexDisplayResult,
      rectangularDisplayResult:
          rectangularDisplayResult ?? this.rectangularDisplayResult,
      polarDisplayResult: polarDisplayResult ?? this.polarDisplayResult,
      magnitudeDisplayResult:
          magnitudeDisplayResult ?? this.magnitudeDisplayResult,
      argumentDisplayResult:
          argumentDisplayResult ?? this.argumentDisplayResult,
      functionDisplayResult:
          functionDisplayResult ?? this.functionDisplayResult,
      plotDisplayResult: plotDisplayResult ?? this.plotDisplayResult,
      graphDisplayResult: graphDisplayResult ?? this.graphDisplayResult,
      equationDisplayResult:
          equationDisplayResult ?? this.equationDisplayResult,
      solveDisplayResult: solveDisplayResult ?? this.solveDisplayResult,
      solutionsDisplayResult:
          solutionsDisplayResult ?? this.solutionsDisplayResult,
      derivativeDisplayResult:
          derivativeDisplayResult ?? this.derivativeDisplayResult,
      integralDisplayResult:
          integralDisplayResult ?? this.integralDisplayResult,
      transformDisplayResult:
          transformDisplayResult ?? this.transformDisplayResult,
      traceDisplayResult: traceDisplayResult ?? this.traceDisplayResult,
      rootDisplayResult: rootDisplayResult ?? this.rootDisplayResult,
      intersectionDisplayResult:
          intersectionDisplayResult ?? this.intersectionDisplayResult,
      datasetDisplayResult: datasetDisplayResult ?? this.datasetDisplayResult,
      statisticsDisplayResult:
          statisticsDisplayResult ?? this.statisticsDisplayResult,
      regressionDisplayResult:
          regressionDisplayResult ?? this.regressionDisplayResult,
      probabilityDisplayResult:
          probabilityDisplayResult ?? this.probabilityDisplayResult,
      summaryDisplayResult: summaryDisplayResult ?? this.summaryDisplayResult,
      vectorDisplayResult: vectorDisplayResult ?? this.vectorDisplayResult,
      matrixDisplayResult: matrixDisplayResult ?? this.matrixDisplayResult,
      unitDisplayResult: unitDisplayResult ?? this.unitDisplayResult,
      baseUnitDisplayResult:
          baseUnitDisplayResult ?? this.baseUnitDisplayResult,
      dimensionDisplayResult:
          dimensionDisplayResult ?? this.dimensionDisplayResult,
      conversionDisplayResult:
          conversionDisplayResult ?? this.conversionDisplayResult,
      shapeDisplayResult: shapeDisplayResult ?? this.shapeDisplayResult,
      rowCount: rowCount ?? this.rowCount,
      columnCount: columnCount ?? this.columnCount,
      sampleSize: sampleSize ?? this.sampleSize,
      statisticName: statisticName ?? this.statisticName,
      plotSeriesCount: plotSeriesCount ?? this.plotSeriesCount,
      plotPointCount: plotPointCount ?? this.plotPointCount,
      plotSegmentCount: plotSegmentCount ?? this.plotSegmentCount,
      solutionCount: solutionCount ?? this.solutionCount,
      solveVariable: solveVariable ?? this.solveVariable,
      solveMethod: solveMethod ?? this.solveMethod,
      solveDomain: solveDomain ?? this.solveDomain,
      viewportDisplayResult:
          viewportDisplayResult ?? this.viewportDisplayResult,
      graphWarnings: graphWarnings ?? this.graphWarnings,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  CalculationOutcome toOutcome() {
    final alternativeResults = <String, String>{};
    if (fractionDisplayResult != null) {
      alternativeResults['fraction'] = fractionDisplayResult!;
    }
    if (symbolicDisplayResult != null) {
      alternativeResults['symbolic'] = symbolicDisplayResult!;
    }
    if (decimalDisplayResult != null) {
      alternativeResults['decimal'] = decimalDisplayResult!;
    }
    if (complexDisplayResult != null) {
      alternativeResults['complex'] = complexDisplayResult!;
    }
    if (polarDisplayResult != null) {
      alternativeResults['polar'] = polarDisplayResult!;
    }
    if (magnitudeDisplayResult != null) {
      alternativeResults['magnitude'] = magnitudeDisplayResult!;
    }
    if (argumentDisplayResult != null) {
      alternativeResults['argument'] = argumentDisplayResult!;
    }
    if (functionDisplayResult != null) {
      alternativeResults['function'] = functionDisplayResult!;
    }
    if (plotDisplayResult != null) {
      alternativeResults['plot'] = plotDisplayResult!;
    }
    if (graphDisplayResult != null) {
      alternativeResults['graph'] = graphDisplayResult!;
    }
    if (equationDisplayResult != null) {
      alternativeResults['equation'] = equationDisplayResult!;
    }
    if (solveDisplayResult != null) {
      alternativeResults['solve'] = solveDisplayResult!;
    }
    if (solutionsDisplayResult != null) {
      alternativeResults['solutions'] = solutionsDisplayResult!;
    }
    if (derivativeDisplayResult != null) {
      alternativeResults['derivative'] = derivativeDisplayResult!;
    }
    if (integralDisplayResult != null) {
      alternativeResults['integral'] = integralDisplayResult!;
    }
    if (transformDisplayResult != null) {
      alternativeResults['transform'] = transformDisplayResult!;
    }
    if (traceDisplayResult != null) {
      alternativeResults['trace'] = traceDisplayResult!;
    }
    if (rootDisplayResult != null) {
      alternativeResults['roots'] = rootDisplayResult!;
    }
    if (intersectionDisplayResult != null) {
      alternativeResults['intersections'] = intersectionDisplayResult!;
    }
    if (datasetDisplayResult != null) {
      alternativeResults['dataset'] = datasetDisplayResult!;
    }
    if (statisticsDisplayResult != null) {
      alternativeResults['statistics'] = statisticsDisplayResult!;
    }
    if (regressionDisplayResult != null) {
      alternativeResults['regression'] = regressionDisplayResult!;
    }
    if (probabilityDisplayResult != null) {
      alternativeResults['probability'] = probabilityDisplayResult!;
    }
    if (vectorDisplayResult != null) {
      alternativeResults['vector'] = vectorDisplayResult!;
    }
    if (matrixDisplayResult != null) {
      alternativeResults['matrix'] = matrixDisplayResult!;
    }
    if (unitDisplayResult != null) {
      alternativeResults['unit'] = unitDisplayResult!;
    }
    if (baseUnitDisplayResult != null) {
      alternativeResults['base'] = baseUnitDisplayResult!;
    }

    return CalculationOutcome.success(
      CalculationResult(
        normalizedExpression: normalizedExpression,
        displayResult: displayResult,
        numericValue: numericValue,
        isApproximate: isApproximate,
        warnings: List.unmodifiable(warnings),
        numericMode: numericMode,
        calculationDomain: calculationDomain,
        resultFormat: resultFormat,
        valueKind: valueKind,
        exactDisplayResult: exactDisplayResult,
        symbolicDisplayResult: symbolicDisplayResult,
        decimalDisplayResult: decimalDisplayResult,
        fractionDisplayResult: fractionDisplayResult,
        complexDisplayResult: complexDisplayResult,
        rectangularDisplayResult: rectangularDisplayResult,
        polarDisplayResult: polarDisplayResult,
        magnitudeDisplayResult: magnitudeDisplayResult,
        argumentDisplayResult: argumentDisplayResult,
        functionDisplayResult: functionDisplayResult,
        plotDisplayResult: plotDisplayResult,
        graphDisplayResult: graphDisplayResult,
        equationDisplayResult: equationDisplayResult,
        solveDisplayResult: solveDisplayResult,
        solutionsDisplayResult: solutionsDisplayResult,
        derivativeDisplayResult: derivativeDisplayResult,
        integralDisplayResult: integralDisplayResult,
        transformDisplayResult: transformDisplayResult,
        traceDisplayResult: traceDisplayResult,
        rootDisplayResult: rootDisplayResult,
        intersectionDisplayResult: intersectionDisplayResult,
        datasetDisplayResult: datasetDisplayResult,
        statisticsDisplayResult: statisticsDisplayResult,
        regressionDisplayResult: regressionDisplayResult,
        probabilityDisplayResult: probabilityDisplayResult,
        summaryDisplayResult: summaryDisplayResult,
        vectorDisplayResult: vectorDisplayResult,
        matrixDisplayResult: matrixDisplayResult,
        unitDisplayResult: unitDisplayResult,
        baseUnitDisplayResult: baseUnitDisplayResult,
        dimensionDisplayResult: dimensionDisplayResult,
        conversionDisplayResult: conversionDisplayResult,
        shapeDisplayResult: shapeDisplayResult,
        rowCount: rowCount,
        columnCount: columnCount,
        sampleSize: sampleSize,
        statisticName: statisticName,
        plotSeriesCount: plotSeriesCount,
        plotPointCount: plotPointCount,
        plotSegmentCount: plotSegmentCount,
        solutionCount: solutionCount,
        solveVariable: solveVariable,
        solveMethod: solveMethod,
        solveDomain: solveDomain,
        viewportDisplayResult: viewportDisplayResult,
        graphWarnings: List.unmodifiable(graphWarnings),
        alternativeResults: alternativeResults,
      ),
    );
  }

  bool isDuplicateOf(CalculatorHistoryItem other) {
    return expression == other.expression &&
        displayResult == other.displayResult &&
        angleMode == other.angleMode &&
        precision == other.precision &&
        numericMode == other.numericMode &&
        calculationDomain == other.calculationDomain &&
        unitMode == other.unitMode &&
        resultFormat == other.resultFormat &&
        valueKind == other.valueKind &&
        sampleSize == other.sampleSize &&
        statisticName == other.statisticName &&
        plotSeriesCount == other.plotSeriesCount &&
        plotPointCount == other.plotPointCount &&
        plotSegmentCount == other.plotSegmentCount &&
        solutionCount == other.solutionCount &&
        solveVariable == other.solveVariable &&
        solveMethod == other.solveMethod &&
        solveDomain == other.solveDomain &&
        rowCount == other.rowCount &&
        columnCount == other.columnCount &&
        shapeDisplayResult == other.shapeDisplayResult &&
        viewportDisplayResult == other.viewportDisplayResult &&
        graphDisplayResult == other.graphDisplayResult &&
        solveDisplayResult == other.solveDisplayResult;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'expression': expression,
      'normalizedExpression': normalizedExpression,
      'displayResult': displayResult,
      'numericValue': numericValue,
      'angleMode': angleMode.name,
      'precision': precision,
      'isApproximate': isApproximate,
      'numericMode': numericMode.name,
      'calculationDomain': calculationDomain.name,
      'unitMode': unitMode.name,
      'resultFormat': resultFormat.name,
      'valueKind': valueKind.name,
      'warnings': warnings,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'exactDisplayResult': exactDisplayResult,
      'symbolicDisplayResult': symbolicDisplayResult,
      'decimalDisplayResult': decimalDisplayResult,
      'fractionDisplayResult': fractionDisplayResult,
      'complexDisplayResult': complexDisplayResult,
      'rectangularDisplayResult': rectangularDisplayResult,
      'polarDisplayResult': polarDisplayResult,
      'magnitudeDisplayResult': magnitudeDisplayResult,
      'argumentDisplayResult': argumentDisplayResult,
      'functionDisplayResult': functionDisplayResult,
      'plotDisplayResult': plotDisplayResult,
      'graphDisplayResult': graphDisplayResult,
      'equationDisplayResult': equationDisplayResult,
      'solveDisplayResult': solveDisplayResult,
      'solutionsDisplayResult': solutionsDisplayResult,
      'derivativeDisplayResult': derivativeDisplayResult,
      'integralDisplayResult': integralDisplayResult,
      'transformDisplayResult': transformDisplayResult,
      'traceDisplayResult': traceDisplayResult,
      'rootDisplayResult': rootDisplayResult,
      'intersectionDisplayResult': intersectionDisplayResult,
      'datasetDisplayResult': datasetDisplayResult,
      'statisticsDisplayResult': statisticsDisplayResult,
      'regressionDisplayResult': regressionDisplayResult,
      'probabilityDisplayResult': probabilityDisplayResult,
      'summaryDisplayResult': summaryDisplayResult,
      'vectorDisplayResult': vectorDisplayResult,
      'matrixDisplayResult': matrixDisplayResult,
      'unitDisplayResult': unitDisplayResult,
      'baseUnitDisplayResult': baseUnitDisplayResult,
      'dimensionDisplayResult': dimensionDisplayResult,
      'conversionDisplayResult': conversionDisplayResult,
      'shapeDisplayResult': shapeDisplayResult,
      'rowCount': rowCount,
      'columnCount': columnCount,
      'sampleSize': sampleSize,
      'statisticName': statisticName,
      'plotSeriesCount': plotSeriesCount,
      'plotPointCount': plotPointCount,
      'plotSegmentCount': plotSegmentCount,
      'solutionCount': solutionCount,
      'solveVariable': solveVariable,
      'solveMethod': solveMethod,
      'solveDomain': solveDomain,
      'viewportDisplayResult': viewportDisplayResult,
      'graphWarnings': graphWarnings,
      'isFavorite': isFavorite,
    };
  }

  String toStoredString() => jsonEncode(toJson());

  factory CalculatorHistoryItem.fromJson(Map<String, dynamic> json) {
    final expression = json['expression'];
    final normalizedExpression = json['normalizedExpression'];
    final displayResult = json['displayResult'];

    if (expression is! String ||
        normalizedExpression is! String ||
        displayResult is! String) {
      throw const FormatException('Missing required history fields.');
    }

    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final angleMode = _parseAngleMode(json['angleMode']) ?? AngleMode.degree;
    final precision = _parsePrecision(json['precision']) ?? 10;
    final numericMode =
        _parseNumericMode(json['numericMode']) ?? NumericMode.approximate;
    final calculationDomain =
        _parseCalculationDomain(json['calculationDomain']) ??
        CalculationDomain.real;
    final unitMode = _parseUnitMode(json['unitMode']) ?? UnitMode.disabled;
    final resultFormat =
        _parseResultFormat(
          json['resultFormat'] ?? json['defaultResultFormat'],
        ) ??
        NumberFormatStyle.auto;
    final valueKind =
        _parseValueKind(json['valueKind']) ?? CalculatorValueKind.doubleValue;

    return CalculatorHistoryItem(
      id: json['id']?.toString().trim().isNotEmpty == true
          ? json['id'].toString()
          : '${createdAt?.microsecondsSinceEpoch ?? 0}-$expression',
      expression: expression,
      normalizedExpression: normalizedExpression,
      displayResult: displayResult,
      numericValue: (json['numericValue'] as num?)?.toDouble(),
      angleMode: angleMode,
      precision: precision,
      isApproximate: json['isApproximate'] == true,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      valueKind: valueKind,
      warnings: (json['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      createdAt: (createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).toUtc(),
      exactDisplayResult: json['exactDisplayResult'] as String?,
      symbolicDisplayResult: json['symbolicDisplayResult'] as String?,
      decimalDisplayResult:
          json['decimalDisplayResult'] as String? ?? displayResult,
      fractionDisplayResult: json['fractionDisplayResult'] as String?,
      complexDisplayResult: json['complexDisplayResult'] as String?,
      rectangularDisplayResult:
          json['rectangularDisplayResult'] as String?,
      polarDisplayResult: json['polarDisplayResult'] as String?,
      magnitudeDisplayResult: json['magnitudeDisplayResult'] as String?,
      argumentDisplayResult: json['argumentDisplayResult'] as String?,
      functionDisplayResult: json['functionDisplayResult'] as String?,
      plotDisplayResult: json['plotDisplayResult'] as String?,
      graphDisplayResult: json['graphDisplayResult'] as String?,
      equationDisplayResult: json['equationDisplayResult'] as String?,
      solveDisplayResult: json['solveDisplayResult'] as String?,
      solutionsDisplayResult: json['solutionsDisplayResult'] as String?,
      derivativeDisplayResult: json['derivativeDisplayResult'] as String?,
      integralDisplayResult: json['integralDisplayResult'] as String?,
      transformDisplayResult: json['transformDisplayResult'] as String?,
      traceDisplayResult: json['traceDisplayResult'] as String?,
      rootDisplayResult: json['rootDisplayResult'] as String?,
      intersectionDisplayResult: json['intersectionDisplayResult'] as String?,
      datasetDisplayResult: json['datasetDisplayResult'] as String?,
      statisticsDisplayResult: json['statisticsDisplayResult'] as String?,
      regressionDisplayResult: json['regressionDisplayResult'] as String?,
      probabilityDisplayResult: json['probabilityDisplayResult'] as String?,
      summaryDisplayResult: json['summaryDisplayResult'] as String?,
      vectorDisplayResult: json['vectorDisplayResult'] as String?,
      matrixDisplayResult: json['matrixDisplayResult'] as String?,
      unitDisplayResult: json['unitDisplayResult'] as String?,
      baseUnitDisplayResult: json['baseUnitDisplayResult'] as String?,
      dimensionDisplayResult: json['dimensionDisplayResult'] as String?,
      conversionDisplayResult: json['conversionDisplayResult'] as String?,
      shapeDisplayResult: json['shapeDisplayResult'] as String?,
      rowCount: (json['rowCount'] as num?)?.toInt(),
      columnCount: (json['columnCount'] as num?)?.toInt(),
      sampleSize: (json['sampleSize'] as num?)?.toInt(),
      statisticName: json['statisticName'] as String?,
      plotSeriesCount: (json['plotSeriesCount'] as num?)?.toInt(),
      plotPointCount: (json['plotPointCount'] as num?)?.toInt(),
      plotSegmentCount: (json['plotSegmentCount'] as num?)?.toInt(),
      solutionCount: (json['solutionCount'] as num?)?.toInt(),
      solveVariable: json['solveVariable'] as String?,
      solveMethod: json['solveMethod'] as String?,
      solveDomain: json['solveDomain'] as String?,
      viewportDisplayResult: json['viewportDisplayResult'] as String?,
      graphWarnings: (json['graphWarnings'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      isFavorite: json['isFavorite'] == true,
    );
  }

  static List<CalculatorHistoryItem> listFromStoredString(
    String? source, {
    int maxItems = 100,
  }) {
    if (source == null || source.trim().isEmpty) {
      return const <CalculatorHistoryItem>[];
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is! List<dynamic>) {
        return const <CalculatorHistoryItem>[];
      }

      final items = <CalculatorHistoryItem>[];
      for (final value in decoded) {
        if (value is Map<String, dynamic>) {
          try {
            items.add(CalculatorHistoryItem.fromJson(value));
          } catch (_) {
            continue;
          }
        }
      }

      items.sort((left, right) => right.createdAt.compareTo(left.createdAt));
      if (items.length > maxItems) {
        return List<CalculatorHistoryItem>.unmodifiable(items.take(maxItems));
      }

      return List<CalculatorHistoryItem>.unmodifiable(items);
    } catch (_) {
      return const <CalculatorHistoryItem>[];
    }
  }

  static String listToStoredString(List<CalculatorHistoryItem> items) {
    return jsonEncode(
      items.map((item) => item.toJson()).toList(growable: false),
    );
  }

  static AngleMode? _parseAngleMode(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return AngleMode.values.cast<AngleMode?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }

  static int? _parsePrecision(Object? raw) {
    if (raw is int && raw > 0) {
      return raw;
    }

    if (raw is num && raw > 0) {
      return raw.toInt();
    }

    return null;
  }

  static NumericMode? _parseNumericMode(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return NumericMode.values.cast<NumericMode?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }

  static CalculationDomain? _parseCalculationDomain(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return CalculationDomain.values.cast<CalculationDomain?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }

  static NumberFormatStyle? _parseResultFormat(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return NumberFormatStyle.values.cast<NumberFormatStyle?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }

  static UnitMode? _parseUnitMode(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return UnitMode.values.cast<UnitMode?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }

  static CalculatorValueKind? _parseValueKind(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return CalculatorValueKind.values.cast<CalculatorValueKind?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }
}
