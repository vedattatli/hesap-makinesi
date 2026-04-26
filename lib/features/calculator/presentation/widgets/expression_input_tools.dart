import 'package:flutter/material.dart';

import '../../../../core/calculator/calculator.dart';
import '../../worksheet/scope/worksheet_symbol.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';

enum ExpressionSuggestionCategory {
  basic,
  trig,
  logExp,
  symbolic,
  complex,
  matrix,
  units,
  stats,
  graph,
  cas,
  worksheet,
}

class ExpressionSuggestion {
  const ExpressionSuggestion({
    required this.name,
    required this.signature,
    required this.category,
    required this.description,
    required this.insertText,
    this.example,
  });

  final String name;
  final String signature;
  final ExpressionSuggestionCategory category;
  final String description;
  final String insertText;
  final String? example;

  String get categoryLabel => switch (category) {
    ExpressionSuggestionCategory.basic => 'Basic',
    ExpressionSuggestionCategory.trig => 'Trig',
    ExpressionSuggestionCategory.logExp => 'Log/Exp',
    ExpressionSuggestionCategory.symbolic => 'Symbolic',
    ExpressionSuggestionCategory.complex => 'Complex',
    ExpressionSuggestionCategory.matrix => 'Matrix',
    ExpressionSuggestionCategory.units => 'Units',
    ExpressionSuggestionCategory.stats => 'Stats',
    ExpressionSuggestionCategory.graph => 'Graph',
    ExpressionSuggestionCategory.cas => 'CAS',
    ExpressionSuggestionCategory.worksheet => 'Worksheet',
  };
}

List<ExpressionSuggestion> defaultExpressionSuggestions() {
  return const <ExpressionSuggestion>[
    ExpressionSuggestion(
      name: 'sin',
      signature: 'sin(value)',
      category: ExpressionSuggestionCategory.trig,
      description: 'Sine using the active angle mode.',
      insertText: 'sin(',
      example: 'sin(30)',
    ),
    ExpressionSuggestion(
      name: 'cos',
      signature: 'cos(value)',
      category: ExpressionSuggestionCategory.trig,
      description: 'Cosine using the active angle mode.',
      insertText: 'cos(',
      example: 'cos(pi)',
    ),
    ExpressionSuggestion(
      name: 'sqrt',
      signature: 'sqrt(value)',
      category: ExpressionSuggestionCategory.symbolic,
      description: 'Square root with exact symbolic output when possible.',
      insertText: 'sqrt(',
      example: 'sqrt(2)',
    ),
    ExpressionSuggestion(
      name: 'ln',
      signature: 'ln(value)',
      category: ExpressionSuggestionCategory.logExp,
      description: 'Natural logarithm.',
      insertText: 'ln(',
      example: 'ln(e)',
    ),
    ExpressionSuggestion(
      name: 'pi',
      signature: 'pi',
      category: ExpressionSuggestionCategory.basic,
      description: 'The circle constant.',
      insertText: 'pi',
      example: 'sin(pi/2)',
    ),
    ExpressionSuggestion(
      name: 'i',
      signature: 'i',
      category: ExpressionSuggestionCategory.complex,
      description: 'Imaginary unit in complex mode.',
      insertText: 'i',
      example: 'sqrt(-1)',
    ),
    ExpressionSuggestion(
      name: 'mat',
      signature: 'mat(rows, cols, values...)',
      category: ExpressionSuggestionCategory.matrix,
      description: 'Matrix constructor.',
      insertText: 'mat(',
      example: 'mat(2,2,1,2,3,4)',
    ),
    ExpressionSuggestion(
      name: 'vec',
      signature: 'vec(values...)',
      category: ExpressionSuggestionCategory.matrix,
      description: 'Vector constructor.',
      insertText: 'vec(',
      example: 'vec(1,2,3)',
    ),
    ExpressionSuggestion(
      name: 'to',
      signature: 'to(value unit, targetUnit)',
      category: ExpressionSuggestionCategory.units,
      description: 'Unit conversion helper.',
      insertText: 'to(',
      example: 'to(72 km/h, m/s)',
    ),
    ExpressionSuggestion(
      name: 'data',
      signature: 'data(values...)',
      category: ExpressionSuggestionCategory.stats,
      description: 'Dataset constructor for statistics.',
      insertText: 'data(',
      example: 'mean(data(1,2,3,4))',
    ),
    ExpressionSuggestion(
      name: 'mean',
      signature: 'mean(data)',
      category: ExpressionSuggestionCategory.stats,
      description: 'Arithmetic mean.',
      insertText: 'mean(',
      example: 'mean(data(1,2,3,4))',
    ),
    ExpressionSuggestion(
      name: 'plot',
      signature: 'plot(expr, xMin, xMax)',
      category: ExpressionSuggestionCategory.graph,
      description: 'Create a graph plot result.',
      insertText: 'plot(',
      example: 'plot(sin(x), -pi, pi)',
    ),
    ExpressionSuggestion(
      name: 'root',
      signature: 'root(expr, min, max)',
      category: ExpressionSuggestionCategory.graph,
      description: 'Find one numeric root in an interval.',
      insertText: 'root(',
      example: 'root(x^2-4, 0, 5)',
    ),
    ExpressionSuggestion(
      name: 'solve',
      signature: 'solve(equation, variable)',
      category: ExpressionSuggestionCategory.cas,
      description: 'CAS-lite equation solver.',
      insertText: 'solve(',
      example: 'solve(x^2 - 4 = 0, x)',
    ),
    ExpressionSuggestion(
      name: 'simplify',
      signature: 'simplify(expr)',
      category: ExpressionSuggestionCategory.cas,
      description: 'Apply safe CAS-lite simplification rules.',
      insertText: 'simplify(',
      example: 'simplify(x + x)',
    ),
    ExpressionSuggestion(
      name: 'factor',
      signature: 'factor(expr)',
      category: ExpressionSuggestionCategory.cas,
      description: 'Limited polynomial factorization.',
      insertText: 'factor(',
      example: 'factor(x^2 - 4)',
    ),
  ];
}

