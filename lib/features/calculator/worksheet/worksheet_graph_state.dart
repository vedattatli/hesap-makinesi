import '../../../core/calculator/calculator.dart';

class WorksheetGraphState {
  const WorksheetGraphState({
    required this.id,
    required this.title,
    required this.expressions,
    required this.viewport,
    required this.autoY,
    required this.showGrid,
    required this.showAxes,
    required this.initialSamples,
    required this.maxSamples,
    required this.adaptiveDepth,
    required this.discontinuityThreshold,
    required this.minStep,
    required this.angleMode,
    required this.numericMode,
    required this.calculationDomain,
    required this.unitMode,
    required this.resultFormat,
    required this.precision,
    required this.createdAt,
    required this.updatedAt,
    this.plotSeriesCount,
    this.plotPointCount,
    this.plotSegmentCount,
    this.lastPlotSummary,
    this.warnings = const <String>[],
  });

  final String id;
  final String title;
  final List<String> expressions;
  final GraphViewport viewport;
  final bool autoY;
  final bool showGrid;
  final bool showAxes;
  final int initialSamples;
  final int maxSamples;
  final int adaptiveDepth;
  final double discontinuityThreshold;
  final double minStep;
  final AngleMode angleMode;
  final NumericMode numericMode;
  final CalculationDomain calculationDomain;
  final UnitMode unitMode;
  final NumberFormatStyle resultFormat;
  final int precision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? plotSeriesCount;
  final int? plotPointCount;
  final int? plotSegmentCount;
  final String? lastPlotSummary;
  final List<String> warnings;

  WorksheetGraphState copyWith({
    String? id,
    String? title,
    List<String>? expressions,
    GraphViewport? viewport,
    bool? autoY,
    bool? showGrid,
    bool? showAxes,
    int? initialSamples,
    int? maxSamples,
    int? adaptiveDepth,
    double? discontinuityThreshold,
    double? minStep,
    AngleMode? angleMode,
    NumericMode? numericMode,
    CalculationDomain? calculationDomain,
    UnitMode? unitMode,
    NumberFormatStyle? resultFormat,
    int? precision,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? plotSeriesCount,
    int? plotPointCount,
    int? plotSegmentCount,
    String? lastPlotSummary,
    List<String>? warnings,
  }) {
    return WorksheetGraphState(
      id: id ?? this.id,
      title: title ?? this.title,
      expressions: expressions ?? this.expressions,
      viewport: viewport ?? this.viewport,
      autoY: autoY ?? this.autoY,
      showGrid: showGrid ?? this.showGrid,
      showAxes: showAxes ?? this.showAxes,
      initialSamples: initialSamples ?? this.initialSamples,
      maxSamples: maxSamples ?? this.maxSamples,
      adaptiveDepth: adaptiveDepth ?? this.adaptiveDepth,
      discontinuityThreshold:
          discontinuityThreshold ?? this.discontinuityThreshold,
      minStep: minStep ?? this.minStep,
      angleMode: angleMode ?? this.angleMode,
      numericMode: numericMode ?? this.numericMode,
      calculationDomain: calculationDomain ?? this.calculationDomain,
      unitMode: unitMode ?? this.unitMode,
      resultFormat: resultFormat ?? this.resultFormat,
      precision: precision ?? this.precision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      plotSeriesCount: plotSeriesCount ?? this.plotSeriesCount,
      plotPointCount: plotPointCount ?? this.plotPointCount,
      plotSegmentCount: plotSegmentCount ?? this.plotSegmentCount,
      lastPlotSummary: lastPlotSummary ?? this.lastPlotSummary,
      warnings: warnings ?? this.warnings,
    );
  }

  CalculationContext toCalculationContext() {
    return CalculationContext(
      angleMode: angleMode,
      precision: precision,
      preferExactResult: numericMode == NumericMode.exact,
      numericMode: numericMode,
      calculationDomain: calculationDomain,
      unitMode: unitMode,
      numberFormatStyle: resultFormat,
    );
  }

