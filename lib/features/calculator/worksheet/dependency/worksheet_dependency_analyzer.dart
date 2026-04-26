import '../../../../core/calculator/calculator.dart';
import '../../../../core/calculator/src/calculator_exception.dart';
import '../worksheet_block.dart';
import 'worksheet_dependency_node.dart';

class WorksheetDependencyAnalyzer {
  const WorksheetDependencyAnalyzer({
    CalculatorLexer lexer = const CalculatorLexer(),
    ExpressionParser parser = const ExpressionParser(),
  }) : _lexer = lexer,
       _parser = parser;

  final CalculatorLexer _lexer;
  final ExpressionParser _parser;

  WorksheetDependencyNode analyzeBlock(WorksheetBlock block) {
    switch (block.type) {
      case WorksheetBlockType.text:
        return WorksheetDependencyNode(
          block: block,
          dependencies: const <String>[],
          variableDependencies: const <String>[],
          functionDependencies: const <String>[],
        );
      case WorksheetBlockType.calculation:
      case WorksheetBlockType.variableDefinition:
      case WorksheetBlockType.casTransform:
        return _analyzeExpressionBlock(
          block,
          expression: block.expression ?? '',
          ignoredVariables: block.isCasTransform
              ? const <String>{'x'}
              : const <String>{},
          ignoreUnits: block.unitMode == UnitMode.enabled,
          allowEquation: _allowsEquationSyntax(block.expression ?? ''),
        );
      case WorksheetBlockType.functionDefinition:
        return _analyzeExpressionBlock(
          block,
          expression: block.bodyExpression ?? '',
          ignoredVariables: block.parameters.toSet(),
          definedSymbol: block.symbolName,
          ignoreUnits: block.unitMode == UnitMode.enabled,
          allowEquation: false,
        );
      case WorksheetBlockType.solve:
        return _analyzeSolveBlock(block);
      case WorksheetBlockType.graph:
        return _analyzeGraphBlock(block);
    }
  }

  WorksheetDependencyNode _analyzeSolveBlock(WorksheetBlock block) {
    final dependencies = <String>{};
    final variableDependencies = <String>{};
    final functionDependencies = <String>{};
    CalculationError? firstError;

    void merge(_AnalyzedExpression analyzed) {
      if (analyzed.parseError != null && firstError == null) {
        firstError = analyzed.parseError;
      }
      dependencies.addAll(analyzed.dependencies);
      variableDependencies.addAll(analyzed.variableDependencies);
      functionDependencies.addAll(analyzed.functionDependencies);
    }

    merge(
      _analyzeExpression(
        block.expression ?? '',
        ignoredVariables: <String>{block.solveVariableName ?? ''},
        ignoreUnits: block.unitMode == UnitMode.enabled,
        allowEquation: true,
      ),
    );
    if ((block.intervalMinExpression ?? '').trim().isNotEmpty) {
      merge(
        _analyzeExpression(
          block.intervalMinExpression!,
          ignoredVariables: <String>{block.solveVariableName ?? ''},
          ignoreUnits: block.unitMode == UnitMode.enabled,
        ),
      );
    }
    if ((block.intervalMaxExpression ?? '').trim().isNotEmpty) {
      merge(
        _analyzeExpression(
          block.intervalMaxExpression!,
          ignoredVariables: <String>{block.solveVariableName ?? ''},
          ignoreUnits: block.unitMode == UnitMode.enabled,
        ),
      );
    }

    return WorksheetDependencyNode(
      block: block,
      dependencies: List<String>.unmodifiable(dependencies.toList()..sort()),
      variableDependencies: List<String>.unmodifiable(
        variableDependencies.toList()..sort(),
      ),
      functionDependencies: List<String>.unmodifiable(
        functionDependencies.toList()..sort(),
      ),
      parseError: firstError,
    );
  }