List<ExpressionSuggestion> worksheetSymbolSuggestions(
  List<WorksheetSymbol> symbols,
) {
  return symbols
      .map(
        (symbol) => ExpressionSuggestion(
          name: symbol.name,
          signature: symbol.signature,
          category: ExpressionSuggestionCategory.worksheet,
          description:
              'Worksheet-scoped ${symbol.type.name}; insert only, not global.',
          insertText: symbol.type == WorksheetSymbolType.function
              ? '${symbol.name}('
              : symbol.name,
          example: symbol.displayValue,
        ),
      )
      .toList(growable: false);
}

List<ExpressionSuggestion> matchingSuggestions({
  required String expression,
  required int cursorOffset,
  required List<ExpressionSuggestion> worksheetSuggestions,
  int limit = 8,
}) {
  final allSuggestions = <ExpressionSuggestion>[
    ...defaultExpressionSuggestions(),
    ...worksheetSuggestions,
  ];
  final token = currentIdentifierToken(expression, cursorOffset).toLowerCase();
  final filtered = token.isEmpty
      ? allSuggestions
      : allSuggestions
            .where(
              (suggestion) =>
                  suggestion.name.toLowerCase().startsWith(token) ||
                  suggestion.signature.toLowerCase().contains(token),
            )
            .toList(growable: false);
  return filtered.take(limit).toList(growable: false);
}

String currentIdentifierToken(String expression, int cursorOffset) {
  final safeOffset = cursorOffset.clamp(0, expression.length);
  var start = safeOffset;
  while (start > 0 && _isIdentifierPart(expression[start - 1])) {
    start--;
  }
  return expression.substring(start, safeOffset);
}

String? bracketValidationMessage(String expression) {
  final stack = <String>[];
  for (var index = 0; index < expression.length; index++) {
    final char = expression[index];
    if (char == '(' || char == '[') {
      stack.add(char);
    } else if (char == ')' || char == ']') {
      if (stack.isEmpty) {
        return 'Unmatched closing bracket near position ${index + 1}.';
      }
      final open = stack.removeLast();
      if ((open == '(' && char != ')') || (open == '[' && char != ']')) {
        return 'Mismatched bracket near position ${index + 1}.';
      }
    }
  }
  if (stack.isNotEmpty) {
    return 'Missing closing bracket for ${stack.last}.';
  }
  return null;
}

bool _isIdentifierPart(String char) {
  return RegExp(r'[A-Za-z0-9_]').hasMatch(char) || char == 'π' || char == 'Ï';
}

