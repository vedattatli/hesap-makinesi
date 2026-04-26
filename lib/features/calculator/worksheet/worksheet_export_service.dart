import 'worksheet_block.dart';
import 'worksheet_document.dart';
import 'worksheet_error.dart';
import 'worksheet_export.dart';

class WorksheetExportService {
  const WorksheetExportService({
    this.maxMarkdownChars = 2000000,
    this.maxCsvRows = 100000,
  });

  final int maxMarkdownChars;
  final int maxCsvRows;

  WorksheetExportResult exportMarkdown(WorksheetDocument document) {
    final buffer = StringBuffer();
    buffer.writeln('# ${document.title}');
    buffer.writeln();
    buffer.writeln('- Worksheet ID: `${document.id}`');
    buffer.writeln('- Created: `${document.createdAt.toIso8601String()}`');
    buffer.writeln('- Updated: `${document.updatedAt.toIso8601String()}`');

    for (final block in document.blocks) {
      buffer.writeln();
      switch (block.type) {
        case WorksheetBlockType.variableDefinition:
          buffer.writeln('## Variable');
          buffer.writeln(
            'Definition: `${block.symbolName} = ${block.expression ?? ''}`',
          );
          buffer.writeln('Status: `${block.isStale ? 'stale' : 'clean'}`');
          if (block.dependencies.isNotEmpty) {
            buffer.writeln('Dependencies: `${block.dependencies.join(', ')}`');
          }
          if (block.result != null) {
            buffer.writeln('Result: `${block.result!.displayResult}`');
          }
          if (block.worksheetErrorMessage != null) {
            buffer.writeln('Error: ${block.worksheetErrorMessage}');
          }
        case WorksheetBlockType.functionDefinition:
          buffer.writeln('## Function');
          buffer.writeln(
            'Definition: `${block.symbolName}(${block.parameters.join(', ')}) = ${block.bodyExpression ?? ''}`',
          );
          buffer.writeln('Status: `${block.isStale ? 'stale' : 'clean'}`');
          if (block.dependencies.isNotEmpty) {
            buffer.writeln('Dependencies: `${block.dependencies.join(', ')}`');
          }
          if (block.result != null) {
            buffer.writeln('Validated: `${block.result!.displayResult}`');
          }
          if (block.worksheetErrorMessage != null) {
            buffer.writeln('Error: ${block.worksheetErrorMessage}');
          }
        case WorksheetBlockType.solve:
          buffer.writeln('## Solve');
          buffer.writeln('Equation: `${block.expression ?? ''}`');
          buffer.writeln('Variable: `${block.solveVariableName ?? 'x'}`');
          if ((block.intervalMinExpression ?? '').trim().isNotEmpty &&
              (block.intervalMaxExpression ?? '').trim().isNotEmpty) {
            buffer.writeln(
              'Interval: `[${block.intervalMinExpression}, ${block.intervalMaxExpression}]`',
            );
          }
          buffer.writeln(
            'Method: `${(block.solveMethodPreference ?? WorksheetSolveMethodPreference.auto).name}`',
          );
          buffer.writeln('Status: `${block.isStale ? 'stale' : 'clean'}`');
          if (block.dependencies.isNotEmpty) {
            buffer.writeln('Dependencies: `${block.dependencies.join(', ')}`');
          }
          if (block.result != null) {
            buffer.writeln('Result: `${block.result!.displayResult}`');
            if (block.result!.warnings.isNotEmpty) {
              buffer.writeln('Warnings: ${block.result!.warnings.join('; ')}');
            }
            if (block.result!.errorMessage != null) {
              buffer.writeln('Error: ${block.result!.errorMessage}');
            }
          }
          if (block.worksheetErrorMessage != null) {
            buffer.writeln('Worksheet Error: ${block.worksheetErrorMessage}');
          }
        case WorksheetBlockType.casTransform:
          buffer.writeln('## CAS Transform');
          buffer.writeln(
            'Transform: `${(block.casTransformType ?? WorksheetCasTransformType.simplify).name}`',
          );
          buffer.writeln('Expression: `${block.expression ?? ''}`');
          buffer.writeln('Status: `${block.isStale ? 'stale' : 'clean'}`');
          if (block.dependencies.isNotEmpty) {
            buffer.writeln('Dependencies: `${block.dependencies.join(', ')}`');
          }
          if (block.result != null) {
            buffer.writeln('Result: `${block.result!.displayResult}`');
            final steps = block.result!.alternativeResults['steps'];
            if (steps != null && steps.trim().isNotEmpty) {
              buffer.writeln('Steps:');
              for (final step in steps.split('\n')) {
                buffer.writeln('- $step');
              }
            }
            if (block.result!.errorMessage != null) {
              buffer.writeln('Error: ${block.result!.errorMessage}');
            }
          }
          if (block.worksheetErrorMessage != null) {
            buffer.writeln('Worksheet Error: ${block.worksheetErrorMessage}');
          }
        case WorksheetBlockType.calculation:
          buffer.writeln('## Calculation');
          if (block.title != null && block.title!.trim().isNotEmpty) {
            buffer.writeln('Title: ${block.title}');
          }
          buffer.writeln('Expression: `${block.expression ?? ''}`');
          if (block.result != null) {
            buffer.writeln('Result: `${block.result!.displayResult}`');
            buffer.writeln(
              'Mode: `${block.numericMode?.name ?? 'approximate'}`, `${block.angleMode?.name ?? 'degree'}`, `${block.resultFormat?.name ?? 'auto'}`, `${block.calculationDomain?.name ?? 'real'}`, `${block.unitMode?.name ?? 'disabled'}`',
            );
            if (block.dependencies.isNotEmpty) {
              buffer.writeln(
                'Dependencies: `${block.dependencies.join(', ')}`',
              );
            }
            buffer.writeln('Status: `${block.isStale ? 'stale' : 'clean'}`');
            if (block.result!.warnings.isNotEmpty) {
              buffer.writeln('Warnings: ${block.result!.warnings.join('; ')}');
            }
            if (block.result!.errorMessage != null) {
              buffer.writeln('Error: ${block.result!.errorMessage}');
            }
          }
          if (block.worksheetErrorMessage != null) {
            buffer.writeln('Worksheet Error: ${block.worksheetErrorMessage}');
          }
        case WorksheetBlockType.graph:
          buffer.writeln('## Graph');
          if (block.title != null && block.title!.trim().isNotEmpty) {
            buffer.writeln('Title: ${block.title}');
          }
          final graph = block.graphState;
          if (graph != null) {
            buffer.writeln('Expressions:');
            for (final expression in graph.expressions) {
              buffer.writeln('- `$expression`');
            }
            buffer.writeln('Viewport: `${graph.viewport.toDisplayString()}`');
            if (block.dependencies.isNotEmpty) {
              buffer.writeln(
                'Dependencies: `${block.dependencies.join(', ')}`',
              );
            }
            buffer.writeln('Status: `${block.isStale ? 'stale' : 'clean'}`');
            if (graph.lastPlotSummary != null) {
              buffer.writeln('Summary: `${graph.lastPlotSummary}`');
            }
            if (graph.warnings.isNotEmpty) {
              buffer.writeln('Warnings: ${graph.warnings.join('; ')}');
            }
          }
          if (block.worksheetErrorMessage != null) {
            buffer.writeln('Error: ${block.worksheetErrorMessage}');
          }
        case WorksheetBlockType.text:
          buffer.writeln('## Note');
          if (block.title != null && block.title!.trim().isNotEmpty) {
            buffer.writeln('Title: ${block.title}');
          }
          buffer.writeln(block.text ?? '');
      }
    }

    final content = buffer.toString().replaceAll('\r\n', '\n');
    if (content.length > maxMarkdownChars) {
      throw const WorksheetException(
        WorksheetError(
          code: WorksheetErrorCode.exportFailed,
          message: 'Worksheet Markdown export is too large.',
        ),
      );
    }

    return WorksheetExportResult(
      fileName: _fileStem(document.title),
      mimeType: 'text/markdown',
      contentText: content,
      extension: 'md',
      createdAt: DateTime.now().toUtc(),
    );
  }

