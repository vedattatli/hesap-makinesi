import 'package:flutter/material.dart';

import '../design/app_motion.dart';
import '../design/app_radii.dart';
import '../design/app_shadows.dart';
import '../design/app_spacing.dart';

const multiplySymbol = '\u00D7';
const divideSymbol = '\u00F7';
const backspaceSymbol = '\u232B';
const cursorLeftSymbol = '\u2190';
const cursorRightSymbol = '\u2192';

/// Dense scientific keypad that delegates all behavior to callbacks.
class CalculatorKeypad extends StatefulWidget {
  const CalculatorKeypad({
    super.key,
    this.reduceMotion = false,
    required this.onTextPressed,
    required this.onFunctionPressed,
    required this.onOperatorPressed,
    required this.onBackspacePressed,
    required this.onClearExpressionPressed,
    required this.onClearAllPressed,
    required this.onMoveCursorLeft,
    required this.onMoveCursorRight,
    required this.onEvaluatePressed,
  });

  final bool reduceMotion;
  final ValueChanged<String> onTextPressed;
  final ValueChanged<String> onFunctionPressed;
  final ValueChanged<String> onOperatorPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearExpressionPressed;
  final VoidCallback onClearAllPressed;
  final VoidCallback onMoveCursorLeft;
  final VoidCallback onMoveCursorRight;
  final VoidCallback onEvaluatePressed;

  @override
  State<CalculatorKeypad> createState() => _CalculatorKeypadState();
}

class _CalculatorKeypadState extends State<CalculatorKeypad> {
  _KeyCategory _selectedCategory = _KeyCategory.all;

  ValueChanged<String> get onTextPressed => widget.onTextPressed;
  ValueChanged<String> get onFunctionPressed => widget.onFunctionPressed;
  ValueChanged<String> get onOperatorPressed => widget.onOperatorPressed;
  VoidCallback get onBackspacePressed => widget.onBackspacePressed;
  VoidCallback get onClearExpressionPressed => widget.onClearExpressionPressed;
  VoidCallback get onClearAllPressed => widget.onClearAllPressed;
  VoidCallback get onMoveCursorLeft => widget.onMoveCursorLeft;
  VoidCallback get onMoveCursorRight => widget.onMoveCursorRight;
  VoidCallback get onEvaluatePressed => widget.onEvaluatePressed;

