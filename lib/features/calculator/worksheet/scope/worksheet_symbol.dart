enum WorksheetSymbolType { variable, function }

class WorksheetSymbol {
  const WorksheetSymbol({
    required this.type,
    required this.name,
    required this.sourceBlockId,
    this.parameters = const <String>[],
    this.displayValue,
    this.dependencies = const <String>[],
    this.isStale = false,
    this.hasError = false,
  });

  final WorksheetSymbolType type;
  final String name;
  final String sourceBlockId;
  final List<String> parameters;
  final String? displayValue;
  final List<String> dependencies;
  final bool isStale;
  final bool hasError;

  String get signature {
    if (type == WorksheetSymbolType.function) {
      return '$name(${parameters.join(', ')})';
    }
    return name;
  }
}