  WorksheetDependencyNode _analyzeGraphBlock(WorksheetBlock block) {
    final dependencies = <String>{};
    final variableDependencies = <String>{};
    final functionDependencies = <String>{};
    CalculationError? firstError;
    for (final expression
        in block.graphState?.expressions ?? const <String>[]) {
      final analyzed = _analyzeExpression(
        expression,
        ignoredVariables: const <String>{'x'},
        ignoreUnits: block.graphState?.unitMode == UnitMode.enabled,
      );
      if (analyzed.parseError != null && firstError == null) {
        firstError = analyzed.parseError;
      }
      dependencies.addAll(analyzed.dependencies);
      variableDependencies.addAll(analyzed.variableDependencies);
      functionDependencies.addAll(analyzed.functionDependencies);
    }
    return WorksheetDependencyNode(
      block: block,
      dependencies: List<String>.unmodifiable(dependencies.toList()..sort()),
      variableDependencies: List<String>.unmodifiable(
        variableDependencies.toList()..sort(),
      ),
      functionDependencies: List<String>.unmodifiable(
        functionDependencies.toList()..sort(),
      ),
      parseError: firstError,
    );
  }

  WorksheetDependencyNode _analyzeExpressionBlock(
    WorksheetBlock block, {
    required String expression,
    required Set<String> ignoredVariables,
    String? definedSymbol,
    required bool ignoreUnits,
    bool allowEquation = false,
  }) {
    final analyzed = _analyzeExpression(
      expression,
      ignoredVariables: ignoredVariables,
      ignoreUnits: ignoreUnits,
      allowEquation: allowEquation,
    );
    return WorksheetDependencyNode(
      block: block,
      definedSymbol: definedSymbol ?? block.symbolName,
      dependencies: analyzed.dependencies,
      variableDependencies: analyzed.variableDependencies,
      functionDependencies: analyzed.functionDependencies,
      ast: analyzed.ast,
      parseError: analyzed.parseError,
    );
  }

  _AnalyzedExpression _analyzeExpression(
    String expression, {
    required Set<String> ignoredVariables,
    required bool ignoreUnits,
    bool allowEquation = false,
  }) {
    try {
      final tokens = _lexer.tokenize(expression.trim(), maxTokenCount: 512);
      final ast = _parser.parse(tokens, allowEquation: allowEquation);
      final collector = _DependencyCollector(
        ignoredVariables: ignoredVariables,
        ignoreUnits: ignoreUnits,
      );
      collector.visit(ast);
      return _AnalyzedExpression(
        ast: ast,
        dependencies: List<String>.unmodifiable(
          collector.dependencies.toList()..sort(),
        ),
        variableDependencies: List<String>.unmodifiable(
          collector.variableDependencies.toList()..sort(),
        ),
        functionDependencies: List<String>.unmodifiable(
          collector.functionDependencies.toList()..sort(),
        ),
      );
    } on CalculatorException catch (error) {
      return _AnalyzedExpression(
        dependencies: const <String>[],
        variableDependencies: const <String>[],
        functionDependencies: const <String>[],
        parseError: error.error,
      );
    } catch (_) {
      return const _AnalyzedExpression(
        dependencies: <String>[],
        variableDependencies: <String>[],
        functionDependencies: <String>[],
        parseError: CalculationError(
          type: CalculationErrorType.syntaxError,
          message: 'Expression could not be parsed for dependency analysis.',
        ),
      );
    }
  }
}

class _AnalyzedExpression {
  const _AnalyzedExpression({
    required this.dependencies,
    required this.variableDependencies,
    required this.functionDependencies,
    this.ast,
    this.parseError,
  });

  final ExpressionNode? ast;
  final List<String> dependencies;
  final List<String> variableDependencies;
  final List<String> functionDependencies;
  final CalculationError? parseError;
}

class _DependencyCollector {
  _DependencyCollector({
    required Set<String> ignoredVariables,
    required bool ignoreUnits,
  }) : _ignoredVariables = ignoredVariables,
       _ignoreUnits = ignoreUnits;

  final Set<String> _ignoredVariables;
  final bool _ignoreUnits;
  final Set<String> dependencies = <String>{};
  final Set<String> variableDependencies = <String>{};
  final Set<String> functionDependencies = <String>{};

  void visit(ExpressionNode node) {
    if (node is NumberNode) {
      return;
    }
    if (node is ConstantNode) {
      _visitConstant(node);
      return;
    }
    if (node is UnaryOperationNode) {
      visit(node.operand);
      return;
    }
    if (node is BinaryOperationNode) {
      visit(node.left);
      visit(node.right);
      return;
    }
    if (node is FunctionCallNode) {
      _visitFunction(node);
      return;
    }
    if (node is EquationNode) {
      visit(node.left);
      visit(node.right);
      return;
    }
    if (node is ListLiteralNode) {
      for (final element in node.elements) {
        visit(element);
      }
      return;
    }
    if (node is UnitAttachmentNode) {
      visit(node.valueExpression);
      return;
    }
  }

