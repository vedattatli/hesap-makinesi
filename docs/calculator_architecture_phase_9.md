# Calculator Architecture - Phase 9

## Scope
Phase 9 adds a pure Dart graphing/function plotting layer without breaking the existing scalar, symbolic, complex, vector, matrix, unit, or statistics stack. The graphing system is intentionally separated into:

- scoped variable resolution
- function expression/value modeling
- graph viewport and sampling models
- pure Dart plotting/analysis engine
- Flutter-only presentation widgets for canvas, pan/zoom, and graph entry

## Phase 8 Baseline
Before this phase the calculator already had:

- typed scalar values: `DoubleValue`, `RationalValue`, `SymbolicValue`
- domain-aware complex arithmetic via `ComplexValue`
- structured values for `VectorValue`, `MatrixValue`, `UnitValue`, `DatasetValue`, and `RegressionValue`
- central `CalculationContext`, `CalculationResult`, controller/state/history/settings flow
- formatter-driven UI rendering with value-kind specific metadata

That meant graphing could be added as another structured value family instead of a special-case UI-only feature.

## Why Graphing Is Separate
Graphing is not just another numeric function. It needs:

- temporary scoped variables such as `x`
- lazy/raw AST handling so `plot(x^2, -5, 5)` does not fail before `plot` receives the expression
- repeated evaluation across a viewport
- discontinuity-aware segmentation instead of a single scalar result
- compact history/result metadata instead of dumping sampled points into the main display

For that reason the graphing layer lives under `lib/core/calculator/graph/` and remains Flutter-independent.

## Scoped Variable Evaluation
Global variables are still not enabled. Normal calculator expressions keep previous behavior:

- `x + 1` outside graph helpers still fails
- `pi`, `e`, `i`, and units keep their existing resolution priority

Graph evaluation creates an ephemeral `GraphVariableScope` containing only the current variable bindings. `ExpressionEvaluator` now accepts an optional scope and resolves scoped variables only after known constants. This keeps graph support local and safe.

## FunctionValue
`FunctionValue` is a structured `CalculatorValue` representing a single-variable graphable expression.

It stores:

- `variableName` (currently scoped to `x`)
- `originalExpression`
- `normalizedExpression`
- parsed `ExpressionNode` AST via `FunctionExpression`

Display format is canonicalized as:

- `f(x) = x ^ 2`
- `f(x) = sin(x)`

`FunctionValue` itself is non-numeric; actual evaluation at `x` is performed by graph helpers using scoped evaluation.

## PlotValue / GraphPlotResult
`PlotValue` is the structured graph result returned by `plot(...)`. It stores:

- `GraphViewport viewport`
- `List<PlotSeries> series`
- `autoYUsed`
- `warnings`

Each `PlotSeries` stores:

- original expression
- normalized expression
- display label
- `List<PlotSegment>`
- total/defined/undefined sample counts
- warnings

Each `PlotSegment` is a continuous drawable run of defined points. Undefined/discontinuous regions create a new segment instead of connecting with a false line.

## GraphViewport
`GraphViewport` is a pure Dart model with:

- `xMin`
- `xMax`
- `yMin`
- `yMax`
- `autoY`

Validation rules:

- all values must be finite
- `xMin < xMax`
- `yMin < yMax` when `autoY` is false

The model also supports `pan(...)`, `zoom(...)`, and a compact display summary.

## GraphSamplingOptions
Sampling is controlled through `GraphSamplingOptions`:

- `initialSamples = 512`
- `maxSamples = 4096`
- `adaptiveDepth = 6`
- `discontinuityThreshold = 6.0`
- `minStep = 1e-4`
- `maxEvaluationErrors = 512`
- adaptive/discontinuity toggles

These guards keep the engine predictable and prevent runaway sampling.

## Adaptive Sampling
Sampling starts with uniform points across the x-range. Adaptive refinement then inserts midpoints only when needed:

- one endpoint is defined and the other is undefined
- or both are defined but the y-change is large relative to viewport span

The refinement is recursive but bounded by `adaptiveDepth`, `maxSamples`, and `minStep`.

This is enough for:

- smooth curves such as `sin(x)` and `x^2`
- boundary-sensitive curves such as `sqrt(x)`
- asymptote-heavy curves such as `1/x` and `tan(x)`

without adding async/isolate complexity in this phase.

## Discontinuity / Asymptote Detection
The engine never silently connects through invalid regions.

