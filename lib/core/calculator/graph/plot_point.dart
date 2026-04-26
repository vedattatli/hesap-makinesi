/// One sampled graph point.
class PlotPoint {
  const PlotPoint({
    required this.x,
    required this.y,
    required this.isDefined,
    this.errorReason,
  });

  final double x;
  final double y;
  final bool isDefined;
  final String? errorReason;
}
