import 'calculator_value.dart';

/// Exact rational value backed by normalized [BigInt] components.
class RationalValue extends CalculatorValue
    implements Comparable<RationalValue> {
  factory RationalValue(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) {
      throw ArgumentError.value(
        denominator,
        'denominator',
        'Denominator cannot be zero.',
      );
    }

    if (numerator == BigInt.zero) {
      return zero;
    }

    var normalizedNumerator = numerator;
    var normalizedDenominator = denominator;
    if (normalizedDenominator.isNegative) {
      normalizedNumerator = -normalizedNumerator;
      normalizedDenominator = -normalizedDenominator;
    }

    final divisor = normalizedNumerator.gcd(normalizedDenominator);
    return RationalValue._(
      normalizedNumerator ~/ divisor,
      normalizedDenominator ~/ divisor,
    );
  }

  factory RationalValue.fromInt(int value) {
    return RationalValue(BigInt.from(value), BigInt.one);
  }

  factory RationalValue.parseLiteral(String rawLiteral, {int? maxDigits}) {
    final literal = rawLiteral.trim();
    if (literal.isEmpty) {
      throw const FormatException('Empty numeric literal.');
    }

    var sign = BigInt.one;
    var body = literal;
    if (body.startsWith('+')) {
      body = body.substring(1);
    } else if (body.startsWith('-')) {
      sign = -BigInt.one;
      body = body.substring(1);
    }

    final scientificParts = body.toLowerCase().split('e');
    if (scientificParts.length > 2) {
      throw FormatException('Invalid numeric literal: $rawLiteral');
    }

    final mantissa = scientificParts.first;
    final exponent = scientificParts.length == 2
        ? int.parse(scientificParts[1])
        : 0;

    final decimalParts = mantissa.split('.');
    if (decimalParts.length > 2) {
      throw FormatException('Invalid numeric literal: $rawLiteral');
    }

    final wholePart = decimalParts.first;
    final fractionPart = decimalParts.length == 2 ? decimalParts[1] : '';
    final digits = '$wholePart$fractionPart';
    if (digits.isEmpty || !RegExp(r'^\d+$').hasMatch(digits)) {
      throw FormatException('Invalid numeric literal: $rawLiteral');
    }

    final normalizedDigits = digits.replaceFirst(RegExp(r'^0+'), '');
    final significantDigits = normalizedDigits.isEmpty ? '0' : normalizedDigits;
    final scale = fractionPart.length - exponent;
    final totalDigits = significantDigits.length + scale.abs();
    if (maxDigits != null && totalDigits > maxDigits) {
      throw RangeError.range(totalDigits, 0, maxDigits, 'literal digits');
    }

    var numerator = BigInt.parse(significantDigits) * sign;
    var denominator = BigInt.one;

    if (scale > 0) {
      denominator = _pow10(scale);
    } else if (scale < 0) {
      numerator *= _pow10(-scale);
    }

    return RationalValue(numerator, denominator);
  }

  RationalValue._(this.numerator, this.denominator);

  final BigInt numerator;
  final BigInt denominator;

  static final zero = RationalValue._(BigInt.zero, BigInt.one);
  static final one = RationalValue._(BigInt.one, BigInt.one);

  @override
  CalculatorValueKind get kind => CalculatorValueKind.rational;

  @override
  bool get isExact => true;

  bool get isInteger => denominator == BigInt.one;

  @override
  double toDouble() {
    return numerator.toDouble() / denominator.toDouble();
  }

  RationalValue add(RationalValue other) {
    return RationalValue(
      numerator * other.denominator + other.numerator * denominator,
      denominator * other.denominator,
    );
  }

  RationalValue subtract(RationalValue other) {
    return RationalValue(
      numerator * other.denominator - other.numerator * denominator,
      denominator * other.denominator,
    );
  }

  RationalValue multiply(RationalValue other) {
    return RationalValue(
      numerator * other.numerator,
      denominator * other.denominator,
    );
  }

  RationalValue divide(RationalValue other) {
    if (other.numerator == BigInt.zero) {
      throw ArgumentError.value(other, 'other', 'Division by zero.');
    }
    return RationalValue(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  RationalValue negate() => RationalValue(-numerator, denominator);

  RationalValue abs() => numerator.isNegative ? negate() : this;

  RationalValue reciprocal() {
    if (numerator == BigInt.zero) {
      throw ArgumentError.value(
        this,
        'this',
        'Zero does not have a reciprocal.',
      );
    }
    return RationalValue(denominator, numerator);
  }

  RationalValue powInteger(int exponent) {
    if (exponent == 0) {
      return one;
    }
    if (exponent > 0) {
      return RationalValue(numerator.pow(exponent), denominator.pow(exponent));
    }

    return reciprocal().powInteger(-exponent);
  }

  @override
  int compareTo(RationalValue other) {
    final left = numerator * other.denominator;
    final right = other.numerator * denominator;
    return left.compareTo(right);
  }

  BigInt floorToBigInt() {
    final quotient = numerator ~/ denominator;
    final remainder = numerator.remainder(denominator);
    if (numerator.isNegative && remainder != BigInt.zero) {
      return quotient - BigInt.one;
    }
    return quotient;
  }

  BigInt ceilToBigInt() {
    final quotient = numerator ~/ denominator;
    final remainder = numerator.remainder(denominator);
    if (numerator.isNegative || remainder == BigInt.zero) {
      return quotient;
    }
    return quotient + BigInt.one;
  }

  BigInt roundToBigInt() {
    final floor = floorToBigInt();
    final ceil = ceilToBigInt();
    final floorDiff = subtract(RationalValue(floor, BigInt.one)).abs();
    final ceilDiff = subtract(RationalValue(ceil, BigInt.one)).abs();
    final comparison = floorDiff.compareTo(ceilDiff);
    if (comparison < 0) {
      return floor;
    }
    if (comparison > 0) {
      return ceil;
    }
    return numerator.isNegative ? floor : ceil;
  }

  String toFractionString() {
    if (denominator == BigInt.one) {
      return numerator.toString();
    }
    return '$numerator/$denominator';
  }

  String toDecimalString(int precision) {
    assert(precision > 0, 'precision must be positive');
    final isNegative = numerator.isNegative;
    final absoluteNumerator = numerator.abs();
    final integerPart = absoluteNumerator ~/ denominator;
    var remainder = absoluteNumerator.remainder(denominator);

    if (remainder == BigInt.zero) {
      return '${isNegative ? '-' : ''}$integerPart';
    }

    final digits = StringBuffer();
    for (var index = 0; index < precision; index++) {
      if (remainder == BigInt.zero) {
        break;
      }
      remainder *= BigInt.from(10);
      final digit = remainder ~/ denominator;
      remainder = remainder.remainder(denominator);
      digits.write(digit);
    }

    final decimalDigits = digits.toString().replaceFirst(RegExp(r'0+$'), '');
    if (decimalDigits.isEmpty) {
      return '${isNegative ? '-' : ''}$integerPart';
    }

    return '${isNegative ? '-' : ''}$integerPart.$decimalDigits';
  }

  RationalValue? tryExactSquareRoot() {
    if (numerator.isNegative) {
      return null;
    }

    final numeratorRoot = _exactIntegerSquareRoot(numerator);
    final denominatorRoot = _exactIntegerSquareRoot(denominator);
    if (numeratorRoot == null || denominatorRoot == null) {
      return null;
    }

    return RationalValue(numeratorRoot, denominatorRoot);
  }

  static BigInt _pow10(int exponent) {
    if (exponent <= 0) {
      return BigInt.one;
    }
    return BigInt.from(10).pow(exponent);
  }

  static BigInt? _exactIntegerSquareRoot(BigInt value) {
    if (value.isNegative) {
      return null;
    }
    if (value < BigInt.two) {
      return value;
    }

    var current = BigInt.one << ((value.bitLength + 1) >> 1);
    while (true) {
      final next = (current + value ~/ current) >> 1;
      if (next >= current) {
        break;
      }
      current = next;
    }

    while (current * current > value) {
      current -= BigInt.one;
    }

    return current * current == value ? current : null;
  }
}
