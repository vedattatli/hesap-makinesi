# Developer Guide

## Project Structure

```text
lib/
  core/calculator/                 Pure Dart math core
  features/calculator/application/ UI-facing controllers and state
  features/calculator/data/        settings, history and storage
  features/calculator/worksheet/   worksheet model, execution and export
  features/calculator/productization/
  features/calculator/presentation/
test/
docs/
scripts/
```

The core calculator must remain Flutter-independent. Flutter widgets should call
controllers and services rather than embedding evaluation semantics in UI code.

## Core Calculator

The core flow is:

1. `CalculatorLexer` tokenizes input.
2. `ExpressionParser` builds AST nodes.
3. `ExpressionEvaluator` evaluates AST with a `CalculationContext`.
4. `ResultFormatter` creates display strings and structured metadata.
5. `CalculatorEngine` returns a `CalculationOutcome`.

Equation syntax is intentionally scoped. `allowEquation` is off by default and is
enabled only for solve/equation contexts.

## Value Types

All structured results use `CalculatorValue` implementations and
`CalculatorValueKind`:

- numeric: double, rational, symbolic
- complex
- vector and matrix
- unit
- dataset and regression
- function and plot
- equation, solve result, system solve and expression transform

When adding a value type, also update formatter metadata, history serialization,
tests and UI badges where appropriate.

## Evaluator / Parser

Guidelines:

- Keep normal function calls eager unless a feature needs raw AST.
- Use typed `CalculationError` instead of throwing arbitrary exceptions.
- Preserve default-off scoped symbol resolution.
- Do not add global variables/functions without a scoped resolver and tests.
- Keep unit identifiers, constants and built-ins protected from accidental
  override.

## UI Architecture

`CalculatorController` owns calculator state, settings and history. UI widgets
read state and dispatch controller actions. `WorksheetController` owns worksheet
documents, blocks, scoped execution and exports.

Presentation code lives in:

- `presentation/design/`: theme, spacing, motion, colors.
- `presentation/widgets/`: display card, keypad, graph, worksheet, settings and
  input tools.
- `presentation/app_localizations.dart`: lightweight localization map.

## Storage

Storage is local-first:

- calculator settings/history use calculator storage abstractions.
- worksheets use worksheet storage abstractions.
- tests use memory storage.
- backup export/import is text JSON through `LocalDataBackupService`.

Missing or corrupt storage should fall back safely without crashing app startup.

## Testing

Run before handing off:

```powershell
flutter analyze
flutter test
git diff --check
dart format --set-exit-if-changed lib test
```

Important test layers:

- Unit tests for values, lexer/parser, evaluator, graph, worksheet, CAS.
- Controller tests for settings/history/worksheet flows.
- Widget tests for UI smoke and keyboard/accessibility behavior.
- Fuzz/property tests for final QA invariants.
- Integration tests for cross-module product flows.

## Adding New Functions

1. Add parser support only if syntax requires it.
2. Add evaluator registry handling.
3. Validate argument count and types.
4. Return typed errors for unsupported inputs.
5. Add exact/approx behavior and warnings.
6. Update result formatter and history metadata if structured.
7. Add unit tests and widget/keypad tests if exposed in UI.

Avoid adding broad lazy evaluation. Raw AST arguments should be narrowly scoped
to functions like graph, solve or CAS transforms.

## Adding New Value Types

1. Implement immutable `CalculatorValue`.
2. Add `CalculatorValueKind`.
3. Define `toDouble` policy explicitly.
4. Update `ResultFormatter`.
5. Update `CalculationResult` metadata only if needed.
6. Update history JSON compatibility.
7. Add tests for display, serialization and unsupported interactions.

## Release Checks

Use [Release Checklist](release_checklist.md). A launch candidate requires clean
analyze, passing full tests, whitespace diff check, reviewed known limitations,
and manual smoke for accessibility, localization, graph, worksheet, export and
backup flows.

