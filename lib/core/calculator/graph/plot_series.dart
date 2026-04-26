import 'plot_segment.dart';

/// One plotted series derived from a single expression.
class PlotSeries {
  const PlotSeries({
    required this.expression,
    required this.normalizedExpression,
    required this.label,
    required this.segments,
    required this.sampleCount,
    required this.definedPointCount,
    required this.undefinedPointCount,
    this.warnings = const <String>[],
  });

  final String expression;
  final String normalizedExpression;
  final String label;
  final List<PlotSegment> segments;
  final int sampleCount;
  final int definedPointCount;
  final int undefinedPointCount;
  final List<String> warnings;
}