class ExpressionAssistStrip extends StatelessWidget {
  const ExpressionAssistStrip({
    super.key,
    required this.expressionController,
    required this.worksheetSuggestions,
    required this.onSuggestionSelected,
    required this.onOpenPalette,
    required this.onOpenMatrixEditor,
    required this.onOpenVectorEditor,
    required this.onOpenUnitConverter,
    required this.onOpenDatasetEditor,
    required this.onOpenSolveCasEditor,
  });

  final TextEditingController expressionController;
  final List<ExpressionSuggestion> worksheetSuggestions;
  final ValueChanged<ExpressionSuggestion> onSuggestionSelected;
  final VoidCallback onOpenPalette;
  final VoidCallback onOpenMatrixEditor;
  final VoidCallback onOpenVectorEditor;
  final VoidCallback onOpenUnitConverter;
  final VoidCallback onOpenDatasetEditor;
  final VoidCallback onOpenSolveCasEditor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selection = expressionController.selection;
    final cursor = selection.isValid
        ? selection.extentOffset
        : expressionController.text.length;
    final suggestions = matchingSuggestions(
      expression: expressionController.text,
      cursorOffset: cursor,
      worksheetSuggestions: worksheetSuggestions,
    );
    final validationMessage = bracketValidationMessage(
      expressionController.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (validationMessage != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            validationMessage,
            key: const Key('expression-validation-message'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ] else ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _previewFor(expressionController.text),
            key: const Key('expression-preview-text'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          key: const Key('autocomplete-suggestion-row'),
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: suggestions
              .map(
                (suggestion) => ActionChip(
                  key: Key('autocomplete-suggestion-${suggestion.name}'),
                  label: Text(suggestion.name),
                  avatar: _SuggestionAvatar(category: suggestion.category),
                  tooltip: '${suggestion.signature}\n${suggestion.description}',
                  onPressed: () => onSuggestionSelected(suggestion),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            OutlinedButton.icon(
              key: const Key('open-function-palette-button'),
              onPressed: onOpenPalette,
              icon: const Icon(Icons.widgets_outlined),
              label: const Text('Palette'),
            ),
            OutlinedButton.icon(
              key: const Key('open-matrix-editor-button'),
              onPressed: onOpenMatrixEditor,
              icon: const Icon(Icons.grid_on_outlined),
              label: const Text('Matrix'),
            ),
            OutlinedButton.icon(
              key: const Key('open-vector-editor-button'),
              onPressed: onOpenVectorEditor,
              icon: const Icon(Icons.linear_scale_outlined),
              label: const Text('Vector'),
            ),
            OutlinedButton.icon(
              key: const Key('open-unit-converter-button'),
              onPressed: onOpenUnitConverter,
              icon: const Icon(Icons.straighten_outlined),
              label: const Text('Units'),
            ),
            OutlinedButton.icon(
              key: const Key('open-dataset-editor-button'),
              onPressed: onOpenDatasetEditor,
              icon: const Icon(Icons.table_rows_outlined),
              label: const Text('Dataset'),
            ),
            OutlinedButton.icon(
              key: const Key('open-solve-cas-editor-button'),
              onPressed: onOpenSolveCasEditor,
              icon: const Icon(Icons.auto_fix_high_outlined),
              label: const Text('Solve/CAS'),
            ),
          ],
        ),
      ],
    );
  }

  String _previewFor(String expression) {
    if (expression.trim().isEmpty) {
      return 'Use suggestions, palettes, or structured editors to build an expression.';
    }
    return 'Preview: ${expression.trim()}';
  }
}

class _SuggestionAvatar extends StatelessWidget {
  const _SuggestionAvatar({required this.category});

  final ExpressionSuggestionCategory category;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      ExpressionSuggestionCategory.basic => Icons.calculate_outlined,
      ExpressionSuggestionCategory.trig => Icons.change_history_outlined,
      ExpressionSuggestionCategory.logExp => Icons.show_chart_outlined,
      ExpressionSuggestionCategory.symbolic => Icons.functions_outlined,
      ExpressionSuggestionCategory.complex => Icons.blur_circular_outlined,
      ExpressionSuggestionCategory.matrix => Icons.grid_on_outlined,
      ExpressionSuggestionCategory.units => Icons.straighten_outlined,
      ExpressionSuggestionCategory.stats => Icons.query_stats_outlined,
      ExpressionSuggestionCategory.graph => Icons.area_chart_outlined,
      ExpressionSuggestionCategory.cas => Icons.auto_fix_high_outlined,
      ExpressionSuggestionCategory.worksheet => Icons.menu_book_outlined,
    };
    return Icon(icon, size: 16);
  }
}