  void _visitConstant(ConstantNode node) {
    if (_ignoredVariables.contains(node.name)) {
      return;
    }
    if (BuiltInSymbolCatalog.isBuiltInConstant(node.name) ||
        (_ignoreUnits && BuiltInSymbolCatalog.isUnitIdentifier(node.name))) {
      return;
    }
    dependencies.add(node.name);
    variableDependencies.add(node.name);
  }

  void _visitFunction(FunctionCallNode node) {
    final normalizedName = node.name.toLowerCase();
    if (normalizedName == 'solvesystem' && node.arguments.length >= 2) {
      final ignored = <String>{..._ignoredVariables};
      final varsArg = node.arguments.last;
      if (varsArg is FunctionCallNode && varsArg.name.toLowerCase() == 'vars') {
        for (final argument in varsArg.arguments) {
          if (argument is ConstantNode) {
            ignored.add(argument.name);
          }
        }
      }
      for (final equation in node.arguments.take(node.arguments.length - 1)) {
        final nestedCollector = _DependencyCollector(
          ignoredVariables: ignored,
          ignoreUnits: _ignoreUnits,
        );
        nestedCollector.visit(equation);
        dependencies.addAll(nestedCollector.dependencies);
        variableDependencies.addAll(nestedCollector.variableDependencies);
        functionDependencies.addAll(nestedCollector.functionDependencies);
      }
      return;
    }
    if (_isCasTransform(normalizedName)) {
      final ignored = <String>{..._ignoredVariables};
      if (node.arguments.length >= 2 && node.arguments[1] is ConstantNode) {
        ignored.add((node.arguments[1] as ConstantNode).name);
      } else {
        ignored.add('x');
      }
      if (node.arguments.isNotEmpty) {
        final nestedCollector = _DependencyCollector(
          ignoredVariables: ignored,
          ignoreUnits: _ignoreUnits,
        );
        nestedCollector.visit(node.arguments.first);
        dependencies.addAll(nestedCollector.dependencies);
        variableDependencies.addAll(nestedCollector.variableDependencies);
        functionDependencies.addAll(nestedCollector.functionDependencies);
      }
      return;
    }
    if (_isLazyScopedVariableFunction(normalizedName) &&
        node.arguments.length >= 2) {
      final variableNode = node.arguments[1];
      final ignored = <String>{..._ignoredVariables};
      if (variableNode is ConstantNode) {
        ignored.add(variableNode.name);
      }
      if (!BuiltInSymbolCatalog.isBuiltInFunction(node.name)) {
        dependencies.add(node.name);
        functionDependencies.add(node.name);
      }
      final nestedCollector = _DependencyCollector(
        ignoredVariables: ignored,
        ignoreUnits: _ignoreUnits,
      );
      nestedCollector.visit(node.arguments.first);
      dependencies.addAll(nestedCollector.dependencies);
      variableDependencies.addAll(nestedCollector.variableDependencies);
      functionDependencies.addAll(nestedCollector.functionDependencies);
      for (var index = 2; index < node.arguments.length; index++) {
        visit(node.arguments[index]);
      }
      return;
    }

    if (!BuiltInSymbolCatalog.isBuiltInFunction(node.name)) {
      dependencies.add(node.name);
      functionDependencies.add(node.name);
    }
    for (final argument in node.arguments) {
      visit(argument);
    }
  }

  bool _isLazyScopedVariableFunction(String name) {
    switch (name) {
      case 'solve':
      case 'nsolve':
      case 'diff':
      case 'derivative':
      case 'derivativeat':
      case 'integral':
      case 'integrate':
      case 'expand':
      case 'factor':
        return true;
      default:
        return false;
    }
  }

  bool _isCasTransform(String name) {
    return name == 'simplify' || name == 'expand' || name == 'factor';
  }
}

bool _allowsEquationSyntax(String expression) {
  final lower = expression.toLowerCase();
  return lower.contains('solve(') ||
      lower.contains('nsolve(') ||
      lower.contains('solvesystem(');
}
