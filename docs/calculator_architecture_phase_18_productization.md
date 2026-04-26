# Calculator Architecture - Phase 18 Productization

## Goal

Phase 18 adds the final local-first product layer around the existing calculator,
graphing, worksheet, CAS-lite, export and accessibility systems. It does not
change calculator semantics. The feature focus is first-run onboarding, examples,
help/reference content, sample worksheets, local JSON backup/restore, settings
data controls and privacy messaging.

## Onboarding

Onboarding is an inline first-launch card rather than a blocking modal. This
keeps existing workflows usable and avoids hiding the calculator behind a route.
The card introduces exact/approx math, graphing, worksheets, units, CAS-lite and
accessibility. It is skippable and persists through
`CalculatorSettings.onboardingCompleted`.

## Examples Library

`CalculatorExamplesLibrary` provides curated examples for:

- basic scientific math,
- exact symbolic arithmetic,
- complex numbers,
- matrix operations,
- units,
- statistics,
- graphing,
- worksheet variables,
- CAS-lite solving.

Examples produce expression strings only; evaluation still goes through the safe
parser/evaluator.

## Help / Reference

The help panel is a compact local reference with sections for syntax, functions,
units, matrix, statistics, graphing, worksheet, CAS-lite and keyboard shortcuts.
It is intentionally static and local. Search can be added later.

## Backup / Restore

`LocalDataBackupService` exports a versioned JSON payload containing:

- settings,
- history,
- worksheets,
- active worksheet id.

Restore validates the schema/version, rejects corrupt JSON safely and ignores
malformed individual history/worksheet entries. No file picker is required; users
copy/export JSON text and paste it back into the restore dialog.

## Export Polish

Worksheet Markdown/CSV/SVG/graph CSV export remains in the worksheet layer. Phase
18 adds product-level backup export and copy-oriented preview UI. The same
privacy-first local-control model applies to every export.

## Settings Polish

Settings now expose grouped product/data actions:

- export backup,
- restore backup,
- load sample worksheets,
- clear worksheets,
- examples,
- help,
- privacy,
- reset settings,
- clear history.

Destructive controls remain explicit button actions; a future phase can add
confirmation dialogs before every delete/reset path.

## Sample Worksheets

`SampleWorksheetFactory` creates deterministic worksheets for:

- trig graph comparison,
- unit physics,
- matrix operations,
- statistics/regression,
- CAS solve/factor workflows.

Samples are normal worksheet documents, not special runtime objects.

## Privacy / Local Data

The privacy notice states that the app has no account system, cloud sync,
external API or upload path. Backup/export data stays under user control.

## Guards

- Backup JSON size is capped.
- Backup schema/version must match.
- Restore caps history and worksheet counts.
- Sample worksheet install avoids duplicate sample ids.
- Existing worksheet/controller limits remain active.

## Next Phase

Future productization can add confirmation dialogs for destructive settings,
searchable help, export templates, richer example walkthroughs, printable docs,
and a release checklist for app-store/web packaging.
