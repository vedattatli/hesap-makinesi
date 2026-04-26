# Calculator Architecture - Phase 13

## CAS-lite expansion scope

Phase 13 extends the Phase 12 equation-solving layer without turning the app into a full CAS. The core remains Flutter-independent and all transforms are deterministic, guarded, and expression-AST based. The supported operations are `simplify`, `expand`, `factor`, `solveSystem`, and `linsolve`; unsupported algebra returns typed errors instead of invented symbolic output.

## Simplification rule engine

The simplifier applies local identity rewrites and safe constant folding:

- `x + 0 -> x`, `0 + x -> x`, `x - 0 -> x`
- `x * 1 -> x`, `1 * x -> x`, `x * 0 -> 0`
- `x / 1 -> x`, `0 / x -> 0`
- `x^1 -> x`, `x^0 -> 1`
- selected function folds such as `sin(0)=0`, `cos(0)=1`, `tan(0)=0`, `ln(1)=0`, `exp(0)=1`
- single-variable polynomial canonicalization, including simple like-term combination such as `x + x -> 2*x`

Rules that need assumptions, such as `sqrt(x^2) -> abs(x)`, are deliberately not applied.

## Polynomial canonicalization

The existing Phase 12 `PolynomialDetector` is reused for canonical form. A new polynomial expression builder converts coefficients back into stable AST order, descending by degree. This makes output deterministic for tests, history, and worksheet export.

## Expand limits

`expand(expr)` supports polynomial addition, subtraction, multiplication, scalar division, and powers with non-negative integer exponents. The guard limits are:

- max expanded degree: `8`
- max expanded terms: `200`

Non-polynomial input such as `sin(x)` or `x^x` returns `unsupportedCasTransform`.

## Factor limits

`factor(expr)` supports:

- common monomial factor extraction, such as `2*x + 2`
- difference of squares, such as `x^2 - 4`
- perfect-square trinomials, such as `x^2 + 2*x + 1`
- rational-root factorization for rational polynomials up to degree `6`

If no guarded pattern matches, the engine returns `factorizationLimit` rather than pretending to factor.

## Systems solver scope

`solveSystem(eq(...), eq(...), vars(...))` is limited to square linear systems. `vars(...)` is interpreted only by `solveSystem`; it does not replace the existing statistics alias `vars(data)` in normal eager evaluation. Coefficients are extracted by guarded scalar evaluation at basis points and checked for linearity. `linsolve(matrixA, vectorB)` reuses the existing matrix inverse and matrix-vector multiplication helpers.

## Inequality solver scope

Inequality parsing and `solveInequality(...)` are postponed. Adding `<`, `<=`, `>`, and `>=` would broaden parser semantics, so this phase keeps equation parsing stable and documents inequality solving as a later CAS-lite expansion.

## CAS step/result explanation

`ExpressionTransformValue` now carries compact `CasStep` summaries. These are not proof traces; they are honest summaries such as “Canonicalized polynomial terms”, “Applied rational-root factorization”, or “Solved with guarded matrix inverse”. The result formatter exposes them through `alternativeResults['steps']` for UI and worksheet export.

## Worksheet CAS block plan

`WorksheetBlockType.casTransform` stores:

- transform type: `simplify`, `expand`, or `factor`
- input expression
- normal mode snapshot
- result snapshot
- dependencies
- stale/error metadata

CAS transform blocks do not define symbols. Run-all evaluates them in dependency order, but the worksheet display order remains unchanged.

## UI CAS tools

The calculator keypad exposes `simplify(`, `expand(`, `factor(`, `solveSystem(`, `linsolve(`, and `vars(` shortcuts. The worksheet panel adds a CAS block card with transform selector, expression input, run/save/recall actions, step display, and stale/error badges.

## Result/history/export effects

CAS transform results use `CalculatorValueKind.expressionTransform` and `CAS-LITE`/`TRANSFORM` badges. System solves use `CalculatorValueKind.solveResult` and the existing solve display path. Worksheet Markdown and CSV exports include CAS transform type and step summaries.

## Guard limits

- simplify polynomial canonicalization degree: `8`
- expand degree: `8`
- expand terms: `200`
- factor degree: `6`
- rational-root candidate guard: inherited from Phase 12 (`5000`)
- linear system variables: `6`
- worksheet block limits: inherited from Phase 10/11

## Next phase: premium UI redesign

The next phase can focus on a polished product shell: visual hierarchy, responsive layout, advanced result inspection, better worksheet block editing affordances, graph/CAS result panels, and accessibility refinements. CAS expansion beyond this point should remain separate from UI polish so algebra correctness stays testable.
