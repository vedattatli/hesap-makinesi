import 'dart:math' as math;

/// Supported symbolic factor categories.
enum SymbolicFactorType { constant, radical }

/// Supported named symbolic constants.
enum SymbolicConstantKind { pi, e }

/// Base type for exact symbolic factors.
abstract class SymbolicFactor {
  const SymbolicFactor();

  SymbolicFactorType get type;

  String get key;

  int get sortOrder;

  double toDouble();
}

/// Symbolic factor for constants such as pi and e.
class ConstantFactor extends SymbolicFactor {
  const ConstantFactor(this.constantKind);

  final SymbolicConstantKind constantKind;

  @override
  SymbolicFactorType get type => SymbolicFactorType.constant;

  @override
  String get key => 'const:${constantKind.name}';

  @override
  int get sortOrder => constantKind == SymbolicConstantKind.pi ? 0 : 1;

  String get displaySymbol => constantKind == SymbolicConstantKind.pi ? 'π' : 'e';

  @override
  double toDouble() {
    return constantKind == SymbolicConstantKind.pi ? math.pi : math.e;
  }

  @override
  bool operator ==(Object other) {
    return other is ConstantFactor && other.constantKind == constantKind;
  }

  @override
  int get hashCode => Object.hash(type, constantKind);
}

/// Symbolic factor for a square root of a positive integer.
class RadicalFactor extends SymbolicFactor {
  RadicalFactor(this.radicand)
    : assert(radicand > BigInt.one, 'radicand must be greater than 1');

  final BigInt radicand;

  @override
  SymbolicFactorType get type => SymbolicFactorType.radical;

  @override
  String get key => 'rad:$radicand';

  @override
  int get sortOrder => 2;

  String get displaySymbol => '√$radicand';

  @override
  double toDouble() {
    return math.sqrt(radicand.toDouble());
  }

  @override
  bool operator ==(Object other) {
    return other is RadicalFactor && other.radicand == radicand;
  }

  @override
  int get hashCode => Object.hash(type, radicand);
}

const symbolicPiFactor = ConstantFactor(SymbolicConstantKind.pi);
const symbolicEFactor = ConstantFactor(SymbolicConstantKind.e);
