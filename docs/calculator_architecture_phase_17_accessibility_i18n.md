# Calculator Architecture - Phase 17 Accessibility / Localization

## Goals

Phase 17 hardens the premium calculator UI for professional accessibility,
localization, desktop and web use without changing calculator semantics. The
calculator core, graph engine, worksheet executor and CAS-lite layers remain
unchanged; this phase only adds presentation-level language, semantics, contrast,
keyboard and responsive affordances.

## Localization

The app uses a lightweight internal localization layer:

- `CalculatorLocalization` is an `InheritedWidget` scoped above
  `CalculatorScreen`.
- `CalculatorStrings` resolves English and Turkish strings from deterministic
  in-repo maps.
- `CalculatorSettings.language` persists the active app language.
- `MaterialApp.locale` follows the persisted language.
- Flutter SDK localization delegates (`flutter_localizations`) provide Material,
  Cupertino and Widgets framework strings for both locales.

This avoids third-party package churn in this phase. A future ARB migration can
replace the map-backed service while preserving the same keys.

Localized areas now include primary app labels, result card labels, mode names,
settings labels, accessibility controls, command palette actions, snackbars and
core semantic labels. Engine error text remains mostly core-owned and can be
lifted into ARB-backed message catalogs later.

## Accessibility Semantics

The expression editor is wrapped with a semantic text-field label and hint. The
result display is a live region with speakable math text so screen readers receive
meaningful updates after evaluation. Status cards use live-region semantics for
errors and warnings. Result badges expose semantic labels, and desktop mode
navigation has a readable navigation label.

Graph and worksheet widgets already expose structured summaries from earlier
phases; Phase 17 keeps those summaries intact and makes the surrounding shell
more keyboard and screen-reader friendly.

## High Contrast

`CalculatorSettings.highContrast` adds a persisted high-contrast preference.
`AppTheme.build(..., highContrast: true)` strengthens:

- surface separation,
- focus border width,
- chip/control outlines,
- error color,
- light/dark seed colors.

The goal is stronger readability while retaining the premium visual language.
Graph palettes and deeper per-series contrast can be further tuned in a later
visual QA pass.

## Reduced Motion Enforcement

The existing `reduceMotion` setting continues to flow through the app shell,
result card transitions, keypad transitions and other motion helpers via
`AppMotion.duration(...)`. Phase 17 keeps the setting persisted and visible in
the accessibility section next to high contrast.

## Keyboard Shortcuts

Desktop/web shortcuts are handled by `CallbackShortcuts` at the app shell:

- `Enter`: evaluate.
- `Ctrl+Enter`: save current result if present, otherwise evaluate.
- `Ctrl+K`: command palette.
- `Ctrl+L`: clear expression.
- `Ctrl+S`: save current result to worksheet.
- `Ctrl+G`: graph mode.
- `Ctrl+W`: worksheet mode.
- `Ctrl+H`: history mode.
- `Esc`: close an open route, otherwise return to calculator mode.

Tab focus traversal remains Flutter-standard and is preserved by using normal
Material controls.

## Desktop / Web Polish

Wide layouts keep the navigation rail and pinned history panel. Compact layouts
use the bottom mode bar. Toolbar labels now localize, history/settings/tooltips
are clearer, and the command palette includes common mode and save/copy actions.
Copy interactions use Flutter clipboard APIs and do not require platform file
picker/share dependencies.

## Responsive Large Text

The UI keeps panels scrollable, uses `Wrap` for dense toolbar/result actions and
preserves minimum Material button sizes. Result actions wrap instead of
overflowing, which helps large text and narrow layouts.

## Testing Strategy

Phase 17 adds tests for:

- settings serialization of language and high contrast,
- controller persistence of accessibility/language preferences,
- settings UI toggles,
- expression/result semantics,
- copy-result clipboard flow,
- desktop graph/worksheet shortcuts.

Existing calculator, graph, worksheet, CAS and performance tests remain the
regression safety net for behavior preservation.

## Guardrails

- No third-party packages.
- No global variable/function resolver changes.
- No calculator semantics changes.
- Accessibility preferences are persisted through existing local settings.
- Localization is presentation-scoped and does not alter core result values.

## Next Phase

A future phase should migrate the internal maps to Flutter ARB localization,
localize core error messages through stable error-code catalogs, tune graph color
contrast per palette, add a full shortcut help overlay, and run manual
screen-reader QA on Windows, web and mobile.
