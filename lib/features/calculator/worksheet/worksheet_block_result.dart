import '../../../core/calculator/calculator.dart';

class WorksheetBlockResult {
  const WorksheetBlockResult({
    required this.displayResult,
    required this.valueKind,
    required this.isApproximate,
    required this.warnings,
    this.errorType,
    this.errorMessage,
    this.normalizedExpression,
    this.exactDisplayResult,
    this.decimalDisplayResult,
    this.fractionDisplayResult,
    this.symbolicDisplayResult,
    this.complexDisplayResult,
    this.vectorDisplayResult,
    this.matrixDisplayResult,
    this.unitDisplayResult,
    this.datasetDisplayResult,
    this.regressionDisplayResult,
    this.probabilityDisplayResult,
    this.graphDisplayResult,
    this.equationDisplayResult,
    this.solveDisplayResult,
    this.solutionsDisplayResult,
    this.derivativeDisplayResult,
    this.integralDisplayResult,
    this.transformDisplayResult,
    this.summaryDisplayResult,
    this.shapeDisplayResult,
    this.viewportDisplayResult,
    this.sampleSize,
    this.statisticName,
    this.rowCount,
    this.columnCount,
    this.plotSeriesCount,
    this.plotPointCount,
    this.plotSegmentCount,
    this.solutionCount,
    this.solveVariable,
    this.solveMethod,
    this.solveDomain,
    this.residualDisplayResult,
    this.alternativeResults = const <String, String>{},
  });

  final String displayResult;
  final CalculatorValueKind? valueKind;
  final bool isApproximate;
  final List<String> warnings;
  final CalculationErrorType? errorType;
  final String? errorMessage;
  final String? normalizedExpression;
  final String? exactDisplayResult;
  final String? decimalDisplayResult;
  final String? fractionDisplayResult;
  final String? symbolicDisplayResult;
  final String? complexDisplayResult;
  final String? vectorDisplayResult;
  final String? matrixDisplayResult;
  final String? unitDisplayResult;
  final String? datasetDisplayResult;
  final String? regressionDisplayResult;
  final String? probabilityDisplayResult;
  final String? graphDisplayResult;
  final String? equationDisplayResult;
  final String? solveDisplayResult;
  final String? solutionsDisplayResult;
  final String? derivativeDisplayResult;
  final String? integralDisplayResult;
  final String? transformDisplayResult;
  final String? summaryDisplayResult;
  final String? shapeDisplayResult;
  final String? viewportDisplayResult;
  final int? sampleSize;
  final String? statisticName;
  final int? rowCount;
  final int? columnCount;
  final int? plotSeriesCount;
  final int? plotPointCount;
  final int? plotSegmentCount;
  final int? solutionCount;
  final String? solveVariable;
  final String? solveMethod;
  final String? solveDomain;
  final String? residualDisplayResult;
  final Map<String, String> alternativeResults;

  bool get hasError => errorType != null || errorMessage != null;

  WorksheetBlockResult copyWith({
    String? displayResult,
    CalculatorValueKind? valueKind,
    bool? isApproximate,
    List<String>? warnings,
    CalculationErrorType? errorType,
    String? errorMessage,
    String? normalizedExpression,
    String? exactDisplayResult,
    String? decimalDisplayResult,
    String? fractionDisplayResult,
    String? symbolicDisplayResult,
    String? complexDisplayResult,
    String? vectorDisplayResult,
    String? matrixDisplayResult,
    String? unitDisplayResult,
    String? datasetDisplayResult,
    String? regressionDisplayResult,
    String? probabilityDisplayResult,
    String? graphDisplayResult,
    String? equationDisplayResult,
    String? solveDisplayResult,
    String? solutionsDisplayResult,
    String? derivativeDisplayResult,
    String? integralDisplayResult,
    String? transformDisplayResult,
    String? summaryDisplayResult,
    String? shapeDisplayResult,
    String? viewportDisplayResult,
    int? sampleSize,
    String? statisticName,
    int? rowCount,
    int? columnCount,
    int? plotSeriesCount,
    int? plotPointCount,
    int? plotSegmentCount,
    int? solutionCount,
    String? solveVariable,
    String? solveMethod,
    String? solveDomain,
    String? residualDisplayResult,
    Map<String, String>? alternativeResults,
  }) {
    return WorksheetBlockResult(
      displayResult: displayResult ?? this.displayResult,
      valueKind: valueKind ?? this.valueKind,
      isApproximate: isApproximate ?? this.isApproximate,
      warnings: warnings ?? this.warnings,
      errorType: errorType ?? this.errorType,
      errorMessage: errorMessage ?? this.errorMessage,
      normalizedExpression: normalizedExpression ?? this.normalizedExpression,
      exactDisplayResult: exactDisplayResult ?? this.exactDisplayResult,
      decimalDisplayResult: decimalDisplayResult ?? this.decimalDisplayResult,
      fractionDisplayResult:
          fractionDisplayResult ?? this.fractionDisplayResult,
      symbolicDisplayResult:
          symbolicDisplayResult ?? this.symbolicDisplayResult,
      complexDisplayResult: complexDisplayResult ?? this.complexDisplayResult,
      vectorDisplayResult: vectorDisplayResult ?? this.vectorDisplayResult,
      matrixDisplayResult: matrixDisplayResult ?? this.matrixDisplayResult,
      unitDisplayResult: unitDisplayResult ?? this.unitDisplayResult,
      datasetDisplayResult: datasetDisplayResult ?? this.datasetDisplayResult,
      regressionDisplayResult:
          regressionDisplayResult ?? this.regressionDisplayResult,
      probabilityDisplayResult:
          probabilityDisplayResult ?? this.probabilityDisplayResult,
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
      summaryDisplayResult: summaryDisplayResult ?? this.summaryDisplayResult,
      shapeDisplayResult: shapeDisplayResult ?? this.shapeDisplayResult,
      viewportDisplayResult:
          viewportDisplayResult ?? this.viewportDisplayResult,
      sampleSize: sampleSize ?? this.sampleSize,
      statisticName: statisticName ?? this.statisticName,
      rowCount: rowCount ?? this.rowCount,
      columnCount: columnCount ?? this.columnCount,
      plotSeriesCount: plotSeriesCount ?? this.plotSeriesCount,
      plotPointCount: plotPointCount ?? this.plotPointCount,
      plotSegmentCount: plotSegmentCount ?? this.plotSegmentCount,
      solutionCount: solutionCount ?? this.solutionCount,
      solveVariable: solveVariable ?? this.solveVariable,
      solveMethod: solveMethod ?? this.solveMethod,
      solveDomain: solveDomain ?? this.solveDomain,
      residualDisplayResult:
          residualDisplayResult ?? this.residualDisplayResult,
      alternativeResults: alternativeResults ?? this.alternativeResults,
    );
  }