  WorksheetExportResult exportWorksheetCsv(WorksheetDocument document) {
    final header = <String>[
      'worksheetId',
      'worksheetTitle',
      'blockId',
      'blockType',
      'orderIndex',
      'symbolName',
      'functionParameters',
      'definitionExpression',
      'equationExpression',
      'solveVariable',
      'solveMethod',
      'solutionCount',
      'solutionsDisplayResult',
      'intervalMin',
      'intervalMax',
      'solveDomain',
      'casTransformType',
      'casSteps',
      'expression',
      'result',
      'valueKind',
      'numericMode',
      'resultFormat',
      'angleMode',
      'calculationDomain',
      'unitMode',
      'precision',
      'warnings',
      'dependencies',
      'stale',
      'worksheetErrorCode',
      'worksheetErrorMessage',
      'errorType',
      'errorMessage',
      'createdAt',
      'updatedAt',
    ];
    final rows = <List<String>>[header];
    for (final block in document.blocks) {
      if (rows.length >= maxCsvRows) {
        throw const WorksheetException(
          WorksheetError(
            code: WorksheetErrorCode.exportFailed,
            message: 'Worksheet CSV export exceeded the row limit.',
          ),
        );
      }
      rows.add(<String>[
        document.id,
        document.title,
        block.id,
        block.type.name,
        block.orderIndex.toString(),
        block.symbolName ?? '',
        block.parameters.join('|'),
        block.bodyExpression ?? '',
        block.isSolve ? (block.expression ?? '') : '',
        block.solveVariableName ?? '',
        block.solveMethodPreference?.name ?? '',
        block.result?.solutionCount?.toString() ?? '',
        block.result?.solutionsDisplayResult ?? '',
        block.intervalMinExpression ?? '',
        block.intervalMaxExpression ?? '',
        block.result?.solveDomain ?? '',
        block.casTransformType?.name ?? '',
        block.result?.alternativeResults['steps'] ?? '',
        block.expression ??
            block.graphState?.expressions.join(' | ') ??
            (block.text ?? ''),
        block.result?.displayResult ?? block.graphState?.lastPlotSummary ?? '',
        block.result?.valueKind?.name ?? (block.isGraph ? 'plot' : ''),
        block.numericMode?.name ?? block.graphState?.numericMode.name ?? '',
        block.resultFormat?.name ?? block.graphState?.resultFormat.name ?? '',
        block.angleMode?.name ?? block.graphState?.angleMode.name ?? '',
        block.calculationDomain?.name ??
            block.graphState?.calculationDomain.name ??
            '',
        block.unitMode?.name ?? block.graphState?.unitMode.name ?? '',
        block.precision?.toString() ??
            block.graphState?.precision.toString() ??
            '',
        (block.result?.warnings ??
                block.graphState?.warnings ??
                const <String>[])
            .join('; '),
        block.dependencies.join('; '),
        block.isStale.toString(),
        block.worksheetErrorCode?.name ?? '',
        block.worksheetErrorMessage ?? '',
        block.result?.errorType?.name ?? '',
        block.result?.errorMessage ?? '',
        block.createdAt.toIso8601String(),
        block.updatedAt.toIso8601String(),
      ]);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsv).join(','));
    }
    return WorksheetExportResult(
      fileName: _fileStem(document.title),
      mimeType: 'text/csv',
      contentText: buffer.toString().replaceAll('\r\n', '\n'),
      extension: 'csv',
      createdAt: DateTime.now().toUtc(),
    );
  }

  String _escapeCsv(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  String _fileStem(String title) {
    final safe = title
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return safe.isEmpty ? 'worksheet_export' : safe;
  }
}
