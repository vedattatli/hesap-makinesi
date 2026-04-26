import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/calculator/calculator.dart';
import '../../worksheet/worksheet_graph_state.dart';
import '../design/app_radii.dart';
import '../design/app_shadows.dart';
import '../design/app_spacing.dart';
import 'expression_input_tools.dart';

class GraphPanel extends StatefulWidget {
  const GraphPanel({
    super.key,
    required this.calculationContext,
    required this.onCommitPlotExpression,
    this.seedExpression,
    this.seedGraphState,
    this.onGraphStateChanged,
    this.onSaveGraphState,
  });

  final CalculationContext calculationContext;
  final ValueChanged<String> onCommitPlotExpression;
  final String? seedExpression;
  final WorksheetGraphState? seedGraphState;
  final ValueChanged<WorksheetGraphState>? onGraphStateChanged;
  final ValueChanged<WorksheetGraphState>? onSaveGraphState;

  @override
  State<GraphPanel> createState() => _GraphPanelState();
}

class _GraphPanelState extends State<GraphPanel> {
  static const _maxSeriesCount = 6;
  static const _maxPlotCacheEntries = 8;
  static const _maxCachedPlotPoints = 30000;

  final CalculatorEngine _engine = const CalculatorEngine();
  final List<TextEditingController> _seriesControllers =
      <TextEditingController>[];
  final TextEditingController _xMinController = TextEditingController(
    text: '-10',
  );
  final TextEditingController _xMaxController = TextEditingController(
    text: '10',
  );
  final TextEditingController _yMinController = TextEditingController(
    text: '-10',
  );
  final TextEditingController _yMaxController = TextEditingController(
    text: '10',
  );

  Timer? _replotDebounce;
  final LinkedHashMap<String, PlotValue> _plotCache =
      LinkedHashMap<String, PlotValue>();
  GraphViewport _viewport = GraphViewport.defaultViewport();
  GraphSamplingOptions _samplingOptions = const GraphSamplingOptions();
  PlotValue? _plotValue;
  CalculationError? _graphError;
  Offset? _gestureStartLocalFocal;
  GraphViewport? _gestureStartViewport;
  bool _autoY = true;
  bool _showGrid = true;
  bool _showAxes = true;
  String? _lastAppliedSeedKey;
  int _plotRequestSerial = 0;

  @override
  void initState() {
    super.initState();
    _applyInitialSeed();
  }

