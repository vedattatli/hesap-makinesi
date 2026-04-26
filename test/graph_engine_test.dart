import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  ExpressionNode parseExpression(String source) {
    const lexer = CalculatorLexer();
    const parser = ExpressionParser();
    return parser.parse(lexer.tokenize(source));
  }

  FunctionExpression functionOf(String source) {
    return FunctionExpression(
      originalExpression: source,
      expressionAst: parseExpression(source),
    );
  }

  group('GraphViewport', () {
    test('creates valid viewport and supports pan/zoom', () {
      final viewport = GraphViewport(
        xMin: -2,
        xMax: 2,
        yMin: -3,
        yMax: 3,
      );

      final panned = viewport.pan(deltaX: 1, deltaY: -1);
      final zoomed = viewport.zoom(scale: 0.5);

      expect(panned.xMin, -1);
      expect(panned.yMax, 2);
      expect(zoomed.width, closeTo(2, 1e-12));
    });

    test('rejects invalid viewport values', () {
      expect(
        () => GraphViewport(xMin: 1, xMax: 1, yMin: -1, yMax: 1),
        throwsArgumentError,
      );
      expect(
        () => GraphViewport(
          xMin: double.nan,
          xMax: 1,
          yMin: -1,
          yMax: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('GraphEngine sampling', () {
    const engine = GraphEngine();
    const context = CalculationContext(
      numericMode: NumericMode.approximate,
      angleMode: AngleMode.radian,
    );

    test('plots x^2 over [-2, 2] as finite segments', () {
      final plot = engine.plotFunction(
        functionOf('x^2'),
        GraphViewport(xMin: -2, xMax: 2, yMin: -1, yMax: 4),
        context,
      );

      expect(plot.seriesCount, 1);
      expect(plot.segmentCount, 1);
      expect(plot.pointCount, greaterThanOrEqualTo(512));
    });

    test('sqrt(x) only plots defined region', () {
      final plot = engine.plotFunction(
        functionOf('sqrt(x)'),
        GraphViewport(xMin: -1, xMax: 4, yMin: -1, yMax: 3),
        context,
      );

      final firstX = plot.series.single.segments.first.points.first.x;
      expect(firstX, greaterThanOrEqualTo(0));
    });

    test('1/x creates at least two segments around zero', () {
      final plot = engine.plotFunction(
        functionOf('1/x'),
        GraphViewport(xMin: -1, xMax: 1, yMin: -10, yMax: 10),
        context,
      );

      expect(plot.series.single.segments.length, greaterThanOrEqualTo(2));
    });

    test('tan(x) does not connect across asymptotes', () {
      final plot = engine.plotFunction(
        functionOf('tan(x)'),
        GraphViewport(
          xMin: -math.pi,
          xMax: math.pi,
          yMin: -10,
          yMax: 10,
        ),
        context,
      );

      expect(plot.series.single.segments.length, greaterThanOrEqualTo(3));
    });

    test('adaptive sampling respects max sample guard', () {
      final plot = engine.plotFunction(
        functionOf('sin(x)'),
        GraphViewport(xMin: -2, xMax: 2, yMin: -2, yMax: 2),
        context,
        options: const GraphSamplingOptions(
          initialSamples: 32,
          maxSamples: 64,
          adaptiveDepth: 6,
        ),
      );

      expect(plot.pointCount, lessThanOrEqualTo(64));
    });
  });
}
