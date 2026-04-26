import '../values/rational_value.dart';
import 'dimension_vector.dart';
import 'unit_definition.dart';
import 'unit_expression.dart';

/// Central lookup table for supported physical units.
class UnitRegistry {
  UnitRegistry._()
    : _definitionsByKey = _definitions,
      _aliasToKey = _buildAliasIndex(_definitions),
      _absoluteToDelta = const <String, String>{
        'degc': 'deltac',
        'degf': 'deltaf',
      };

  static final instance = UnitRegistry._();
  static final Map<String, UnitDefinition> _definitions = _buildDefinitions();

  final Map<String, UnitDefinition> _definitionsByKey;
  final Map<String, String> _aliasToKey;
  final Map<String, String> _absoluteToDelta;

  UnitDefinition? lookup(String rawIdentifier) {
    final normalized = rawIdentifier.toLowerCase();
    final canonicalKey = _aliasToKey[normalized];
    if (canonicalKey == null) {
      return null;
    }
    return _definitionsByKey[canonicalKey];
  }

  UnitExpression canonicalize(UnitExpression expression) {
    if (expression.isDimensionless) {
      return UnitExpression.dimensionless();
    }
    if (expression.isAffineAbsolute) {
      return expression;
    }

    for (final definition in _definitionsByKey.values) {
      if (definition.isAffine) {
        continue;
      }
      if (definition.dimension != expression.dimension) {
        continue;
      }
      if (definition.factorToBase.compareTo(expression.factorToBase) != 0) {
        continue;
      }
      if (definition.flavor != expression.flavor) {
        continue;
      }
      return UnitExpression.fromDefinition(definition);
    }

    return expression;
  }

  UnitExpression? deltaCounterpart(UnitExpression expression) {
    final key = expression.singleCanonicalKey;
    if (key == null) {
      return null;
    }
    final deltaKey = _absoluteToDelta[key];
    if (deltaKey == null) {
      return null;
    }
    final definition = _definitionsByKey[deltaKey];
    if (definition == null) {
      return null;
    }
    return UnitExpression.fromDefinition(definition);
  }

  UnitExpression baseExpressionForDimension(DimensionVector dimension) {
    if (dimension.isDimensionless) {
      return UnitExpression.dimensionless();
    }

    final exponents = <String, int>{};
    final displaySymbols = <String, String>{};

    void add(String key, String symbol, int exponent) {
      if (exponent == 0) {
        return;
      }
      exponents[key] = exponent;
      displaySymbols[key] = symbol;
    }

    add('kg', 'kg', dimension.mass);
    add('m', 'm', dimension.length);
    add('s', 's', dimension.time);
    add('a', 'A', dimension.electricCurrent);
    add('k', 'K', dimension.thermodynamicTemperature);
    add('mol', 'mol', dimension.amountOfSubstance);
    add('cd', 'cd', dimension.luminousIntensity);

    return UnitExpression(
      exponents: exponents,
      displaySymbols: displaySymbols,
      dimension: dimension,
      factorToBase: RationalValue.one,
    );
  }

  static Map<String, String> _buildAliasIndex(
    Map<String, UnitDefinition> definitions,
  ) {
    final aliases = <String, String>{};
    for (final definition in definitions.values) {
      aliases[definition.canonicalKey] = definition.canonicalKey;
      for (final alias in definition.aliases) {
        aliases[alias.toLowerCase()] = definition.canonicalKey;
      }
    }
    return aliases;
  }