  String buildPlotExpression() {
    final series = expressions.length == 1
        ? expressions.single
        : '[${expressions.join(', ')}]';
    if (autoY) {
      return 'plot($series, ${_formatNumber(viewport.xMin)}, ${_formatNumber(viewport.xMax)})';
    }
    return 'plot($series, ${_formatNumber(viewport.xMin)}, ${_formatNumber(viewport.xMax)}, ${_formatNumber(viewport.yMin)}, ${_formatNumber(viewport.yMax)})';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'expressions': expressions,
      'viewport': <String, dynamic>{
        'xMin': viewport.xMin,
        'xMax': viewport.xMax,
        'yMin': viewport.yMin,
        'yMax': viewport.yMax,
        'autoY': autoY,
      },
      'showGrid': showGrid,
      'showAxes': showAxes,
      'initialSamples': initialSamples,
      'maxSamples': maxSamples,
      'adaptiveDepth': adaptiveDepth,
      'discontinuityThreshold': discontinuityThreshold,
      'minStep': minStep,
      'angleMode': angleMode.name,
      'numericMode': numericMode.name,
      'calculationDomain': calculationDomain.name,
      'unitMode': unitMode.name,
      'resultFormat': resultFormat.name,
      'precision': precision,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'plotSeriesCount': plotSeriesCount,
      'plotPointCount': plotPointCount,
      'plotSegmentCount': plotSegmentCount,
      'lastPlotSummary': lastPlotSummary,
      'warnings': warnings,
    };
  }

  factory WorksheetGraphState.fromJson(Map<String, dynamic> json) {
    final expressions =
        (json['expressions'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
    if (expressions.isEmpty) {
      throw const FormatException(
        'Worksheet graph state requires expressions.',
      );
    }

    final viewportJson = json['viewport'];
    final autoY =
        viewportJson is Map<String, dynamic> && viewportJson['autoY'] == true;
    final viewport = GraphViewport(
      xMin: (viewportJson as Map<String, dynamic>?)?['xMin'] is num
          ? (viewportJson!['xMin'] as num).toDouble()
          : -10,
      xMax: viewportJson?['xMax'] is num
          ? (viewportJson!['xMax'] as num).toDouble()
          : 10,
      yMin: viewportJson?['yMin'] is num
          ? (viewportJson!['yMin'] as num).toDouble()
          : -10,
      yMax: viewportJson?['yMax'] is num
          ? (viewportJson!['yMax'] as num).toDouble()
          : 10,
      autoY: autoY,
    );
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final updatedAt =
        DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toUtc() ??
        createdAt;

    return WorksheetGraphState(
      id: json['id']?.toString().trim().isNotEmpty == true
          ? json['id'].toString()
          : '${createdAt.microsecondsSinceEpoch}-${expressions.first}',
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString()
          : 'Saved Graph',
      expressions: expressions,
      viewport: viewport,
      autoY: autoY,
      showGrid: json['showGrid'] != false,
      showAxes: json['showAxes'] != false,
      initialSamples: (json['initialSamples'] as num?)?.toInt() ?? 512,
      maxSamples: (json['maxSamples'] as num?)?.toInt() ?? 4096,
      adaptiveDepth: (json['adaptiveDepth'] as num?)?.toInt() ?? 6,
      discontinuityThreshold:
          (json['discontinuityThreshold'] as num?)?.toDouble() ?? 6.0,
      minStep: (json['minStep'] as num?)?.toDouble() ?? 1e-4,
      angleMode: AngleMode.values.cast<AngleMode?>().firstWhere(
        (value) => value?.name == json['angleMode'],
        orElse: () => AngleMode.radian,
      )!,
      numericMode: NumericMode.values.cast<NumericMode?>().firstWhere(
        (value) => value?.name == json['numericMode'],
        orElse: () => NumericMode.approximate,
      )!,
      calculationDomain: CalculationDomain.values
          .cast<CalculationDomain?>()
          .firstWhere(
            (value) => value?.name == json['calculationDomain'],
            orElse: () => CalculationDomain.real,
          )!,
      unitMode: UnitMode.values.cast<UnitMode?>().firstWhere(
        (value) => value?.name == json['unitMode'],
        orElse: () => UnitMode.disabled,
      )!,
      resultFormat: NumberFormatStyle.values
          .cast<NumberFormatStyle?>()
          .firstWhere(
            (value) => value?.name == json['resultFormat'],
            orElse: () => NumberFormatStyle.auto,
          )!,
      precision: (json['precision'] as num?)?.toInt() ?? 10,
      createdAt: createdAt,
      updatedAt: updatedAt,
      plotSeriesCount: (json['plotSeriesCount'] as num?)?.toInt(),
      plotPointCount: (json['plotPointCount'] as num?)?.toInt(),
      plotSegmentCount: (json['plotSegmentCount'] as num?)?.toInt(),
      lastPlotSummary: json['lastPlotSummary'] as String?,
      warnings: (json['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  factory WorksheetGraphState.fromPlotValue({
    required String id,
    required String title,
    required List<String> expressions,
    required PlotValue plotValue,
    required CalculationContext context,
    required bool showGrid,
    required bool showAxes,
    GraphSamplingOptions options = const GraphSamplingOptions(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final timestamp = updatedAt ?? DateTime.now().toUtc();
    return WorksheetGraphState(
      id: id,
      title: title,
      expressions: List<String>.unmodifiable(expressions),
      viewport: plotValue.viewport,
      autoY: plotValue.autoYUsed,
      showGrid: showGrid,
      showAxes: showAxes,
      initialSamples: options.initialSamples,
      maxSamples: options.maxSamples,
      adaptiveDepth: options.adaptiveDepth,
      discontinuityThreshold: options.discontinuityThreshold,
      minStep: options.minStep,
      angleMode: context.angleMode,
      numericMode: context.numericMode,
      calculationDomain: context.calculationDomain,
      unitMode: context.unitMode,
      resultFormat: context.numberFormatStyle,
      precision: context.precision,
      createdAt: createdAt ?? timestamp,
      updatedAt: timestamp,
      plotSeriesCount: plotValue.seriesCount,
      plotPointCount: plotValue.pointCount,
      plotSegmentCount: plotValue.segmentCount,
      lastPlotSummary:
          '${plotValue.seriesCount} series, ${plotValue.pointCount} points, ${plotValue.segmentCount} segments',
      warnings: List<String>.unmodifiable(plotValue.warnings),
    );
  }

  static String _formatNumber(double value) {
    final normalized = value.abs() < 1e-12 ? 0.0 : value;
    if (normalized == normalized.roundToDouble()) {
      return normalized.toInt().toString();
    }
    return normalized.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
