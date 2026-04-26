# Known Limitations

This app is intentionally broad but not unlimited. The following limits are
known and should be presented honestly in launch notes and support material.

## Calculator / CAS

- CAS-lite is not a full computer algebra system.
- Symbolic simplification, expand and factor use guarded deterministic rules.
- General symbolic equation solving is not supported.
- General systems of nonlinear equations are not supported.
- Inequality solving is limited and not a full symbolic sign-analysis engine.
- Symbolic integration is intentionally small; unsupported integrals return
  typed errors or require numeric bounds.
- Numeric solve and graph root helpers are approximate and interval/guard based.
- Complex numeric solving is limited; scalarized real functions are preferred.
- Matrix/vector equation solving is not supported.

## Worksheet Scope

- Variables and user-defined functions are worksheet-scoped only.
- There are no global user-defined variables or global functions.
- Cross-worksheet dependencies are not supported.
- Calculation block results do not automatically define symbols.
- Recursive worksheet functions and dependency cycles are rejected.

## Graphing

- Graphing is 2D only.
- No 3D, polar, parametric, implicit, inequality shading or histogram charts.
- Adaptive sampling is heuristic; extreme discontinuities may require manual
  viewport adjustment.
- Root/intersection helpers do not guarantee finding every root in pathological
  functions.
- PNG export is not a core pure-Dart export path; SVG and graph data CSV are the
  stable text exports.

## Statistics / Probability

- This is not a full statistics package.
- No hypothesis test suite, Bayesian inference, ANOVA or advanced ML.
- Continuous distribution helpers are approximate.
- Advanced arbitrary-precision special functions are not implemented.

## Units

- Unit algebra is practical and dimensional, not a full symbolic dimensional
  solver.
- Solving equations with rich unit algebra is intentionally limited.
- Some affine temperature operations are restricted to avoid misleading math.

## Product / Storage

- No cloud sync.
- No account system.
- No external API or network upload by default.
- No file picker or share package is included; export uses preview/copy text
  workflows.
- Backup/restore is local JSON text and must be user-managed.
- No collaborative editing.

## UI / Platform

- Golden screenshot tests are not yet part of default CI because rendering is
  still responsive and platform-sensitive.
- Desktop/web polish exists, but release candidates should still receive manual
  smoke on target platforms.
- Very large worksheets, exports or graph data are guarded and may require users
  to reduce scope.

