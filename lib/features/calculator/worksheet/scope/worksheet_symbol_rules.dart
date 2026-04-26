import '../../../../core/calculator/calculator.dart';
import '../worksheet_error.dart';

class WorksheetSymbolRules {
  WorksheetSymbolRules._();

  static final RegExp _identifierPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  static bool isValidIdentifier(String name) {
    return _identifierPattern.hasMatch(name.trim());
  }

  static WorksheetError? validateDefinitionName(
    String rawName, {
    required String kindLabel,
    bool allowGraphVariableName = false,
  }) {
    final name = rawName.trim();
    if (name.isEmpty) {
      return WorksheetError(
        code: WorksheetErrorCode.invalidSymbolName,
        message: '$kindLabel name cannot be empty.',
      );
    }
    if (!_identifierPattern.hasMatch(name)) {
      return WorksheetError(
        code: WorksheetErrorCode.invalidSymbolName,
        message:
            '$kindLabel name "$name" must start with a letter or underscore and contain only letters, digits, or underscores.',
      );
    }
    if (!allowGraphVariableName && name == 'x') {
      return WorksheetError(
        code: WorksheetErrorCode.invalidSymbolName,
        message:
            'Worksheet symbol name "x" is reserved for graph/function local scope in this phase.',
      );
    }
    if (BuiltInSymbolCatalog.isBuiltInConstant(name) ||
        BuiltInSymbolCatalog.isBuiltInFunction(name)) {
      return WorksheetError(
        code: WorksheetErrorCode.reservedSymbolName,
        message: '"$name" is reserved and cannot be used as a $kindLabel name.',
      );
    }
    if (BuiltInSymbolCatalog.isUnitIdentifier(name) && name != 'a') {
      return WorksheetError(
        code: WorksheetErrorCode.invalidSymbolName,
        message: '"$name" is reserved and cannot be used as a $kindLabel name.',
      );
    }
    return null;
  }
}
