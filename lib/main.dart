import 'package:flutter/material.dart';

import 'calculator_engine.dart';

const _multiplySymbol = '\u00D7';
const _divideSymbol = '\u00F7';
const _backspaceSymbol = '\u232B';

void main() {
  runApp(const ScientificCalculatorApp());
}

class ScientificCalculatorApp extends StatelessWidget {
  const ScientificCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF22C7A9),
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scientific Calculator',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: baseTheme.textTheme.apply(
          bodyColor: const Color(0xFFF4F8FB),
          displayColor: const Color(0xFFF4F8FB),
        ),
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const List<List<String>> _buttonRows = [
    ['sin', 'cos', 'tan', 'log'],
    ['sqrt', '^', '(', ')'],
    ['7', '8', '9', _divideSymbol],
    ['4', '5', '6', _multiplySymbol],
    ['1', '2', '3', '-'],
    ['0', '.', _backspaceSymbol, '+'],
  ];

  final CalculatorEngine _engine = CalculatorEngine();

  String _expression = '';
  String _result = '0';
  bool _afterEvaluation = false;
  AngleMode _angleMode = AngleMode.degree;

  @override
  Widget build(BuildContext context) {
    final displayExpression = _expression.isEmpty ? '0' : _expression;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF07131E),
            Color(0xFF0E2231),
            Color(0xFF143A45),
          ],
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _DisplayPanel(
                      expression: displayExpression,
                      result: _result,
                      angleMode: _angleMode,
                      onAngleModeChanged: _updateAngleMode,
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF08141D).withValues(alpha: 0.76),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF7DD9C8).withValues(alpha: 0.18),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x50000000),
                              blurRadius: 30,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              for (final row in _buttonRows) ...[
                                Expanded(
                                  child: Row(
                                    children: [
                                      for (var index = 0; index < row.length; index++) ...[
                                        if (index > 0) const SizedBox(width: 12),
                                        Expanded(
                                          child: _CalculatorButton(
                                            label: row[index],
                                            kind: _buttonKindFor(row[index]),
                                            onPressed: () => _handleButton(row[index]),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _CalculatorButton(
                                        label: 'C',
                                        kind: _ButtonKind.utility,
                                        onPressed: _clearAll,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _CalculatorButton(
                                        label: '=',
                                        kind: _ButtonKind.equals,
                                        onPressed: _evaluateExpression,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleButton(String label) {
    switch (label) {
      case 'C':
        _clearAll();
        return;
      case _backspaceSymbol:
        _backspace();
        return;
      case '=':
        _evaluateExpression();
        return;
      case '+':
      case '-':
      case _multiplySymbol:
      case _divideSymbol:
      case '^':
        _insertOperator(label);
        return;
      case '(':
        _insertOpeningParenthesis();
        return;
      case ')':
        _insertClosingParenthesis();
        return;
      case '.':
        _insertDecimalPoint();
        return;
      case 'sin':
      case 'cos':
      case 'tan':
      case 'log':
      case 'sqrt':
        _insertFunction(label);
        return;
      default:
        _insertDigit(label);
    }
  }

  void _updateAngleMode(Set<AngleMode> selection) {
    if (selection.isEmpty) {
      return;
    }

    setState(() {
      _angleMode = selection.first;
    });

    if (_expression.isEmpty || _result == 'Error') {
      return;
    }

    try {
      final value = _engine.evaluate(_expression, angleMode: _angleMode);
      setState(() {
        _result = _formatNumber(value);
      });
    } catch (_) {
      // Ignore incomplete expressions while the mode changes.
    }
  }

  void _clearAll() {
    setState(() {
      _expression = '';
      _result = '0';
      _afterEvaluation = false;
    });
  }

  void _backspace() {
    if (_expression.isEmpty) {
      return;
    }

    setState(() {
      _expression = _expression.substring(0, _expression.length - 1);
      _afterEvaluation = false;
      if (_expression.isEmpty) {
        _result = '0';
      }
    });
  }

  void _insertDigit(String digit) {
    setState(() {
      _prepareForFreshInput();

      if (_expression.isNotEmpty && _lastCharacter() == ')') {
        _expression += _multiplySymbol;
      }

      _expression += digit;
    });
  }

  void _insertDecimalPoint() {
    setState(() {
      _prepareForFreshInput();

      if (_expression.isNotEmpty && _lastCharacter() == ')') {
        _expression += _multiplySymbol;
      }

      final segment = _currentNumberSegment();
      if (segment.contains('.')) {
        return;
      }

      if (_expression.isEmpty ||
          _isOperator(_lastCharacter()) ||
          _lastCharacter() == '(') {
        _expression += '0.';
        return;
      }

      _expression += '.';
    });
  }

  void _insertOperator(String operatorSymbol) {
    setState(() {
      if (_result == 'Error') {
        if (operatorSymbol == '-') {
          _expression = '-';
          _result = '0';
        }
        return;
      }

      if (_afterEvaluation) {
        _expression = _result;
        _afterEvaluation = false;
      }

      if (_expression.isEmpty) {
        if (operatorSymbol == '-') {
          _expression = '-';
        }
        return;
      }

      final last = _lastCharacter();

      if (last == '(') {
        if (operatorSymbol == '-') {
          _expression += operatorSymbol;
        }
        return;
      }

      if (_isOperator(last)) {
        _expression =
            _expression.substring(0, _expression.length - 1) + operatorSymbol;
        return;
      }

      if (last == '.') {
        return;
      }

      _expression += operatorSymbol;
    });
  }

  void _insertOpeningParenthesis() {
    setState(() {
      _prepareForFreshInput();

      if (_endsWithValue()) {
        _expression += '$_multiplySymbol(';
        return;
      }

      _expression += '(';
    });
  }

  void _insertClosingParenthesis() {
    if (!_canCloseParenthesis()) {
      return;
    }

    setState(() {
      _expression += ')';
    });
  }

  void _insertFunction(String functionName) {
    setState(() {
      _prepareForFreshInput();

      if (_endsWithValue()) {
        _expression += _multiplySymbol;
      }

      _expression += '$functionName(';
    });
  }

  void _evaluateExpression() {
    if (_expression.isEmpty) {
      return;
    }

    try {
      final value = _engine.evaluate(_expression, angleMode: _angleMode);
      setState(() {
        _result = _formatNumber(value);
        _afterEvaluation = true;
      });
    } catch (_) {
      setState(() {
        _result = 'Error';
        _afterEvaluation = false;
      });
    }
  }

  bool _canCloseParenthesis() {
    if (_expression.isEmpty) {
      return false;
    }

    final openCount = '('.allMatches(_expression).length;
    final closeCount = ')'.allMatches(_expression).length;

    if (closeCount >= openCount) {
      return false;
    }

    final last = _lastCharacter();
    return !_isOperator(last) && last != '(';
  }

  bool _endsWithValue() {
    if (_expression.isEmpty) {
      return false;
    }

    final last = _lastCharacter();
    return _isDigit(last) || last == ')';
  }

  String _currentNumberSegment() {
    if (_expression.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    for (var index = _expression.length - 1; index >= 0; index--) {
      final character = _expression[index];
      if (_isDigit(character) || character == '.') {
        buffer.write(character);
        continue;
      }
      break;
    }

    return buffer.toString().split('').reversed.join();
  }

  String _lastCharacter() => _expression[_expression.length - 1];

  bool _isDigit(String value) => '0123456789'.contains(value);

  bool _isOperator(String value) =>
      value == '+' ||
      value == '-' ||
      value == _multiplySymbol ||
      value == _divideSymbol ||
      value == '^';

  void _prepareForFreshInput() {
    if (_afterEvaluation || _result == 'Error') {
      _expression = '';
      _result = '0';
      _afterEvaluation = false;
    }
  }

  String _formatNumber(double value) {
    final normalized = value == -0.0 ? 0.0 : value;
    final text = normalized.toStringAsPrecision(12);

    if (text.contains('e') || text.contains('E')) {
      return text;
    }

    if (!text.contains('.')) {
      return text;
    }

    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  _ButtonKind _buttonKindFor(String label) {
    if (label == 'C' || label == _backspaceSymbol) {
      return _ButtonKind.utility;
    }
    if (label == '=') {
      return _ButtonKind.equals;
    }
    if (_isOperator(label)) {
      return _ButtonKind.operator;
    }
    if (const {'sin', 'cos', 'tan', 'log', 'sqrt', '(', ')'}.contains(label)) {
      return _ButtonKind.function;
    }
    return _ButtonKind.number;
  }
}

class _DisplayPanel extends StatelessWidget {
  const _DisplayPanel({
    required this.expression,
    required this.result,
    required this.angleMode,
    required this.onAngleModeChanged,
  });

  final String expression;
  final String result;
  final AngleMode angleMode;
  final ValueChanged<Set<AngleMode>> onAngleModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF09151D),
            Color(0xFF0D2029),
            Color(0xFF12323B),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF7DD9C8).withValues(alpha: 0.24),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x5A000000),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scientific Calculator',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Flutter ile hazirlandi',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFB7CBD2),
                    ),
                  ),
                ],
              );

              final angleSelector = DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF0C171F),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SegmentedButton<AngleMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<AngleMode>(
                      value: AngleMode.degree,
                      label: Text('DEG'),
                    ),
                    ButtonSegment<AngleMode>(
                      value: AngleMode.radian,
                      label: Text('RAD'),
                    ),
                  ],
                  selected: {angleMode},
                  onSelectionChanged: onAngleModeChanged,
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF041216);
                      }
                      return const Color(0xFFB8D6D9);
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF80E4C4);
                      }
                      return const Color(0xFF10212A);
                    }),
                    side: WidgetStateProperty.all(BorderSide.none),
                  ),
                ),
              );

              if (constraints.maxWidth < 430) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 16),
                    angleSelector,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  angleSelector,
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Expression',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF8EB4B5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            reverse: true,
            scrollDirection: Axis.horizontal,
            child: Text(
              expression,
              key: const Key('expression-text'),
              textAlign: TextAlign.right,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE7F1F4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Result',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF8EB4B5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                result,
                key: const Key('result-text'),
                textAlign: TextAlign.right,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: result == 'Error'
                      ? const Color(0xFFFF8A80)
                      : const Color(0xFFFAFFFE),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({
    required this.label,
    required this.kind,
    required this.onPressed,
  });

  final String label;
  final _ButtonKind kind;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = switch (kind) {
      _ButtonKind.number => const _ButtonPalette(
          background: Color(0xFF16252F),
          foreground: Color(0xFFF5FBFD),
        ),
      _ButtonKind.function => const _ButtonPalette(
          background: Color(0xFF4D6976),
          foreground: Color(0xFFE9F6FA),
        ),
      _ButtonKind.operator => const _ButtonPalette(
          background: Color(0xFFFFA22A),
          foreground: Color(0xFF221200),
        ),
      _ButtonKind.utility => const _ButtonPalette(
          background: Color(0xFFFF5A66),
          foreground: Color(0xFFFFF2F4),
        ),
      _ButtonKind.equals => const _ButtonPalette(
          background: Color(0xFF54B658),
          foreground: Color(0xFFF5FFF6),
        ),
    };

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: EdgeInsets.zero,
        backgroundColor: style.background,
        foregroundColor: style.foreground,
        textStyle: TextStyle(
          fontSize: kind == _ButtonKind.function ? 20 : 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      child: Center(child: Text(label)),
    );
  }
}

class _ButtonPalette {
  const _ButtonPalette({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

enum _ButtonKind { number, function, operator, utility, equals }
