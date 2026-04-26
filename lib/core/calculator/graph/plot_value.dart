import '../values/calculator_value.dart';
import 'graph_viewport.dart';
import 'plot_series.dart';

/// Structured graph result containing sampled plot series.
class PlotValue extends CalculatorValue {
  const PlotValue({
    required this.viewport,
    required this.series,
    required this.autoYUsed,
    this.warnings = const <String>[],
  });

  final GraphViewport viewport;
  final List<PlotSeries> series;
  final bool autoYUsed;
  final List<String> warnings;

  int get seriesCount => series.length;

  int get pointCount => series.fold<int>(0, (sum, item) => sum + item.sampleCount);

  int get segmentCount =>
      series.fold<int>(0, (sum, item) => sum + item.segments.length);

  @override
  CalculatorValueKind get kind => CalculatorValueKind.plot;

  @override
  bool get isExact => false;

  @override
  double toDouble() => pointCount.toDouble();
}
