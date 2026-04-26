import '../../../core/calculator/calculator.dart';
import 'scope/worksheet_symbol.dart';
import 'worksheet_block_result.dart';
import 'worksheet_error.dart';
import 'worksheet_graph_state.dart';

enum WorksheetBlockType {
  calculation,
  graph,
  text,
  variableDefinition,
  functionDefinition,
  solve,
  casTransform,
}

enum WorksheetTextFormat { plain, markdownLite }

enum WorksheetSolveMethodPreference { auto, exact, numeric }

enum WorksheetCasTransformType { simplify, expand, factor }

class WorksheetBlock {
  const WorksheetBlock({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.orderIndex,
    this.title,
    this.isCollapsed = false,
    this.expression,
    this.bodyExpression,
    this.symbolName,
    this.parameters = const <String>[],
    this.solveVariableName,
    this.intervalMinExpression,
    this.intervalMaxExpression,
    this.solveMethodPreference,
    this.casTransformType,
    this.angleMode,
    this.precision,
    this.numericMode,
    this.calculationDomain,
    this.unitMode,
    this.resultFormat,
    this.result,
    this.graphState,
    this.text,
    this.textFormat,
    this.dependencies = const <String>[],
    this.isStale = false,
    this.lastEvaluatedAt,
    this.worksheetErrorCode,
    this.worksheetErrorMessage,
  });

  factory WorksheetBlock.calculation({
    required String id,
    required int orderIndex,
    required String expression,
    required AngleMode angleMode,
    required int precision,
    required NumericMode numericMode,
    required CalculationDomain calculationDomain,
    required UnitMode unitMode,
    required NumberFormatStyle resultFormat,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    bool isCollapsed = false,
    WorksheetBlockResult? result,
    List<String> dependencies = const <String>[],
    bool isStale = false,
    DateTime? lastEvaluatedAt,
    WorksheetErrorCode? worksheetErrorCode,
    String? worksheetErrorMessage,
  }) {
    final timestamp = (updatedAt ?? createdAt ?? DateTime.now().toUtc())
        .toUtc();
    return WorksheetBlock(
      id: id,
      type: WorksheetBlockType.calculation,
      title: title,
      createdAt: (createdAt ?? timestamp).toUtc(),
      updatedAt: timestamp,
      orderIndex: orderIndex,
      isCollapsed: isCollapsed,
      expression: expression,
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      result: result,
      dependencies: List<String>.unmodifiable(dependencies),
      isStale: isStale,
      lastEvaluatedAt: lastEvaluatedAt,
      worksheetErrorCode: worksheetErrorCode,
      worksheetErrorMessage: worksheetErrorMessage,
    );
  }

  factory WorksheetBlock.variableDefinition({
    required String id,
    required int orderIndex,
    required String name,
    required String expression,
    required AngleMode angleMode,
    required int precision,
    required NumericMode numericMode,
    required CalculationDomain calculationDomain,
    required UnitMode unitMode,
    required NumberFormatStyle resultFormat,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    bool isCollapsed = false,
    WorksheetBlockResult? result,
    List<String> dependencies = const <String>[],
    bool isStale = true,
    DateTime? lastEvaluatedAt,
    WorksheetErrorCode? worksheetErrorCode,
    String? worksheetErrorMessage,
  }) {
    final timestamp = (updatedAt ?? createdAt ?? DateTime.now().toUtc())
        .toUtc();
    return WorksheetBlock(
      id: id,
      type: WorksheetBlockType.variableDefinition,
      title: title,
      createdAt: (createdAt ?? timestamp).toUtc(),
      updatedAt: timestamp,
      orderIndex: orderIndex,
      isCollapsed: isCollapsed,
      symbolName: name,
      expression: expression,
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      result: result,
      dependencies: List<String>.unmodifiable(dependencies),
      isStale: isStale,
      lastEvaluatedAt: lastEvaluatedAt,
      worksheetErrorCode: worksheetErrorCode,
      worksheetErrorMessage: worksheetErrorMessage,
    );
  }