  factory WorksheetBlockResult.fromCalculationResult(CalculationResult result) {
    return WorksheetBlockResult(
      displayResult: result.displayResult,
      valueKind: result.valueKind,
      isApproximate: result.isApproximate,
      warnings: List<String>.unmodifiable(result.warnings),
      normalizedExpression: result.normalizedExpression,
      exactDisplayResult: result.exactDisplayResult,
      decimalDisplayResult: result.decimalDisplayResult,
      fractionDisplayResult: result.fractionDisplayResult,
      symbolicDisplayResult: result.symbolicDisplayResult,
      complexDisplayResult: result.complexDisplayResult,
      vectorDisplayResult: result.vectorDisplayResult,
      matrixDisplayResult: result.matrixDisplayResult,
      unitDisplayResult: result.unitDisplayResult,
      datasetDisplayResult: result.datasetDisplayResult,
      regressionDisplayResult: result.regressionDisplayResult,
      probabilityDisplayResult: result.probabilityDisplayResult,
      graphDisplayResult: result.graphDisplayResult,
      equationDisplayResult: result.equationDisplayResult,
      solveDisplayResult: result.solveDisplayResult,
      solutionsDisplayResult: result.solutionsDisplayResult,
      derivativeDisplayResult: result.derivativeDisplayResult,
      integralDisplayResult: result.integralDisplayResult,
      transformDisplayResult: result.transformDisplayResult,
      summaryDisplayResult: result.summaryDisplayResult,
      shapeDisplayResult: result.shapeDisplayResult,
      viewportDisplayResult: result.viewportDisplayResult,
      sampleSize: result.sampleSize,
      statisticName: result.statisticName,
      rowCount: result.rowCount,
      columnCount: result.columnCount,
      plotSeriesCount: result.plotSeriesCount,
      plotPointCount: result.plotPointCount,
      plotSegmentCount: result.plotSegmentCount,
      solutionCount: result.solutionCount,
      solveVariable: result.solveVariable,
      solveMethod: result.solveMethod,
      solveDomain: result.solveDomain,
      residualDisplayResult: result.residualDisplayResult,
      alternativeResults: Map<String, String>.unmodifiable(
        result.alternativeResults,
      ),
    );
  }

