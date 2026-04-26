import '../../../../core/calculator/calculator.dart';
import '../../../../core/calculator/src/expression_printer.dart';
import '../dependency/worksheet_dependency_analyzer.dart';
import '../dependency/worksheet_dependency_graph.dart';
import '../dependency/worksheet_dependency_node.dart';
import '../scope/worksheet_symbol.dart';
import '../scope/worksheet_symbol_rules.dart';
import '../scope/worksheet_symbol_table.dart';
import '../worksheet_block.dart';
import '../worksheet_block_result.dart';
import '../worksheet_document.dart';
import '../worksheet_error.dart';
import '../worksheet_graph_state.dart';
import 'worksheet_execution_result.dart';

class WorksheetExecutor {
  WorksheetExecutor({
    CalculatorEngine engine = const CalculatorEngine(),
    WorksheetDependencyAnalyzer analyzer = const WorksheetDependencyAnalyzer(),
    this.maxSymbols = 500,
    this.maxFunctionParameters = 5,
    this.maxFunctionCallDepth = 32,
    this.maxDependencyGraphNodes = 1000,
    this.maxDependencyGraphEdges = 5000,
  }) : _engine = engine,
       _analyzer = analyzer;

  final CalculatorEngine _engine;
  final WorksheetDependencyAnalyzer _analyzer;
  final int maxSymbols;
  final int maxFunctionParameters;
  final int maxFunctionCallDepth;
  final int maxDependencyGraphNodes;
  final int maxDependencyGraphEdges;

  WorksheetExecutionResult validate(WorksheetDocument worksheet) {
    final stopwatch = Stopwatch()..start();
    final preparation = _prepare(worksheet);
    stopwatch.stop();
    return WorksheetExecutionResult(
      worksheet: preparation.worksheet,
      symbolTable: WorksheetSymbolTable(
        symbols: List<WorksheetSymbol>.unmodifiable(
          _symbolSummariesFromWorksheet(preparation.worksheet),
        ),
      ),
      runOrder: const <String>[],
      summary: _buildSummary(
        preparation.worksheet,
        const <String>[],
        elapsed: stopwatch.elapsed,
      ),
      elapsed: stopwatch.elapsed,
    );
  }

  WorksheetExecutionResult runAll(WorksheetDocument worksheet) {
    final preparation = _prepare(worksheet);
    final runOrder = preparation.topologicalOrder;
    return _execute(
      preparation,
      runIds: runOrder.toSet(),
      runOrder: runOrder,
      skipCleanBlocks: true,
    );
  }

  WorksheetExecutionResult runBlock(
    WorksheetDocument worksheet,
    String blockId,
  ) {
    final preparation = _prepare(worksheet);
    final relevant = <String>{
      blockId,
      ...preparation.graph.ancestorsOf(blockId),
    };
    final runOrder = preparation.topologicalOrder
        .where(relevant.contains)
        .toList(growable: false);
    return _execute(preparation, runIds: relevant, runOrder: runOrder);
  }

  WorksheetExecutionResult runAffected(
    WorksheetDocument worksheet,
    String blockId,
  ) {
    final preparation = _prepare(worksheet);
    final descendants = preparation.graph.descendantsOf(blockId);
    final relevant = <String>{blockId, ...descendants};
    for (final dependentId in descendants) {
      relevant.addAll(preparation.graph.ancestorsOf(dependentId));
    }
    final runOrder = preparation.topologicalOrder
        .where(relevant.contains)
        .toList(growable: false);
    return _execute(preparation, runIds: relevant, runOrder: runOrder);
  }