  factory WorksheetBlock.functionDefinition({
    required String id,
    required int orderIndex,
    required String name,
    required List<String> parameters,
    required String bodyExpression,
    required AngleMode angleMode,
    required int precision,
    required NumericMode numericMode,
    required CalculationDomain calculationDomain,
    required UnitMode unitMode,
    required NumberFormatStyle resultFormat,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    bool isCollapsed = false,
    WorksheetBlockResult? result,
    List<String> dependencies = const <String>[],
    bool isStale = true,
    DateTime? lastEvaluatedAt,
    WorksheetErrorCode? worksheetErrorCode,
    String? worksheetErrorMessage,
  }) {
    final timestamp = (updatedAt ?? createdAt ?? DateTime.now().toUtc())
        .toUtc();
    return WorksheetBlock(
      id: id,
      type: WorksheetBlockType.functionDefinition,
      title: title,
      createdAt: (createdAt ?? timestamp).toUtc(),
      updatedAt: timestamp,
      orderIndex: orderIndex,
      isCollapsed: isCollapsed,
      symbolName: name,
      parameters: List<String>.unmodifiable(parameters),
      bodyExpression: bodyExpression,
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      result: result,
      dependencies: List<String>.unmodifiable(dependencies),
      isStale: isStale,
      lastEvaluatedAt: lastEvaluatedAt,
      worksheetErrorCode: worksheetErrorCode,
      worksheetErrorMessage: worksheetErrorMessage,
    );
  }

  factory WorksheetBlock.graph({
    required String id,
    required int orderIndex,
    required WorksheetGraphState graphState,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    bool isCollapsed = false,
    List<String> dependencies = const <String>[],
    bool isStale = false,
    DateTime? lastEvaluatedAt,
    WorksheetErrorCode? worksheetErrorCode,
    String? worksheetErrorMessage,
  }) {
    final timestamp = (updatedAt ?? createdAt ?? DateTime.now().toUtc())
        .toUtc();
    return WorksheetBlock(
      id: id,
      type: WorksheetBlockType.graph,
      title: title,
      createdAt: (createdAt ?? timestamp).toUtc(),
      updatedAt: timestamp,
      orderIndex: orderIndex,
      isCollapsed: isCollapsed,
      graphState: graphState,
      dependencies: List<String>.unmodifiable(dependencies),
      isStale: isStale,
      lastEvaluatedAt: lastEvaluatedAt,
      worksheetErrorCode: worksheetErrorCode,
      worksheetErrorMessage: worksheetErrorMessage,
    );
  }

  factory WorksheetBlock.solve({
    required String id,
    required int orderIndex,
    required String equationExpression,
    required String variableName,
    required AngleMode angleMode,
    required int precision,
    required NumericMode numericMode,
    required CalculationDomain calculationDomain,
    required UnitMode unitMode,
    required NumberFormatStyle resultFormat,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    bool isCollapsed = false,
    WorksheetBlockResult? result,
    List<String> dependencies = const <String>[],
    bool isStale = true,
    DateTime? lastEvaluatedAt,
    WorksheetErrorCode? worksheetErrorCode,
    String? worksheetErrorMessage,
    String? intervalMinExpression,
    String? intervalMaxExpression,
    WorksheetSolveMethodPreference methodPreference =
        WorksheetSolveMethodPreference.auto,
  }) {
    final timestamp = (updatedAt ?? createdAt ?? DateTime.now().toUtc())
        .toUtc();
    return WorksheetBlock(
      id: id,
      type: WorksheetBlockType.solve,
      title: title,
      createdAt: (createdAt ?? timestamp).toUtc(),
      updatedAt: timestamp,
      orderIndex: orderIndex,
      isCollapsed: isCollapsed,
      expression: equationExpression,
      solveVariableName: variableName,
      intervalMinExpression: intervalMinExpression,
      intervalMaxExpression: intervalMaxExpression,
      solveMethodPreference: methodPreference,
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      result: result,
      dependencies: List<String>.unmodifiable(dependencies),
      isStale: isStale,
      lastEvaluatedAt: lastEvaluatedAt,
      worksheetErrorCode: worksheetErrorCode,
      worksheetErrorMessage: worksheetErrorMessage,
    );
  }

