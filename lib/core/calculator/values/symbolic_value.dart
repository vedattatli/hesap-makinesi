import 'calculator_value.dart';
import 'rational_value.dart';
import 'symbolic_factor.dart';
import 'symbolic_term.dart';

/// Exact symbolic sum of normalized symbolic terms.
class SymbolicValue extends CalculatorValue {
  factory SymbolicValue(
    Iterable<SymbolicTerm> terms, {
    int maxTermCount = 100,
    int maxFactorCount = 24,
  }) {
    final combined = <String, SymbolicTerm>{};
    for (final rawTerm in terms) {
      final term = SymbolicTerm(
        coefficient: rawTerm.coefficient,
        factors: rawTerm.factors,
        maxFactorCount: maxFactorCount,
      );
      if (term.isZero) {
        continue;
      }

      final key = term.factorKey;
      final existing = combined[key];
      if (existing == null) {
        combined[key] = term;
      } else {
        final nextCoefficient = existing.coefficient.add(term.coefficient);
        if (nextCoefficient.numerator == BigInt.zero) {
          combined.remove(key);
        } else {
          combined[key] = SymbolicTerm(
            coefficient: nextCoefficient,
            factors: existing.factors,
            maxFactorCount: maxFactorCount,
          );
        }
      }
    }

    final normalizedTerms = combined.values.toList(growable: false)
      ..sort((left, right) => left.sortKey.compareTo(right.sortKey));
    if (normalizedTerms.length > maxTermCount) {
      throw RangeError.range(
        normalizedTerms.length,
        0,
        maxTermCount,
        'term count',
      );
    }

    return SymbolicValue._(
      List<SymbolicTerm>.unmodifiable(normalizedTerms),
      maxTermCount: maxTermCount,
      maxFactorCount: maxFactorCount,
    );
  }

  const SymbolicValue._(
    this.terms, {
    required this.maxTermCount,
    required this.maxFactorCount,
  });

  final List<SymbolicTerm> terms;
  final int maxTermCount;
  final int maxFactorCount;

  @override
  CalculatorValueKind get kind => CalculatorValueKind.symbolic;

  @override
  bool get isExact => true;

  bool get isZero => terms.isEmpty;

  bool get isSingleTerm => terms.length == 1;

  SymbolicTerm? get singleTerm => isSingleTerm ? terms.first : null;

  @override
  double toDouble() {
    var value = 0.0;
    for (final term in terms) {
      value += term.toDouble();
    }
    return value;
  }

  String toSymbolicString() {
    if (terms.isEmpty) {
      return '0';
    }

    final buffer = StringBuffer();
    for (var index = 0; index < terms.length; index++) {
      final term = terms[index];
      final isNegative = term.coefficient.numerator.isNegative;
      final unsigned = term.toUnsignedDisplayString();
      if (index == 0) {
        if (isNegative) {
          buffer.write('-');
        }
        buffer.write(unsigned);
        continue;
      }

      buffer.write(isNegative ? ' - ' : ' + ');
      buffer.write(unsigned);
    }

    return buffer.toString();
  }

  RationalValue? tryCollapseToRational() {
    if (terms.isEmpty) {
      return RationalValue.zero;
    }
    if (terms.length == 1 && terms.first.isRational) {
      return terms.first.coefficient;
    }
    return null;
  }

  RationalValue? tryAsPiMultiple() {
    final term = singleTerm;
    if (term == null || !term.hasOnlyConstant(SymbolicConstantKind.pi)) {
      return null;
    }
    return term.coefficient;
  }

  RationalValue? tryAsEMultiple() {
    final term = singleTerm;
    if (term == null || !term.hasOnlyConstant(SymbolicConstantKind.e)) {
      return null;
    }
    return term.coefficient;
  }

  static SymbolicValue fromRational(
    RationalValue value, {
    int maxTermCount = 100,
    int maxFactorCount = 24,
  }) {
    return SymbolicValue(
      [SymbolicTerm(coefficient: value, maxFactorCount: maxFactorCount)],
      maxTermCount: maxTermCount,
      maxFactorCount: maxFactorCount,
    );
  }

  static SymbolicValue fromFactor(
    SymbolicFactor factor, {
    RationalValue? coefficient,
    int maxTermCount = 100,
    int maxFactorCount = 24,
  }) {
    return SymbolicValue(
      [
        SymbolicTerm(
          coefficient: coefficient ?? RationalValue.one,
          factors: [factor],
          maxFactorCount: maxFactorCount,
        ),
      ],
      maxTermCount: maxTermCount,
      maxFactorCount: maxFactorCount,
    );
  }
}
