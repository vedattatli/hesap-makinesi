/// Immutable SI base-dimension exponent vector.
class DimensionVector {
  const DimensionVector({
    this.length = 0,
    this.mass = 0,
    this.time = 0,
    this.electricCurrent = 0,
    this.thermodynamicTemperature = 0,
    this.amountOfSubstance = 0,
    this.luminousIntensity = 0,
  });

  static const dimensionless = DimensionVector();

  final int length;
  final int mass;
  final int time;
  final int electricCurrent;
  final int thermodynamicTemperature;
  final int amountOfSubstance;
  final int luminousIntensity;

  bool get isDimensionless =>
      length == 0 &&
      mass == 0 &&
      time == 0 &&
      electricCurrent == 0 &&
      thermodynamicTemperature == 0 &&
      amountOfSubstance == 0 &&
      luminousIntensity == 0;

  bool get isPureTemperature =>
      thermodynamicTemperature != 0 &&
      length == 0 &&
      mass == 0 &&
      time == 0 &&
      electricCurrent == 0 &&
      amountOfSubstance == 0 &&
      luminousIntensity == 0;

  DimensionVector add(DimensionVector other) {
    return DimensionVector(
      length: length + other.length,
      mass: mass + other.mass,
      time: time + other.time,
      electricCurrent: electricCurrent + other.electricCurrent,
      thermodynamicTemperature:
          thermodynamicTemperature + other.thermodynamicTemperature,
      amountOfSubstance: amountOfSubstance + other.amountOfSubstance,
      luminousIntensity: luminousIntensity + other.luminousIntensity,
    );
  }

  DimensionVector subtract(DimensionVector other) {
    return DimensionVector(
      length: length - other.length,
      mass: mass - other.mass,
      time: time - other.time,
      electricCurrent: electricCurrent - other.electricCurrent,
      thermodynamicTemperature:
          thermodynamicTemperature - other.thermodynamicTemperature,
      amountOfSubstance: amountOfSubstance - other.amountOfSubstance,
      luminousIntensity: luminousIntensity - other.luminousIntensity,
    );
  }

  DimensionVector multiplyByExponent(int exponent) {
    return DimensionVector(
      length: length * exponent,
      mass: mass * exponent,
      time: time * exponent,
      electricCurrent: electricCurrent * exponent,
      thermodynamicTemperature: thermodynamicTemperature * exponent,
      amountOfSubstance: amountOfSubstance * exponent,
      luminousIntensity: luminousIntensity * exponent,
    );
  }

  DimensionVector divideByExponent(int divisor) {
    assert(divisor != 0, 'divisor must not be zero');
    return DimensionVector(
      length: length ~/ divisor,
      mass: mass ~/ divisor,
      time: time ~/ divisor,
      electricCurrent: electricCurrent ~/ divisor,
      thermodynamicTemperature: thermodynamicTemperature ~/ divisor,
      amountOfSubstance: amountOfSubstance ~/ divisor,
      luminousIntensity: luminousIntensity ~/ divisor,
    );
  }

  String toDisplayString() {
    if (isDimensionless) {
      return 'dimensionless';
    }

    final parts = <String>[];
    void addPart(String symbol, int exponent) {
      if (exponent == 0) {
        return;
      }
      parts.add(exponent == 1 ? symbol : '$symbol${_superscript(exponent)}');
    }

    addPart('L', length);
    addPart('M', mass);
    addPart('T', time);
    addPart('I', electricCurrent);
    addPart('Θ', thermodynamicTemperature);
    addPart('N', amountOfSubstance);
    addPart('J', luminousIntensity);
    return parts.join('*');
  }

  @override
  String toString() => toDisplayString();

  @override
  bool operator ==(Object other) {
    return other is DimensionVector &&
        length == other.length &&
        mass == other.mass &&
        time == other.time &&
        electricCurrent == other.electricCurrent &&
        thermodynamicTemperature == other.thermodynamicTemperature &&
        amountOfSubstance == other.amountOfSubstance &&
        luminousIntensity == other.luminousIntensity;
  }

  @override
  int get hashCode => Object.hash(
    length,
    mass,
    time,
    electricCurrent,
    thermodynamicTemperature,
    amountOfSubstance,
    luminousIntensity,
  );

  static String _superscript(int exponent) {
    const digits = <String, String>{
      '-': '⁻',
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
    };
    return exponent
        .toString()
        .split('')
        .map((character) => digits[character] ?? character)
        .join();
  }
}