  @override
  void dispose() {
    _replotDebounce?.cancel();
    for (final controller in _seriesControllers) {
      controller.dispose();
    }
    _xMinController.dispose();
    _xMaxController.dispose();
    _yMinController.dispose();
    _yMaxController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GraphPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSeedKey = _seedKey(widget.seedGraphState, widget.seedExpression);
    if (nextSeedKey != _lastAppliedSeedKey) {
      _applyInitialSeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      key: const Key('graph-panel'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: AppRadii.panel,
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
        boxShadow: AppShadows.panel(colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Graph Panel',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pure Dart graph engine backed by the calculator parser',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                key: const Key('graph-function-editor-button'),
                onPressed: _openGraphFunctionEditor,
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Editor'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                key: const Key('graph-add-series-button'),
                onPressed: _seriesControllers.length >= _maxSeriesCount
                    ? null
                    : _addSeries,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                key: const Key('graph-reset-button'),
                onPressed: _resetViewport,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                key: const Key('graph-save-to-worksheet-button'),
                onPressed: _plotValue == null || widget.onSaveGraphState == null
                    ? null
                    : () {
                        final graphState = _currentGraphState();
                        if (graphState != null) {
                          widget.onSaveGraphState!(graphState);
                        }
                      },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save graph'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List<Widget>.generate(_seriesControllers.length, (index) {
            final controller = _seriesControllers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: Key('graph-expression-$index'),
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Function ${index + 1}',
                        hintText: 'sin(x)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (_seriesControllers.length > 1) ...<Widget>[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      key: Key('graph-remove-series-$index'),
                      onPressed: () => _removeSeries(index),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _ViewportField(
                keyName: 'graph-xmin-input',
                label: 'xMin',
                controller: _xMinController,
              ),
              _ViewportField(
                keyName: 'graph-xmax-input',
                label: 'xMax',
                controller: _xMaxController,
              ),
              _ViewportField(
                keyName: 'graph-ymin-input',
                label: 'yMin',
                controller: _yMinController,
                enabled: !_autoY,
              ),
              _ViewportField(
                keyName: 'graph-ymax-input',
                label: 'yMax',
                controller: _yMaxController,
                enabled: !_autoY,
              ),
              FilterChip(
                key: const Key('graph-autoy-toggle'),
                label: const Text('Auto Y'),
                selected: _autoY,
                onSelected: (selected) {
                  setState(() => _autoY = selected);
                },
              ),
              FilterChip(
                key: const Key('graph-grid-toggle'),
                label: const Text('Grid'),
                selected: _showGrid,
                onSelected: (selected) {
                  setState(() => _showGrid = selected);
                },
              ),
              FilterChip(
                key: const Key('graph-axes-toggle'),
                label: const Text('Axes'),
                selected: _showAxes,
                onSelected: (selected) {
                  setState(() => _showAxes = selected);
                },
              ),
              FilledButton.icon(
                key: const Key('graph-plot-button'),
                onPressed: () => _plot(recordHistory: true),
                icon: const Icon(Icons.show_chart),
                label: const Text('Plot'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _seriesControllers
                .asMap()
                .entries
                .map((entry) {
                  final color = _seriesColor(entry.key);
                  return Chip(
                    avatar: CircleAvatar(backgroundColor: color, radius: 8),
                    label: Text(
                      entry.value.text.trim().isEmpty
                          ? 'series ${entry.key + 1}'
                          : entry.value.text.trim(),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                math.max(260, constraints.maxWidth * 0.55),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Semantics(
                        label:
                            'Graph canvas with ${_plotValue?.seriesCount ?? 0} series. ${_plotValue?.viewport.toDisplayString() ?? _viewport.toDisplayString()}',
                        child: GestureDetector(
                          onScaleStart: (details) {
                            _gestureStartViewport = _viewport;
                            _gestureStartLocalFocal = details.localFocalPoint;
                          },
                          onScaleUpdate: (details) {
                            _handleScaleUpdate(details, size);
                          },
                          child: CustomPaint(
                            key: const Key('graph-canvas'),
                            size: size,
                            painter: _GraphPainter(
                              plotValue: _plotValue,
                              fallbackViewport: _viewport,
                              colorScheme: colorScheme,
                              showGrid: _showGrid,
                              showAxes: _showAxes,
                            ),
                          ),
                        ),
                      ),
                      if (_plotValue == null && _graphError == null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                key: const Key('graph-empty-state'),
                                constraints: const BoxConstraints(
                                  maxWidth: 360,
                                ),
                                padding: AppSpacing.compactCard,
                                decoration: BoxDecoration(
                                  borderRadius: AppRadii.panel,
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.84),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.24),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.gesture_outlined,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Try sin(x), cos(x), x^2 or 1/x',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (_plotValue ??
                            PlotValue(
                              viewport: _viewport,
                              series: const <PlotSeries>[],
                              autoYUsed: _autoY,
                            ))
                        .viewport
                        .toDisplayString(),
                    key: const Key('graph-viewport-summary'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_plotValue != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      '${_plotValue!.seriesCount} series | ${_plotValue!.pointCount} points | ${_plotValue!.segmentCount} segments',
                      key: const Key('graph-panel-summary-text'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_graphError != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      _graphError!.message,
                      key: const Key('graph-error-text'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_plotValue?.warnings.isNotEmpty == true) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      _plotValue!.warnings.join('\n'),
                      key: const Key('graph-warning-text'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _addSeries() {
    setState(() {
      _seriesControllers.add(TextEditingController(text: 'cos(x)'));
    });
  }

  void _removeSeries(int index) {
    setState(() {
      final controller = _seriesControllers.removeAt(index);
      controller.dispose();
    });
  }

  void _resetViewport() {
    _plotRequestSerial++;
    _viewport = GraphViewport.defaultViewport();
    _autoY = true;
    _showGrid = true;
    _showAxes = true;
    _syncViewportControllers(_viewport);
    _plot(recordHistory: false);
  }

  Future<void> _openGraphFunctionEditor() async {
    final result = await showModalBottomSheet<GraphFunctionEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return GraphFunctionEditorSheet(
          expressions: _seriesControllers
              .map((controller) => controller.text.trim())
              .where((expression) => expression.isNotEmpty)
              .toList(growable: false),
          viewport: _viewport,
          autoY: _autoY,
        );
      },
    );
    if (result == null) {
      return;
    }
    setState(() {
      while (_seriesControllers.length < result.expressions.length) {
        _seriesControllers.add(TextEditingController());
      }
      while (_seriesControllers.length > result.expressions.length) {
        _seriesControllers.removeLast().dispose();
      }
      for (var index = 0; index < result.expressions.length; index++) {
        _seriesControllers[index].text = result.expressions[index];
      }
      _autoY = result.autoY;
      _xMinController.text = result.xMin;
      _xMaxController.text = result.xMax;
      _yMinController.text = result.yMin;
      _yMaxController.text = result.yMax;
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, Size size) {
    final baseViewport = _gestureStartViewport ?? _viewport;
    final baseFocal = _gestureStartLocalFocal ?? details.localFocalPoint;
    final centerX =
        baseViewport.xMin +
        (baseFocal.dx.clamp(0.0, size.width) / size.width) * baseViewport.width;
    final centerY =
        baseViewport.yMax -
        (baseFocal.dy.clamp(0.0, size.height) / size.height) *
            baseViewport.height;
    var nextViewport = baseViewport.zoom(
      scale: 1 / math.max(details.scale, 1e-6),
      centerX: centerX,
      centerY: centerY,
    );
    final dragDx = details.localFocalPoint.dx - baseFocal.dx;
    final dragDy = details.localFocalPoint.dy - baseFocal.dy;
    nextViewport = nextViewport.pan(
      deltaX: -(dragDx / size.width) * nextViewport.width,
      deltaY: (dragDy / size.height) * nextViewport.height,
    );
    _viewport = nextViewport.copyWith(autoY: _autoY);
    _syncViewportControllers(_viewport);
    _scheduleReplot();
  }

  void _scheduleReplot() {
    _replotDebounce?.cancel();
    final scheduledRequest = ++_plotRequestSerial;
    _replotDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted || scheduledRequest != _plotRequestSerial) {
        return;
      }
      _plot(recordHistory: false);
    });
  }

  void _plot({required bool recordHistory}) {
    final requestId = ++_plotRequestSerial;
    late final String expression;
    try {
      expression = _buildPlotExpression();
    } on FormatException catch (error) {
      setState(() {
        _graphError = CalculationError(
          type: CalculationErrorType.invalidFunctionExpression,
          message: error.message,
        );
        _plotValue = null;
      });
      return;
    }
    final cacheKey = _plotCacheKey(expression);
    final cachedPlot = _takeCachedPlot(cacheKey);
    if (cachedPlot != null) {
      if (!mounted || requestId != _plotRequestSerial) {
        return;
      }
      _applyPlotValue(cachedPlot);
      final graphState = _currentGraphState();
      if (graphState != null) {
        widget.onGraphStateChanged?.call(graphState);
      }
      if (recordHistory) {
        widget.onCommitPlotExpression(expression);
      }
      return;
    }
    final outcome = _engine.evaluate(
      expression,
      context: widget.calculationContext,
    );
    if (!mounted || requestId != _plotRequestSerial) {
      return;
    }
    if (outcome.isFailure) {
      setState(() {
        _graphError = outcome.error;
        _plotValue = null;
      });
      return;
    }

    final result = outcome.result!;
    if (result.value is! PlotValue) {
      setState(() {
        _graphError = const CalculationError(
          type: CalculationErrorType.invalidGraphOperation,
          message: 'Plot fonksiyonu gecerli bir grafik sonucu dondurmedi.',
        );
        _plotValue = null;
      });
      return;
    }

    final plotValue = result.value! as PlotValue;
    _rememberPlot(cacheKey, plotValue);
    _applyPlotValue(plotValue);

    final graphState = _currentGraphState();
    if (graphState != null) {
      widget.onGraphStateChanged?.call(graphState);
    }

    if (recordHistory) {
      widget.onCommitPlotExpression(expression);
    }
  }

  void _applyPlotValue(PlotValue plotValue) {
    setState(() {
      _graphError = null;
      _plotValue = plotValue;
      _viewport = plotValue.viewport;
      _syncViewportControllers(plotValue.viewport);
    });
  }

  String _buildPlotExpression() {
    final expressions = _seriesControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
    if (expressions.isEmpty) {
      throw const FormatException('At least one graph expression is required.');
    }
    final xMin = _xMinController.text.trim();
    final xMax = _xMaxController.text.trim();
    final yMin = _yMinController.text.trim();
    final yMax = _yMaxController.text.trim();
    final series = expressions.length == 1
        ? expressions.single
        : '[${expressions.join(', ')}]';
    if (_autoY) {
      return 'plot($series, $xMin, $xMax)';
    }
    return 'plot($series, $xMin, $xMax, $yMin, $yMax)';
  }

  String _plotCacheKey(String expression) {
    final context = widget.calculationContext;
    return [
      expression,
      context.angleMode.name,
      context.numericMode.name,
      context.calculationDomain.name,
      context.unitMode.name,
      context.numberFormatStyle.name,
      context.precision,
      context.preferExactResult,
      _samplingOptions.cacheKey,
    ].join('|');
  }

  PlotValue? _takeCachedPlot(String cacheKey) {
    final value = _plotCache.remove(cacheKey);
    if (value == null) {
      return null;
    }
    _plotCache[cacheKey] = value;
    return value;
  }

  void _rememberPlot(String cacheKey, PlotValue plotValue) {
    _plotCache[cacheKey] = plotValue;
    while (_plotCache.length > _maxPlotCacheEntries ||
        _cachedPointCount() > _maxCachedPlotPoints) {
      _plotCache.remove(_plotCache.keys.first);
    }
  }

  int _cachedPointCount() {
    return _plotCache.values.fold<int>(
      0,
      (total, plot) => total + plot.pointCount,
    );
  }

  void _syncViewportControllers(GraphViewport viewport) {
    _xMinController.text = _formatViewportValue(viewport.xMin);
    _xMaxController.text = _formatViewportValue(viewport.xMax);
    _yMinController.text = _formatViewportValue(viewport.yMin);
    _yMaxController.text = _formatViewportValue(viewport.yMax);
  }

  String _formatViewportValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Color _seriesColor(int index) {
    const palette = <Color>[
      Color(0xFF2563EB),
      Color(0xFFDC2626),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
    ];
    return palette[index % palette.length];
  }

  void _applyInitialSeed() {
    final graphState = widget.seedGraphState;
    if (graphState != null) {
      _applyGraphState(graphState);
      _lastAppliedSeedKey = _seedKey(
        widget.seedGraphState,
        widget.seedExpression,
      );
      return;
    }

    final initialExpression = (widget.seedExpression?.contains('x') ?? false)
        ? widget.seedExpression!.trim()
        : 'sin(x)';
    if (_seriesControllers.isEmpty) {
      _seriesControllers.add(TextEditingController(text: initialExpression));
    } else {
      _seriesControllers.first.text = initialExpression;
      while (_seriesControllers.length > 1) {
        final controller = _seriesControllers.removeLast();
        controller.dispose();
      }
    }
    _lastAppliedSeedKey = _seedKey(
      widget.seedGraphState,
      widget.seedExpression,
    );
  }

  void _applyGraphState(WorksheetGraphState graphState) {
    while (_seriesControllers.length < graphState.expressions.length) {
      _seriesControllers.add(TextEditingController());
    }
    while (_seriesControllers.length > graphState.expressions.length) {
      final controller = _seriesControllers.removeLast();
      controller.dispose();
    }
    for (var index = 0; index < graphState.expressions.length; index++) {
      _seriesControllers[index].text = graphState.expressions[index];
    }
    _viewport = graphState.viewport;
    _autoY = graphState.autoY;
    _showGrid = graphState.showGrid;
    _showAxes = graphState.showAxes;
    _samplingOptions = GraphSamplingOptions(
      initialSamples: graphState.initialSamples,
      maxSamples: graphState.maxSamples,
      adaptiveDepth: graphState.adaptiveDepth,
      discontinuityThreshold: graphState.discontinuityThreshold,
      minStep: graphState.minStep,
    );
    _syncViewportControllers(graphState.viewport);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _plot(recordHistory: false);
    });
  }

  WorksheetGraphState? _currentGraphState() {
    final plotValue = _plotValue;
    if (plotValue == null) {
      return null;
    }
    final expressions = _seriesControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
    if (expressions.isEmpty) {
      return null;
    }
    return WorksheetGraphState.fromPlotValue(
      id:
          widget.seedGraphState?.id ??
          'graph-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      title: widget.seedGraphState?.title ?? 'Saved Graph',
      expressions: expressions,
      plotValue: plotValue,
      context: widget.calculationContext,
      showGrid: _showGrid,
      showAxes: _showAxes,
      options: _samplingOptions,
      createdAt: widget.seedGraphState?.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  String _seedKey(WorksheetGraphState? graphState, String? expression) {
    if (graphState != null) {
      return '${graphState.id}-${graphState.updatedAt.microsecondsSinceEpoch}';
    }
    return 'expr-${expression ?? ''}';
  }
}

class _ViewportField extends StatelessWidget {
  const _ViewportField({
    required this.keyName,
    required this.label,
    required this.controller,
    this.enabled = true,
  });

  final String keyName;
  final String label;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: TextField(
        key: Key(keyName),
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
    required this.plotValue,
    required this.fallbackViewport,
    required this.colorScheme,
    required this.showGrid,
    required this.showAxes,
  });

  final PlotValue? plotValue;
  final GraphViewport fallbackViewport;
  final ColorScheme colorScheme;
  final bool showGrid;
  final bool showAxes;

  GraphViewport get _viewport => plotValue?.viewport ?? fallbackViewport;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = colorScheme.surface;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      background,
    );

    if (showGrid) {
      _drawGrid(canvas, size);
    }
    if (showAxes) {
      _drawAxes(canvas, size);
    }
    _drawSeries(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final xStep = _niceStep(_viewport.width / 8);
    final yStep = _niceStep(_viewport.height / 8);
    for (
      double x = (_viewport.xMin / xStep).floor() * xStep;
      x <= _viewport.xMax;
      x += xStep
    ) {
      final dx = _mapX(x, size);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (
      double y = (_viewport.yMin / yStep).floor() * yStep;
      y <= _viewport.yMax;
      y += yStep
    ) {
      final dy = _mapY(y, size);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }
  }

  void _drawAxes(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.75)
      ..strokeWidth = 1.6;
    if (_viewport.xMin <= 0 && _viewport.xMax >= 0) {
      final x = _mapX(0, size);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), axisPaint);
    }
    if (_viewport.yMin <= 0 && _viewport.yMax >= 0) {
      final y = _mapY(0, size);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }
  }

  void _drawSeries(Canvas canvas, Size size) {
    if (plotValue == null) {
      return;
    }
    const palette = <Color>[
      Color(0xFF2563EB),
      Color(0xFFDC2626),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
    ];
    for (var index = 0; index < plotValue!.series.length; index++) {
      final series = plotValue!.series[index];
      final paint = Paint()
        ..color = palette[index % palette.length]
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      for (final segment in series.segments) {
        final path = Path();
        for (
          var pointIndex = 0;
          pointIndex < segment.points.length;
          pointIndex++
        ) {
          final point = segment.points[pointIndex];
          final offset = Offset(_mapX(point.x, size), _mapY(point.y, size));
          if (pointIndex == 0) {
            path.moveTo(offset.dx, offset.dy);
          } else {
            path.lineTo(offset.dx, offset.dy);
          }
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  double _mapX(double x, Size size) {
    return ((x - _viewport.xMin) / _viewport.width) * size.width;
  }

  double _mapY(double y, Size size) {
    return size.height -
        ((y - _viewport.yMin) / _viewport.height) * size.height;
  }

  double _niceStep(double rawStep) {
    final magnitude = math.pow(10, math.log(rawStep) / math.ln10).toDouble();
    final normalized = rawStep / magnitude;
    final nice = normalized < 1.5
        ? 1.0
        : normalized < 3
        ? 2.0
        : normalized < 7
        ? 5.0
        : 10.0;
    return nice * magnitude;
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.plotValue != plotValue ||
        oldDelegate.fallbackViewport != fallbackViewport ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showAxes != showAxes;
  }
}
