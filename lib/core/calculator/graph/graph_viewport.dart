import 'dart:math' as math;

/// Rectangular viewport used by graph sampling and Flutter graph presentation.
class GraphViewport {
  GraphViewport({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    this.autoY = false,
  }) {
    if (!xMin.isFinite || !xMax.isFinite || !yMin.isFinite || !yMax.isFinite) {
      throw ArgumentError('viewport values must be finite');
    }
    if (xMin >= xMax) {
      throw ArgumentError('xMin must be less than xMax');
    }
    if (!autoY && yMin >= yMax) {
      throw ArgumentError('yMin must be less than yMax');
    }
  }

  factory GraphViewport.defaultViewport() {
    return GraphViewport(
      xMin: -10,
      xMax: 10,
      yMin: -10,
      yMax: 10,
      autoY: true,
    );
  }

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final bool autoY;

  double get width => xMax - xMin;

  double get height => yMax - yMin;

  GraphViewport copyWith({
    double? xMin,
    double? xMax,
    double? yMin,
    double? yMax,
    bool? autoY,
  }) {
    return GraphViewport(
      xMin: xMin ?? this.xMin,
      xMax: xMax ?? this.xMax,
      yMin: yMin ?? this.yMin,
      yMax: yMax ?? this.yMax,
      autoY: autoY ?? this.autoY,
    );
  }

  GraphViewport pan({
    required double deltaX,
    required double deltaY,
  }) {
    return GraphViewport(
      xMin: xMin + deltaX,
      xMax: xMax + deltaX,
      yMin: yMin + deltaY,
      yMax: yMax + deltaY,
      autoY: autoY,
    );
  }

  GraphViewport zoom({
    required double scale,
    double? centerX,
    double? centerY,
  }) {
    final safeScale = scale <= 0 ? 1.0 : scale;
    final pivotX = centerX ?? (xMin + xMax) / 2;
    final pivotY = centerY ?? (yMin + yMax) / 2;
    final nextHalfWidth = width * safeScale / 2;
    final nextHalfHeight = height * safeScale / 2;
    return GraphViewport(
      xMin: pivotX - nextHalfWidth,
      xMax: pivotX + nextHalfWidth,
      yMin: pivotY - nextHalfHeight,
      yMax: pivotY + nextHalfHeight,
      autoY: autoY,
    );
  }

  String toDisplayString() {
    return 'x ∈ [${_formatNumber(xMin)}, ${_formatNumber(xMax)}], '
        'y ∈ [${_formatNumber(yMin)}, ${_formatNumber(yMax)}]'
        '${autoY ? ' (autoY)' : ''}';
  }

  String _formatNumber(double value) {
    final normalized = value.abs() < 1e-12 ? 0.0 : value;
    if (normalized == normalized.roundToDouble()) {
      return normalized.toInt().toString();
    }
    return normalized.toStringAsFixed(
      math.max(0, math.min(6, normalized.abs() >= 100 ? 2 : 4)),
    ).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