  factory WorksheetBlock.casTransform({
    required String id,
    required int orderIndex,
    required String expression,
    required WorksheetCasTransformType transformType,
    required AngleMode angleMode,
    required int precision,
    required NumericMode numericMode,
    required CalculationDomain calculationDomain,
    required UnitMode unitMode,
    required NumberFormatStyle resultFormat,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    bool isCollapsed = false,
    WorksheetBlockResult? result,
    List<String> dependencies = const <String>[],
    bool isStale = true,
    DateTime? lastEvaluatedAt,
    WorksheetErrorCode? worksheetErrorCode,
    String? worksheetErrorMessage,
  }) {
    final timestamp = (updatedAt ?? createdAt ?? DateTime.now().toUtc())
        .toUtc();
    return WorksheetBlock(
      id: id,
      type: WorksheetBlockType.casTransform,
      title: title,
      createdAt: (createdAt ?? timestamp).toUtc(),
      updatedAt: timestamp,
      orderIndex: orderIndex,
      isCollapsed: isCollapsed,
      expression: expression,
      casTransformType: transformType,
      angleMode: angleMode,
      precision: precision,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      resultFormat: resultFormat,
      result: result,
      dependencies: List<String>.unmodifiable(dependencies),
      isStale: isStale,
      lastEvaluatedAt: lastEvaluatedAt,
      worksheetErrorCode: worksheetErrorCode,
      worksheetErrorMessage: worksheetErrorMessage,
    );
  }

  factory WorksheetBlock.text({
    required String id,
    required int orderIndex,
    required String text,
    WorksheetTextFormat format = WorksheetTextFormat.plain,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    bool isCollapsed = false,
  }) {
    final timestamp = (updatedAt ?? createdAt ?? DateTime.now().toUtc())
        .toUtc();
    return WorksheetBlock(
      id: id,
      type: WorksheetBlockType.text,
      title: title,
      createdAt: (createdAt ?? timestamp).toUtc(),
      updatedAt: timestamp,
      orderIndex: orderIndex,
      isCollapsed: isCollapsed,
      text: text,
      textFormat: format,
    );
  }

  final String id;
  final WorksheetBlockType type;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int orderIndex;
  final bool isCollapsed;
  final String? expression;
  final String? bodyExpression;
  final String? symbolName;
  final List<String> parameters;
  final String? solveVariableName;
  final String? intervalMinExpression;
  final String? intervalMaxExpression;
  final WorksheetSolveMethodPreference? solveMethodPreference;
  final WorksheetCasTransformType? casTransformType;
  final AngleMode? angleMode;
  final int? precision;
  final NumericMode? numericMode;
  final CalculationDomain? calculationDomain;
  final UnitMode? unitMode;
  final NumberFormatStyle? resultFormat;
  final WorksheetBlockResult? result;
  final WorksheetGraphState? graphState;
  final String? text;
  final WorksheetTextFormat? textFormat;
  final List<String> dependencies;
  final bool isStale;
  final DateTime? lastEvaluatedAt;
  final WorksheetErrorCode? worksheetErrorCode;
  final String? worksheetErrorMessage;

  bool get isCalculation => type == WorksheetBlockType.calculation;
  bool get isGraph => type == WorksheetBlockType.graph;
  bool get isText => type == WorksheetBlockType.text;
  bool get isVariableDefinition =>
      type == WorksheetBlockType.variableDefinition;
  bool get isFunctionDefinition =>
      type == WorksheetBlockType.functionDefinition;
  bool get isSolve => type == WorksheetBlockType.solve;
  bool get isCasTransform => type == WorksheetBlockType.casTransform;
  bool get definesSymbol => isVariableDefinition || isFunctionDefinition;

  WorksheetSymbolType? get symbolType {
    if (isVariableDefinition) {
      return WorksheetSymbolType.variable;
    }
    if (isFunctionDefinition) {
      return WorksheetSymbolType.function;
    }
    return null;
  }

