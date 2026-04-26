# Hesap Makinesi Documentation

This directory is the launch-candidate documentation hub for the calculator.
It links the phase architecture notes, user-facing guidance, developer guidance,
testing commands, release checklist, and known limitations.

## Start Here

- [User Guide](user_guide.md): how to use the calculator, graphing, worksheet,
  CAS-lite, export and backup features.
- [Developer Guide](developer_guide.md): project structure, core architecture,
  testing, and safe extension patterns.
- [Release Checklist](release_checklist.md): final validation and manual smoke
  checks before a launch candidate is accepted.
- [Known Limitations](known_limitations.md): honest scope boundaries and
  unsupported areas.
- [Final Regression Matrix](final_regression_matrix.md): must-pass examples for
  calculator, graph, worksheet, CAS, UI and export flows.

## Architecture Overview

The app is layered so the mathematical core stays independent from Flutter:

- `lib/core/calculator/`: lexer, parser, evaluator, typed values, formatting,
  graph engine, statistics, units, CAS-lite and performance helpers.
- `lib/features/calculator/application/`: UI-facing controllers and immutable
  state snapshots.
- `lib/features/calculator/data/`: calculator settings, history and local or
  memory storage.
- `lib/features/calculator/worksheet/`: worksheet documents, blocks, scoped
  symbols, dependency graph execution, export and backup integration.
- `lib/features/calculator/productization/`: examples, sample worksheets and
  local backup services.
- `lib/features/calculator/presentation/`: Flutter UI, design system,
  localization, panels, graph painter, worksheet UI and input tools.
- `test/`: unit, controller, widget, fuzz, property, integration, storage,
  graph, worksheet, CAS and productization tests.

## Phase Docs Index

- [Phase 1](calculator_architecture_phase_1.md): Flutter-independent math core.
- [Phase 2](calculator_architecture_phase_2.md): controller/state/storage/UI
  foundation.
- [Phase 3](calculator_architecture_phase_3.md): typed numeric values,
  RationalValue, exact/approx mode and formatting.
- [Phase 4](calculator_architecture_phase_4.md): symbolic-lite values, radicals,
  constants and exact trig table.
- [Phase 5](calculator_architecture_phase_5.md): real/complex domain and
  ComplexValue.
- [Phase 6](calculator_architecture_phase_6.md): vector and matrix support.
- [Phase 7](calculator_architecture_phase_7.md): units, dimensions and
  conversion.
- [Phase 8](calculator_architecture_phase_8.md): datasets, statistics,
  probability and regression.
- [Phase 9](calculator_architecture_phase_9.md): graphing, scoped variable
  evaluation and graph UI.
- [Phase 10](calculator_architecture_phase_10.md): worksheet, notebook and
  export foundation.
- [Phase 11](calculator_architecture_phase_11.md): worksheet-scoped variables,
  functions and dependency graph.
- [Phase 12](calculator_architecture_phase_12.md): equation parsing, solve,
  derivative/integral helpers and SolveBlock.
- [Phase 13](calculator_architecture_phase_13.md): CAS-lite simplification,
  expand/factor, systems and CAS blocks.
- [Phase 14](calculator_architecture_phase_14_premium_ui.md): premium UI,
  design system and motion.
- [Phase 15](calculator_architecture_phase_15_input_editors.md): advanced input
  editors and palettes.
- [Phase 16](calculator_architecture_phase_16_performance.md): performance
  hardening, guards and benchmarks.
- [Phase 17](calculator_architecture_phase_17_accessibility_i18n.md):
  accessibility, localization, desktop and web polish.
- [Phase 18](calculator_architecture_phase_18_productization.md): onboarding,
  examples, help, backup and product polish.
- [Phase 19](calculator_architecture_phase_19_final_qa.md): final QA,
  regression matrix, fuzz/property tests and release hardening.

## Module Map

| Module | Responsibility |
| --- | --- |
| `CalculatorLexer` / `ExpressionParser` | Safe tokenization and AST parsing. |
| `ExpressionEvaluator` | Typed expression evaluation with optional scoped symbols. |
| `CalculatorValue` hierarchy | Scalar, symbolic, complex, unit, vector, matrix, dataset, graph and CAS result values. |
| `ResultFormatter` | Display strings and structured result metadata. |
| `GraphEngine` | Pure Dart plotting, sampling and graph analysis. |
| `WorksheetExecutor` | Scoped symbol resolution, dependency graph, run block and run all. |
| `WorksheetExportService` | Markdown, CSV and worksheet-safe export text. |
| `GraphSvgExporter` / `GraphDataCsvExporter` | Pure Dart graph export. |
| `CalculatorController` | Calculator state, history and settings bridge for UI. |
| `WorksheetController` | Worksheet lifecycle, block editing, execution and export bridge. |

## Testing Guide

Release-candidate validation commands:

```powershell
flutter analyze
flutter test
git diff --check
dart format --set-exit-if-changed lib test
```

On the current Windows development machine, Flutter may need the explicit path:

```powershell
& C:\src\flutter\bin\flutter.bat analyze
& C:\src\flutter\bin\flutter.bat test
git diff --check
& C:\src\flutter\bin\dart.bat format --set-exit-if-changed lib test
```

The helper script `scripts/qa_check.ps1` wraps these commands for local or CI-like
use when `flutter` and `dart` are on PATH.