  WorksheetExecutionResult markDependentsStale(
    WorksheetDocument worksheet,
    String blockId,
  ) {
    final preparation = _prepare(worksheet);
    final affected = <String>{
      blockId,
      ...preparation.graph.descendantsOf(blockId),
    };
    final updatedBlocks = preparation.worksheet.blocks
        .map((block) {
          if (!affected.contains(block.id) || block.isText) {
            return block;
          }
          return block.copyWith(
            isStale: true,
            updatedAt: DateTime.now().toUtc(),
            clearWorksheetError: true,
            clearLastEvaluatedAt: true,
            clearResult:
                block.isCalculation ||
                block.isVariableDefinition ||
                block.isFunctionDefinition ||
                block.isSolve ||
                block.isCasTransform,
          );
        })
        .toList(growable: false);
    final updatedWorksheet = preparation.worksheet.copyWith(
      blocks: List<WorksheetBlock>.unmodifiable(updatedBlocks),
      updatedAt: DateTime.now().toUtc(),
    );
    return WorksheetExecutionResult(
      worksheet: updatedWorksheet,
      symbolTable: WorksheetSymbolTable(
        symbols: List<WorksheetSymbol>.unmodifiable(
          _symbolSummariesFromWorksheet(updatedWorksheet),
        ),
      ),
      runOrder: const <String>[],
      summary: _buildSummary(updatedWorksheet, const <String>[]),
    );
  }

  WorksheetDependencyGraph dependencyGraphFor(WorksheetDocument worksheet) {
    return _prepare(worksheet).graph;
  }