class FunctionSymbolPalette extends StatefulWidget {
  const FunctionSymbolPalette({
    super.key,
    required this.worksheetSuggestions,
    required this.onInsert,
  });

  final List<ExpressionSuggestion> worksheetSuggestions;
  final ValueChanged<ExpressionSuggestion> onInsert;

  @override
  State<FunctionSymbolPalette> createState() => _FunctionSymbolPaletteState();
}

class _FunctionSymbolPaletteState extends State<FunctionSymbolPalette> {
  ExpressionSuggestionCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final allSuggestions = <ExpressionSuggestion>[
      ...defaultExpressionSuggestions(),
      ...widget.worksheetSuggestions,
    ];
    final visibleSuggestions = _selectedCategory == null
        ? allSuggestions
        : allSuggestions
              .where((suggestion) => suggestion.category == _selectedCategory)
              .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          key: const Key('function-symbol-palette'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Function & Symbol Palette',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      key: const Key('palette-category-All'),
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) => setState(() {
                        _selectedCategory = null;
                      }),
                    ),
                  ),
                  for (final category in ExpressionSuggestionCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        key: Key(
                          'palette-category-${_categoryLabel(category)}',
                        ),
                        label: Text(_categoryLabel(category)),
                        selected: _selectedCategory == category,
                        onSelected: (_) => setState(() {
                          _selectedCategory = category;
                        }),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: visibleSuggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = visibleSuggestions[index];
                  return ListTile(
                    key: Key('palette-item-${suggestion.name}'),
                    leading: _SuggestionAvatar(category: suggestion.category),
                    title: Text(suggestion.signature),
                    subtitle: Text(
                      '${suggestion.categoryLabel} • ${suggestion.description}'
                      '${suggestion.example == null ? '' : '\nExample: ${suggestion.example}'}',
                    ),
                    isThreeLine: suggestion.example != null,
                    onTap: () => widget.onInsert(suggestion),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(ExpressionSuggestionCategory category) {
    return switch (category) {
      ExpressionSuggestionCategory.basic => 'Basic',
      ExpressionSuggestionCategory.trig => 'Trig',
      ExpressionSuggestionCategory.logExp => 'Log/Exp',
      ExpressionSuggestionCategory.symbolic => 'Symbolic',
      ExpressionSuggestionCategory.complex => 'Complex',
      ExpressionSuggestionCategory.matrix => 'Matrix',
      ExpressionSuggestionCategory.units => 'Units',
      ExpressionSuggestionCategory.stats => 'Stats',
      ExpressionSuggestionCategory.graph => 'Graph',
      ExpressionSuggestionCategory.cas => 'CAS',
      ExpressionSuggestionCategory.worksheet => 'Worksheet',
    };
  }
}

class MatrixEditorSheet extends StatefulWidget {
  const MatrixEditorSheet({super.key});

  @override
  State<MatrixEditorSheet> createState() => _MatrixEditorSheetState();
}

class _MatrixEditorSheetState extends State<MatrixEditorSheet> {
  static const _maxSize = 6;
  int _rows = 2;
  int _columns = 2;
  final List<TextEditingController> _controllers = List.generate(
    _maxSize * _maxSize,
    (index) =>
        TextEditingController(text: index == 0 || index == 3 ? '1' : '0'),
  );

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      keyName: 'matrix-editor-sheet',
      title: 'Matrix Editor',
      subtitle: 'Build exact cell expressions and insert a mat(...) literal.',
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _NumberDropdown(
                  keyName: 'matrix-editor-rows',
                  label: 'Rows',
                  value: _rows,
                  max: _maxSize,
                  onChanged: (value) => setState(() => _rows = value),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NumberDropdown(
                  keyName: 'matrix-editor-columns',
                  label: 'Columns',
                  value: _columns,
                  max: _maxSize,
                  onChanged: (value) => setState(() => _columns = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var row = 0; row < _rows; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: <Widget>[
                  for (var column = 0; column < _columns; column++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: TextField(
                          key: Key('matrix-cell-$row-$column'),
                          controller: _controllers[row * _maxSize + column],
                          decoration: InputDecoration(
                            labelText: 'r${row + 1}c${column + 1}',
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          _PreviewText(keyName: 'matrix-preview-text', value: _preview()),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('matrix-editor-insert'),
            onPressed: () => Navigator.of(context).pop(_expression()),
            icon: const Icon(Icons.add),
            label: const Text('Insert matrix'),
          ),
        ],
      ),
    );
  }

  String _expression() {
    final values = <String>[];
    for (var row = 0; row < _rows; row++) {
      for (var column = 0; column < _columns; column++) {
        final text = _controllers[row * _maxSize + column].text.trim();
        values.add(text.isEmpty ? '0' : text);
      }
    }
    return 'mat($_rows,$_columns,${values.join(',')})';
  }

  String _preview() {
    final rows = <String>[];
    for (var row = 0; row < _rows; row++) {
      final values = <String>[];
      for (var column = 0; column < _columns; column++) {
        final text = _controllers[row * _maxSize + column].text.trim();
        values.add(text.isEmpty ? '0' : text);
      }
      rows.add('[${values.join(', ')}]');
    }
    return '[${rows.join(', ')}]';
  }
}

class VectorEditorSheet extends StatefulWidget {
  const VectorEditorSheet({super.key});

  @override
  State<VectorEditorSheet> createState() => _VectorEditorSheetState();
}

class _VectorEditorSheetState extends State<VectorEditorSheet> {
  static const _maxLength = 6;
  int _length = 3;
  final List<TextEditingController> _controllers = List.generate(
    _maxLength,
    (index) => TextEditingController(text: '${index + 1}'),
  );

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      keyName: 'vector-editor-sheet',
      title: 'Vector Editor',
      subtitle: 'Create a vector expression from exact cell strings.',
      child: Column(
        children: <Widget>[
          _NumberDropdown(
            keyName: 'vector-editor-length',
            label: 'Length',
            value: _length,
            max: _maxLength,
            onChanged: (value) => setState(() => _length = value),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < _length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: TextField(
                key: Key('vector-cell-$index'),
                controller: _controllers[index],
                decoration: InputDecoration(labelText: 'Value ${index + 1}'),
              ),
            ),
          _PreviewText(keyName: 'vector-preview-text', value: _expression()),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('vector-editor-insert'),
            onPressed: () => Navigator.of(context).pop(_expression()),
            icon: const Icon(Icons.add),
            label: const Text('Insert vector'),
          ),
        ],
      ),
    );
  }

  String _expression() {
    final values = _controllers
        .take(_length)
        .map((controller) {
          final text = controller.text.trim();
          return text.isEmpty ? '0' : text;
        })
        .join(',');
    return 'vec($values)';
  }
}

