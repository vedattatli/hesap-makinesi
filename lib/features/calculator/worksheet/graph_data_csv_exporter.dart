import '../../../core/calculator/graph/plot_value.dart';
import 'worksheet_error.dart';

class GraphDataCsvExporter {
  const GraphDataCsvExporter({
    this.maxRows = 100000,
    this.maxPointCount = 50000,
  });

  final int maxRows;
  final int maxPointCount;

  String export(PlotValue plotValue) {
    if (plotValue.pointCount > maxPointCount) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.graphExportFailed,
          message:
              'Graph data export is too large. Reduce the sample count or series count.',
        ),
      );
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'seriesIndex,seriesLabel,segmentIndex,pointIndex,x,y,defined',
    );
    var rowCount = 1;
    for (
      var seriesIndex = 0;
      seriesIndex < plotValue.series.length;
      seriesIndex++
    ) {
      final series = plotValue.series[seriesIndex];
      for (
        var segmentIndex = 0;
        segmentIndex < series.segments.length;
        segmentIndex++
      ) {
        final segment = series.segments[segmentIndex];
        for (
          var pointIndex = 0;
          pointIndex < segment.points.length;
          pointIndex++
        ) {
          if (rowCount >= maxRows) {
            throw const WorksheetException(
              WorksheetError(
                code: WorksheetErrorCode.graphExportFailed,
                message: 'Graph data CSV export exceeded the row limit.',
              ),
            );
          }
          final point = segment.points[pointIndex];
          buffer.writeln(
            '${seriesIndex + 1},${_escape(series.label)},${segmentIndex + 1},${pointIndex + 1},${_fmt(point.x)},${_fmt(point.y)},true',
          );
          rowCount++;
        }
      }
    }
    return buffer.toString();
  }

  String _escape(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  String _fmt(num value) =>
      value.toStringAsFixed(10).replaceFirst(RegExp(r'\.?0+$'), '');
}
