import 'package:flutter_test/flutter_test.dart';
import 'package:hesap_makinesi/core/calculator/calculator.dart';
import 'package:hesap_makinesi/core/calculator/src/result_formatter.dart';

void main() {
  group('MatrixValue', () {
    final formatter = ResultFormatter();
    const exactContext = CalculationContext(
      numericMode: NumericMode.exact,
      calculationDomain: CalculationDomain.complex,
      numberFormatStyle: NumberFormatStyle.symbolic,
      precision: 10,
    );

    String display(CalculatorValue value) {
      return formatter.format(value, exactContext).displayResult;
    }

    MatrixValue matrix2x2(int a, int b, int c, int d) {
      return MatrixValue(<List<CalculatorValue>>[
        <CalculatorValue>[RationalValue.fromInt(a), RationalValue.fromInt(b)],
        <CalculatorValue>[RationalValue.fromInt(c), RationalValue.fromInt(d)],
      ]);
    }

    test('creation validates rectangular shape and flags', () {
      final matrix = matrix2x2(1, 2, 3, 4);
      final approximate = MatrixValue(<List<CalculatorValue>>[
        <CalculatorValue>[DoubleValue(1.1), RationalValue.one],
      ]);

      expect(matrix.rowCount, 2);
      expect(matrix.columnCount, 2);
      expect(matrix.isSquare, isTrue);
      expect(matrix.isExact, isTrue);
      expect(approximate.isApproximate, isTrue);
      expect(
        () => MatrixValue(<List<CalculatorValue>>[
          <CalculatorValue>[RationalValue.one],
          <CalculatorValue>[RationalValue.one, RationalValue.one],
        ]),
        throwsArgumentError,
      );
    });

    test('rows are immutable', () {
      final matrix = matrix2x2(1, 2, 3, 4);

      expect(
        () => matrix.rows[0][0] = RationalValue.fromInt(9),
        throwsUnsupportedError,
      );
    });

    test('display formats compact matrix string', () {
      expect(display(matrix2x2(1, 2, 3, 4)), '[[1, 2], [3, 4]]');
    });

    test('adds and subtracts same-shape matrices', () {
      final left = matrix2x2(1, 2, 3, 4);
      final right = matrix2x2(5, 6, 7, 8);

      expect(display(LinearAlgebra.addMatrices(left, right)), '[[6, 8], [10, 12]]');
      expect(display(LinearAlgebra.subtractMatrices(right, left)), '[[4, 4], [4, 4]]');
    });

    test('matrix dimension mismatch throws', () {
      final left = MatrixValue(<List<CalculatorValue>>[
        <CalculatorValue>[RationalValue.one, RationalValue.one],
      ]);
      final right = matrix2x2(1, 2, 3, 4);

      expect(
        () => LinearAlgebra.addMatrices(left, right),
        throwsA(isA<LinearAlgebraException>()),
      );
    });

    test('supports scalar multiply and matrix multiply', () {
      final left = matrix2x2(1, 2, 3, 4);
      final right = matrix2x2(5, 6, 7, 8);

      expect(
        display(LinearAlgebra.scaleMatrix(left, RationalValue.fromInt(2))),
        '[[2, 4], [6, 8]]',
      );
      expect(display(LinearAlgebra.multiplyMatrices(left, right)), '[[19, 22], [43, 50]]');
    });

    test('supports matrix-vector multiplication', () {
      final matrix = matrix2x2(1, 2, 3, 4);
      final vector = VectorValue(
        <CalculatorValue>[RationalValue.fromInt(5), RationalValue.fromInt(6)],
      );

      expect(display(LinearAlgebra.multiplyMatrixVector(matrix, vector)), '[17, 39]');
    });

    test('supports transpose and trace', () {
      final matrix = matrix2x2(1, 2, 3, 4);

      expect(display(LinearAlgebra.transpose(matrix)), '[[1, 3], [2, 4]]');
      expect(display(LinearAlgebra.trace(matrix)), '5');
    });

    test('supports determinant 1x1 2x2 and 3x3', () {
      final oneByOne = MatrixValue(<List<CalculatorValue>>[
        <CalculatorValue>[RationalValue.fromInt(5)],
      ]);
      final threeByThree = MatrixValue(<List<CalculatorValue>>[
        <CalculatorValue>[
          RationalValue.one,
          RationalValue.fromInt(2),
          RationalValue.fromInt(3),
        ],
        <CalculatorValue>[
          RationalValue.zero,
          RationalValue.one,
          RationalValue.fromInt(4),
        ],
        <CalculatorValue>[
          RationalValue.fromInt(5),
          RationalValue.fromInt(6),
          RationalValue.zero,
        ],
      ]);

      expect(display(LinearAlgebra.determinant(oneByOne)), '5');
      expect(display(LinearAlgebra.determinant(matrix2x2(1, 2, 3, 4))), '-2');
      expect(display(LinearAlgebra.determinant(threeByThree)), '1');
    });

    test('supports inverse 1x1 and 2x2', () {
      final oneByOne = MatrixValue(<List<CalculatorValue>>[
        <CalculatorValue>[RationalValue.fromInt(2)],
      ]);
      final matrix = matrix2x2(1, 2, 3, 4);

      expect(display(LinearAlgebra.inverse(oneByOne)), '[[1/2]]');
      expect(display(LinearAlgebra.inverse(matrix)), '[[-2, 1], [3/2, -1/2]]');
    });

    test('singular inverse throws', () {
      final singular = matrix2x2(1, 2, 2, 4);

      expect(
        () => LinearAlgebra.inverse(singular),
        throwsA(isA<LinearAlgebraException>()),
      );
    });

    test('identity zeros ones and diag constructors work', () {
      expect(display(LinearAlgebra.identity(3)), '[[1, 0, 0], [0, 1, 0], [0, 0, 1]]');
      expect(display(LinearAlgebra.zeros(2, 3)), '[[0, 0, 0], [0, 0, 0]]');
      expect(display(LinearAlgebra.ones(2, 2)), '[[1, 1], [1, 1]]');
      expect(
        display(
          LinearAlgebra.diagonal(<CalculatorValue>[
            RationalValue.one,
            RationalValue.fromInt(2),
            RationalValue.fromInt(3),
          ]),
        ),
        '[[1, 0, 0], [0, 2, 0], [0, 0, 3]]',
      );
    });
  });
}