  factory WorksheetBlockResult.fromCalculationError(
    CalculationError error, {
    String? normalizedExpression,
  }) {
    return WorksheetBlockResult(
      displayResult: error.message,
      valueKind: null,
      isApproximate: false,
      warnings: const <String>[],
      errorType: error.type,
      errorMessage: error.message,
      normalizedExpression: normalizedExpression,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'displayResult': displayResult,
      'valueKind': valueKind?.name,
      'isApproximate': isApproximate,
      'warnings': warnings,
      'errorType': errorType?.name,
      'errorMessage': errorMessage,
      'normalizedExpression': normalizedExpression,
      'exactDisplayResult': exactDisplayResult,
      'decimalDisplayResult': decimalDisplayResult,
      'fractionDisplayResult': fractionDisplayResult,
      'symbolicDisplayResult': symbolicDisplayResult,
      'complexDisplayResult': complexDisplayResult,
      'vectorDisplayResult': vectorDisplayResult,
      'matrixDisplayResult': matrixDisplayResult,
      'unitDisplayResult': unitDisplayResult,
      'datasetDisplayResult': datasetDisplayResult,
      'regressionDisplayResult': regressionDisplayResult,
      'probabilityDisplayResult': probabilityDisplayResult,
      'graphDisplayResult': graphDisplayResult,
      'equationDisplayResult': equationDisplayResult,
      'solveDisplayResult': solveDisplayResult,
      'solutionsDisplayResult': solutionsDisplayResult,
      'derivativeDisplayResult': derivativeDisplayResult,
      'integralDisplayResult': integralDisplayResult,
      'transformDisplayResult': transformDisplayResult,
      'summaryDisplayResult': summaryDisplayResult,
      'shapeDisplayResult': shapeDisplayResult,
      'viewportDisplayResult': viewportDisplayResult,
      'sampleSize': sampleSize,
      'statisticName': statisticName,
      'rowCount': rowCount,
      'columnCount': columnCount,
      'plotSeriesCount': plotSeriesCount,
      'plotPointCount': plotPointCount,
      'plotSegmentCount': plotSegmentCount,
      'solutionCount': solutionCount,
      'solveVariable': solveVariable,
      'solveMethod': solveMethod,
      'solveDomain': solveDomain,
      'residualDisplayResult': residualDisplayResult,
      'alternativeResults': alternativeResults,
    };
  }

  factory WorksheetBlockResult.fromJson(Map<String, dynamic> json) {
    return WorksheetBlockResult(
      displayResult: json['displayResult']?.toString() ?? '',
      valueKind: CalculatorValueKind.values
          .cast<CalculatorValueKind?>()
          .firstWhere(
            (value) => value?.name == json['valueKind'],
            orElse: () => null,
          ),
      isApproximate: json['isApproximate'] == true,
      warnings: (json['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      errorType: CalculationErrorType.values
          .cast<CalculationErrorType?>()
          .firstWhere(
            (value) => value?.name == json['errorType'],
            orElse: () => null,
          ),
      errorMessage: json['errorMessage'] as String?,
      normalizedExpression: json['normalizedExpression'] as String?,
      exactDisplayResult: json['exactDisplayResult'] as String?,
      decimalDisplayResult: json['decimalDisplayResult'] as String?,
      fractionDisplayResult: json['fractionDisplayResult'] as String?,
      symbolicDisplayResult: json['symbolicDisplayResult'] as String?,
      complexDisplayResult: json['complexDisplayResult'] as String?,
      vectorDisplayResult: json['vectorDisplayResult'] as String?,
      matrixDisplayResult: json['matrixDisplayResult'] as String?,
      unitDisplayResult: json['unitDisplayResult'] as String?,
      datasetDisplayResult: json['datasetDisplayResult'] as String?,
      regressionDisplayResult: json['regressionDisplayResult'] as String?,
      probabilityDisplayResult: json['probabilityDisplayResult'] as String?,
      graphDisplayResult: json['graphDisplayResult'] as String?,
      equationDisplayResult: json['equationDisplayResult'] as String?,
      solveDisplayResult: json['solveDisplayResult'] as String?,
      solutionsDisplayResult: json['solutionsDisplayResult'] as String?,
      derivativeDisplayResult: json['derivativeDisplayResult'] as String?,
      integralDisplayResult: json['integralDisplayResult'] as String?,
      transformDisplayResult: json['transformDisplayResult'] as String?,
      summaryDisplayResult: json['summaryDisplayResult'] as String?,
      shapeDisplayResult: json['shapeDisplayResult'] as String?,
      viewportDisplayResult: json['viewportDisplayResult'] as String?,
      sampleSize: (json['sampleSize'] as num?)?.toInt(),
      statisticName: json['statisticName'] as String?,
      rowCount: (json['rowCount'] as num?)?.toInt(),
      columnCount: (json['columnCount'] as num?)?.toInt(),
      plotSeriesCount: (json['plotSeriesCount'] as num?)?.toInt(),
      plotPointCount: (json['plotPointCount'] as num?)?.toInt(),
      plotSegmentCount: (json['plotSegmentCount'] as num?)?.toInt(),
      solutionCount: (json['solutionCount'] as num?)?.toInt(),
      solveVariable: json['solveVariable'] as String?,
      solveMethod: json['solveMethod'] as String?,
      solveDomain: json['solveDomain'] as String?,
      residualDisplayResult: json['residualDisplayResult'] as String?,
      alternativeResults: Map<String, String>.unmodifiable(
        (json['alternativeResults'] as Map<String, dynamic>? ??
                const <String, dynamic>{})
            .map((key, value) => MapEntry(key, value.toString())),
      ),
    );
  }
}