  @override
  Widget build(BuildContext context) {
    final allKeys = <_KeySpec>[
      _KeySpec.function('data', () => onFunctionPressed('data')),
      _KeySpec.function('to', () => onFunctionPressed('to')),
      _KeySpec.function('vec', () => onFunctionPressed('vec')),
      _KeySpec.function('mat', () => onFunctionPressed('mat')),
      _KeySpec.function('solve', () => onFunctionPressed('solve')),
      _KeySpec.function('plot', () => onFunctionPressed('plot')),
      _KeySpec.function('sin', () => onFunctionPressed('sin')),
      _KeySpec.function('cos', () => onFunctionPressed('cos')),
      _KeySpec.function('tan', () => onFunctionPressed('tan')),
      _KeySpec.function('ln', () => onFunctionPressed('ln')),
      _KeySpec.function('log', () => onFunctionPressed('log')),
      _KeySpec.function('sqrt', () => onFunctionPressed('sqrt')),
      _KeySpec.function('abs', () => onFunctionPressed('abs')),
      _KeySpec.function('pow', () => onFunctionPressed('pow')),
      _KeySpec.function('min', () => onFunctionPressed('min')),
      _KeySpec.function('max', () => onFunctionPressed('max')),
      _KeySpec.function('fn', () => onFunctionPressed('fn')),
      _KeySpec.function('evalAt', () => onFunctionPressed('evalAt')),
      _KeySpec.function('root', () => onFunctionPressed('root')),
      _KeySpec.function('roots', () => onFunctionPressed('roots')),
      _KeySpec.function('inter', () => onFunctionPressed('intersections')),
      _KeySpec.function('slope', () => onFunctionPressed('slope')),
      _KeySpec.function('area', () => onFunctionPressed('area')),
      _KeySpec.function('eq', () => onFunctionPressed('eq')),
      _KeySpec.function('nsolve', () => onFunctionPressed('nsolve')),
      _KeySpec.function('diff', () => onFunctionPressed('diff')),
      _KeySpec.function('dAt', () => onFunctionPressed('derivativeAt')),
      _KeySpec.function('int', () => onFunctionPressed('integral')),
      _KeySpec.function('integrate', () => onFunctionPressed('integrate')),
      _KeySpec.function('simplify', () => onFunctionPressed('simplify')),
      _KeySpec.function('expand', () => onFunctionPressed('expand')),
      _KeySpec.function('factor', () => onFunctionPressed('factor')),
      _KeySpec.function('sys', () => onFunctionPressed('solveSystem')),
      _KeySpec.function('linsolve', () => onFunctionPressed('linsolve')),
      _KeySpec.function('vars', () => onFunctionPressed('vars')),
      _KeySpec.function('mean', () => onFunctionPressed('mean')),
      _KeySpec.function('median', () => onFunctionPressed('median')),
      _KeySpec.function('mode', () => onFunctionPressed('mode')),
      _KeySpec.function('var', () => onFunctionPressed('variance')),
      _KeySpec.function('std', () => onFunctionPressed('stddev')),
      _KeySpec.function('quant', () => onFunctionPressed('quantile')),
      _KeySpec.function('nCr', () => onFunctionPressed('nCr')),
      _KeySpec.function('nPr', () => onFunctionPressed('nPr')),
      _KeySpec.function('fact', () => onFunctionPressed('factorial')),
      _KeySpec.function('binom', () => onFunctionPressed('binomPmf')),
      _KeySpec.function('normCdf', () => onFunctionPressed('normalCdf')),
      _KeySpec.function('linreg', () => onFunctionPressed('linreg')),
      _KeySpec.function('corr', () => onFunctionPressed('corr')),
      _KeySpec.function('dot', () => onFunctionPressed('dot')),
      _KeySpec.function('cross', () => onFunctionPressed('cross')),
      _KeySpec.function('norm', () => onFunctionPressed('norm')),
      _KeySpec.function('det', () => onFunctionPressed('det')),
      _KeySpec.function('inv', () => onFunctionPressed('inv')),
      _KeySpec.function('tr', () => onFunctionPressed('transpose')),
      _KeySpec.function('id', () => onFunctionPressed('identity')),
      _KeySpec.function('m', () => onTextPressed(' m')),
      _KeySpec.function('cm', () => onTextPressed(' cm')),
      _KeySpec.function('km', () => onTextPressed(' km')),
      _KeySpec.function('s', () => onTextPressed(' s')),
      _KeySpec.function('h', () => onTextPressed(' h')),
      _KeySpec.function('kg', () => onTextPressed(' kg')),
      _KeySpec.function('N', () => onTextPressed(' N')),
      _KeySpec.function('J', () => onTextPressed(' J')),
      _KeySpec.function('W', () => onTextPressed(' W')),
      _KeySpec.function('Pa', () => onTextPressed(' Pa')),
      _KeySpec.function('degC', () => onTextPressed(' degC')),
      _KeySpec.function('degF', () => onTextPressed(' degF')),
      _KeySpec.function('deltaC', () => onTextPressed(' deltaC')),
      _KeySpec.function('deltaF', () => onTextPressed(' deltaF')),
      _KeySpec.function('π', () => onTextPressed('π')),
      _KeySpec.function('e', () => onTextPressed('e')),
      _KeySpec.function('i', () => onTextPressed('i')),
      _KeySpec.function('x', () => onTextPressed('x')),
      _KeySpec.function('re', () => onFunctionPressed('re')),
      _KeySpec.function('im', () => onFunctionPressed('im')),
      _KeySpec.function('conj', () => onFunctionPressed('conj')),
      _KeySpec.function('arg', () => onFunctionPressed('arg')),
      _KeySpec.function('cis', () => onFunctionPressed('cis')),
      _KeySpec.function('polar', () => onFunctionPressed('polar')),
      _KeySpec.function('(', () => onTextPressed('(')),
      _KeySpec.function(')', () => onTextPressed(')')),
      _KeySpec.operator('^', () => onOperatorPressed('^')),
      _KeySpec.number('7', () => onTextPressed('7')),
      _KeySpec.number('8', () => onTextPressed('8')),
      _KeySpec.number('9', () => onTextPressed('9')),
      _KeySpec.operator(divideSymbol, () => onOperatorPressed(divideSymbol)),
      _KeySpec.utility(backspaceSymbol, onBackspacePressed),
      _KeySpec.number('4', () => onTextPressed('4')),
      _KeySpec.number('5', () => onTextPressed('5')),
      _KeySpec.number('6', () => onTextPressed('6')),
      _KeySpec.operator(
        multiplySymbol,
        () => onOperatorPressed(multiplySymbol),
      ),
      _KeySpec.utility(cursorLeftSymbol, onMoveCursorLeft),
      _KeySpec.number('1', () => onTextPressed('1')),
      _KeySpec.number('2', () => onTextPressed('2')),
      _KeySpec.number('3', () => onTextPressed('3')),
      _KeySpec.operator('-', () => onOperatorPressed('-')),
      _KeySpec.utility(cursorRightSymbol, onMoveCursorRight),
      _KeySpec.number('0', () => onTextPressed('0')),
      _KeySpec.number('.', () => onTextPressed('.')),
      _KeySpec.utility('C', onClearExpressionPressed),
      _KeySpec.utility('AC', onClearAllPressed),
      _KeySpec.operator('+', () => onOperatorPressed('+')),
    ];
    final keys = allKeys
        .where((key) => _matchesCategory(key, _selectedCategory))
        .toList(growable: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.card,
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
        boxShadow: AppShadows.control(colorScheme),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                key: const Key('keypad-category-tabs'),
                scrollDirection: Axis.horizontal,
                itemCount: _KeyCategory.values.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final category = _KeyCategory.values[index];
                  return ChoiceChip(
                    key: Key('keypad-category-${category.label}'),
                    label: Text(category.label),
                    selected: _selectedCategory == category,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: AppMotion.duration(
                AppMotion.normal,
                reduceMotion: widget.reduceMotion,
              ),
              child: GridView.builder(
                key: ValueKey<_KeyCategory>(_selectedCategory),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: keys.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.16,
                ),
                itemBuilder: (context, index) {
                  final key = keys[index];
                  return _CalculatorButton(
                    label: key.label,
                    kind: key.kind,
                    onPressed: key.onPressed,
                    reduceMotion: widget.reduceMotion,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _CalculatorButton(
                label: '=',
                kind: _KeyKind.equals,
                onPressed: onEvaluatePressed,
                reduceMotion: widget.reduceMotion,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesCategory(_KeySpec key, _KeyCategory category) {
    if (category == _KeyCategory.all) {
      return true;
    }
    final label = key.label;
    return switch (category) {
      _KeyCategory.basic =>
        key.kind != _KeyKind.function ||
            const <String>{'(', ')', 'π', 'Ï€', 'e', 'i', 'x'}.contains(label),
      _KeyCategory.scientific => const <String>{
        'sin',
        'cos',
        'tan',
        'ln',
        'log',
        'sqrt',
        'abs',
        'pow',
        'min',
        'max',
      }.contains(label),
      _KeyCategory.cas => const <String>{
        'solve',
        'eq',
        'nsolve',
        'diff',
        'dAt',
        'int',
        'integrate',
        'simplify',
        'expand',
        'factor',
        'sys',
        'linsolve',
        'vars',
      }.contains(label),
      _KeyCategory.graph => const <String>{
        'x',
        'fn',
        'plot',
        'evalAt',
        'root',
        'roots',
        'inter',
        'slope',
        'area',
      }.contains(label),
      _KeyCategory.matrix => const <String>{
        'vec',
        'mat',
        'dot',
        'cross',
        'norm',
        'det',
        'inv',
        'tr',
        'id',
      }.contains(label),
      _KeyCategory.units => const <String>{
        'to',
        'm',
        'cm',
        'km',
        's',
        'h',
        'kg',
        'N',
        'J',
        'W',
        'Pa',
        'degC',
        'degF',
        'deltaC',
        'deltaF',
      }.contains(label),
      _KeyCategory.stats => const <String>{
        'data',
        'mean',
        'median',
        'mode',
        'var',
        'std',
        'quant',
        'nCr',
        'nPr',
        'fact',
        'binom',
        'normCdf',
        'linreg',
        'corr',
      }.contains(label),
      _KeyCategory.worksheet => const <String>{
        'data',
        'fn',
        'solve',
        'simplify',
        'plot',
        'vars',
      }.contains(label),
      _KeyCategory.all => true,
    };
  }
}

class _KeySpec {
  const _KeySpec.number(this.label, this.onPressed) : kind = _KeyKind.number;

  const _KeySpec.function(this.label, this.onPressed)
    : kind = _KeyKind.function;

  const _KeySpec.operator(this.label, this.onPressed)
    : kind = _KeyKind.operator;

  const _KeySpec.utility(this.label, this.onPressed) : kind = _KeyKind.utility;

  final String label;
  final _KeyKind kind;
  final VoidCallback onPressed;
}

class _CalculatorButton extends StatefulWidget {
  const _CalculatorButton({
    required this.label,
    required this.kind,
    required this.onPressed,
    required this.reduceMotion,
  });

  final String label;
  final _KeyKind kind;
  final VoidCallback onPressed;
  final bool reduceMotion;

  @override
  State<_CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<_CalculatorButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final style = switch (widget.kind) {
      _KeyKind.number => _ButtonPalette(
        background: colorScheme.surfaceContainerLow,
        foreground: colorScheme.onSurface,
      ),
      _KeyKind.function => _ButtonPalette(
        background: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
      ),
      _KeyKind.operator => _ButtonPalette(
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      ),
      _KeyKind.utility => _ButtonPalette(
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      ),
      _KeyKind.equals => _ButtonPalette(
        background: colorScheme.primary,
        foreground: colorScheme.onPrimary,
      ),
    };

    return Semantics(
      button: true,
      label: _semanticLabelFor(widget.label),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: AppMotion.duration(
            AppMotion.fast,
            reduceMotion: widget.reduceMotion,
          ),
          curve: AppMotion.standard,
          child: FilledButton(
            key: Key('button-${widget.label}'),
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: style.background,
              foregroundColor: style.foreground,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.control,
              ),
              textStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: widget.kind == _KeyKind.function ? 18 : 22,
              ),
            ),
            child: Center(child: Text(widget.label)),
          ),
        ),
      ),
    );
  }

