import 'dart:math' as math;

import 'calculator_value.dart';
import 'complex_value.dart';
import 'double_value.dart';
import 'matrix_value.dart';
import 'rational_value.dart';
import 'scalar_value_math.dart';
import 'symbolic_value.dart';
import 'unit_math.dart';
import 'unit_value.dart';
import 'vector_value.dart';

enum LinearAlgebraErrorType {
  dimensionMismatch,
  invalidShape,
  singularMatrix,
  unsupportedOperation,
  computationLimit,
  domainError,
}

class LinearAlgebraException implements Exception {
  const LinearAlgebraException(this.type, this.message);

  final LinearAlgebraErrorType type;
  final String message;

  @override
  String toString() => message;
}

/// Vector and matrix helpers layered on top of scalar calculator values.
class LinearAlgebra {
  const LinearAlgebra._();

  static const maxTotalElements = 400;
  static const maxExactDeterminantSize = 6;
  static const maxApproximateDeterminantSize = 12;
  static const maxInverseSize = 10;
  static const maxPreviewRows = 6;
  static const maxPreviewColumns = 6;

  static VectorValue addVectors(VectorValue left, VectorValue right) {
    _requireSameVectorLength(left, right);
    return VectorValue(
      List<CalculatorValue>.generate(
        left.length,
        (index) => _addScalar(left.elements[index], right.elements[index]),
        growable: false,
      ),
    );
  }

  static VectorValue subtractVectors(VectorValue left, VectorValue right) {
    _requireSameVectorLength(left, right);
    return VectorValue(
      List<CalculatorValue>.generate(
        left.length,
        (index) => _subtractScalar(left.elements[index], right.elements[index]),
        growable: false,
      ),
    );
  }

  static VectorValue scaleVector(VectorValue vector, CalculatorValue scalar) {
    _requireScalar(scalar, operation: 'Vector scaling');
    return VectorValue(
      vector.elements
          .map((element) => _multiplyScalar(element, scalar))
          .toList(growable: false),
    );
  }