  WorksheetExecutionResult _execute(
    _PreparedWorksheet preparation, {
    required Set<String> runIds,
    required List<String> runOrder,
    bool skipCleanBlocks = false,
  }) {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now().toUtc();
    final updatedBlocks = <String, WorksheetBlock>{
      for (final block in preparation.worksheet.blocks) block.id: block,
    };
    final variableValues = <String, CalculatorValue>{};
    final functions = <String, ScopedFunctionDefinition>{};
    final generatedPlots = <String, PlotValue>{};
    final failedBlocks = <String>{};
    final executedBlockIds = <String>[];
    final skippedBlockIds = <String>[];

    void markWorksheetError(
      String blockId,
      WorksheetErrorCode code,
      String message,
    ) {
      final current = updatedBlocks[blockId];
      if (current == null) {
        return;
      }
      updatedBlocks[blockId] = current.copyWith(
        isStale: true,
        updatedAt: now,
        worksheetErrorCode: code,
        worksheetErrorMessage: message,
      );
      failedBlocks.add(blockId);
    }

    for (final blockId in runOrder) {
      if (!runIds.contains(blockId)) {
        continue;
      }
      final current = updatedBlocks[blockId];
      final node = preparation.nodesByBlockId[blockId];
      if (current == null || node == null || current.isText) {
        continue;
      }
      if (current.worksheetErrorCode != null) {
        failedBlocks.add(blockId);
        continue;
      }

      if (skipCleanBlocks && _canSkipCleanBlock(current)) {
        skippedBlockIds.add(blockId);
        continue;
      }

      final upstreamDependencies =
          preparation.graph.dependenciesByBlockId[blockId] ?? const <String>{};
      final failedUpstream = upstreamDependencies
          .where(failedBlocks.contains)
          .toList(growable: false);
      if (failedUpstream.isNotEmpty) {
        markWorksheetError(
          blockId,
          WorksheetErrorCode.staleDependency,
          'This block depends on a failed upstream definition.',
        );
        continue;
      }

      final scope = EvaluationScope(
        variables: variableValues,
        functions: functions,
        maxCallDepth: maxFunctionCallDepth,
      );

      switch (current.type) {
        case WorksheetBlockType.text:
          continue;
        case WorksheetBlockType.variableDefinition:
          executedBlockIds.add(blockId);
          final outcome = _engine.evaluate(
            current.expression ?? '',
            context: _contextFor(current),
            scope: scope,
          );
          final result = outcome.isSuccess
              ? WorksheetBlockResult.fromCalculationResult(outcome.result!)
              : WorksheetBlockResult.fromCalculationError(
                  outcome.error!,
                  normalizedExpression: current.expression,
                );
          updatedBlocks[blockId] = current.copyWith(
            result: result,
            isStale: false,
            lastEvaluatedAt: now,
            updatedAt: now,
            clearWorksheetError: true,
          );
          if (outcome.isSuccess) {
            variableValues[current.symbolName!] = outcome.result!.value!;
          } else {
            failedBlocks.add(blockId);
          }
        case WorksheetBlockType.functionDefinition:
          executedBlockIds.add(blockId);
          final preparedAst = node.ast;
          if (preparedAst == null) {
            markWorksheetError(
              blockId,
              WorksheetErrorCode.invalidFunctionDefinition,
              node.parseError?.message ??
                  'Function body could not be parsed for worksheet execution.',
            );
            continue;
          }
          final definition = ScopedFunctionDefinition(
            name: current.symbolName!,
            parameters: current.parameters,
            bodyExpression: current.bodyExpression ?? '',
            normalizedBodyExpression: ExpressionPrinter().print(preparedAst),
            bodyAst: preparedAst,
            sourceId: current.id,
          );
          functions[current.symbolName!] = definition;
          updatedBlocks[blockId] = current.copyWith(
            result: WorksheetBlockResult(
              displayResult:
                  '${current.symbolName}(${current.parameters.join(', ')}) = ${definition.normalizedBodyExpression}',
              valueKind: CalculatorValueKind.function,
              isApproximate: false,
              warnings: const <String>[],
              normalizedExpression: definition.normalizedBodyExpression,
            ),
            isStale: false,
            lastEvaluatedAt: now,
            updatedAt: now,
            clearWorksheetError: true,
          );
        case WorksheetBlockType.calculation:
          executedBlockIds.add(blockId);
          final outcome = _engine.evaluate(
            current.expression ?? '',
            context: _contextFor(current),
            scope: scope,
          );
          final result = outcome.isSuccess
              ? WorksheetBlockResult.fromCalculationResult(outcome.result!)
              : WorksheetBlockResult.fromCalculationError(
                  outcome.error!,
                  normalizedExpression: current.expression,
                );
          updatedBlocks[blockId] = current.copyWith(
            result: result,
            isStale: false,
            lastEvaluatedAt: now,
            updatedAt: now,
            clearWorksheetError: true,
          );
          if (outcome.isFailure) {
            failedBlocks.add(blockId);
          }
        case WorksheetBlockType.solve:
          executedBlockIds.add(blockId);
          final outcome = _engine.evaluate(
            _buildSolveExpression(current),
            context: _contextFor(current),
            scope: scope,
          );
          final result = outcome.isSuccess
              ? WorksheetBlockResult.fromCalculationResult(outcome.result!)
              : WorksheetBlockResult.fromCalculationError(
                  outcome.error!,
                  normalizedExpression: current.expression,
                );
          updatedBlocks[blockId] = current.copyWith(
            result: result,
            isStale: false,
            lastEvaluatedAt: now,
            updatedAt: now,
            clearWorksheetError: true,
          );
          if (outcome.isFailure) {
            failedBlocks.add(blockId);
          }
        case WorksheetBlockType.casTransform:
          executedBlockIds.add(blockId);
          final outcome = _engine.evaluate(
            _buildCasTransformExpression(current),
            context: _contextFor(current),
            scope: scope,
          );
          final result = outcome.isSuccess
              ? WorksheetBlockResult.fromCalculationResult(outcome.result!)
              : WorksheetBlockResult.fromCalculationError(
                  outcome.error!,
                  normalizedExpression: current.expression,
                );
          updatedBlocks[blockId] = current.copyWith(
            result: result,
            isStale: false,
            lastEvaluatedAt: now,
            updatedAt: now,
            clearWorksheetError: true,
          );
          if (outcome.isFailure) {
            failedBlocks.add(blockId);
          }
        case WorksheetBlockType.graph:
          executedBlockIds.add(blockId);
          final outcome = _engine.evaluate(
            current.graphState?.buildPlotExpression() ?? '',
            context:
                current.graphState?.toCalculationContext() ??
                _contextFor(current),
            scope: scope,
          );
          if (outcome.isFailure || outcome.result?.value is! PlotValue) {
            markWorksheetError(
              blockId,
              WorksheetErrorCode.blockRunFailed,
              outcome.error?.message ??
                  'Graph block could not be evaluated in worksheet scope.',
            );
            continue;
          }
          final plot = outcome.result!.value! as PlotValue;
          generatedPlots[blockId] = plot;
          final updatedGraphState = current.graphState!.copyWith(
            viewport: plot.viewport,
            plotSeriesCount: plot.seriesCount,
            plotPointCount: plot.pointCount,
            plotSegmentCount: plot.segmentCount,
            lastPlotSummary:
                '${plot.seriesCount} series, ${plot.pointCount} points, ${plot.segmentCount} segments',
            warnings: List<String>.unmodifiable(plot.warnings),
            updatedAt: now,
          );
          updatedBlocks[blockId] = current.copyWith(
            graphState: updatedGraphState,
            isStale: false,
            lastEvaluatedAt: now,
            updatedAt: now,
            clearWorksheetError: true,
          );
      }
    }

    final symbols = <WorksheetSymbol>[];
    for (final block in preparation.worksheet.blocks) {
      final updated = updatedBlocks[block.id]!;
      if (updated.isVariableDefinition) {
        symbols.add(
          WorksheetSymbol(
            type: WorksheetSymbolType.variable,
            name: updated.symbolName!,
            sourceBlockId: updated.id,
            displayValue: updated.result?.displayResult,
            dependencies: updated.dependencies,
            isStale: updated.isStale,
            hasError:
                updated.worksheetErrorCode != null ||
                updated.result?.hasError == true,
          ),
        );
      } else if (updated.isFunctionDefinition) {
        symbols.add(
          WorksheetSymbol(
            type: WorksheetSymbolType.function,
            name: updated.symbolName!,
            sourceBlockId: updated.id,
            parameters: updated.parameters,
            displayValue: updated.result?.displayResult,
            dependencies: updated.dependencies,
            isStale: updated.isStale,
            hasError: updated.worksheetErrorCode != null,
          ),
        );
      }
    }

    final orderedBlocks = preparation.worksheet.blocks
        .map((block) => updatedBlocks[block.id]!)
        .toList(growable: false);
    final updatedWorksheet = preparation.worksheet.copyWith(
      blocks: List<WorksheetBlock>.unmodifiable(orderedBlocks),
      updatedAt: now,
      activeGraphState: generatedPlots.isEmpty
          ? preparation.worksheet.activeGraphState
          : (updatedBlocks.values
                    .where(
                      (block) =>
                          block.isGraph && generatedPlots.containsKey(block.id),
                    )
                    .map((block) => block.graphState)
                    .whereType<WorksheetGraphState>()
                    .lastOrNull ??
                preparation.worksheet.activeGraphState),
    );
    stopwatch.stop();

    return WorksheetExecutionResult(
      worksheet: updatedWorksheet,
      symbolTable: WorksheetSymbolTable(
        variableValues: Map<String, CalculatorValue>.unmodifiable(
          variableValues,
        ),
        functionDefinitions: Map<String, ScopedFunctionDefinition>.unmodifiable(
          functions,
        ),
        symbols: List<WorksheetSymbol>.unmodifiable(symbols),
      ),
      runOrder: runOrder,
      summary: _buildSummary(
        updatedWorksheet,
        runOrder,
        skippedCount: skippedBlockIds.length,
        elapsed: stopwatch.elapsed,
      ),
      generatedPlots: Map<String, PlotValue>.unmodifiable(generatedPlots),
      executedBlockIds: List<String>.unmodifiable(executedBlockIds),
      skippedBlockIds: List<String>.unmodifiable(skippedBlockIds),
      elapsed: stopwatch.elapsed,
    );
  }