  String _semanticLabelFor(String label) {
    return switch (label) {
      multiplySymbol => 'Multiply',
      divideSymbol => 'Divide',
      backspaceSymbol => 'Backspace',
      cursorLeftSymbol => 'Move cursor left',
      cursorRightSymbol => 'Move cursor right',
      'C' => 'Clear expression',
      'AC' => 'Clear all',
      '=' => 'Evaluate',
      '^' => 'Power',
      'i' => 'Imaginary unit',
      'x' => 'Graph variable x',
      'data' => 'Insert dataset function',
      'fn' => 'Insert function constructor',
      'plot' => 'Insert plot function',
      'evalAt' => 'Insert evaluate-at function',
      'root' => 'Insert root finder function',
      'roots' => 'Insert roots function',
      'inter' => 'Insert intersections function',
      'slope' => 'Insert slope function',
      'area' => 'Insert area function',
      'solve' => 'Insert solve function',
      'eq' => 'Insert equation function',
      'nsolve' => 'Insert numeric solve function',
      'diff' => 'Insert derivative function',
      'dAt' => 'Insert derivative-at function',
      'int' => 'Insert integral function',
      'integrate' => 'Insert definite integral function',
      'mean' => 'Insert mean function',
      'median' => 'Insert median function',
      'mode' => 'Insert mode function',
      'var' => 'Insert variance function',
      'std' => 'Insert standard deviation function',
      'quant' => 'Insert quantile function',
      'nCr' => 'Insert combinations function',
      'nPr' => 'Insert permutations function',
      'fact' => 'Insert factorial function',
      'binom' => 'Insert binomial probability function',
      'normCdf' => 'Insert normal CDF function',
      'linreg' => 'Insert linear regression function',
      'corr' => 'Insert correlation function',
      'vec' => 'Insert vector function',
      'mat' => 'Insert matrix function',
      'dot' => 'Insert dot product function',
      'cross' => 'Insert cross product function',
      'norm' => 'Insert vector norm function',
      'det' => 'Insert determinant function',
      'inv' => 'Insert inverse function',
      'tr' => 'Insert transpose function',
      'id' => 'Insert identity matrix function',
      'to' => 'Insert unit conversion function',
      'm' => 'Insert meter unit',
      'cm' => 'Insert centimeter unit',
      'km' => 'Insert kilometer unit',
      's' => 'Insert second unit',
      'h' => 'Insert hour unit',
      'kg' => 'Insert kilogram unit',
      'N' => 'Insert newton unit',
      'J' => 'Insert joule unit',
      'W' => 'Insert watt unit',
      'Pa' => 'Insert pascal unit',
      'degC' => 'Insert degree Celsius unit',
      'degF' => 'Insert degree Fahrenheit unit',
      'deltaC' => 'Insert delta Celsius unit',
      'deltaF' => 'Insert delta Fahrenheit unit',
      _ => label,
    };
  }
}

class _ButtonPalette {
  const _ButtonPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

enum _KeyKind { number, function, operator, utility, equals }

enum _KeyCategory {
  all('All'),
  basic('Basic'),
  scientific('Scientific'),
  cas('CAS'),
  graph('Graph'),
  matrix('Matrix'),
  units('Units'),
  stats('Stats'),
  worksheet('Worksheet');

  const _KeyCategory(this.label);

  final String label;
}
