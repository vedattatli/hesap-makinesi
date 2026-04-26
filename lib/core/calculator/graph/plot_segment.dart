import 'plot_point.dart';

/// Continuous graph segment that should be drawn without crossing breaks.
class PlotSegment {
  const PlotSegment(this.points);

  final List<PlotPoint> points;
}