Segment breaks happen when:

- evaluation throws a domain error or produces NaN/Infinity
- graph-specific unsupported outputs occur
- adjacent defined points jump too far vertically relative to the viewport

This prevents false vertical bridges across:

- `1/x` around `x = 0`
- `tan(x)` around `pi/2 + k*pi`
- left-domain gaps like `sqrt(x)` for `x < 0`

## Root / Intersection / Trace Helpers
Graph analysis helpers are implemented in pure Dart:

- `evalAt(expression, x)`
- `trace(expression, x)`
- `root(expression, xMin, xMax)`
- `roots(expression, xMin, xMax)`
- `intersect(expression1, expression2, xMin, xMax)`
- `intersections(...)`
- `slope(expression, x)`
- `area(expression, xMin, xMax)`

Policies:

- roots use sampling + sign-change bracketing + bisection
- intersections solve roots of `f(x) - g(x)`
- slope uses central-difference approximation
- area uses bounded numerical integration

Current analysis limits:

- root scan samples: `2048`
- bisection iterations: `80`
- integration subintervals: `4096`

## Lazy Graph Arguments
Graph functions must receive expression AST arguments before ordinary evaluation.
To preserve compatibility, only these functions use narrow raw-AST handling:

- `fn`
- `function`
- `plot`
- `evalAt`
- `trace`
- `root`
- `roots`
- `intersect`
- `intersections`
- `slope`
- `area`

All other functions stay eager and behave exactly as before.

## Supported Graph Output Policy
Graph plotting accepts scalar real outputs only.

Accepted sampling outputs:

- `DoubleValue`
- `RationalValue`
- `SymbolicValue`
- dimensionless `UnitValue`

Rejected outputs:

- complex values unless user scalarizes them with helpers like `re(...)`, `im(...)`, `abs(...)`
- non-dimensionless units
- vectors, matrices, datasets, regression values, plot values, function values

Unsupported graph outputs are treated as typed graph errors, not as drawable undefined samples.

## Result Formatting
Formatter support was extended for:

- `FunctionValue`
- `PlotValue`
- graph helper metadata

Display policy:

- compact summaries only
- never dump thousands of sampled points into `displayResult`

Examples:

- `f(x) = x ^ 2`
- `Plot: y = sin(x)`
- `1 series, 512 points, 1 segments`
- viewport summary
- trace/root/intersection summaries in alternative metadata fields

## Flutter Graph Panel
The Flutter UI remains a presentation layer only.

The new graph panel provides:

- graph mode toggle
- function list editor
- viewport controls
- auto-Y toggle
- plot button
- reset button
- `CustomPainter` canvas
- gesture pan/zoom
- local debounce for repeated viewport-driven replotting
- legend and warning/error display

Important design choice:

- user-triggered plot commits through the existing controller/history flow
- pan/zoom replotting stays local and does not spam history

## Settings / History / Storage
This phase extends history/result metadata for graph outputs, including:

- function/plot display summaries
- viewport display
- series/point/segment counts
- graph warnings

Compact plot metadata is serialized, but full sampled point arrays are not written to history. Recall is based on expression + viewport summary rather than thousands of saved samples.

Dedicated persistent graph settings were intentionally not added in this phase to avoid broad settings churn. The graph panel keeps live viewport state locally while explicit `plot(...)` evaluations still flow through normal history.

## Guard Limits
Implemented graph limits:

- initial samples: `512`
- max samples: `4096`
- adaptive depth: `6`
- max evaluation errors per series: `512`
- root scan samples: `2048`
- max bisection iterations: `80`
- max integration subintervals: `4096`
- max UI series count: `6`
- UI replot debounce: `120 ms`

Existing earlier-phase guards remain active for:

- token/expression complexity
- exact rational digit limits
- symbolic term/factor limits
- matrix limits
- unit limits

## Intentionally Deferred
Not included in Phase 9:

- symbolic derivative/integral engine
- symbolic root solving
- 3D, parametric, polar, or implicit plots
- histogram/statistical charts
- export PNG/SVG/CSV
- notebook/worksheet system
- persistent user-defined functions/variables
- isolate-based graph compute pipeline

## Next Phase Direction
Phase 10 can build a worksheet/notebook/export layer on top of the new graph structures:

- named expressions
- saved graphs and graph-state serialization
- export-friendly plot metadata
- lightweight notebook cells
- future user-defined function persistence
