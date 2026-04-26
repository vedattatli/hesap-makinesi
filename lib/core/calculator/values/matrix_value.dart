import 'dart:math' as math;

import 'calculator_value.dart';
import 'scalar_value_math.dart';

/// Immutable rectangular matrix with scalar calculator entries.
class MatrixValue extends CalculatorValue {
  factory MatrixValue(Iterable<Iterable<CalculatorValue>> rows) {
    final normalizedRows = rows
        .map(
          (row) => row.map(ScalarValueMath.collapse).toList(growable: false),
        )
        .toList(growable: false);

    if (normalizedRows.isEmpty) {
      throw ArgumentError.value(rows, 'rows', 'Matrix cannot be empty.');
    }

    final columnCount = normalizedRows.first.length;
    if (columnCount == 0) {
      throw ArgumentError.value(rows, 'rows', 'Matrix rows cannot be empty.');
    }

    for (final row in normalizedRows) {
      if (row.length != columnCount) {
        throw ArgumentError.value(
          rows,
          'rows',
          'Matrix must be rectangular.',
        );
      }
    }

    return MatrixValue._(
      List<List<CalculatorValue>>.unmodifiable(
        normalizedRows
            .map(List<CalculatorValue>.unmodifiable)
            .toList(growable: false),
      ),
    );
  }

  const MatrixValue._(this.rows);

  final List<List<CalculatorValue>> rows;

  int get rowCount => rows.length;

  int get columnCount => rows.first.length;

  bool get isSquare => rowCount == columnCount;

  int get totalElements => rowCount * columnCount;

  CalculatorValue entryAt(int row, int column) => rows[row][column];

  @override
  CalculatorValueKind get kind => CalculatorValueKind.matrix;

  @override
  bool get isExact => rows.every(
    (row) => row.every((entry) => entry.isExact),
  );

  MatrixValue simplify() => MatrixValue(rows);

  @override
  double toDouble() {
    var sumSquares = 0.0;
    for (final row in rows) {
      for (final entry in row) {
        final value = entry.toDouble();
        sumSquares += value * value;
      }
    }
    return math.sqrt(sumSquares);
  }
}