  static VectorValue divideVector(VectorValue vector, CalculatorValue scalar) {
    _requireScalar(scalar, operation: 'Vector division');
    if (_isZeroScalar(scalar)) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.domainError,
        'Vector division by zero is undefined.',
      );
    }
    return VectorValue(
      vector.elements
          .map((element) => _divideScalar(element, scalar))
          .toList(growable: false),
    );
  }

  static VectorValue negateVector(VectorValue vector) {
    return VectorValue(
      vector.elements.map(_negateScalar).toList(growable: false),
    );
  }

  static CalculatorValue dot(VectorValue left, VectorValue right) {
    _requireSameVectorLength(left, right);
    var total = RationalValue.zero as CalculatorValue;
    for (var index = 0; index < left.length; index++) {
      total = _addScalar(
        total,
        _multiplyScalar(left.elements[index], right.elements[index]),
      );
    }
    return _collapseScalar(total);
  }

  static VectorValue cross(VectorValue left, VectorValue right) {
    if (left.length != 3 || right.length != 3) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.dimensionMismatch,
        'Cross product requires 3-dimensional vectors.',
      );
    }

    final a1 = left.elements[0];
    final a2 = left.elements[1];
    final a3 = left.elements[2];
    final b1 = right.elements[0];
    final b2 = right.elements[1];
    final b3 = right.elements[2];

    return VectorValue(<CalculatorValue>[
      _subtractScalar(_multiplyScalar(a2, b3), _multiplyScalar(a3, b2)),
      _subtractScalar(_multiplyScalar(a3, b1), _multiplyScalar(a1, b3)),
      _subtractScalar(_multiplyScalar(a1, b2), _multiplyScalar(a2, b1)),
    ]);
  }

  static CalculatorValue norm(VectorValue vector) {
    var total = RationalValue.zero as CalculatorValue;
    for (final element in vector.elements) {
      total = _addScalar(total, _magnitudeSquaredScalar(element));
    }
    return _sqrtScalar(total);
  }

  static VectorValue unit(VectorValue vector) {
    final magnitude = norm(vector);
    if (_isZeroScalar(magnitude)) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.domainError,
        'Unit vector is undefined for the zero vector.',
      );
    }
    return divideVector(vector, magnitude);
  }

  static MatrixValue addMatrices(MatrixValue left, MatrixValue right) {
    _requireSameMatrixShape(left, right);
    return MatrixValue(
      List<List<CalculatorValue>>.generate(
        left.rowCount,
        (row) => List<CalculatorValue>.generate(
          left.columnCount,
          (column) => _addScalar(
            left.entryAt(row, column),
            right.entryAt(row, column),
          ),
          growable: false,
        ),
        growable: false,
      ),
    );
  }

  static MatrixValue subtractMatrices(MatrixValue left, MatrixValue right) {
    _requireSameMatrixShape(left, right);
    return MatrixValue(
      List<List<CalculatorValue>>.generate(
        left.rowCount,
        (row) => List<CalculatorValue>.generate(
          left.columnCount,
          (column) => _subtractScalar(
            left.entryAt(row, column),
            right.entryAt(row, column),
          ),
          growable: false,
        ),
        growable: false,
      ),
    );
  }

  static MatrixValue scaleMatrix(MatrixValue matrix, CalculatorValue scalar) {
    _requireScalar(scalar, operation: 'Matrix scaling');
    return MatrixValue(
      matrix.rows
          .map(
            (row) => row
                .map((entry) => _multiplyScalar(entry, scalar))
                .toList(growable: false),
          )
          .toList(growable: false),
    );
  }

  static MatrixValue divideMatrix(MatrixValue matrix, CalculatorValue scalar) {
    _requireScalar(scalar, operation: 'Matrix division');
    if (_isZeroScalar(scalar)) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.domainError,
        'Matrix division by zero is undefined.',
      );
    }
    return MatrixValue(
      matrix.rows
          .map(
            (row) => row
                .map((entry) => _divideScalar(entry, scalar))
                .toList(growable: false),
          )
          .toList(growable: false),
    );
  }

  static MatrixValue negateMatrix(MatrixValue matrix) {
    return MatrixValue(
      matrix.rows
          .map(
            (row) => row.map(_negateScalar).toList(growable: false),
          )
          .toList(growable: false),
    );
  }

  static MatrixValue multiplyMatrices(MatrixValue left, MatrixValue right) {
    if (left.columnCount != right.rowCount) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.dimensionMismatch,
        'Matrix multiplication requires left columns to equal right rows.',
      );
    }
    _guardElementCount(left.rowCount * right.columnCount);

    return MatrixValue(
      List<List<CalculatorValue>>.generate(
        left.rowCount,
        (row) => List<CalculatorValue>.generate(
          right.columnCount,
          (column) {
            var total = RationalValue.zero as CalculatorValue;
            for (var pivot = 0; pivot < left.columnCount; pivot++) {
              total = _addScalar(
                total,
                _multiplyScalar(
                  left.entryAt(row, pivot),
                  right.entryAt(pivot, column),
                ),
              );
            }
            return _collapseScalar(total);
          },
          growable: false,
        ),
        growable: false,
      ),
    );
  }

  static VectorValue multiplyMatrixVector(MatrixValue matrix, VectorValue vector) {
    if (matrix.columnCount != vector.length) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.dimensionMismatch,
        'Matrix-vector multiplication requires matrix columns to equal vector length.',
      );
    }
    return VectorValue(
      List<CalculatorValue>.generate(matrix.rowCount, (row) {
        var total = RationalValue.zero as CalculatorValue;
        for (var column = 0; column < matrix.columnCount; column++) {
          total = _addScalar(
            total,
            _multiplyScalar(matrix.entryAt(row, column), vector.elements[column]),
          );
        }
        return _collapseScalar(total);
      }, growable: false),
    );
  }

  static MatrixValue transpose(MatrixValue matrix) {
    return MatrixValue(
      List<List<CalculatorValue>>.generate(
        matrix.columnCount,
        (column) => List<CalculatorValue>.generate(
          matrix.rowCount,
          (row) => matrix.entryAt(row, column),
          growable: false,
        ),
        growable: false,
      ),
    );
  }

  static CalculatorValue trace(MatrixValue matrix) {
    if (!matrix.isSquare) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.dimensionMismatch,
        'Trace requires a square matrix.',
      );
    }

    var total = RationalValue.zero as CalculatorValue;
    for (var index = 0; index < matrix.rowCount; index++) {
      total = _addScalar(total, matrix.entryAt(index, index));
    }
    return _collapseScalar(total);
  }

  static CalculatorValue determinant(MatrixValue matrix) {
    if (!matrix.isSquare) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.dimensionMismatch,
        'Determinant requires a square matrix.',
      );
    }

    final size = matrix.rowCount;
    if (size == 1) {
      return matrix.entryAt(0, 0);
    }

    if (matrix.isExact) {
      if (size > maxExactDeterminantSize) {
        throw const LinearAlgebraException(
          LinearAlgebraErrorType.computationLimit,
          'Exact determinant size limit exceeded.',
        );
      }
      return _determinantRecursive(matrix);
    }

    if (size > maxApproximateDeterminantSize) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.computationLimit,
        'Approximate determinant size limit exceeded.',
      );
    }

    return _determinantByElimination(matrix);
  }

  static MatrixValue inverse(MatrixValue matrix) {
    if (!matrix.isSquare) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.dimensionMismatch,
        'Inverse requires a square matrix.',
      );
    }

    if (matrix.rowCount > maxInverseSize) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.computationLimit,
        'Matrix inverse size limit exceeded.',
      );
    }

    final size = matrix.rowCount;
    final left = List<List<CalculatorValue>>.generate(
      size,
      (row) => List<CalculatorValue>.generate(
        size,
        (column) => matrix.entryAt(row, column),
        growable: true,
      ),
      growable: true,
    );
    final right = List<List<CalculatorValue>>.generate(
      size,
      (row) => List<CalculatorValue>.generate(
        size,
        (column) => row == column ? RationalValue.one : RationalValue.zero,
        growable: true,
      ),
      growable: true,
    );

    for (var pivotIndex = 0; pivotIndex < size; pivotIndex++) {
      var pivotRow = pivotIndex;
      while (pivotRow < size && _isZeroScalar(left[pivotRow][pivotIndex])) {
        pivotRow++;
      }

      if (pivotRow == size) {
        throw const LinearAlgebraException(
          LinearAlgebraErrorType.singularMatrix,
          'Inverse is undefined for a singular matrix.',
        );
      }

      if (pivotRow != pivotIndex) {
        final tempLeft = left[pivotIndex];
        left[pivotIndex] = left[pivotRow];
        left[pivotRow] = tempLeft;

        final tempRight = right[pivotIndex];
        right[pivotIndex] = right[pivotRow];
        right[pivotRow] = tempRight;
      }

      final pivot = left[pivotIndex][pivotIndex];
      for (var column = 0; column < size; column++) {
        left[pivotIndex][column] = _divideScalar(left[pivotIndex][column], pivot);
        right[pivotIndex][column] = _divideScalar(
          right[pivotIndex][column],
          pivot,
        );
      }

      for (var row = 0; row < size; row++) {
        if (row == pivotIndex) {
          continue;
        }

        final factor = left[row][pivotIndex];
        if (_isZeroScalar(factor)) {
          continue;
        }

        for (var column = 0; column < size; column++) {
          left[row][column] = _subtractScalar(
            left[row][column],
            _multiplyScalar(factor, left[pivotIndex][column]),
          );
          right[row][column] = _subtractScalar(
            right[row][column],
            _multiplyScalar(factor, right[pivotIndex][column]),
          );
        }
      }
    }

    return MatrixValue(
      right
          .map(
            (row) => row.map(_collapseScalar).toList(growable: false),
          )
          .toList(growable: false),
    );
  }

  static VectorValue createVector(List<CalculatorValue> elements) {
    _guardElementCount(elements.length);
    return VectorValue(elements);
  }

  static MatrixValue createMatrix(
    int rowCount,
    int columnCount,
    List<CalculatorValue> values,
  ) {
    if (rowCount <= 0 || columnCount <= 0) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.invalidShape,
        'Matrix dimensions must be positive integers.',
      );
    }
    if (values.length != rowCount * columnCount) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.invalidShape,
        'Matrix literal value count must match rows * columns.',
      );
    }
    _guardElementCount(values.length);
    final rows = List<List<CalculatorValue>>.generate(
      rowCount,
      (row) => List<CalculatorValue>.generate(
        columnCount,
        (column) => values[row * columnCount + column],
        growable: false,
      ),
      growable: false,
    );
    return MatrixValue(rows);
  }

  static MatrixValue identity(int size) {
    if (size <= 0) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.invalidShape,
        'Identity size must be positive.',
      );
    }
    _guardElementCount(size * size);
    return MatrixValue(
      List<List<CalculatorValue>>.generate(
        size,
        (row) => List<CalculatorValue>.generate(
          size,
          (column) => row == column ? RationalValue.one : RationalValue.zero,
          growable: false,
        ),
        growable: false,
      ),
    );
  }

  static MatrixValue zeros(int rowCount, int columnCount) {
    if (rowCount <= 0 || columnCount <= 0) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.invalidShape,
        'Matrix dimensions must be positive integers.',
      );
    }
    _guardElementCount(rowCount * columnCount);
    return MatrixValue(
      List<List<CalculatorValue>>.generate(
        rowCount,
        (_) => List<CalculatorValue>.filled(
          columnCount,
          RationalValue.zero,
          growable: false,
        ),
        growable: false,
      ),
    );
  }

  static MatrixValue ones(int rowCount, int columnCount) {
    if (rowCount <= 0 || columnCount <= 0) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.invalidShape,
        'Matrix dimensions must be positive integers.',
      );
    }
    _guardElementCount(rowCount * columnCount);
    return MatrixValue(
      List<List<CalculatorValue>>.generate(
        rowCount,
        (_) => List<CalculatorValue>.filled(
          columnCount,
          RationalValue.one,
          growable: false,
        ),
        growable: false,
      ),
    );
  }

  static MatrixValue diagonal(List<CalculatorValue> diagonalEntries) {
    if (diagonalEntries.isEmpty) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.invalidShape,
        'Diagonal matrix requires at least one entry.',
      );
    }
    final size = diagonalEntries.length;
    _guardElementCount(size * size);
    return MatrixValue(
      List<List<CalculatorValue>>.generate(
        size,
        (row) => List<CalculatorValue>.generate(
          size,
          (column) => row == column
              ? diagonalEntries[row]
              : RationalValue.zero,
          growable: false,
        ),
        growable: false,
      ),
    );
  }

  static void _requireSameVectorLength(VectorValue left, VectorValue right) {
    if (left.length != right.length) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.dimensionMismatch,
        'Vector operations require vectors of the same length.',
      );
    }
  }

  static void _requireSameMatrixShape(MatrixValue left, MatrixValue right) {
    if (left.rowCount != right.rowCount || left.columnCount != right.columnCount) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.dimensionMismatch,
        'Matrix operations require matrices with the same shape.',
      );
    }
  }

  static void _guardElementCount(int count) {
    if (count > maxTotalElements) {
      throw const LinearAlgebraException(
        LinearAlgebraErrorType.computationLimit,
        'Matrix/vector size limit exceeded.',
      );
    }
  }

  static void _requireScalar(
    CalculatorValue value, {
    required String operation,
  }) {
    if (value is VectorValue || value is MatrixValue) {
      throw LinearAlgebraException(
        LinearAlgebraErrorType.unsupportedOperation,
        '$operation requires a scalar value.',
      );
    }
  }

  static CalculatorValue _determinantRecursive(MatrixValue matrix) {
    final size = matrix.rowCount;
    if (size == 1) {
      return matrix.entryAt(0, 0);
    }
    if (size == 2) {
      return _subtractScalar(
        _multiplyScalar(matrix.entryAt(0, 0), matrix.entryAt(1, 1)),
        _multiplyScalar(matrix.entryAt(0, 1), matrix.entryAt(1, 0)),
      );
    }
    if (size == 3) {
      final a = matrix.entryAt(0, 0);
      final b = matrix.entryAt(0, 1);
      final c = matrix.entryAt(0, 2);
      final d = matrix.entryAt(1, 0);
      final e = matrix.entryAt(1, 1);
      final f = matrix.entryAt(1, 2);
      final g = matrix.entryAt(2, 0);
      final h = matrix.entryAt(2, 1);
      final i = matrix.entryAt(2, 2);
      final positive = _addScalar(
        _addScalar(
          _multiplyScalar(a, _multiplyScalar(e, i)),
          _multiplyScalar(b, _multiplyScalar(f, g)),
        ),
        _multiplyScalar(c, _multiplyScalar(d, h)),
      );
      final negative = _addScalar(
        _addScalar(
          _multiplyScalar(c, _multiplyScalar(e, g)),
          _multiplyScalar(b, _multiplyScalar(d, i)),
        ),
        _multiplyScalar(a, _multiplyScalar(f, h)),
      );
      return _collapseScalar(_subtractScalar(positive, negative));
    }

    var total = RationalValue.zero as CalculatorValue;
    for (var column = 0; column < size; column++) {
      final cofactor = _determinantRecursive(_minor(matrix, 0, column));
      final signedCofactor = column.isEven ? cofactor : _negateScalar(cofactor);
      total = _addScalar(
        total,
        _multiplyScalar(matrix.entryAt(0, column), signedCofactor),
      );
    }
    return _collapseScalar(total);
  }

  static MatrixValue _minor(MatrixValue matrix, int removeRow, int removeColumn) {
    return MatrixValue(
      List<List<CalculatorValue>>.generate(
        matrix.rowCount - 1,
        (row) {
          final sourceRow = row >= removeRow ? row + 1 : row;
          return List<CalculatorValue>.generate(
            matrix.columnCount - 1,
            (column) {
              final sourceColumn = column >= removeColumn ? column + 1 : column;
              return matrix.entryAt(sourceRow, sourceColumn);
            },
            growable: false,
          );
        },
        growable: false,
      ),
    );
  }

  static CalculatorValue _determinantByElimination(MatrixValue matrix) {
    final rows = List<List<double>>.generate(
      matrix.rowCount,
      (row) => List<double>.generate(
        matrix.columnCount,
        (column) => matrix.entryAt(row, column).toDouble(),
        growable: true,
      ),
      growable: true,
    );

    var determinant = 1.0;
    var sign = 1.0;
    for (var pivot = 0; pivot < matrix.rowCount; pivot++) {
      var pivotRow = pivot;
      var pivotMagnitude = rows[pivot][pivot].abs();
      for (var row = pivot + 1; row < matrix.rowCount; row++) {
        final magnitude = rows[row][pivot].abs();
        if (magnitude > pivotMagnitude) {
          pivotMagnitude = magnitude;
          pivotRow = row;
        }
      }
      if (pivotMagnitude < 1e-12) {
        return DoubleValue(0);
      }
      if (pivotRow != pivot) {
        final temp = rows[pivot];
        rows[pivot] = rows[pivotRow];
        rows[pivotRow] = temp;
        sign *= -1;
      }

      final pivotValue = rows[pivot][pivot];
      determinant *= pivotValue;
      for (var row = pivot + 1; row < matrix.rowCount; row++) {
        final factor = rows[row][pivot] / pivotValue;
        for (var column = pivot; column < matrix.columnCount; column++) {
          rows[row][column] -= factor * rows[pivot][column];
        }
      }
    }

    return DoubleValue(determinant * sign);
  }

  static CalculatorValue _magnitudeSquaredScalar(CalculatorValue value) {
    if (value is ComplexValue) {
      return _addScalar(
        _multiplyScalar(value.realPart, value.realPart),
        _multiplyScalar(value.imaginaryPart, value.imaginaryPart),
      );
    }
    return _multiplyScalar(value, value);
  }

  static CalculatorValue _sqrtScalar(CalculatorValue value) {
    if (value is UnitValue) {
      return UnitMath.squareRoot(value);
    }
    if (_isExactScalar(value)) {
      return _collapseScalar(ScalarValueMath.squareRoot(value));
    }
    return DoubleValue(math.sqrt(value.toDouble()));
  }

  static CalculatorValue _collapseScalar(CalculatorValue value) {
    if (value is ComplexValue) {
      return value.simplify();
    }
    return ScalarValueMath.collapse(value);
  }

  static bool _isExactScalar(CalculatorValue value) {
    return value is RationalValue ||
        value is SymbolicValue ||
        value is UnitValue && value.isExact ||
        value is ComplexValue && value.isExact;
  }

  static bool _isZeroScalar(CalculatorValue value) {
    if (value is UnitValue) {
      return ScalarValueMath.isZero(value.baseMagnitude);
    }
    if (value is ComplexValue) {
      return _isZeroScalar(value.realPart) && _isZeroScalar(value.imaginaryPart);
    }
    return ScalarValueMath.isZero(value);
  }

  static CalculatorValue _addScalar(CalculatorValue left, CalculatorValue right) {
    if (left is UnitValue && right is UnitValue) {
      return UnitMath.add(left, right);
    }
    if (left is ComplexValue || right is ComplexValue) {
      return ComplexValue.promote(left).addValue(right);
    }
    return ScalarValueMath.add(left, right);
  }

  static CalculatorValue _subtractScalar(
    CalculatorValue left,
    CalculatorValue right,
  ) {
    if (left is UnitValue && right is UnitValue) {
      return UnitMath.subtract(left, right);
    }
    if (left is ComplexValue || right is ComplexValue) {
      return ComplexValue.promote(left).subtractValue(right);
    }
    return ScalarValueMath.subtract(left, right);
  }

  static CalculatorValue _multiplyScalar(
    CalculatorValue left,
    CalculatorValue right,
  ) {
    if (left is UnitValue && right is UnitValue) {
      return UnitMath.multiply(left, right);
    }
    if (left is UnitValue) {
      return UnitMath.multiplyScalar(right, left);
    }
    if (right is UnitValue) {
      return UnitMath.multiplyScalar(left, right);
    }
    if (left is ComplexValue || right is ComplexValue) {
      return ComplexValue.promote(left).multiplyValue(right);
    }
    return ScalarValueMath.multiply(left, right);
  }

  static CalculatorValue _divideScalar(
    CalculatorValue left,
    CalculatorValue right,
  ) {
    if (left is UnitValue && right is UnitValue) {
      return UnitMath.divide(left, right);
    }
    if (left is UnitValue) {
      return UnitMath.divideByScalar(left, right);
    }
    if (right is UnitValue) {
      return UnitMath.divideScalarByUnit(left, right);
    }
    if (left is ComplexValue || right is ComplexValue) {
      return ComplexValue.promote(left).divideValue(right);
    }
    return ScalarValueMath.divide(left, right);
  }

  static CalculatorValue _negateScalar(CalculatorValue value) {
    if (value is UnitValue) {
      return UnitValue.fromBaseMagnitude(
        baseMagnitude: ScalarValueMath.negate(value.baseMagnitude),
        displayUnit: value.displayUnit,
      );
    }
    if (value is ComplexValue) {
      return value.negateValue();
    }
    return ScalarValueMath.negate(value);
  }
}