  bool _canSkipCleanBlock(WorksheetBlock block) {
    if (block.isStale || block.definesSymbol || block.isText) {
      return false;
    }
    if (block.isGraph) {
      return block.graphState?.plotPointCount != null ||
          block.graphState?.lastPlotSummary != null;
    }
    return block.result != null;
  }

  _PreparedWorksheet _prepare(WorksheetDocument worksheet) {
    if (worksheet.blocks.length > maxDependencyGraphNodes) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.limitExceeded,
          message: 'Worksheet exceeds the dependency graph node limit.',
        ),
      );
    }

    final analyzedNodes = <String, WorksheetDependencyNode>{};
    for (final block in worksheet.blocks) {
      analyzedNodes[block.id] = _analyzer.analyzeBlock(block);
    }

    final updatedBlocks = <String, WorksheetBlock>{
      for (final block in worksheet.blocks)
        block.id: block.copyWith(
          dependencies:
              analyzedNodes[block.id]?.dependencies ?? const <String>[],
          clearWorksheetError: true,
          updatedAt: block.updatedAt,
        ),
    };

    final symbolOwners = <String, String>{};
    final symbolErrors = <String, WorksheetError>{};
    final symbolCount = worksheet.blocks
        .where((block) => block.definesSymbol)
        .length;
    if (symbolCount > maxSymbols) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.limitExceeded,
          message: 'Worksheet exceeds the maximum scoped symbol limit.',
        ),
      );
    }

    for (final block in worksheet.blocks) {
      final updated = updatedBlocks[block.id]!;
      if (!updated.definesSymbol) {
        continue;
      }
      final name = updated.symbolName ?? '';
      final nameError = WorksheetSymbolRules.validateDefinitionName(
        name,
        kindLabel: updated.isVariableDefinition ? 'Variable' : 'Function',
      );
      if (nameError != null) {
        symbolErrors[block.id] = nameError;
        continue;
      }
      if (updated.isFunctionDefinition) {
        final functionNode = analyzedNodes[block.id];
        if (functionNode != null &&
            functionNode.functionDependencies.contains(name)) {
          symbolErrors[block.id] = WorksheetError(
            code: WorksheetErrorCode.recursiveFunction,
            message:
                'Function "$name" recursively references itself and cannot be evaluated in this phase.',
          );
          continue;
        }
        if (updated.parameters.length > maxFunctionParameters) {
          symbolErrors[block.id] = WorksheetError(
            code: WorksheetErrorCode.invalidFunctionDefinition,
            message:
                'Function "$name" exceeds the maximum parameter count of $maxFunctionParameters.',
          );
          continue;
        }
        final duplicates = <String>{};
        final seen = <String>{};
        for (final parameter in updated.parameters) {
          final parameterError = WorksheetSymbolRules.validateDefinitionName(
            parameter,
            kindLabel: 'Parameter',
            allowGraphVariableName: true,
          );
          if (parameterError != null) {
            symbolErrors[block.id] = parameterError;
            break;
          }
          if (!seen.add(parameter)) {
            duplicates.add(parameter);
          }
        }
        if (duplicates.isNotEmpty) {
          symbolErrors[block.id] = WorksheetError(
            code: WorksheetErrorCode.invalidFunctionDefinition,
            message:
                'Function "$name" contains duplicate parameter names: ${duplicates.join(', ')}.',
          );
          continue;
        }
        if (symbolErrors.containsKey(block.id)) {
          continue;
        }
      }
      if (symbolOwners.containsKey(name)) {
        symbolErrors[block.id] = WorksheetError(
          code: WorksheetErrorCode.duplicateSymbol,
          message:
              'Symbol "$name" is defined more than once in this worksheet.',
        );
        final otherBlockId = symbolOwners[name]!;
        symbolErrors.putIfAbsent(
          otherBlockId,
          () => WorksheetError(
            code: WorksheetErrorCode.duplicateSymbol,
            message:
                'Symbol "$name" is defined more than once in this worksheet.',
          ),
        );
        continue;
      }
      symbolOwners[name] = block.id;
    }

    final dependenciesByBlockId = <String, Set<String>>{};
    final dependentsByBlockId = <String, Set<String>>{};
    var edgeCount = 0;

    for (final block in worksheet.blocks) {
      final node = analyzedNodes[block.id]!;
      final deps = <String>{};
      if (node.parseError != null) {
        updatedBlocks[block.id] = updatedBlocks[block.id]!.copyWith(
          isStale: true,
          worksheetErrorCode: WorksheetErrorCode.invalidWorksheet,
          worksheetErrorMessage: node.parseError!.message,
        );
        continue;
      }
      if (symbolErrors.containsKey(block.id)) {
        final error = symbolErrors[block.id]!;
        updatedBlocks[block.id] = updatedBlocks[block.id]!.copyWith(
          isStale: true,
          worksheetErrorCode: error.code,
          worksheetErrorMessage: error.message,
        );
        continue;
      }
      for (final dependency in node.dependencies) {
        final owner = symbolOwners[dependency];
        if (owner == null) {
          updatedBlocks[block.id] = updatedBlocks[block.id]!.copyWith(
            isStale: true,
            worksheetErrorCode: WorksheetErrorCode.undefinedSymbol,
            worksheetErrorMessage:
                '"$dependency" is not defined in this worksheet.',
          );
          continue;
        }
        deps.add(owner);
        dependentsByBlockId.putIfAbsent(owner, () => <String>{}).add(block.id);
      }
      dependenciesByBlockId[block.id] = deps;
      edgeCount += deps.length;
    }

    if (edgeCount > maxDependencyGraphEdges) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.limitExceeded,
          message: 'Worksheet exceeds the dependency graph edge limit.',
        ),
      );
    }

    final graph = WorksheetDependencyGraph(
      nodesByBlockId: Map<String, WorksheetDependencyNode>.unmodifiable(
        analyzedNodes,
      ),
      dependenciesByBlockId: Map<String, Set<String>>.unmodifiable(
        dependenciesByBlockId.map(
          (key, value) => MapEntry(key, Set<String>.unmodifiable(value)),
        ),
      ),
      dependentsByBlockId: Map<String, Set<String>>.unmodifiable(
        dependentsByBlockId.map(
          (key, value) => MapEntry(key, Set<String>.unmodifiable(value)),
        ),
      ),
      symbolOwners: Map<String, String>.unmodifiable(symbolOwners),
    );

    final cyclicBlockIds = _findCycleBlockIds(graph);
    if (cyclicBlockIds.isNotEmpty) {
      final path = _formatCyclePath(
        cyclicBlockIds,
        analyzedNodes,
        updatedBlocks,
      );
      for (final blockId in cyclicBlockIds) {
        updatedBlocks[blockId] = updatedBlocks[blockId]!.copyWith(
          isStale: true,
          worksheetErrorCode: WorksheetErrorCode.dependencyCycle,
          worksheetErrorMessage: 'Dependency cycle detected: $path.',
        );
      }
      for (final blockId in worksheet.blocks.map((block) => block.id)) {
        if (cyclicBlockIds.contains(blockId)) {
          continue;
        }
        final ancestors = graph.ancestorsOf(blockId);
        if (ancestors.any(cyclicBlockIds.contains)) {
          updatedBlocks[blockId] = updatedBlocks[blockId]!.copyWith(
            isStale: true,
            worksheetErrorCode: WorksheetErrorCode.staleDependency,
            worksheetErrorMessage: 'This block depends on a cyclic definition.',
          );
        }
      }
    }

    final topologicalOrder = _topologicalOrder(worksheet, graph);
    final preparedWorksheet = worksheet.copyWith(
      blocks: List<WorksheetBlock>.unmodifiable(
        worksheet.blocks
            .map((block) => updatedBlocks[block.id]!)
            .toList(growable: false),
      ),
    );
    return _PreparedWorksheet(
      worksheet: preparedWorksheet,
      nodesByBlockId: analyzedNodes,
      graph: graph,
      topologicalOrder: topologicalOrder,
    );
  }

  List<String> _topologicalOrder(
    WorksheetDocument worksheet,
    WorksheetDependencyGraph graph,
  ) {
    final activeIds = worksheet.blocks
        .where((block) => !block.isText)
        .map((block) => block.id)
        .toList(growable: false);
    final inDegree = <String, int>{
      for (final id in activeIds)
        id: graph.dependenciesByBlockId[id]?.length ?? 0,
    };
    final displayIndex = <String, int>{
      for (final block in worksheet.blocks) block.id: block.orderIndex,
    };
    final queue =
        activeIds.where((id) => inDegree[id] == 0).toList(growable: true)..sort(
          (left, right) => displayIndex[left]!.compareTo(displayIndex[right]!),
        );
    final result = <String>[];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);
      final dependents =
          (graph.dependentsByBlockId[current] ?? const <String>{}).toList()
            ..sort(
              (left, right) =>
                  displayIndex[left]!.compareTo(displayIndex[right]!),
            );
      for (final dependent in dependents) {
        inDegree[dependent] = (inDegree[dependent] ?? 0) - 1;
        if (inDegree[dependent] == 0) {
          queue.add(dependent);
          queue.sort(
            (left, right) =>
                displayIndex[left]!.compareTo(displayIndex[right]!),
          );
        }
      }
    }
    for (final id in activeIds) {
      if (!result.contains(id)) {
        result.add(id);
      }
    }
    return List<String>.unmodifiable(result);
  }

  Set<String> _findCycleBlockIds(WorksheetDependencyGraph graph) {
    final states = <String, int>{};
    final stack = <String>[];
    final cycle = <String>{};

    bool visit(String blockId) {
      states[blockId] = 1;
      stack.add(blockId);
      for (final dependency
          in graph.dependenciesByBlockId[blockId] ?? const <String>{}) {
        final state = states[dependency] ?? 0;
        if (state == 0) {
          if (visit(dependency)) {
            return true;
          }
        } else if (state == 1) {
          final startIndex = stack.indexOf(dependency);
          if (startIndex != -1) {
            cycle.addAll(stack.sublist(startIndex));
          }
          cycle.add(dependency);
          return true;
        }
      }
      stack.removeLast();
      states[blockId] = 2;
      return false;
    }

    for (final blockId in graph.nodesByBlockId.keys) {
      if ((states[blockId] ?? 0) == 0 && visit(blockId)) {
        break;
      }
    }
    return cycle;
  }

  String _formatCyclePath(
    Set<String> cycleIds,
    Map<String, WorksheetDependencyNode> nodes,
    Map<String, WorksheetBlock> blocks,
  ) {
    final ordered = cycleIds.toList(growable: false)
      ..sort(
        (left, right) =>
            blocks[left]!.orderIndex.compareTo(blocks[right]!.orderIndex),
      );
    final names = ordered
        .map((id) => nodes[id]?.definedSymbol ?? blocks[id]?.symbolName ?? id)
        .toList(growable: false);
    if (names.isEmpty) {
      return 'cycle';
    }
    return '${names.join(' -> ')} -> ${names.first}';
  }

  CalculationContext _contextFor(WorksheetBlock block) {
    return CalculationContext(
      angleMode: block.angleMode ?? AngleMode.degree,
      precision: block.precision ?? 10,
      preferExactResult:
          (block.numericMode ?? NumericMode.approximate) == NumericMode.exact,
      numericMode: block.numericMode ?? NumericMode.approximate,
      calculationDomain: block.calculationDomain ?? CalculationDomain.real,
      unitMode: block.unitMode ?? UnitMode.disabled,
      numberFormatStyle: block.resultFormat ?? NumberFormatStyle.auto,
    );
  }

  String _buildSummary(
    WorksheetDocument worksheet,
    List<String> runOrder, {
    int skippedCount = 0,
    Duration elapsed = Duration.zero,
  }) {
    final staleCount = worksheet.blocks.where((block) => block.isStale).length;
    final errorCount = worksheet.blocks
        .where(
          (block) =>
              block.worksheetErrorCode != null ||
              block.result?.hasError == true,
        )
        .length;
    final executed = runOrder.isEmpty
        ? 'validated'
        : 'ran ${runOrder.length} block(s)';
    final skipped = skippedCount > 0 ? '; skipped clean: $skippedCount' : '';
    final elapsedText = elapsed == Duration.zero
        ? ''
        : '; ${elapsed.inMicroseconds} us';
    return '$executed; stale: $staleCount; errors: $errorCount$skipped$elapsedText';
  }

  String _buildSolveExpression(WorksheetBlock block) {
    final builder = StringBuffer();
    final method =
        block.solveMethodPreference ?? WorksheetSolveMethodPreference.auto;
    builder.write(
      method == WorksheetSolveMethodPreference.numeric ? 'nsolve(' : 'solve(',
    );
    builder.write(block.expression ?? '');
    builder.write(', ');
    builder.write(block.solveVariableName ?? 'x');
    final min = block.intervalMinExpression?.trim() ?? '';
    final max = block.intervalMaxExpression?.trim() ?? '';
    if (min.isNotEmpty && max.isNotEmpty) {
      builder.write(', ');
      builder.write(min);
      builder.write(', ');
      builder.write(max);
    }
    builder.write(')');
    return builder.toString();
  }

  String _buildCasTransformExpression(WorksheetBlock block) {
    final transform =
        block.casTransformType ?? WorksheetCasTransformType.simplify;
    return '${transform.name}(${block.expression ?? ''})';
  }

  List<WorksheetSymbol> _symbolSummariesFromWorksheet(
    WorksheetDocument worksheet,
  ) {
    final symbols = <WorksheetSymbol>[];
    for (final block in worksheet.blocks) {
      if (block.isVariableDefinition) {
        symbols.add(
          WorksheetSymbol(
            type: WorksheetSymbolType.variable,
            name: block.symbolName!,
            sourceBlockId: block.id,
            displayValue: block.result?.displayResult,
            dependencies: block.dependencies,
            isStale: block.isStale,
            hasError:
                block.worksheetErrorCode != null ||
                block.result?.hasError == true,
          ),
        );
      } else if (block.isFunctionDefinition) {
        symbols.add(
          WorksheetSymbol(
            type: WorksheetSymbolType.function,
            name: block.symbolName!,
            sourceBlockId: block.id,
            parameters: block.parameters,
            displayValue: block.result?.displayResult,
            dependencies: block.dependencies,
            isStale: block.isStale,
            hasError: block.worksheetErrorCode != null,
          ),
        );
      }
    }
    return symbols;
  }
}

class _PreparedWorksheet {
  const _PreparedWorksheet({
    required this.worksheet,
    required this.nodesByBlockId,
    required this.graph,
    required this.topologicalOrder,
  });

  final WorksheetDocument worksheet;
  final Map<String, WorksheetDependencyNode> nodesByBlockId;
  final WorksheetDependencyGraph graph;
  final List<String> topologicalOrder;
}

extension<T> on Iterable<T> {
  T? get lastOrNull {
    if (isEmpty) {
      return null;
    }
    return last;
  }
}
