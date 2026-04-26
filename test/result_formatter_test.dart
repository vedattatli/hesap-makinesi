import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/core/calculator/src/result_formatter.dart';

void main() {
  group('ResultFormatter', () {
    final formatter = ResultFormatter();

    test('exact auto format prefers fraction', () {
      final formatted = formatter.format(
        RationalValue(BigInt.one, BigInt.from(2)),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.auto,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, '1/2');
      expect(formatted.decimalDisplayResult, '0.5');
    });

    test('exact decimal format prefers decimal', () {
      final formatted = formatter.format(
        RationalValue(BigInt.one, BigInt.from(2)),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.decimal,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, '0.5');
      expect(formatted.fractionDisplayResult, '1/2');
    });

    test('exact fraction format prefers fraction', () {
      final formatted = formatter.format(
        RationalValue(BigInt.one, BigInt.from(2)),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.fraction,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, '1/2');
    });

    test('integer rational displays without denominator', () {
      final formatted = formatter.format(
        RationalValue(BigInt.from(2), BigInt.one),
        const CalculationContext(numericMode: NumericMode.exact),
      );

      expect(formatted.displayResult, '2');
    });

    test('approximate values keep noise cleanup', () {
      final formatted = formatter.format(
        DoubleValue(0.000000000000001),
        const CalculationContext(
          numericMode: NumericMode.approximate,
          precision: 10,
        ),
      );

      expect(formatted.displayResult, '0');
    });

    test('auto symbolic format prefers symbolic display', () {
      final formatted = formatter.format(
        SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.auto,
          precision: 6,
        ),
      );

      expect(formatted.displayResult, '\u221A2');
      expect(formatted.decimalDisplayResult, isNotEmpty);
    });

    test('decimal symbolic format prefers decimal display', () {
      final formatted = formatter.format(
        SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.decimal,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, '1.4142');
      expect(formatted.symbolicDisplayResult, '\u221A2');
    });

    test('symbolic format keeps symbolic primary display', () {
      final formatted = formatter.format(
        SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.symbolic,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, '\u221A2');
      expect(formatted.symbolicDisplayResult, '\u221A2');
    });

    test('formats pure imaginary complex values cleanly', () {
      final formatted = formatter.format(
        ComplexValue(
          realPart: RationalValue.zero,
          imaginaryPart: RationalValue.one,
        ),
        const CalculationContext(
          numericMode: NumericMode.exact,
          calculationDomain: CalculationDomain.complex,
          numberFormatStyle: NumberFormatStyle.symbolic,
          precision: 6,
        ),
      );

      expect(formatted.displayResult, 'i');
      expect(formatted.polarDisplayResult, isNotNull);
    });

    test('formats rectangular exact complex values', () {
      final formatted = formatter.format(
        ComplexValue(
          realPart: RationalValue(BigInt.from(11), BigInt.from(25)),
          imaginaryPart: RationalValue(BigInt.from(2), BigInt.from(25)),
        ),
        const CalculationContext(
          numericMode: NumericMode.exact,
          calculationDomain: CalculationDomain.complex,
          numberFormatStyle: NumberFormatStyle.symbolic,
          precision: 6,
        ),
      );

      expect(formatted.displayResult, '11/25 + 2i/25');
      expect(formatted.decimalDisplayResult, '0.44 + 0.08i');
      expect(formatted.polarDisplayResult, isNotNull);
    });

    test('decimal format prefers decimal rectangular complex display', () {
      final formatted = formatter.format(
        ComplexValue(
          realPart: RationalValue.zero,
          imaginaryPart: SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
        ),
        const CalculationContext(
          numericMode: NumericMode.exact,
          calculationDomain: CalculationDomain.complex,
          numberFormatStyle: NumberFormatStyle.decimal,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, '1.4142i');
      expect(formatted.symbolicDisplayResult, '\u221A2i');
    });

    test('formats vector displays and shape metadata', () {
      final formatted = formatter.format(
        VectorValue(<CalculatorValue>[
          RationalValue.one,
          RationalValue.fromInt(2),
          SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
        ]),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.symbolic,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, '[1, 2, \u221A2]');
      expect(formatted.vectorDisplayResult, '[1, 2, \u221A2]');
      expect(formatted.shapeDisplayResult, '3 \u00D7 1');
    });

    test('formats matrix displays and shape metadata', () {
      final formatted = formatter.format(
        MatrixValue(<List<CalculatorValue>>[
          <CalculatorValue>[RationalValue.one, RationalValue.fromInt(2)],
          <CalculatorValue>[RationalValue.fromInt(3), RationalValue.fromInt(4)],
        ]),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.symbolic,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, '[[1, 2], [3, 4]]');
      expect(formatted.matrixDisplayResult, '[[1, 2], [3, 4]]');
      expect(formatted.shapeDisplayResult, '2 \u00D7 2');
    });

    test('decimal format applies to matrix entries', () {
      final formatted = formatter.format(
        MatrixValue(<List<CalculatorValue>>[
          <CalculatorValue>[
            RationalValue(BigInt.one, BigInt.from(2)),
            SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
          ],
        ]),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.decimal,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, '[[0.5, 1.4142]]');
      expect(formatted.symbolicDisplayResult, '[[1/2, \u221A2]]');
    });

    test('large matrices use preview display while keeping full matrix result', () {
      final matrix = MatrixValue(
        List<List<CalculatorValue>>.generate(
          7,
          (row) => List<CalculatorValue>.generate(
            7,
            (column) => RationalValue.fromInt(row * 7 + column + 1),
          ),
        ),
      );

      final formatted = formatter.format(
        matrix,
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.symbolic,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, contains('...'));
      expect(formatted.matrixDisplayResult, isNotNull);
      expect(formatted.matrixDisplayResult, isNot(contains('...')));
      expect(formatted.shapeDisplayResult, '7 \u00D7 7');
    });

    test('formats exact unit values with base and dimension alternatives', () {
      final meter = UnitExpression.fromDefinition(UnitRegistry.instance.lookup('m')!);
      final formatted = formatter.format(
        UnitValue.fromDisplayMagnitude(
          displayMagnitude: RationalValue(BigInt.from(16), BigInt.from(5)),
          displayUnit: meter,
        ),
        const CalculationContext(
          numericMode: NumericMode.exact,
          unitMode: UnitMode.enabled,
          numberFormatStyle: NumberFormatStyle.auto,
          precision: 6,
        ),
      );

      expect(formatted.displayResult, '16/5 m');
      expect(formatted.unitDisplayResult, '16/5 m');
      expect(formatted.baseUnitDisplayResult, '16/5 m');
      expect(formatted.dimensionDisplayResult, 'L');
    });

    test('formats decimal unit values when decimal style is selected', () {
      final velocity = UnitExpression(
        exponents: const <String, int>{'km': 1, 'h': -1},
        displaySymbols: const <String, String>{'km': 'km', 'h': 'h'},
        dimension: const DimensionVector(length: 1, time: -1),
        factorToBase: RationalValue(BigInt.from(5), BigInt.from(18)),
      );
      final formatted = formatter.format(
        UnitValue.fromDisplayMagnitude(
          displayMagnitude: RationalValue(BigInt.from(5), BigInt.from(2)),
          displayUnit: velocity,
        ),
        const CalculationContext(
          numericMode: NumericMode.exact,
          unitMode: UnitMode.enabled,
          numberFormatStyle: NumberFormatStyle.decimal,
          precision: 4,
        ),
      );

      expect(formatted.displayResult, '2.5 km/h');
      expect(formatted.unitDisplayResult, '5/2 km/h');
      expect(formatted.decimalDisplayResult, '2.5 km/h');
    });

    test('formats symbolic unit magnitudes cleanly', () {
      final meter = UnitExpression.fromDefinition(UnitRegistry.instance.lookup('m')!);
      final formatted = formatter.format(
        UnitValue.fromDisplayMagnitude(
          displayMagnitude: SymbolicValue.fromFactor(RadicalFactor(BigInt.from(2))),
          displayUnit: meter,
        ),
        const CalculationContext(
          numericMode: NumericMode.exact,
          unitMode: UnitMode.enabled,
          numberFormatStyle: NumberFormatStyle.symbolic,
          precision: 6,
        ),
      );

      expect(formatted.displayResult, '\u221A2 m');
      expect(formatted.unitDisplayResult, '\u221A2 m');
    });

    test('formats vectors with unit entries through scalar formatter', () {
      final meter = UnitExpression.fromDefinition(UnitRegistry.instance.lookup('m')!);
      final formatted = formatter.format(
        VectorValue(<CalculatorValue>[
          UnitValue.fromDisplayMagnitude(
            displayMagnitude: RationalValue.one,
            displayUnit: meter,
          ),
          UnitValue.fromDisplayMagnitude(
            displayMagnitude: RationalValue(BigInt.one, BigInt.from(2)),
            displayUnit: meter,
          ),
        ]),
        const CalculationContext(
          numericMode: NumericMode.exact,
          unitMode: UnitMode.enabled,
          numberFormatStyle: NumberFormatStyle.symbolic,
          precision: 6,
        ),
      );

      expect(formatted.displayResult, '[1 m, 1/2 m]');
      expect(formatted.shapeDisplayResult, '2 \u00D7 1');
    });

    test('formats dataset displays with statistics metadata', () {
      final formatted = formatter.format(
        DatasetValue(<CalculatorValue>[
          RationalValue.one,
          RationalValue.fromInt(2),
          RationalValue.fromInt(3),
          RationalValue.fromInt(4),
        ]),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.auto,
          precision: 6,
        ),
        statisticName: 'data',
        sampleSize: 4,
      );

      expect(formatted.displayResult, 'data(1, 2, 3, 4)');
      expect(formatted.datasetDisplayResult, 'data(1, 2, 3, 4)');
      expect(formatted.sampleSize, 4);
    });

    test('large datasets use preview while keeping full dataset display', () {
      final formatted = formatter.format(
        DatasetValue(
          List<CalculatorValue>.generate(
            60,
            (index) => RationalValue.fromInt(index + 1),
          ),
        ),
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.auto,
          precision: 6,
        ),
        statisticName: 'data',
        sampleSize: 60,
      );

      expect(formatted.displayResult, contains('...; n=60'));
      expect(formatted.datasetDisplayResult, isNotNull);
      expect(formatted.datasetDisplayResult, isNot(contains('...')));
    });

    test('formats regression displays and summary metadata', () {
      final regression = RegressionValue(
        slope: RationalValue.fromInt(2),
        intercept: RationalValue.zero,
        r: RationalValue.one,
        rSquared: RationalValue.one,
        sampleSize: 3,
        xMean: RationalValue.fromInt(2),
        yMean: RationalValue.fromInt(4),
      );

      final formatted = formatter.format(
        regression,
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.symbolic,
          precision: 6,
        ),
        statisticName: 'linreg',
        sampleSize: 3,
      );

      expect(formatted.displayResult, 'y = 2x + 0');
      expect(formatted.regressionDisplayResult, 'y = 2x + 0');
      expect(formatted.alternativeResults['slope'], '2');
      expect(formatted.alternativeResults['intercept'], '0');
      expect(formatted.summaryDisplayResult, contains('r = 1'));
    });

    test('formats probability metadata without changing scalar display', () {
      final formatted = formatter.format(
        const DoubleValue(0.5),
        const CalculationContext(
          numericMode: NumericMode.approximate,
          numberFormatStyle: NumberFormatStyle.decimal,
          precision: 6,
        ),
        statisticName: 'normalCdf',
      );

      expect(formatted.displayResult, '0.5');
      expect(formatted.probabilityDisplayResult, isNotNull);
      expect(formatted.probabilityDisplayResult, contains('Normal'));
    });

    test('formats function displays without evaluating samples', () {
      final function = FunctionValue(
        function: FunctionExpression(
          originalExpression: 'x^2',
          expressionAst: const BinaryOperationNode(
            left: ConstantNode(name: 'x', position: 0),
            operator: '^',
            right: NumberNode(rawValue: '2', value: 2, position: 2),
            position: 0,
          ),
        ),
      );

      final formatted = formatter.format(
        function,
        const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.symbolic,
        ),
      );

      expect(formatted.displayResult, 'f(x) = x ^ 2');
      expect(formatted.functionDisplayResult, 'f(x) = x ^ 2');
    });

    test('formats plot displays as compact graph summaries', () {
      final plot = PlotValue(
        viewport: GraphViewport(
          xMin: -5,
          xMax: 5,
          yMin: -1,
          yMax: 25,
          autoY: true,
        ),
        autoYUsed: true,
        series: const <PlotSeries>[
          PlotSeries(
            expression: 'x^2',
            normalizedExpression: 'x ^ 2',
            label: 'y = x ^ 2',
            segments: <PlotSegment>[
              PlotSegment(<PlotPoint>[
                PlotPoint(x: -1, y: 1, isDefined: true),
                PlotPoint(x: 0, y: 0, isDefined: true),
                PlotPoint(x: 1, y: 1, isDefined: true),
              ]),
            ],
            sampleCount: 3,
            definedPointCount: 3,
            undefinedPointCount: 0,
          ),
        ],
      );

      final formatted = formatter.format(
        plot,
        const CalculationContext(
          numericMode: NumericMode.approximate,
          numberFormatStyle: NumberFormatStyle.auto,
        ),
      );

      expect(formatted.displayResult, 'Plot: y = x ^ 2');
      expect(formatted.plotDisplayResult, 'Plot: y = x ^ 2');
      expect(formatted.graphDisplayResult, contains('1 series'));
      expect(formatted.viewportDisplayResult, contains('x ∈'));
      expect(formatted.plotPointCount, 3);
    });
  });
}
