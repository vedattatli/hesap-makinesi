import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';

void main() {
  group('CalculatorEngine approximate mode', () {
    const engine = CalculatorEngine();
    const tolerance = 1e-10;

    test('evaluates operator precedence', () {
      final outcome = engine.evaluate('2 + 3 * 4');

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.numericValue, closeTo(14, tolerance));
    });

    test('evaluates parentheses correctly', () {
      final outcome = engine.evaluate('(2 + 3) * 4');

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.numericValue, closeTo(20, tolerance));
    });

    test('evaluates right associative powers', () {
      final outcome = engine.evaluate('2^3^2');

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.numericValue, closeTo(512, tolerance));
    });

    test('supports implicit multiplication with constants', () {
      final outcome = engine.evaluate('2pi');

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.numericValue, closeTo(2 * math.pi, tolerance));
      expect(outcome.result!.normalizedExpression, '2 * pi');
    });

    test('keeps sqrt(2) approximate in approximate mode', () {
      final outcome = engine.evaluate('sqrt(2)');

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.displayResult, isNot('√2'));
      expect(outcome.result!.numericValue, closeTo(math.sqrt(2), tolerance));
      expect(outcome.result!.valueKind, CalculatorValueKind.doubleValue);
    });

    test('keeps pi approximate in approximate mode', () {
      final outcome = engine.evaluate('pi');

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.displayResult, isNot('π'));
      expect(outcome.result!.numericValue, closeTo(math.pi, tolerance));
    });

    test('evaluates sine in DEG mode', () {
      final outcome = engine.evaluate(
        'sin(30)',
        context: const CalculationContext(angleMode: AngleMode.degree),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.numericValue, closeTo(0.5, tolerance));
    });

    test('evaluates sine in RAD mode', () {
      final outcome = engine.evaluate(
        'sin(pi/2)',
        context: const CalculationContext(angleMode: AngleMode.radian),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.numericValue, closeTo(1, tolerance));
    });

    test('evaluates sine in GRAD mode', () {
      final outcome = engine.evaluate(
        'sin(100)',
        context: const CalculationContext(angleMode: AngleMode.gradian),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.numericValue, closeTo(1, tolerance));
    });

    test('formats floating point noise near zero cleanly', () {
      final outcome = engine.evaluate(
        'cos(90)',
        context: const CalculationContext(
          angleMode: AngleMode.degree,
          precision: 10,
        ),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.displayResult, '0');
    });

    test('keeps 1/3 + 1/6 as decimal in approximate mode', () {
      final outcome = engine.evaluate('1/3 + 1/6');

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.displayResult, '0.5');
      expect(outcome.result!.numericMode, NumericMode.approximate);
    });

    test('returns division by zero error', () {
      final outcome = engine.evaluate('1/0');

      expect(outcome.isFailure, isTrue);
      expect(outcome.error!.type, CalculationErrorType.divisionByZero);
    });

    test('returns domain error for sqrt(-1)', () {
      final outcome = engine.evaluate('sqrt(-1)');

      expect(outcome.isFailure, isTrue);
      expect(outcome.error!.type, CalculationErrorType.domainError);
    });

    test('returns warning for tangent near undefined degree point', () {
      final outcome = engine.evaluate(
        'tan(90)',
        context: const CalculationContext(angleMode: AngleMode.degree),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.warnings, isNotEmpty);
    });
  });

  group('CalculatorEngine exact symbolic-lite mode', () {
    const engine = CalculatorEngine();
    const exact = CalculationContext(numericMode: NumericMode.exact);
    const exactDeg = CalculationContext(
      numericMode: NumericMode.exact,
      angleMode: AngleMode.degree,
    );
    const exactRad = CalculationContext(
      numericMode: NumericMode.exact,
      angleMode: AngleMode.radian,
    );
    const exactGrad = CalculationContext(
      numericMode: NumericMode.exact,
      angleMode: AngleMode.gradian,
    );

    test('keeps rational arithmetic exact', () {
      final outcome = engine.evaluate('1/3 + 1/6', context: exact);

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.displayResult, '1/2');
      expect(outcome.result!.decimalDisplayResult, '0.5');
      expect(outcome.result!.valueKind, CalculatorValueKind.rational);
      expect(outcome.result!.isApproximate, isFalse);
    });

    test('simplifies radicals exactly', () {
      expect(engine.evaluate('sqrt(4)', context: exact).result!.displayResult, '2');
      expect(
        engine.evaluate('sqrt(9/16)', context: exact).result!.displayResult,
        '3/4',
      );
      expect(
        engine.evaluate('sqrt(1/4)', context: exact).result!.displayResult,
        '1/2',
      );
      expect(engine.evaluate('sqrt(2)', context: exact).result!.displayResult, '√2');
      expect(engine.evaluate('sqrt(8)', context: exact).result!.displayResult, '2√2');
      expect(
        engine.evaluate('sqrt(12)', context: exact).result!.displayResult,
        '2√3',
      );
      expect(
        engine.evaluate('sqrt(18)', context: exact).result!.displayResult,
        '3√2',
      );
      expect(
        engine.evaluate('sqrt(50)', context: exact).result!.displayResult,
        '5√2',
      );
      expect(
        engine.evaluate('sqrt(8/9)', context: exact).result!.displayResult,
        '2√2/3',
      );
      expect(
        engine.evaluate('sqrt(12/25)', context: exact).result!.displayResult,
        '2√3/5',
      );
    });

    test('handles symbolic arithmetic with radicals', () {
      expect(
        engine.evaluate('sqrt(2) + sqrt(8)', context: exact).result!.displayResult,
        '3√2',
      );
      expect(
        engine.evaluate('sqrt(2) - sqrt(8)', context: exact).result!.displayResult,
        '-√2',
      );
      expect(
        engine.evaluate('sqrt(2) * sqrt(8)', context: exact).result!.displayResult,
        '4',
      );
      expect(
        engine.evaluate('sqrt(2) * sqrt(3)', context: exact).result!.displayResult,
        '√6',
      );
      expect(
        engine.evaluate('sqrt(3) * sqrt(3)', context: exact).result!.displayResult,
        '3',
      );
      expect(
        engine.evaluate('sqrt(2) / sqrt(8)', context: exact).result!.displayResult,
        '1/2',
      );
      expect(
        engine.evaluate('sqrt(8) / sqrt(2)', context: exact).result!.displayResult,
        '2',
      );
      expect(
        engine.evaluate('sqrt(2)^2', context: exact).result!.displayResult,
        '2',
      );
      expect(
        engine.evaluate('sqrt(2)^3', context: exact).result!.displayResult,
        '2√2',
      );
      expect(engine.evaluate('2^0.5', context: exact).result!.displayResult, '√2');
      expect(
        engine.evaluate('pow(2, 0.5)', context: exact).result!.displayResult,
        '√2',
      );
    });

    test('keeps symbolic constants exact', () {
      final pi = engine.evaluate('pi', context: exact).result!;
      final unicodePi = engine.evaluate('π', context: exact).result!;
      final eValue = engine.evaluate('e', context: exact).result!;

      expect(pi.displayResult, 'π');
      expect(unicodePi.displayResult, 'π');
      expect(pi.warnings, isEmpty);
      expect(pi.numericValue, closeTo(math.pi, 1e-10));
      expect(pi.decimalDisplayResult, isNotEmpty);

      expect(eValue.displayResult, 'e');
      expect(eValue.warnings, isEmpty);
      expect(eValue.numericValue, closeTo(math.e, 1e-10));
    });

    test('combines symbolic constants', () {
      expect(engine.evaluate('2*pi', context: exact).result!.displayResult, '2π');
      expect(engine.evaluate('pi/2', context: exact).result!.displayResult, 'π/2');
      expect(
        engine.evaluate('pi + pi', context: exact).result!.displayResult,
        '2π',
      );
      expect(
        engine.evaluate('2*pi + pi', context: exact).result!.displayResult,
        '3π',
      );
      expect(engine.evaluate('e + e', context: exact).result!.displayResult, '2e');
    });

    test('returns exact trig values in RAD mode', () {
      expect(engine.evaluate('sin(0)', context: exactRad).result!.displayResult, '0');
      expect(engine.evaluate('cos(0)', context: exactRad).result!.displayResult, '1');
      expect(engine.evaluate('tan(0)', context: exactRad).result!.displayResult, '0');
      expect(
        engine.evaluate('sin(pi/6)', context: exactRad).result!.displayResult,
        '1/2',
      );
      expect(
        engine.evaluate('cos(pi/3)', context: exactRad).result!.displayResult,
        '1/2',
      );
      expect(
        engine.evaluate('tan(pi/4)', context: exactRad).result!.displayResult,
        '1',
      );
      expect(
        engine.evaluate('sin(pi/4)', context: exactRad).result!.displayResult,
        '√2/2',
      );
      expect(
        engine.evaluate('cos(pi/4)', context: exactRad).result!.displayResult,
        '√2/2',
      );
      expect(
        engine.evaluate('sin(pi/3)', context: exactRad).result!.displayResult,
        '√3/2',
      );
      expect(
        engine.evaluate('cos(pi/6)', context: exactRad).result!.displayResult,
        '√3/2',
      );
      expect(
        engine.evaluate('sin(pi/2)', context: exactRad).result!.displayResult,
        '1',
      );
      expect(
        engine.evaluate('cos(pi)', context: exactRad).result!.displayResult,
        '-1',
      );
      expect(
        engine.evaluate('sin(pi)', context: exactRad).result!.displayResult,
        '0',
      );
    });

    test('returns exact trig values in DEG mode', () {
      expect(engine.evaluate('sin(30)', context: exactDeg).result!.displayResult, '1/2');
      expect(engine.evaluate('cos(60)', context: exactDeg).result!.displayResult, '1/2');
      expect(engine.evaluate('tan(45)', context: exactDeg).result!.displayResult, '1');
      expect(
        engine.evaluate('sin(45)', context: exactDeg).result!.displayResult,
        '√2/2',
      );
      expect(
        engine.evaluate('cos(45)', context: exactDeg).result!.displayResult,
        '√2/2',
      );
      expect(
        engine.evaluate('sin(60)', context: exactDeg).result!.displayResult,
        '√3/2',
      );
      expect(
        engine.evaluate('cos(30)', context: exactDeg).result!.displayResult,
        '√3/2',
      );
      expect(engine.evaluate('sin(90)', context: exactDeg).result!.displayResult, '1');
      expect(
        engine.evaluate('cos(180)', context: exactDeg).result!.displayResult,
        '-1',
      );
    });

    test('returns exact trig values in GRAD mode', () {
      expect(engine.evaluate('sin(100)', context: exactGrad).result!.displayResult, '1');
      expect(
        engine.evaluate('cos(200)', context: exactGrad).result!.displayResult,
        '-1',
      );
      expect(engine.evaluate('tan(50)', context: exactGrad).result!.displayResult, '1');
      expect(
        engine.evaluate('sin(50)', context: exactGrad).result!.displayResult,
        '√2/2',
      );
      expect(
        engine.evaluate('cos(50)', context: exactGrad).result!.displayResult,
        '√2/2',
      );
    });

    test('returns exact inverse trig values', () {
      expect(engine.evaluate('asin(0)', context: exactRad).result!.displayResult, '0');
      expect(
        engine.evaluate('asin(1/2)', context: exactRad).result!.displayResult,
        'π/6',
      );
      expect(
        engine.evaluate('asin(1)', context: exactRad).result!.displayResult,
        'π/2',
      );
      expect(
        engine.evaluate('acos(1)', context: exactRad).result!.displayResult,
        '0',
      );
      expect(
        engine.evaluate('acos(1/2)', context: exactRad).result!.displayResult,
        'π/3',
      );
      expect(
        engine.evaluate('acos(0)', context: exactRad).result!.displayResult,
        'π/2',
      );
      expect(
        engine.evaluate('atan(0)', context: exactRad).result!.displayResult,
        '0',
      );
      expect(
        engine.evaluate('atan(1)', context: exactRad).result!.displayResult,
        'π/4',
      );
      expect(
        engine.evaluate('asin(1/2)', context: exactDeg).result!.displayResult,
        '30',
      );
      expect(
        engine.evaluate('asin(1)', context: exactDeg).result!.displayResult,
        '90',
      );
      expect(
        engine.evaluate('acos(1/2)', context: exactDeg).result!.displayResult,
        '60',
      );
      expect(
        engine.evaluate('acos(0)', context: exactDeg).result!.displayResult,
        '90',
      );
      expect(
        engine.evaluate('atan(1)', context: exactDeg).result!.displayResult,
        '45',
      );
      expect(
        engine.evaluate('asin(1)', context: exactGrad).result!.displayResult,
        '100',
      );
      expect(
        engine.evaluate('acos(0)', context: exactGrad).result!.displayResult,
        '100',
      );
      expect(
        engine.evaluate('atan(1)', context: exactGrad).result!.displayResult,
        '50',
      );
    });

    test('keeps symbolic exact results warning-free', () {
      expect(engine.evaluate('sqrt(2)', context: exact).result!.warnings, isEmpty);
      expect(engine.evaluate('pi', context: exact).result!.warnings, isEmpty);
      expect(
        engine.evaluate('sin(pi/6)', context: exactRad).result!.warnings,
        isEmpty,
      );
    });

    test('falls back with warning for unsupported exact symbolic operations', () {
      final lnPi = engine.evaluate('ln(pi)', context: exact);
      final sinSqrtTwo = engine.evaluate('sin(sqrt(2))', context: exactDeg);

      expect(lnPi.isSuccess, isTrue);
      expect(lnPi.result!.warnings, isNotEmpty);
      expect(lnPi.result!.isApproximate, isTrue);

      expect(sinSqrtTwo.isSuccess, isTrue);
      expect(sinSqrtTwo.result!.warnings, isNotEmpty);
      expect(sinSqrtTwo.result!.isApproximate, isTrue);
    });

    test('raises domain style error for tan(pi/2) exact', () {
      final outcome = engine.evaluate('tan(pi/2)', context: exactRad);

      expect(outcome.isFailure, isTrue);
      expect(outcome.error!.type, CalculationErrorType.domainError);
    });

    test('decimal format shows decimal primary and symbolic alternative', () {
      final outcome = engine.evaluate(
        'sqrt(2)',
        context: const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.decimal,
          precision: 4,
        ),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.displayResult, '1.4142');
      expect(outcome.result!.symbolicDisplayResult, '√2');
    });

    test('symbolic format keeps symbolic primary display', () {
      final outcome = engine.evaluate(
        'sqrt(2)',
        context: const CalculationContext(
          numericMode: NumericMode.exact,
          numberFormatStyle: NumberFormatStyle.symbolic,
          precision: 4,
        ),
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.displayResult, '√2');
      expect(outcome.result!.valueKind, CalculatorValueKind.symbolic);
    });
  });

  group('CalculatorEngine complex domain', () {
    const engine = CalculatorEngine();
    const complexApprox = CalculationContext(
      calculationDomain: CalculationDomain.complex,
    );
    const complexExact = CalculationContext(
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.complex,
    );
    const complexExactRad = CalculationContext(
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.complex,
      angleMode: AngleMode.radian,
    );
    const complexExactDeg = CalculationContext(
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.complex,
      angleMode: AngleMode.degree,
    );
    const complexExactGrad = CalculationContext(
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.complex,
      angleMode: AngleMode.gradian,
    );

    test('real mode keeps i unsupported', () {
      final outcome = engine.evaluate('i');

      expect(outcome.isFailure, isTrue);
      expect(outcome.error!.type, CalculationErrorType.unknownConstant);
    });

    test('complex mode recognizes imaginary unit and basic powers', () {
      expect(
        engine.evaluate('i', context: complexExact).result!.displayResult,
        'i',
      );
      expect(
        engine.evaluate('2i', context: complexExact).result!.displayResult,
        '2i',
      );
      expect(
        engine.evaluate('3+4i', context: complexExact).result!.displayResult,
        '3 + 4i',
      );
      expect(
        engine.evaluate('3-4i', context: complexExact).result!.displayResult,
        '3 - 4i',
      );
      expect(
        engine.evaluate('i^2', context: complexExact).result!.displayResult,
        '-1',
      );
      expect(
        engine.evaluate('i*i', context: complexExact).result!.displayResult,
        '-1',
      );
      expect(
        engine.evaluate('i^3', context: complexExact).result!.displayResult,
        '-i',
      );
      expect(
        engine.evaluate('i^4', context: complexExact).result!.displayResult,
        '1',
      );
      expect(
        engine.evaluate('1/i', context: complexExact).result!.displayResult,
        '-i',
      );
      expect(
        engine.evaluate('-i', context: complexExact).result!.displayResult,
        '-i',
      );
    });

    test('complex arithmetic stays exact when possible', () {
      expect(
        engine
            .evaluate('(3+4i)+(1-2i)', context: complexExact)
            .result!
            .displayResult,
        '4 + 2i',
      );
      expect(
        engine
            .evaluate('(3+4i)-(1-2i)', context: complexExact)
            .result!
            .displayResult,
        '2 + 6i',
      );
      expect(
        engine
            .evaluate('(1+2i)*(3+4i)', context: complexExact)
            .result!
            .displayResult,
        '-5 + 10i',
      );
      expect(
        engine
            .evaluate('(1+2i)/(3+4i)', context: complexExact)
            .result!
            .displayResult,
        '11/25 + 2i/25',
      );
      expect(
        engine
            .evaluate('(1+i)(1-i)', context: complexExact)
            .result!
            .displayResult,
        '2',
      );
      expect(
        engine.evaluate('(1+i)^2', context: complexExact).result!.displayResult,
        '2i',
      );
      expect(
        engine.evaluate('i^-1', context: complexExact).result!.displayResult,
        '-i',
      );
    });

    test('complex sqrt supports negative real inputs', () {
      expect(
        engine.evaluate('sqrt(-1)', context: complexExact).result!.displayResult,
        'i',
      );
      expect(
        engine.evaluate('sqrt(-4)', context: complexExact).result!.displayResult,
        '2i',
      );
      expect(
        engine
            .evaluate('sqrt(-9/4)', context: complexExact)
            .result!
            .displayResult,
        '3i/2',
      );
      expect(
        engine.evaluate('sqrt(-2)', context: complexExact).result!.displayResult,
        '\u221A2i',
      );
      expect(
        engine.evaluate('(-1)^0.5', context: complexExact).result!.displayResult,
        'i',
      );
      expect(
        engine
            .evaluate('pow(-1, 0.5)', context: complexExact)
            .result!
            .displayResult,
        'i',
      );
    });

    test('complex helper functions expose parts and polar builders', () {
      expect(
        engine.evaluate('re(3+4i)', context: complexExact).result!.displayResult,
        '3',
      );
      expect(
        engine.evaluate('im(3+4i)', context: complexExact).result!.displayResult,
        '4',
      );
      expect(
        engine
            .evaluate('conj(3+4i)', context: complexExact)
            .result!
            .displayResult,
        '3 - 4i',
      );
      expect(
        engine
            .evaluate('abs(3+4i)', context: complexExact)
            .result!
            .displayResult,
        '5',
      );
      expect(
        engine.evaluate('arg(1+i)', context: complexExactRad).result!.displayResult,
        '\u03C0/4',
      );
      expect(
        engine.evaluate('arg(1+i)', context: complexExactDeg).result!.displayResult,
        '45',
      );
      expect(
        engine
            .evaluate('arg(1+i)', context: complexExactGrad)
            .result!
            .displayResult,
        '50',
      );
      expect(
        engine
            .evaluate('polar(1, pi/2)', context: complexExactRad)
            .result!
            .displayResult,
        'i',
      );
      expect(
        engine.evaluate('cis(pi)', context: complexExactRad).result!.displayResult,
        '-1',
      );
    });

    test('complex ln and exp return exact symbolic special cases', () {
      final lnNegativeOne = engine.evaluate('ln(-1)', context: complexExactRad);
      final lnI = engine.evaluate('ln(i)', context: complexExactRad);
      final expIPi = engine.evaluate('exp(i*pi)', context: complexExactRad);
      final expHalfTurn = engine.evaluate(
        'exp(i*pi/2)',
        context: complexExactRad,
      );

      expect(lnNegativeOne.isSuccess, isTrue);
      expect(lnNegativeOne.result!.displayResult, '\u03C0i');
      expect(lnNegativeOne.result!.warnings, isEmpty);

      expect(lnI.isSuccess, isTrue);
      expect(lnI.result!.displayResult, '\u03C0i/2');
      expect(lnI.result!.warnings, isEmpty);

      expect(expIPi.isSuccess, isTrue);
      expect(expIPi.result!.displayResult, '-1');

      expect(expHalfTurn.isSuccess, isTrue);
      expect(expHalfTurn.result!.displayResult, 'i');
    });

    test('approximate complex mode preserves decimal complex output', () {
      final outcome = engine.evaluate('sqrt(-2)', context: complexApprox);

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.valueKind, CalculatorValueKind.complex);
      expect(outcome.result!.displayResult, isNot('\u221A2i'));
      expect(outcome.result!.displayResult, contains('i'));
    });
  });

  group('CalculatorEngine vector and matrix support', () {
    const engine = CalculatorEngine();
    const exact = CalculationContext(numericMode: NumericMode.exact);
    const complexExact = CalculationContext(
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.complex,
    );

    test('parses vector literals and constructors', () {
      expect(engine.evaluate('vec(1,2,3)', context: exact).result!.displayResult, '[1, 2, 3]');
      expect(engine.evaluate('[1,2,3]', context: exact).result!.displayResult, '[1, 2, 3]');
    });

    test('supports vector arithmetic and helpers', () {
      expect(
        engine
            .evaluate('vec(1,2,3)+vec(4,5,6)', context: exact)
            .result!
            .displayResult,
        '[5, 7, 9]',
      );
      expect(
        engine
            .evaluate('vec(4,5,6)-vec(1,2,3)', context: exact)
            .result!
            .displayResult,
        '[3, 3, 3]',
      );
      expect(
        engine.evaluate('2*vec(1,2,3)', context: exact).result!.displayResult,
        '[2, 4, 6]',
      );
      expect(
        engine.evaluate('vec(1,2,3)*2', context: exact).result!.displayResult,
        '[2, 4, 6]',
      );
      expect(
        engine
            .evaluate('dot(vec(1,2,3),vec(4,5,6))', context: exact)
            .result!
            .displayResult,
        '32',
      );
      expect(
        engine
            .evaluate('cross(vec(1,0,0),vec(0,1,0))', context: exact)
            .result!
            .displayResult,
        '[0, 0, 1]',
      );
      expect(
        engine.evaluate('norm(vec(3,4))', context: exact).result!.displayResult,
        '5',
      );
      expect(
        engine.evaluate('unit(vec(3,4))', context: exact).result!.displayResult,
        '[3/5, 4/5]',
      );
    });

    test('parses matrix literals and constructors', () {
      expect(
        engine
            .evaluate('mat(2,2,1,2,3,4)', context: exact)
            .result!
            .displayResult,
        '[[1, 2], [3, 4]]',
      );
      expect(
        engine.evaluate('[[1,2],[3,4]]', context: exact).result!.displayResult,
        '[[1, 2], [3, 4]]',
      );
    });

    test('supports matrix operations', () {
      expect(
        engine
            .evaluate(
              'mat(2,2,1,2,3,4)+mat(2,2,5,6,7,8)',
              context: exact,
            )
            .result!
            .displayResult,
        '[[6, 8], [10, 12]]',
      );
      expect(
        engine
            .evaluate(
              'mat(2,2,5,6,7,8)-mat(2,2,1,2,3,4)',
              context: exact,
            )
            .result!
            .displayResult,
        '[[4, 4], [4, 4]]',
      );
      expect(
        engine
            .evaluate('2*mat(2,2,1,2,3,4)', context: exact)
            .result!
            .displayResult,
        '[[2, 4], [6, 8]]',
      );
      expect(
        engine
            .evaluate(
              'mat(2,2,1,2,3,4)*mat(2,2,5,6,7,8)',
              context: exact,
            )
            .result!
            .displayResult,
        '[[19, 22], [43, 50]]',
      );
      expect(
        engine
            .evaluate('mat(2,2,1,2,3,4)*vec(5,6)', context: exact)
            .result!
            .displayResult,
        '[17, 39]',
      );
      expect(
        engine
            .evaluate('transpose(mat(2,2,1,2,3,4))', context: exact)
            .result!
            .displayResult,
        '[[1, 3], [2, 4]]',
      );
      expect(
        engine.evaluate('det(mat(2,2,1,2,3,4))', context: exact).result!.displayResult,
        '-2',
      );
      expect(
        engine
            .evaluate('det(mat(3,3,1,2,3,0,1,4,5,6,0))', context: exact)
            .result!
            .displayResult,
        '1',
      );
      expect(
        engine
            .evaluate('inv(mat(2,2,1,2,3,4))', context: exact)
            .result!
            .displayResult,
        '[[-2, 1], [3/2, -1/2]]',
      );
      expect(
        engine.evaluate('identity(3)', context: exact).result!.displayResult,
        '[[1, 0, 0], [0, 1, 0], [0, 0, 1]]',
      );
      expect(
        engine.evaluate('zeros(2,3)', context: exact).result!.displayResult,
        '[[0, 0, 0], [0, 0, 0]]',
      );
      expect(
        engine.evaluate('ones(2,2)', context: exact).result!.displayResult,
        '[[1, 1], [1, 1]]',
      );
      expect(
        engine.evaluate('diag(1,2,3)', context: exact).result!.displayResult,
        '[[1, 0, 0], [0, 2, 0], [0, 0, 3]]',
      );
    });

    test('supports complex and symbolic matrix entries', () {
      expect(
        engine
            .evaluate('det(mat(2,2,i,0,0,i))', context: complexExact)
            .result!
            .displayResult,
        '-1',
      );
      expect(
        engine
            .evaluate('mat(2,2,i,0,0,i)*mat(2,2,i,0,0,i)', context: complexExact)
            .result!
            .displayResult,
        '[[-1, 0], [0, -1]]',
      );
      expect(
        engine
            .evaluate('det(mat(2,2,sqrt(2),0,0,sqrt(2)))', context: exact)
            .result!
            .displayResult,
        '2',
      );
      expect(
        engine
            .evaluate('mat(2,2,pi,0,0,pi)', context: exact)
            .result!
            .displayResult,
        '[[\u03C0, 0], [0, \u03C0]]',
      );
    });

    test('produces typed errors for vector and matrix mismatches', () {
      expect(
        engine.evaluate('vec(1,2)+vec(1,2,3)', context: exact).error!.type,
        CalculationErrorType.dimensionMismatch,
      );
      expect(
        engine
            .evaluate('dot(vec(1,2),vec(1,2,3))', context: exact)
            .error!
            .type,
        CalculationErrorType.dimensionMismatch,
      );
      expect(
        engine.evaluate('cross(vec(1,2),vec(1,2))', context: exact).error!.type,
        CalculationErrorType.dimensionMismatch,
      );
      expect(
        engine.evaluate('mat(2,2,1,2,3)', context: exact).error!.type,
        CalculationErrorType.invalidMatrixShape,
      );
      expect(
        engine
            .evaluate(
              'mat(2,3,1,2,3,4,5,6)*mat(2,2,1,2,3,4)',
              context: exact,
            )
            .error!
            .type,
        CalculationErrorType.dimensionMismatch,
      );
      expect(
        engine
            .evaluate('det(mat(2,3,1,2,3,4,5,6))', context: exact)
            .error!
            .type,
        CalculationErrorType.dimensionMismatch,
      );
      expect(
        engine
            .evaluate('inv(mat(2,2,1,2,2,4))', context: exact)
            .error!
            .type,
        CalculationErrorType.singularMatrix,
      );
      expect(
        engine
            .evaluate('mat(2,2,1,2,3,4)/mat(2,2,1,0,0,1)', context: exact)
            .error!
            .type,
        CalculationErrorType.unsupportedOperation,
      );
      expect(
        engine.evaluate('[[1,2],[3]]', context: exact).error!.type,
        CalculationErrorType.invalidMatrixShape,
      );
    });
  });

  group('CalculatorEngine unit mode', () {
    const engine = CalculatorEngine();
    const exactUnits = CalculationContext(
      numericMode: NumericMode.exact,
      unitMode: UnitMode.enabled,
    );
    const decimalUnits = CalculationContext(
      numericMode: NumericMode.exact,
      unitMode: UnitMode.enabled,
      numberFormatStyle: NumberFormatStyle.decimal,
      precision: 4,
    );

    test('unit mode disabled preserves previous unknown-unit behavior', () {
      final outcome = engine.evaluate('3 m + 20 cm');

      expect(outcome.isFailure, isTrue);
      expect(outcome.error!.type, CalculationErrorType.unknownUnit);
    });

    test('parses basic unit syntax when enabled', () {
      expect(engine.evaluate('3 m', context: exactUnits).result!.displayResult, '3 m');
      expect(engine.evaluate('3m', context: exactUnits).result!.displayResult, '3 m');
      expect(engine.evaluate('3*m', context: exactUnits).result!.displayResult, '3 m');
      expect(
        engine.evaluate('to(100 cm, m)', context: exactUnits).result!.displayResult,
        '1 m',
      );
    });

    test('supports unit-aware addition and conversion', () {
      final sum = engine.evaluate('3 m + 20 cm', context: exactUnits).result!;
      final reverseSum = engine.evaluate(
        '100 cm + 1 m',
        context: exactUnits,
      ).result!;

      expect(sum.displayResult, '16/5 m');
      expect(sum.baseUnitDisplayResult, '16/5 m');
      expect(sum.dimensionDisplayResult, 'L');
      expect(reverseSum.displayResult, '200 cm');
      expect(reverseSum.baseUnitDisplayResult, '2 m');
    });

    test('rejects incompatible unit addition and conversion', () {
      final addOutcome = engine.evaluate('3 m + 2 s', context: exactUnits);
      final convertOutcome = engine.evaluate('to(3 m, s)', context: exactUnits);

      expect(addOutcome.isFailure, isTrue);
      expect(addOutcome.error!.type, CalculationErrorType.dimensionMismatch);
      expect(convertOutcome.isFailure, isTrue);
      expect(
        convertOutcome.error!.type,
        CalculationErrorType.invalidUnitConversion,
      );
    });

    test('supports compound unit arithmetic and derived units', () {
      expect(
        engine.evaluate('5 km / 2 h', context: exactUnits).result!.displayResult,
        '5/2 km/h',
      );
      expect(
        engine.evaluate('10 m / 2 s', context: exactUnits).result!.displayResult,
        '5 m/s',
      );
      expect(
        engine.evaluate('2 m * 3 m', context: exactUnits).result!.displayResult,
        '6 m²',
      );
      expect(
        engine.evaluate('10 N * 2 m', context: exactUnits).result!.displayResult,
        '20 J',
      );
      expect(
        engine.evaluate('20 J / 5 s', context: exactUnits).result!.displayResult,
        '4 W',
      );
      expect(
        engine.evaluate('1000 N / 2 m^2', context: exactUnits).result!.displayResult,
        '500 Pa',
      );
      expect(
        engine.evaluate('60 Hz * 2 s', context: exactUnits).result!.displayResult,
        '120',
      );
      expect(
        engine.evaluate('10 m / 2 m', context: exactUnits).result!.displayResult,
        '5',
      );
    });

    test('preserves requested target display units in conversions', () {
      expect(
        engine.evaluate('to(1 J, N*m)', context: exactUnits).result!.displayResult,
        '1 N*m',
      );
      expect(
        engine.evaluate('to(1 W, J/s)', context: exactUnits).result!.displayResult,
        '1 J/s',
      );
    });

    test('supports unit-aware sqrt and symbolic magnitudes', () {
      expect(
        engine.evaluate('sqrt(9 m^2)', context: exactUnits).result!.displayResult,
        '3 m',
      );
      expect(
        engine.evaluate('sqrt(2 m^2)', context: exactUnits).result!.displayResult,
        '\u221A2 m',
      );

      final unsupported = engine.evaluate('sqrt(3 m)', context: exactUnits);
      expect(unsupported.isFailure, isTrue);
      expect(
        unsupported.error!.type,
        CalculationErrorType.unsupportedOperation,
      );
    });

    test('handles temperature conversion and affine arithmetic', () {
      expect(
        engine.evaluate('to(25 degC, degF)', context: exactUnits).result!.displayResult,
        '77 degF',
      );
      expect(
        engine.evaluate('to(0 degC, K)', context: decimalUnits).result!.displayResult,
        '273.15 K',
      );
      expect(
        engine.evaluate('to(32 degF, degC)', context: exactUnits).result!.displayResult,
        '0 degC',
      );
      expect(
        engine.evaluate('to(10 deltaC, deltaF)', context: exactUnits).result!.displayResult,
        '18 deltaF',
      );
      expect(
        engine.evaluate('25 degC + 10 deltaC', context: exactUnits).result!.displayResult,
        '35 degC',
      );
      expect(
        engine.evaluate('25 degC - 20 degC', context: exactUnits).result!.displayResult,
        '5 deltaC',
      );
      expect(
        engine.evaluate('2 * 10 deltaC', context: exactUnits).result!.displayResult,
        '20 deltaC',
      );

      final invalid = engine.evaluate('25 degC + 10 degC', context: exactUnits);
      expect(invalid.isFailure, isTrue);
      expect(
        invalid.error!.type,
        CalculationErrorType.affineUnitOperation,
      );
    });

    test('enforces dimensionless requirements for transcendentals', () {
      final trig = engine.evaluate('sin(3 m)', context: exactUnits);
      final log = engine.evaluate('log(2 m)', context: exactUnits);

      expect(trig.isFailure, isTrue);
      expect(trig.error!.type, CalculationErrorType.invalidUnitOperation);
      expect(log.isFailure, isTrue);
      expect(log.error!.type, CalculationErrorType.invalidUnitOperation);
    });

    test('vector entries can carry unit values', () {
      expect(
        engine.evaluate('vec(1 m, 20 cm)', context: exactUnits).result!.displayResult,
        '[1 m, 20 cm]',
      );
      expect(
        engine
            .evaluate('vec(1 m, 2 m) + vec(3 m, 4 m)', context: exactUnits)
            .result!
            .displayResult,
        '[4 m, 6 m]',
      );
    });
  });

  group('CalculatorEngine statistics and probability', () {
    const engine = CalculatorEngine();
    const exact = CalculationContext(numericMode: NumericMode.exact);
    const exactUnits = CalculationContext(
      numericMode: NumericMode.exact,
      unitMode: UnitMode.enabled,
    );
    const complexExact = CalculationContext(
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.complex,
    );

    test('constructs datasets and computes descriptive statistics', () {
      expect(
        engine.evaluate('data(1,2,3,4)', context: exact).result!.displayResult,
        'data(1, 2, 3, 4)',
      );
      expect(
        engine.evaluate('count(data(1,2,3))', context: exact).result!.displayResult,
        '3',
      );
      expect(
        engine.evaluate('sum(data(1,2,3))', context: exact).result!.displayResult,
        '6',
      );
      expect(
        engine
            .evaluate('product(data(1,2,3))', context: exact)
            .result!
            .displayResult,
        '6',
      );
      expect(
        engine
            .evaluate('mean(data(1,2,3,4))', context: exact)
            .result!
            .displayResult,
        '5/2',
      );
      expect(
        engine
            .evaluate('median(data(1,2,3))', context: exact)
            .result!
            .displayResult,
        '2',
      );
      expect(
        engine
            .evaluate('median(data(1,2,3,4))', context: exact)
            .result!
            .displayResult,
        '5/2',
      );
      expect(
        engine
            .evaluate('mode(data(1,2,2,3))', context: exact)
            .result!
            .displayResult,
        '2',
      );
      expect(
        engine
            .evaluate('mode(data(1,1,2,2,3))', context: exact)
            .result!
            .displayResult,
        '[1, 2]',
      );
      expect(
        engine
            .evaluate('range(data(1,5,9))', context: exact)
            .result!
            .displayResult,
        '8',
      );
      expect(
        engine
            .evaluate('min(data(1,2,3))', context: exact)
            .result!
            .displayResult,
        '1',
      );
      expect(
        engine
            .evaluate('max(data(1,2,3))', context: exact)
            .result!
            .displayResult,
        '3',
      );
    });

    test('computes sample and population variance and standard deviation', () {
      expect(
        engine.evaluate('varp(data(1,2,3,4))', context: exact).result!.displayResult,
        '5/4',
      );
      expect(
        engine.evaluate('vars(data(1,2,3,4))', context: exact).result!.displayResult,
        '5/3',
      );
      expect(
        engine.evaluate('variance(data(1,2,3,4))', context: exact).result!.displayResult,
        '5/3',
      );
      expect(
        engine.evaluate('stdp(data(1,2,3,4))', context: exact).result!.displayResult,
        '\u221A5/2',
      );
      expect(
        engine.evaluate('stds(data(1,2,3,4))', context: exact).result!.displayResult,
        '\u221A15/3',
      );
      expect(
        engine.evaluate('stddev(data(1,2,3,4))', context: exact).result!.displayResult,
        '\u221A15/3',
      );
      expect(
        engine.evaluate('mad(data(1,2,3,4))', context: exact).result!.displayResult,
        '1',
      );
    });

    test('computes quantiles percentiles and quartile helpers with R7 policy', () {
      expect(
        engine.evaluate('quantile(data(1,2,3,4),0)', context: exact).result!.displayResult,
        '1',
      );
      expect(
        engine.evaluate('quantile(data(1,2,3,4),1)', context: exact).result!.displayResult,
        '4',
      );
      expect(
        engine
            .evaluate('quantile(data(1,2,3,4),0.25)', context: exact)
            .result!
            .displayResult,
        '7/4',
      );
      expect(
        engine
            .evaluate('percentile(data(1,2,3,4),25)', context: exact)
            .result!
            .displayResult,
        '7/4',
      );
      expect(
        engine
            .evaluate('quartiles(data(1,2,3,4,5))', context: exact)
            .result!
            .displayResult,
        '[2, 3, 4]',
      );
      expect(
        engine.evaluate('iqr(data(1,2,3,4,5))', context: exact).result!.displayResult,
        '2',
      );
    });

    test('computes weighted mean and validates weights', () {
      expect(
        engine
            .evaluate('wmean(data(1,2,3),data(1,1,2))', context: exact)
            .result!
            .displayResult,
        '9/4',
      );

      final mismatched = engine.evaluate(
        'wmean(data(1,2),data(1))',
        context: exact,
      );
      final negativeWeights = engine.evaluate(
        'wmean(data(1,2,3),data(1,-1,2))',
        context: exact,
      );
      final zeroWeights = engine.evaluate(
        'wmean(data(1,2,3),data(0,0,0))',
        context: exact,
      );

      expect(mismatched.isFailure, isTrue);
      expect(mismatched.error!.type, CalculationErrorType.dimensionMismatch);
      expect(negativeWeights.isFailure, isTrue);
      expect(
        negativeWeights.error!.type,
        CalculationErrorType.invalidStatisticsArgument,
      );
      expect(zeroWeights.isFailure, isTrue);
      expect(
        zeroWeights.error!.type,
        CalculationErrorType.invalidStatisticsArgument,
      );
    });

    test('supports exact combinatorics helpers', () {
      expect(
        engine.evaluate('factorial(0)', context: exact).result!.displayResult,
        '1',
      );
      expect(
        engine.evaluate('factorial(5)', context: exact).result!.displayResult,
        '120',
      );
      expect(
        engine.evaluate('nCr(5,2)', context: exact).result!.displayResult,
        '10',
      );
      expect(
        engine.evaluate('nPr(5,2)', context: exact).result!.displayResult,
        '20',
      );
      expect(
        engine.evaluate('nCr(52,5)', context: exact).result!.displayResult,
        '2598960',
      );
    });

    test('supports discrete distributions with exact and approximate policies', () {
      expect(
        engine.evaluate('binomPmf(10,0.5,3)', context: exact).result!.displayResult,
        '15/128',
      );
      expect(
        engine.evaluate('binomCdf(10,0.5,3)', context: exact).result!.displayResult,
        '11/64',
      );
      expect(
        engine.evaluate('geomPmf(0.25,3)', context: exact).result!.displayResult,
        '9/64',
      );
      expect(
        engine.evaluate('geomCdf(0.25,3)', context: exact).result!.displayResult,
        '37/64',
      );
      expect(
        engine.evaluate('binomPmf(5,0,0)', context: exact).result!.displayResult,
        '1',
      );
      expect(
        engine.evaluate('binomPmf(5,1,5)', context: exact).result!.displayResult,
        '1',
      );

      final poissonPmf = engine.evaluate('poissonPmf(4,2)', context: exact).result!;
      final poissonCdf = engine.evaluate('poissonCdf(4,2)', context: exact).result!;
      expect(poissonPmf.numericValue, closeTo(0.0902235221577, 1e-10));
      expect(poissonPmf.isApproximate, isTrue);
      expect(poissonCdf.numericValue, closeTo(0.947346982656, 1e-10));
    });

    test('supports continuous distributions and z-score', () {
      final pdf = engine.evaluate('normalPdf(0,0,1)', context: exact).result!;
      final cdfZero = engine.evaluate('normalCdf(0,0,1)', context: exact).result!;
      final cdf196 = engine.evaluate('normalCdf(1.96,0,1)', context: exact).result!;

      expect(pdf.numericValue, closeTo(0.398942280401, 1e-9));
      expect(cdfZero.displayResult, '0.5');
      expect(cdf196.numericValue, closeTo(0.975002104852, 1e-7));
      expect(
        engine.evaluate('zscore(85,70,10)', context: exact).result!.displayResult,
        '1.5',
      );
      expect(
        engine.evaluate('uniformPdf(0.5,0,1)', context: exact).result!.displayResult,
        '1',
      );
      expect(
        engine.evaluate('uniformCdf(0.5,0,1)', context: exact).result!.displayResult,
        '0.5',
      );
    });

    test('computes covariance correlation regression and prediction', () {
      expect(
        engine.evaluate('covp(data(1,2,3),data(2,4,6))', context: exact).result!.displayResult,
        '4/3',
      );
      expect(
        engine.evaluate('covs(data(1,2,3),data(2,4,6))', context: exact).result!.displayResult,
        '2',
      );
      expect(
        engine.evaluate('corr(data(1,2,3),data(2,4,6))', context: exact).result!.displayResult,
        '1',
      );
      expect(
        engine.evaluate('corr(data(1,2,3),data(3,2,1))', context: exact).result!.displayResult,
        '-1',
      );
      final regression = engine.evaluate(
        'linreg(data(1,2,3),data(2,4,6))',
        context: exact,
      ).result!;
      expect(regression.displayResult, 'y = 2x + 0');
      expect(regression.valueKind, CalculatorValueKind.regression);
      expect(regression.sampleSize, 3);
      expect(regression.regressionDisplayResult, 'y = 2x + 0');
      expect(regression.summaryDisplayResult, contains('r = 1'));
      expect(
        engine
            .evaluate('linpred(data(1,2,3),data(2,4,6),4)', context: exact)
            .result!
            .displayResult,
        '8',
      );
    });

    test('supports compatible unit datasets and rejects complex or matrix stats', () {
      expect(
        engine
            .evaluate('sum(data(1 m, 20 cm))', context: exactUnits)
            .result!
            .displayResult,
        '6/5 m',
      );
      expect(
        engine
            .evaluate('mean(data(1 m, 20 cm))', context: exactUnits)
            .result!
            .displayResult,
        '3/5 m',
      );
      expect(
        engine
            .evaluate('variance(data(1 m, 20 cm))', context: exactUnits)
            .result!
            .displayResult,
        '8/25 m\u00B2',
      );
      expect(
        engine
            .evaluate('stddev(data(1 m, 20 cm))', context: exactUnits)
            .result!
            .displayResult,
        '2\u221A2/5 m',
      );

      final incompatibleUnits = engine.evaluate(
        'mean(data(1 m, 2 s))',
        context: exactUnits,
      );
      final complexInput = engine.evaluate(
        'mean(data(i,2))',
        context: complexExact,
      );
      final matrixInput = engine.evaluate(
        'mean(mat(2,2,1,2,3,4))',
        context: exact,
      );

      expect(incompatibleUnits.isFailure, isTrue);
      expect(
        incompatibleUnits.error!.type,
        CalculationErrorType.dimensionMismatch,
      );
      expect(complexInput.isFailure, isTrue);
      expect(
        complexInput.error!.type,
        CalculationErrorType.unsupportedOperation,
      );
      expect(matrixInput.isFailure, isTrue);
      expect(
        matrixInput.error!.type,
        CalculationErrorType.unsupportedOperation,
      );
    });

    test('returns typed errors for invalid statistics and probability arguments', () {
      expect(
        engine.evaluate('mean(data())', context: exact).error!.type,
        CalculationErrorType.invalidDataset,
      );
      expect(
        engine.evaluate('vars(data(1))', context: exact).error!.type,
        CalculationErrorType.insufficientData,
      );
      expect(
        engine.evaluate('quantile(data(1,2,3),-0.1)', context: exact).error!.type,
        CalculationErrorType.invalidStatisticsArgument,
      );
      expect(
        engine.evaluate('nCr(5,-1)', context: exact).error!.type,
        CalculationErrorType.invalidProbabilityParameter,
      );
      expect(
        engine.evaluate('normalPdf(0,0,0)', context: exact).error!.type,
        CalculationErrorType.invalidProbabilityParameter,
      );
      expect(
        engine
            .evaluate('corr(data(1,1,1),data(2,3,4))', context: exact)
            .error!
            .type,
        CalculationErrorType.invalidStatisticsArgument,
      );
    });
  });

  group('CalculatorEngine graphing and scoped variables', () {
    const engine = CalculatorEngine();
    const graphContext = CalculationContext(
      angleMode: AngleMode.radian,
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.real,
    );

    test('normal expressions still reject x outside graph scope', () {
      final outcome = engine.evaluate('x + 1');

      expect(outcome.isFailure, isTrue);
      expect(
        outcome.error!.type,
        anyOf(
          CalculationErrorType.undefinedVariable,
          CalculationErrorType.unknownConstant,
        ),
      );
    });

    test('fn creates a function value display', () {
      final outcome = engine.evaluate('fn(x^2)', context: graphContext);

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.valueKind, CalculatorValueKind.function);
      expect(outcome.result!.displayResult, 'f(x) = x ^ 2');
    });

    test('evalAt and trace evaluate expressions inside graph scope', () {
      final evalAt = engine.evaluate('evalAt(x^2, 3)', context: graphContext);
      final trace = engine.evaluate('trace(x^2, 3)', context: graphContext);

      expect(evalAt.isSuccess, isTrue);
      expect(evalAt.result!.displayResult, '9');
      expect(trace.isSuccess, isTrue);
      expect(trace.result!.displayResult, '9');
      expect(trace.result!.traceDisplayResult, contains('x = 3'));
    });

    test('plot returns plot metadata for single and multiple series', () {
      final single = engine.evaluate('plot(x^2, -5, 5)', context: graphContext);
      final multi = engine.evaluate(
        'plot([sin(x), cos(x)], -pi, pi)',
        context: graphContext,
      );

      expect(single.isSuccess, isTrue);
      expect(single.result!.valueKind, CalculatorValueKind.plot);
      expect(single.result!.plotSeriesCount, 1);
      expect(single.result!.plotPointCount, greaterThan(0));
      expect(multi.isSuccess, isTrue);
      expect(multi.result!.plotSeriesCount, 2);
    });

    test('root and roots find real roots in interval', () {
      final root = engine.evaluate('root(x^2 - 4, 0, 5)', context: graphContext);
      final roots = engine.evaluate(
        'roots(x^2 - 4, -5, 5)',
        context: graphContext,
      );

      expect(root.isSuccess, isTrue);
      expect(root.result!.numericValue, closeTo(2, 1e-6));
      expect(roots.isSuccess, isTrue);
      expect(roots.result!.displayResult, contains('-2'));
      expect(roots.result!.displayResult, contains('2'));
    });

    test('intersections returns x y pairs and slope/area are approximate', () {
      final intersections = engine.evaluate(
        'intersections(x, 2 - x, -5, 5)',
        context: graphContext,
      );
      final slope = engine.evaluate('slope(x^2, 3)', context: graphContext);
      final area = engine.evaluate(
        'area(sin(x), 0, pi)',
        context: graphContext,
      );

      expect(intersections.isSuccess, isTrue);
      expect(intersections.result!.valueKind, CalculatorValueKind.matrix);
      expect(intersections.result!.intersectionDisplayResult, isNotNull);
      expect(slope.isSuccess, isTrue);
      expect(slope.result!.numericValue, closeTo(6, 1e-3));
      expect(area.isSuccess, isTrue);
      expect(area.result!.numericValue, closeTo(2, 1e-3));
    });

    test('graph plotting rejects unsupported output values', () {
      final complexPlot = engine.evaluate(
        'plot(i*x, -1, 1)',
        context: const CalculationContext(
          numericMode: NumericMode.exact,
          calculationDomain: CalculationDomain.complex,
          angleMode: AngleMode.radian,
        ),
      );
      final vectorPlot = engine.evaluate(
        'plot(vec(x, x), -1, 1)',
        context: graphContext,
      );

      expect(complexPlot.isFailure, isTrue);
      expect(
        complexPlot.error!.type,
        CalculationErrorType.unsupportedGraphValue,
      );
      expect(vectorPlot.isFailure, isTrue);
      expect(
        vectorPlot.error!.type,
        CalculationErrorType.unsupportedGraphValue,
      );
    });

    test('scalarized graph inputs still work', () {
      final outcome = engine.evaluate(
        'plot(mean(data(1,2,3)) * x, 0, 10)',
        context: graphContext,
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result!.valueKind, CalculatorValueKind.plot);
    });
  });
}
