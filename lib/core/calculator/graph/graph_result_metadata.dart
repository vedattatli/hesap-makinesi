/// Extra display metadata attached to graph-related evaluator results.
class GraphResultMetadata {
  const GraphResultMetadata({
    this.functionDisplayResult,
    this.plotDisplayResult,
    this.graphDisplayResult,
    this.traceDisplayResult,
    this.rootDisplayResult,
    this.intersectionDisplayResult,
    this.plotSeriesCount,
    this.plotPointCount,
    this.plotSegmentCount,
    this.viewportDisplayResult,
    this.graphWarnings = const <String>[],
  });

  final String? functionDisplayResult;
  final String? plotDisplayResult;
  final String? graphDisplayResult;
  final String? traceDisplayResult;
  final String? rootDisplayResult;
  final String? intersectionDisplayResult;
  final int? plotSeriesCount;
  final int? plotPointCount;
  final int? plotSegmentCount;
  final String? viewportDisplayResult;
  final List<String> graphWarnings;
}
