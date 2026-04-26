# User Guide

## Getting Started

Hesap Makinesi is a local-first scientific calculator with exact arithmetic,
symbolic-lite results, units, graphing, worksheets and CAS-lite helpers. Enter an
expression, press Enter or the evaluate button, and review the result card for
alternatives, warnings, badges and save/export actions.

Your settings, history, worksheets and backups stay local unless you copy or
share exported text yourself.

## Scientific Calculator

Use standard operators:

```text
1 + 2 * 3
(4 + 5) / 3
sin(30)
sqrt(2)
log(100)
```

Angle mode controls trig functions. Degree, radian and grad modes are available
from settings or mode controls.

## Exact / Symbolic

Exact mode keeps rational and symbolic results when safe:

```text
1/3 + 1/6      -> 1/2
sqrt(8)        -> simplified radical
sin(pi/6)      -> exact trig result in supported exact contexts
```

Approximate mode favors decimal output. Result alternatives may show exact,
decimal, fraction or symbolic forms depending on the value type.

## Complex

Enable complex domain to use the imaginary unit and complex helpers:

```text
sqrt(-1)
3 + 4i
abs(3+4i)
conj(3+4i)
re(3+4i)
im(3+4i)
```

Real mode intentionally rejects complex-only expressions.

## Matrix / Vector

Vectors and matrices can be typed directly:

```text
vec(1,2,3)
mat(2,2,1,2,3,4)
det(mat(2,2,1,2,3,4))
inv(mat(2,2,1,2,3,4))
transpose(mat(2,2,1,2,3,4))
identity(3)
```

Matrix guards prevent unsupported shapes, singular inverses and excessive
computation.

## Units

Enable unit mode, then write unit-aware expressions:

```text
3 m + 20 cm
to(100 cm, m)
to(72 km/h, m/s)
to(32 degF, degC)
```

Incompatible dimensions produce typed errors instead of silent conversion.

## Statistics

Datasets use `data(...)`:

```text
data(1,2,3,4)
mean(data(1,2,3,4))
median(data(1,2,3,4))
varp(data(1,2,3,4))
stds(data(1,2,3,4))
quantile(data(1,2,3,4), 0.25)
linreg(data(1,2,3), data(2,4,6))
```

Probability helpers include binomial, poisson, geometric, normal and uniform
functions. Distribution functions are approximate where the math requires it.

## Graphing

Use graph mode or graph functions:

```text
plot(sin(x), -pi, pi)
plot(x^2, -5, 5)
evalAt(x^2, 3)
roots(x^2 - 4, -5, 5)
slope(x^2, 3)
area(sin(x), 0, pi)
```

The graph engine samples safely and breaks line segments around undefined
points, discontinuities and asymptotes.

## Worksheet

Worksheets are local notebooks made of blocks:

- Calculation blocks store expressions and results.
- Text blocks store notes.
- Graph blocks store expressions and viewport metadata.
- Variable blocks define worksheet-scoped symbols.
- Function blocks define worksheet-scoped functions.
- Solve and CAS blocks run CAS-lite workflows.

Run all uses dependency ordering, detects cycles and marks downstream blocks
stale when upstream definitions change.

## Variables / Functions

Worksheet variables and functions are scoped to the active worksheet:

```text
a = 2
b = a + 3
f(x) = x^2 + a
f(3)
```

These symbols do not become global calculator variables. A normal calculator
expression like `a + 1` still errors unless it is evaluated through worksheet
scope.

## CAS-lite Solve

CAS-lite supports guarded solving and expression transforms:

```text
solve(2*x + 3 = 7, x)
solve(x^2 - 4 = 0, x)
nsolve(cos(x)-x, x, 0, 1)
diff(x^2, x)
integrate(sin(x), x, 0, pi)
simplify(x + x)
expand((x+1)^2)
factor(x^2 - 4)
```

This is not a full CAS. Unsupported forms return typed errors or ask for a
numeric interval.

## Export / Backup

Worksheet exports:

- Markdown
- CSV
- Graph SVG
- Graph data CSV

Backup export produces local JSON containing settings, history and worksheets.
Restore validates the JSON and rejects corrupt input safely. There is no cloud
sync or account system.

## Keyboard Shortcuts

- `Enter`: evaluate.
- `Ctrl+K`: command palette.
- `Ctrl+L`: clear expression.
- `Ctrl+S`: save current result to worksheet.
- `Ctrl+G`: graph mode.
- `Ctrl+W`: worksheet mode.
- `Ctrl+H`: history mode.
- `Esc`: close dialogs or sheets where supported.

## Limitations

See [Known Limitations](known_limitations.md) for the full list. Important
boundaries: no cloud sync, no global variables, no full CAS, no symbolic systems
solver, no 3D graphing, no file picker/share package, and numeric graph/solve
helpers are approximate.