class DatasetEditorSheet extends StatefulWidget {
  const DatasetEditorSheet({super.key});

  @override
  State<DatasetEditorSheet> createState() => _DatasetEditorSheetState();
}

class _DatasetEditorSheetState extends State<DatasetEditorSheet> {
  final TextEditingController _controller = TextEditingController(
    text: '1, 2, 3, 4',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _summary();
    return _EditorShell(
      keyName: 'dataset-editor-sheet',
      title: 'Dataset Editor',
      subtitle: 'Paste comma-separated values; no CSV import yet.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const Key('dataset-editor-input'),
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Values'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            stats,
            key: const Key('dataset-summary-text'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('dataset-editor-insert'),
            onPressed: () => Navigator.of(context).pop(_expression()),
            icon: const Icon(Icons.add),
            label: const Text('Insert dataset'),
          ),
        ],
      ),
    );
  }

  String _expression() => 'data(${_controller.text.trim()})';

  String _summary() {
    final values = _controller.text
        .split(',')
        .map((part) => double.tryParse(part.trim()))
        .whereType<double>()
        .toList(growable: false);
    if (values.isEmpty) {
      return 'No numeric preview yet.';
    }
    values.sort();
    return 'count = ${values.length}, min = ${values.first}, max = ${values.last}';
  }
}

class UnitConverterSheet extends StatefulWidget {
  const UnitConverterSheet({super.key});

  @override
  State<UnitConverterSheet> createState() => _UnitConverterSheetState();
}