  WorksheetBlock copyWith({
    String? id,
    WorksheetBlockType? type,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? orderIndex,
    bool? isCollapsed,
    String? expression,
    String? bodyExpression,
    String? symbolName,
    List<String>? parameters,
    String? solveVariableName,
    String? intervalMinExpression,
    String? intervalMaxExpression,
    WorksheetSolveMethodPreference? solveMethodPreference,
    WorksheetCasTransformType? casTransformType,
    AngleMode? angleMode,
    int? precision,
    NumericMode? numericMode,
    CalculationDomain? calculationDomain,
    UnitMode? unitMode,
    NumberFormatStyle? resultFormat,
    WorksheetBlockResult? result,
    bool clearResult = false,
    WorksheetGraphState? graphState,
    bool clearGraphState = false,
    String? text,
    WorksheetTextFormat? textFormat,
    List<String>? dependencies,
    bool? isStale,
    DateTime? lastEvaluatedAt,
    bool clearLastEvaluatedAt = false,
    WorksheetErrorCode? worksheetErrorCode,
    String? worksheetErrorMessage,
    bool clearWorksheetError = false,
  }) {
    return WorksheetBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      orderIndex: orderIndex ?? this.orderIndex,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      expression: expression ?? this.expression,
      bodyExpression: bodyExpression ?? this.bodyExpression,
      symbolName: symbolName ?? this.symbolName,
      parameters: List<String>.unmodifiable(parameters ?? this.parameters),
      solveVariableName: solveVariableName ?? this.solveVariableName,
      intervalMinExpression:
          intervalMinExpression ?? this.intervalMinExpression,
      intervalMaxExpression:
          intervalMaxExpression ?? this.intervalMaxExpression,
      solveMethodPreference:
          solveMethodPreference ?? this.solveMethodPreference,
      casTransformType: casTransformType ?? this.casTransformType,
      angleMode: angleMode ?? this.angleMode,
      precision: precision ?? this.precision,
      numericMode: numericMode ?? this.numericMode,
      calculationDomain: calculationDomain ?? this.calculationDomain,
      unitMode: unitMode ?? this.unitMode,
      resultFormat: resultFormat ?? this.resultFormat,
      result: clearResult ? null : (result ?? this.result),
      graphState: clearGraphState ? null : (graphState ?? this.graphState),
      text: text ?? this.text,
      textFormat: textFormat ?? this.textFormat,
      dependencies: List<String>.unmodifiable(
        dependencies ?? this.dependencies,
      ),
      isStale: isStale ?? this.isStale,
      lastEvaluatedAt: clearLastEvaluatedAt
          ? null
          : (lastEvaluatedAt ?? this.lastEvaluatedAt),
      worksheetErrorCode: clearWorksheetError
          ? null
          : (worksheetErrorCode ?? this.worksheetErrorCode),
      worksheetErrorMessage: clearWorksheetError
          ? null
          : (worksheetErrorMessage ?? this.worksheetErrorMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'title': title,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'orderIndex': orderIndex,
      'isCollapsed': isCollapsed,
      'expression': expression,
      'bodyExpression': bodyExpression,
      'symbolName': symbolName,
      'parameters': parameters,
      'solveVariableName': solveVariableName,
      'intervalMinExpression': intervalMinExpression,
      'intervalMaxExpression': intervalMaxExpression,
      'solveMethodPreference': solveMethodPreference?.name,
      'casTransformType': casTransformType?.name,
      'angleMode': angleMode?.name,
      'precision': precision,
      'numericMode': numericMode?.name,
      'calculationDomain': calculationDomain?.name,
      'unitMode': unitMode?.name,
      'resultFormat': resultFormat?.name,
      'result': result?.toJson(),
      'graphState': graphState?.toJson(),
      'text': text,
      'textFormat': textFormat?.name,
      'dependencies': dependencies,
      'isStale': isStale,
      'lastEvaluatedAt': lastEvaluatedAt?.toUtc().toIso8601String(),
      'worksheetErrorCode': worksheetErrorCode?.name,
      'worksheetErrorMessage': worksheetErrorMessage,
    };
  }

  static WorksheetBlock? tryFromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    if (rawType is! String) {
      return null;
    }

