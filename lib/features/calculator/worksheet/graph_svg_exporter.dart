import 'dart:math' as math;

import '../../../core/calculator/graph/plot_value.dart';
import '../../../core/calculator/graph/plot_segment.dart';
import '../../../core/calculator/graph/plot_point.dart';
import 'worksheet_error.dart';
import 'worksheet_graph_state.dart';

class GraphSvgExporter {
  const GraphSvgExporter({
    this.width = 800,
    this.height = 480,
    this.maxPointCount = 50000,
  });

  final int width;
  final int height;
  final int maxPointCount;

  String export(PlotValue plotValue, WorksheetGraphState graphState) {
    if (plotValue.pointCount > maxPointCount) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.graphExportFailed,
          message:
              'Graph SVG export is too large. Reduce the sample count or series count.',
        ),
      );
    }

    final buffer = StringBuffer();
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">',
    );
    buffer.writeln(
      '<title>${_escape(plotValue.series.length == 1 ? plotValue.series.first.label : graphState.title)}</title>',
    );
    buffer.writeln('<rect width="$width" height="$height" fill="#ffffff" />');

    if (graphState.showGrid) {
      for (final x in _gridLines(
        plotValue.viewport.xMin,
        plotValue.viewport.xMax,
      )) {
        final dx = _mapX(x, plotValue.viewport.xMin, plotValue.viewport.xMax);
        buffer.writeln(
          '<line x1="${_fmt(dx)}" y1="0" x2="${_fmt(dx)}" y2="$height" stroke="#d8dde2" stroke-width="1" />',
        );
      }
      for (final y in _gridLines(
        plotValue.viewport.yMin,
        plotValue.viewport.yMax,
      )) {
        final dy = _mapY(y, plotValue.viewport.yMin, plotValue.viewport.yMax);
        buffer.writeln(
          '<line x1="0" y1="${_fmt(dy)}" x2="$width" y2="${_fmt(dy)}" stroke="#d8dde2" stroke-width="1" />',
        );
      }
    }

    if (graphState.showAxes) {
      if (plotValue.viewport.xMin <= 0 && plotValue.viewport.xMax >= 0) {
        final dx = _mapX(0, plotValue.viewport.xMin, plotValue.viewport.xMax);
        buffer.writeln(
          '<line x1="${_fmt(dx)}" y1="0" x2="${_fmt(dx)}" y2="$height" stroke="#20292f" stroke-width="1.5" />',
        );
      }
      if (plotValue.viewport.yMin <= 0 && plotValue.viewport.yMax >= 0) {
        final dy = _mapY(0, plotValue.viewport.yMin, plotValue.viewport.yMax);
        buffer.writeln(
          '<line x1="0" y1="${_fmt(dy)}" x2="$width" y2="${_fmt(dy)}" stroke="#20292f" stroke-width="1.5" />',
        );
      }
    }

    const palette = <String>[
      '#2563eb',
      '#dc2626',
      '#059669',
      '#d97706',
      '#7c3aed',
      '#0891b2',
    ];
    for (
      var seriesIndex = 0;
      seriesIndex < plotValue.series.length;
      seriesIndex++
    ) {
      final series = plotValue.series[seriesIndex];
      final color = palette[seriesIndex % palette.length];
      for (final segment in series.segments) {
        if (segment.points.length < 2) {
          continue;
        }
        buffer.writeln(
          '<polyline fill="none" stroke="$color" stroke-width="2" points="${_segmentPoints(segment, plotValue)}" />',
        );
      }
    }

    buffer.write('</svg>');
    return buffer.toString();
  }

  Iterable<double> _gridLines(double min, double max) sync* {
    final step = _niceStep((max - min).abs() / 8);
    for (
      double value = (min / step).floor() * step;
      value <= max;
      value += step
    ) {
      yield value;
    }
  }

  double _mapX(double x, double xMin, double xMax) {
    return ((x - xMin) / (xMax - xMin)) * width;
  }

  double _mapY(double y, double yMin, double yMax) {
    return height - (((y - yMin) / (yMax - yMin)) * height);
  }

  String _segmentPoints(PlotSegment segment, PlotValue plotValue) {
    return segment.points
        .map(
          (PlotPoint point) =>
              '${_fmt(_mapX(point.x, plotValue.viewport.xMin, plotValue.viewport.xMax))},${_fmt(_mapY(point.y, plotValue.viewport.yMin, plotValue.viewport.yMax))}',
        )
        .join(' ');
  }

  double _niceStep(double rawStep) {
    final safe = rawStep <= 0 ? 1.0 : rawStep;
    final exponent = math
        .pow(10, (math.log(safe) / math.ln10).floor())
        .toDouble();
    final normalized = safe / exponent;
    final nice = normalized < 1.5
        ? 1.0
        : normalized < 3
        ? 2.0
        : normalized < 7
        ? 5.0
        : 10.0;
    return nice * exponent;
  }

  String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  String _fmt(num value) =>
      value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
}
