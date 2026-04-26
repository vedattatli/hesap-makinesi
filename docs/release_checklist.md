# Release Checklist

Use this checklist before marking a build as launch-candidate ready.

## Automated Checks

- [ ] `flutter analyze` passes with no issues.
- [ ] `flutter test` passes.
- [ ] `git diff --check` reports no whitespace errors.
- [ ] `dart format --set-exit-if-changed lib test` passes or formatting has
  been applied intentionally.
- [ ] No unexpected generated files or local-only artifacts are included.
- [ ] Known CRLF warnings, if present, are understood and non-blocking.

## Manual Smoke

- [ ] App launches to calculator mode.
- [ ] Exact calculation: `1/3 + 1/6` displays `1/2`.
- [ ] Approx calculation: `sqrt(2)` displays decimal output.
- [ ] Complex mode: `sqrt(-1)` displays `i`.
- [ ] Matrix: `det(mat(2,2,1,2,3,4))` displays `-2`.
- [ ] Units: `to(100 cm, m)` displays compatible conversion.
- [ ] Statistics: `mean(data(1,2,3,4))` displays expected mean.
- [ ] Solve: `solve(x^2-4=0,x)` displays two solutions.
- [ ] CAS transform: `factor(x^2-4)` displays factored form.
- [ ] Graph: plot `sin(x)` and verify axes/canvas render.
- [ ] Graph discontinuity: plot `1/x` and verify no false connection across 0.
- [ ] Worksheet: create worksheet, add calculation block, run block.
- [ ] Worksheet scope: define `a=2`, evaluate `a+3` inside worksheet.
- [ ] Normal calculator still rejects `a+1` outside worksheet scope.
- [ ] Export worksheet Markdown preview.
- [ ] Export graph SVG preview.
- [ ] Backup JSON export and corrupt restore error path.

## Accessibility Smoke

- [ ] Keyboard shortcuts: Enter, Ctrl+K, Ctrl+L, Ctrl+G, Ctrl+W, Ctrl+H.
- [ ] Tab traversal reaches main controls.
- [ ] Result card has meaningful screen-reader summary.
- [ ] Graph canvas exposes semantic summary.
- [ ] Error and warning messages are visible and readable.
- [ ] High contrast mode keeps badges, warnings and focus rings readable.
- [ ] Reduced motion setting shortens or disables non-essential motion.
- [ ] Large text does not clip primary calculator, graph or worksheet panels.

## Localization Smoke

- [ ] English labels render.
- [ ] Turkish labels render where localized.
- [ ] Settings language switch persists.
- [ ] Numeric and expression semantics do not change with locale.

## Data / Privacy Smoke

- [ ] History persists across app restart using local storage.
- [ ] Worksheets persist across app restart using local storage.
- [ ] Backup export clearly states local-first behavior.
- [ ] Restore rejects invalid JSON safely.
- [ ] Clear history and clear worksheets actions require intentional user action.
- [ ] Known limitations have been reviewed for honesty.

## Launch-Candidate Decision

Mark ready only if automated checks pass and no blocker appears in manual smoke.
If any blocker exists, record it with reproduction steps before release prep.