class _UnitConverterSheetState extends State<UnitConverterSheet> {
  static const _units = <String>[
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
  ];
  final TextEditingController _valueController = TextEditingController(
    text: '72',
  );
  String _sourceUnit = 'km/h';
  String _targetUnit = 'm/s';

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitOptions = <String>{..._units, 'km/h', 'm/s'}.toList();
    return _EditorShell(
      keyName: 'unit-converter-sheet',
      title: 'Unit Converter',
      subtitle: 'Build a safe to(value unit, targetUnit) expression.',
      child: Column(
        children: <Widget>[
          TextField(
            key: const Key('unit-converter-value'),
            controller: _valueController,
            decoration: const InputDecoration(labelText: 'Value'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: _StringDropdown(
                  keyName: 'unit-converter-source',
                  label: 'Source unit',
                  value: _sourceUnit,
                  values: unitOptions,
                  onChanged: (value) => setState(() => _sourceUnit = value),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StringDropdown(
                  keyName: 'unit-converter-target',
                  label: 'Target unit',
                  value: _targetUnit,
                  values: unitOptions,
                  onChanged: (value) => setState(() => _targetUnit = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _PreviewText(keyName: 'unit-converter-preview', value: _expression()),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('unit-converter-insert'),
            onPressed: () => Navigator.of(context).pop(_expression()),
            icon: const Icon(Icons.add),
            label: const Text('Insert conversion'),
          ),
        ],
      ),
    );
  }

  String _expression() {
    return 'to(${_valueController.text.trim()} $_sourceUnit, $_targetUnit)';
  }
}

class SolveCasEditorSheet extends StatefulWidget {
  const SolveCasEditorSheet({super.key});

  @override
  State<SolveCasEditorSheet> createState() => _SolveCasEditorSheetState();
}

class _SolveCasEditorSheetState extends State<SolveCasEditorSheet> {
  bool _solveMode = true;
  String _casTransform = 'simplify';
  final TextEditingController _equationController = TextEditingController(
    text: 'x^2 - 4 = 0',
  );
  final TextEditingController _variableController = TextEditingController(
    text: 'x',
  );
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void dispose() {
    _equationController.dispose();
    _variableController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      keyName: 'solve-cas-editor-sheet',
      title: 'Solve / CAS Editor',
      subtitle:
          'Generate solve, simplify, expand, factor, diff, or integral calls.',
      child: Column(
        children: <Widget>[
          SegmentedButton<bool>(
            key: const Key('solve-cas-mode-toggle'),
            showSelectedIcon: false,
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text('Solve')),
              ButtonSegment<bool>(value: false, label: Text('CAS')),
            ],
            selected: <bool>{_solveMode},
            onSelectionChanged: (selection) {
              setState(() => _solveMode = selection.first);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('solve-cas-expression-input'),
            controller: _equationController,
            decoration: InputDecoration(
              labelText: _solveMode ? 'Equation / expression' : 'Expression',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('solve-cas-variable-input'),
            controller: _variableController,
            decoration: const InputDecoration(labelText: 'Variable'),
          ),
          if (_solveMode) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('solve-cas-min-input'),
                    controller: _minController,
                    decoration: const InputDecoration(
                      labelText: 'Interval min (optional)',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    key: const Key('solve-cas-max-input'),
                    controller: _maxController,
                    decoration: const InputDecoration(
                      labelText: 'Interval max (optional)',
                    ),
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _StringDropdown(
              keyName: 'solve-cas-transform-select',
              label: 'Transform',
              value: _casTransform,
              values: const <String>[
                'simplify',
                'expand',
                'factor',
                'diff',
                'integral',
              ],
              onChanged: (value) => setState(() => _casTransform = value),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _PreviewText(keyName: 'solve-cas-preview-text', value: _expression()),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('solve-cas-editor-insert'),
            onPressed: () => Navigator.of(context).pop(_expression()),
            icon: const Icon(Icons.add),
            label: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  String _expression() {
    final expression = _equationController.text.trim();
    final variable = _variableController.text.trim().isEmpty
        ? 'x'
        : _variableController.text.trim();
    if (_solveMode) {
      final min = _minController.text.trim();
      final max = _maxController.text.trim();
      if (min.isNotEmpty && max.isNotEmpty) {
        return 'solve($expression, $variable, $min, $max)';
      }
      return 'solve($expression, $variable)';
    }
    if (_casTransform == 'diff' || _casTransform == 'integral') {
      return '$_casTransform($expression, $variable)';
    }
    return '$_casTransform($expression)';
  }
}

class GraphFunctionEditorResult {
  const GraphFunctionEditorResult({
    required this.expressions,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.autoY,
  });

  final List<String> expressions;
  final String xMin;
  final String xMax;
  final String yMin;
  final String yMax;
  final bool autoY;
}

class GraphFunctionEditorSheet extends StatefulWidget {
  const GraphFunctionEditorSheet({
    super.key,
    required this.expressions,
    required this.viewport,
    required this.autoY,
  });

  final List<String> expressions;
  final GraphViewport viewport;
  final bool autoY;

  @override
  State<GraphFunctionEditorSheet> createState() =>
      _GraphFunctionEditorSheetState();
}

class _GraphFunctionEditorSheetState extends State<GraphFunctionEditorSheet> {
  late final TextEditingController _expressionsController;
  late final TextEditingController _xMinController;
  late final TextEditingController _xMaxController;
  late final TextEditingController _yMinController;
  late final TextEditingController _yMaxController;
  late bool _autoY;

  @override
  void initState() {
    super.initState();
    _expressionsController = TextEditingController(
      text: widget.expressions.join('\n'),
    );
    _xMinController = TextEditingController(
      text: _format(widget.viewport.xMin),
    );
    _xMaxController = TextEditingController(
      text: _format(widget.viewport.xMax),
    );
    _yMinController = TextEditingController(
      text: _format(widget.viewport.yMin),
    );
    _yMaxController = TextEditingController(
      text: _format(widget.viewport.yMax),
    );
    _autoY = widget.autoY;
  }

  @override
  void dispose() {
    _expressionsController.dispose();
    _xMinController.dispose();
    _xMaxController.dispose();
    _yMinController.dispose();
    _yMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      keyName: 'graph-function-editor-sheet',
      title: 'Graph Function Editor',
      subtitle: 'One function per line. Expressions use graph-scoped x.',
      child: Column(
        children: <Widget>[
          TextField(
            key: const Key('graph-editor-expressions'),
            controller: _expressionsController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Expressions',
              hintText: 'sin(x)\ncos(x)\nx^2',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('graph-editor-xmin'),
                  controller: _xMinController,
                  decoration: const InputDecoration(labelText: 'xMin'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  key: const Key('graph-editor-xmax'),
                  controller: _xMaxController,
                  decoration: const InputDecoration(labelText: 'xMax'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('graph-editor-ymin'),
                  controller: _yMinController,
                  enabled: !_autoY,
                  decoration: const InputDecoration(labelText: 'yMin'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  key: const Key('graph-editor-ymax'),
                  controller: _yMaxController,
                  enabled: !_autoY,
                  decoration: const InputDecoration(labelText: 'yMax'),
                ),
              ),
            ],
          ),
          SwitchListTile(
            key: const Key('graph-editor-autoy'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto Y range'),
            value: _autoY,
            onChanged: (value) => setState(() => _autoY = value),
          ),
          FilledButton.icon(
            key: const Key('graph-editor-apply'),
            onPressed: () => Navigator.of(context).pop(
              GraphFunctionEditorResult(
                expressions: _expressionsController.text
                    .split('\n')
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty)
                    .toList(growable: false),
                xMin: _xMinController.text.trim(),
                xMax: _xMaxController.text.trim(),
                yMin: _yMinController.text.trim(),
                yMax: _yMaxController.text.trim(),
                autoY: _autoY,
              ),
            ),
            icon: const Icon(Icons.check),
            label: const Text('Apply to graph'),
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _EditorShell extends StatelessWidget {
  const _EditorShell({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String keyName;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Container(
            key: Key(keyName),
            padding: AppSpacing.compactCard,
            decoration: BoxDecoration(
              borderRadius: AppRadii.panel,
              color: theme.colorScheme.surfaceContainerHigh,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberDropdown extends StatelessWidget {
  const _NumberDropdown({
    required this.keyName,
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String keyName;
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: Key(keyName),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: <int>[for (var index = 1; index <= max; index++) index]
          .map(
            (item) => DropdownMenuItem<int>(
              value: item,
              child: Text(item.toString()),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _StringDropdown extends StatelessWidget {
  const _StringDropdown({
    required this.keyName,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String keyName;
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: Key(keyName),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _PreviewText extends StatelessWidget {
  const _PreviewText({required this.keyName, required this.value});

  final String keyName;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      value,
      key: Key(keyName),
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