  static Map<String, UnitDefinition> _buildDefinitions() {
    RationalValue literal(String raw) => RationalValue.parseLiteral(raw);

    const length = DimensionVector(length: 1);
    const mass = DimensionVector(mass: 1);
    const time = DimensionVector(time: 1);
    const current = DimensionVector(electricCurrent: 1);
    const temperature = DimensionVector(thermodynamicTemperature: 1);
    const amount = DimensionVector(amountOfSubstance: 1);
    const luminous = DimensionVector(luminousIntensity: 1);
    final volume = const DimensionVector(length: 1).multiplyByExponent(3);
    final hertz = const DimensionVector(time: -1);
    final newton = const DimensionVector(length: 1, mass: 1, time: -2);
    final pascal = const DimensionVector(length: -1, mass: 1, time: -2);
    final joule = const DimensionVector(length: 2, mass: 1, time: -2);
    final watt = const DimensionVector(length: 2, mass: 1, time: -3);

    return <String, UnitDefinition>{
      'm': UnitDefinition(
        canonicalKey: 'm',
        displaySymbol: 'm',
        aliases: const ['m'],
        dimension: length,
        factorToBase: RationalValue.one,
      ),
      'nm': UnitDefinition(
        canonicalKey: 'nm',
        displaySymbol: 'nm',
        aliases: const ['nm'],
        dimension: length,
        factorToBase: literal('1e-9'),
      ),
      'um': UnitDefinition(
        canonicalKey: 'um',
        displaySymbol: 'µm',
        aliases: const ['um', 'µm', 'μm'],
        dimension: length,
        factorToBase: literal('1e-6'),
      ),
      'mm': UnitDefinition(
        canonicalKey: 'mm',
        displaySymbol: 'mm',
        aliases: const ['mm'],
        dimension: length,
        factorToBase: literal('1e-3'),
      ),
      'cm': UnitDefinition(
        canonicalKey: 'cm',
        displaySymbol: 'cm',
        aliases: const ['cm'],
        dimension: length,
        factorToBase: literal('1e-2'),
      ),
      'dm': UnitDefinition(
        canonicalKey: 'dm',
        displaySymbol: 'dm',
        aliases: const ['dm'],
        dimension: length,
        factorToBase: literal('1e-1'),
      ),
      'km': UnitDefinition(
        canonicalKey: 'km',
        displaySymbol: 'km',
        aliases: const ['km'],
        dimension: length,
        factorToBase: RationalValue.fromInt(1000),
      ),
      'in': UnitDefinition(
        canonicalKey: 'in',
        displaySymbol: 'in',
        aliases: const ['in'],
        dimension: length,
        factorToBase: literal('0.0254'),
      ),
      'ft': UnitDefinition(
        canonicalKey: 'ft',
        displaySymbol: 'ft',
        aliases: const ['ft'],
        dimension: length,
        factorToBase: literal('0.3048'),
      ),
      'yd': UnitDefinition(
        canonicalKey: 'yd',
        displaySymbol: 'yd',
        aliases: const ['yd'],
        dimension: length,
        factorToBase: literal('0.9144'),
      ),
      'mi': UnitDefinition(
        canonicalKey: 'mi',
        displaySymbol: 'mi',
        aliases: const ['mi'],
        dimension: length,
        factorToBase: literal('1609.344'),
      ),
      'kg': UnitDefinition(
        canonicalKey: 'kg',
        displaySymbol: 'kg',
        aliases: const ['kg'],
        dimension: mass,
        factorToBase: RationalValue.one,
      ),
      'mg': UnitDefinition(
        canonicalKey: 'mg',
        displaySymbol: 'mg',
        aliases: const ['mg'],
        dimension: mass,
        factorToBase: literal('1e-6'),
      ),
      'g': UnitDefinition(
        canonicalKey: 'g',
        displaySymbol: 'g',
        aliases: const ['g'],
        dimension: mass,
        factorToBase: literal('1e-3'),
      ),
      't': UnitDefinition(
        canonicalKey: 't',
        displaySymbol: 't',
        aliases: const ['t'],
        dimension: mass,
        factorToBase: RationalValue.fromInt(1000),
      ),
      'oz': UnitDefinition(
        canonicalKey: 'oz',
        displaySymbol: 'oz',
        aliases: const ['oz'],
        dimension: mass,
        factorToBase: literal('0.028349523125'),
      ),
      'lb': UnitDefinition(
        canonicalKey: 'lb',
        displaySymbol: 'lb',
        aliases: const ['lb'],
        dimension: mass,
        factorToBase: literal('0.45359237'),
      ),
      'ms': UnitDefinition(
        canonicalKey: 'ms',
        displaySymbol: 'ms',
        aliases: const ['ms'],
        dimension: time,
        factorToBase: literal('1e-3'),
      ),
      's': UnitDefinition(
        canonicalKey: 's',
        displaySymbol: 's',
        aliases: const ['s', 'sec'],
        dimension: time,
        factorToBase: RationalValue.one,
      ),
      'min': UnitDefinition(
        canonicalKey: 'min',
        displaySymbol: 'min',
        aliases: const ['min'],
        dimension: time,
        factorToBase: RationalValue.fromInt(60),
      ),
      'h': UnitDefinition(
        canonicalKey: 'h',
        displaySymbol: 'h',
        aliases: const ['h', 'hr'],
        dimension: time,
        factorToBase: RationalValue.fromInt(3600),
      ),
      'day': UnitDefinition(
        canonicalKey: 'day',
        displaySymbol: 'day',
        aliases: const ['day'],
        dimension: time,
        factorToBase: RationalValue.fromInt(86400),
      ),
      'a': UnitDefinition(
        canonicalKey: 'a',
        displaySymbol: 'A',
        aliases: const ['a'],
        dimension: current,
        factorToBase: RationalValue.one,
      ),
      'k': UnitDefinition(
        canonicalKey: 'k',
        displaySymbol: 'K',
        aliases: const ['k'],
        dimension: temperature,
        factorToBase: RationalValue.one,
      ),
      'degc': UnitDefinition(
        canonicalKey: 'degc',
        displaySymbol: 'degC',
        aliases: const ['degc', '°c'],
        dimension: temperature,
        factorToBase: RationalValue.one,
        offsetToBase: literal('273.15'),
        flavor: UnitValueFlavor.affineAbsolute,
      ),
      'degf': UnitDefinition(
        canonicalKey: 'degf',
        displaySymbol: 'degF',
        aliases: const ['degf', '°f'],
        dimension: temperature,
        factorToBase: RationalValue(BigInt.from(5), BigInt.from(9)),
        offsetToBase: RationalValue(BigInt.from(45967), BigInt.from(180)),
        flavor: UnitValueFlavor.affineAbsolute,
      ),
      'deltac': UnitDefinition(
        canonicalKey: 'deltac',
        displaySymbol: 'deltaC',
        aliases: const ['deltac'],
        dimension: temperature,
        factorToBase: RationalValue.one,
        flavor: UnitValueFlavor.affineDelta,
      ),
      'deltaf': UnitDefinition(
        canonicalKey: 'deltaf',
        displaySymbol: 'deltaF',
        aliases: const ['deltaf'],
        dimension: temperature,
        factorToBase: RationalValue(BigInt.from(5), BigInt.from(9)),
        flavor: UnitValueFlavor.affineDelta,
      ),
      'mol': UnitDefinition(
        canonicalKey: 'mol',
        displaySymbol: 'mol',
        aliases: const ['mol'],
        dimension: amount,
        factorToBase: RationalValue.one,
      ),
      'cd': UnitDefinition(
        canonicalKey: 'cd',
        displaySymbol: 'cd',
        aliases: const ['cd'],
        dimension: luminous,
        factorToBase: RationalValue.one,
      ),
      'l': UnitDefinition(
        canonicalKey: 'l',
        displaySymbol: 'L',
        aliases: const ['l', 'L'],
        dimension: volume,
        factorToBase: literal('1e-3'),
      ),
      'ml': UnitDefinition(
        canonicalKey: 'ml',
        displaySymbol: 'mL',
        aliases: const ['ml', 'mL'],
        dimension: volume,
        factorToBase: literal('1e-6'),
      ),
      'hz': UnitDefinition(
        canonicalKey: 'hz',
        displaySymbol: 'Hz',
        aliases: const ['hz'],
        dimension: hertz,
        factorToBase: RationalValue.one,
      ),
      'n': UnitDefinition(
        canonicalKey: 'n',
        displaySymbol: 'N',
        aliases: const ['n'],
        dimension: newton,
        factorToBase: RationalValue.one,
      ),
      'pa': UnitDefinition(
        canonicalKey: 'pa',
        displaySymbol: 'Pa',
        aliases: const ['pa'],
        dimension: pascal,
        factorToBase: RationalValue.one,
      ),
      'j': UnitDefinition(
        canonicalKey: 'j',
        displaySymbol: 'J',
        aliases: const ['j'],
        dimension: joule,
        factorToBase: RationalValue.one,
      ),
      'w': UnitDefinition(
        canonicalKey: 'w',
        displaySymbol: 'W',
        aliases: const ['w'],
        dimension: watt,
        factorToBase: RationalValue.one,
      ),
      'bar': UnitDefinition(
        canonicalKey: 'bar',
        displaySymbol: 'bar',
        aliases: const ['bar'],
        dimension: pascal,
        factorToBase: RationalValue.fromInt(100000),
      ),
      'atm': UnitDefinition(
        canonicalKey: 'atm',
        displaySymbol: 'atm',
        aliases: const ['atm'],
        dimension: pascal,
        factorToBase: RationalValue.fromInt(101325),
      ),
      'cal': UnitDefinition(
        canonicalKey: 'cal',
        displaySymbol: 'cal',
        aliases: const ['cal'],
        dimension: joule,
        factorToBase: literal('4.184'),
      ),
      'kwh': UnitDefinition(
        canonicalKey: 'kwh',
        displaySymbol: 'kWh',
        aliases: const ['kwh'],
        dimension: joule,
        factorToBase: RationalValue.fromInt(3600000),
      ),
    };
  }
}