    final type = WorksheetBlockType.values
        .cast<WorksheetBlockType?>()
        .firstWhere((value) => value?.name == rawType, orElse: () => null);
    if (type == null) {
      return null;
    }

    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final updatedAt =
        DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toUtc() ??
        createdAt;
    final id = json['id']?.toString().trim().isNotEmpty == true
        ? json['id'].toString()
        : '${createdAt.microsecondsSinceEpoch}-${type.name}';
    final title = json['title'] as String?;
    final orderIndex = (json['orderIndex'] as num?)?.toInt() ?? 0;
    final isCollapsed = json['isCollapsed'] == true;
    final dependencies =
        (json['dependencies'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList(growable: false);
    final isStale = json['isStale'] == true;
    final lastEvaluatedAt = DateTime.tryParse(
      json['lastEvaluatedAt']?.toString() ?? '',
    )?.toUtc();
    final worksheetErrorCode = WorksheetErrorCode.values
        .cast<WorksheetErrorCode?>()
        .firstWhere(
          (value) => value?.name == json['worksheetErrorCode'],
          orElse: () => null,
        );
    final worksheetErrorMessage = json['worksheetErrorMessage'] as String?;
    final resultJson = json['result'];
    final result = resultJson is Map<String, dynamic>
        ? WorksheetBlockResult.fromJson(resultJson)
        : null;

    AngleMode angleModeOrDefault([AngleMode fallback = AngleMode.degree]) {
      return AngleMode.values.cast<AngleMode?>().firstWhere(
        (value) => value?.name == json['angleMode'],
        orElse: () => fallback,
      )!;
    }

    NumericMode numericModeOrDefault([
      NumericMode fallback = NumericMode.approximate,
    ]) {
      return NumericMode.values.cast<NumericMode?>().firstWhere(
        (value) => value?.name == json['numericMode'],
        orElse: () => fallback,
      )!;
    }

    CalculationDomain domainOrDefault([
      CalculationDomain fallback = CalculationDomain.real,
    ]) {
      return CalculationDomain.values.cast<CalculationDomain?>().firstWhere(
        (value) => value?.name == json['calculationDomain'],
        orElse: () => fallback,
      )!;
    }

    UnitMode unitModeOrDefault([UnitMode fallback = UnitMode.disabled]) {
      return UnitMode.values.cast<UnitMode?>().firstWhere(
        (value) => value?.name == json['unitMode'],
        orElse: () => fallback,
      )!;
    }

    NumberFormatStyle formatOrDefault([
      NumberFormatStyle fallback = NumberFormatStyle.auto,
    ]) {
      return NumberFormatStyle.values.cast<NumberFormatStyle?>().firstWhere(
        (value) => value?.name == json['resultFormat'],
        orElse: () => fallback,
      )!;
    }

    switch (type) {
      case WorksheetBlockType.calculation:
        final expression = json['expression']?.toString();
        if (expression == null) {
          return null;
        }
        return WorksheetBlock.calculation(
          id: id,
          orderIndex: orderIndex,
          expression: expression,
          angleMode: angleModeOrDefault(),
          precision: (json['precision'] as num?)?.toInt() ?? 10,
          numericMode: numericModeOrDefault(),
          calculationDomain: domainOrDefault(),
          unitMode: unitModeOrDefault(),
          resultFormat: formatOrDefault(),
          createdAt: createdAt,
          updatedAt: updatedAt,
          title: title,
          isCollapsed: isCollapsed,
          result: result,
          dependencies: dependencies,
          isStale: isStale,
          lastEvaluatedAt: lastEvaluatedAt,
          worksheetErrorCode: worksheetErrorCode,
          worksheetErrorMessage: worksheetErrorMessage,
        );
      case WorksheetBlockType.variableDefinition:
        final expression = json['expression']?.toString();
        final symbolName = json['symbolName']?.toString();
        if (expression == null || symbolName == null) {
          return null;
        }
        return WorksheetBlock.variableDefinition(
          id: id,
          orderIndex: orderIndex,
          name: symbolName,
          expression: expression,
          angleMode: angleModeOrDefault(),
          precision: (json['precision'] as num?)?.toInt() ?? 10,
          numericMode: numericModeOrDefault(),
          calculationDomain: domainOrDefault(),
          unitMode: unitModeOrDefault(),
          resultFormat: formatOrDefault(),
          createdAt: createdAt,
          updatedAt: updatedAt,
          title: title,
          isCollapsed: isCollapsed,
          result: result,
          dependencies: dependencies,
          isStale: isStale,
          lastEvaluatedAt: lastEvaluatedAt,
          worksheetErrorCode: worksheetErrorCode,
          worksheetErrorMessage: worksheetErrorMessage,
        );
      case WorksheetBlockType.functionDefinition:
        final bodyExpression = json['bodyExpression']?.toString();
        final symbolName = json['symbolName']?.toString();
        if (bodyExpression == null || symbolName == null) {
          return null;
        }
        return WorksheetBlock.functionDefinition(
          id: id,
          orderIndex: orderIndex,
          name: symbolName,
          parameters:
              (json['parameters'] as List<dynamic>? ?? const <dynamic>[])
                  .whereType<String>()
                  .toList(growable: false),
          bodyExpression: bodyExpression,
          angleMode: angleModeOrDefault(),
          precision: (json['precision'] as num?)?.toInt() ?? 10,
          numericMode: numericModeOrDefault(),
          calculationDomain: domainOrDefault(),
          unitMode: unitModeOrDefault(),
          resultFormat: formatOrDefault(),
          createdAt: createdAt,
          updatedAt: updatedAt,
          title: title,
          isCollapsed: isCollapsed,
          result: result,
          dependencies: dependencies,
          isStale: isStale,
          lastEvaluatedAt: lastEvaluatedAt,
          worksheetErrorCode: worksheetErrorCode,
          worksheetErrorMessage: worksheetErrorMessage,
        );
      case WorksheetBlockType.graph:
        final graphJson = json['graphState'];
        if (graphJson is! Map<String, dynamic>) {
          return null;
        }
        try {
          return WorksheetBlock.graph(
            id: id,
            orderIndex: orderIndex,
            graphState: WorksheetGraphState.fromJson(graphJson),
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            isCollapsed: isCollapsed,
            dependencies: dependencies,
            isStale: isStale,
            lastEvaluatedAt: lastEvaluatedAt,
            worksheetErrorCode: worksheetErrorCode,
            worksheetErrorMessage: worksheetErrorMessage,
          );
        } catch (_) {
          return null;
        }
      case WorksheetBlockType.solve:
        final equationExpression = json['expression']?.toString();
        final solveVariableName = json['solveVariableName']?.toString();
        if (equationExpression == null || solveVariableName == null) {
          return null;
        }
        return WorksheetBlock.solve(
          id: id,
          orderIndex: orderIndex,
          equationExpression: equationExpression,
          variableName: solveVariableName,
          angleMode: angleModeOrDefault(),
          precision: (json['precision'] as num?)?.toInt() ?? 10,
          numericMode: numericModeOrDefault(),
          calculationDomain: domainOrDefault(),
          unitMode: unitModeOrDefault(),
          resultFormat: formatOrDefault(),
          createdAt: createdAt,
          updatedAt: updatedAt,
          title: title,
          isCollapsed: isCollapsed,
          result: result,
          dependencies: dependencies,
          isStale: isStale,
          lastEvaluatedAt: lastEvaluatedAt,
          worksheetErrorCode: worksheetErrorCode,
          worksheetErrorMessage: worksheetErrorMessage,
          intervalMinExpression: json['intervalMinExpression']?.toString(),
          intervalMaxExpression: json['intervalMaxExpression']?.toString(),
          methodPreference: WorksheetSolveMethodPreference.values
              .cast<WorksheetSolveMethodPreference?>()
              .firstWhere(
                (value) => value?.name == json['solveMethodPreference'],
                orElse: () => WorksheetSolveMethodPreference.auto,
              )!,
        );
      case WorksheetBlockType.casTransform:
        final expression = json['expression']?.toString();
        if (expression == null) {
          return null;
        }
        final transformType = WorksheetCasTransformType.values
            .cast<WorksheetCasTransformType?>()
            .firstWhere(
              (value) => value?.name == json['casTransformType'],
              orElse: () => WorksheetCasTransformType.simplify,
            )!;
        return WorksheetBlock.casTransform(
          id: id,
          orderIndex: orderIndex,
          expression: expression,
          transformType: transformType,
          angleMode: angleModeOrDefault(),
          precision: (json['precision'] as num?)?.toInt() ?? 10,
          numericMode: numericModeOrDefault(),
          calculationDomain: domainOrDefault(),
          unitMode: unitModeOrDefault(),
          resultFormat: formatOrDefault(),
          createdAt: createdAt,
          updatedAt: updatedAt,
          title: title,
          isCollapsed: isCollapsed,
          result: result,
          dependencies: dependencies,
          isStale: isStale,
          lastEvaluatedAt: lastEvaluatedAt,
          worksheetErrorCode: worksheetErrorCode,
          worksheetErrorMessage: worksheetErrorMessage,
        );
      case WorksheetBlockType.text:
        return WorksheetBlock.text(
          id: id,
          orderIndex: orderIndex,
          text: json['text']?.toString() ?? '',
          format: WorksheetTextFormat.values
              .cast<WorksheetTextFormat?>()
              .firstWhere(
                (value) => value?.name == json['textFormat'],
                orElse: () => WorksheetTextFormat.plain,
              )!,
          createdAt: createdAt,
          updatedAt: updatedAt,
          title: title,
          isCollapsed: isCollapsed,
        );
    }
  }
}
