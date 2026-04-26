import 'package:flutter/material.dart';

import '../../../../core/calculator/calculator.dart';
import '../../data/calculator_settings.dart';
import '../app_localizations.dart';

/// Bottom sheet used to tweak angle mode, precision and theme preferences.
class CalculatorSettingsSheet extends StatelessWidget {
  const CalculatorSettingsSheet({
    super.key,
    required this.angleMode,
    required this.numericMode,
    required this.calculationDomain,
    required this.unitMode,
    required this.resultFormat,
    required this.precision,
    required this.themePreference,
    required this.reduceMotion,
    required this.highContrast,
    required this.language,
    required this.onAngleModeChanged,
    required this.onNumericModeChanged,
    required this.onCalculationDomainChanged,
    required this.onUnitModeChanged,
    required this.onResultFormatChanged,
    required this.onPrecisionChanged,
    required this.onThemePreferenceChanged,
    required this.onReduceMotionChanged,
    required this.onHighContrastChanged,
    required this.onLanguageChanged,
    required this.onResetSettings,
    required this.onClearWorksheets,
    required this.onLoadSampleWorksheets,
    required this.onExportBackup,
    required this.onRestoreBackup,
    required this.onOpenExamples,
    required this.onOpenHelp,
    required this.onOpenPrivacy,
    required this.onClearHistory,
  });

  final AngleMode angleMode;
  final NumericMode numericMode;
  final CalculationDomain calculationDomain;
  final UnitMode unitMode;
  final NumberFormatStyle resultFormat;
  final int precision;
  final CalculatorThemePreference themePreference;
  final bool reduceMotion;
  final bool highContrast;
  final CalculatorAppLanguage language;
  final ValueChanged<AngleMode> onAngleModeChanged;
  final ValueChanged<NumericMode> onNumericModeChanged;
  final ValueChanged<CalculationDomain> onCalculationDomainChanged;
  final ValueChanged<UnitMode> onUnitModeChanged;
  final ValueChanged<NumberFormatStyle> onResultFormatChanged;
  final ValueChanged<int> onPrecisionChanged;
  final ValueChanged<CalculatorThemePreference> onThemePreferenceChanged;
  final ValueChanged<bool> onReduceMotionChanged;
  final ValueChanged<bool> onHighContrastChanged;
  final ValueChanged<CalculatorAppLanguage> onLanguageChanged;
  final VoidCallback onResetSettings;
  final VoidCallback onClearWorksheets;
  final VoidCallback onLoadSampleWorksheets;
  final VoidCallback onExportBackup;
  final VoidCallback onRestoreBackup;
  final VoidCallback onOpenExamples;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = CalculatorLocalization.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.t('settings.title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.t('settings.angleMode'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<AngleMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<AngleMode>(
                    value: AngleMode.degree,
                    label: Text('DEG'),
                  ),
                  ButtonSegment<AngleMode>(
                    value: AngleMode.radian,
                    label: Text('RAD'),
                  ),
                  ButtonSegment<AngleMode>(
                    value: AngleMode.gradian,
                    label: Text('GRAD'),
                  ),
                ],
                selected: {angleMode},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  onAngleModeChanged(selection.first);
                },
              ),
              const SizedBox(height: 20),
              Text(
                strings.t('settings.numericMode'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<NumericMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<NumericMode>(
                    value: NumericMode.approximate,
                    label: Text('APPROX'),
                  ),
                  ButtonSegment<NumericMode>(
                    value: NumericMode.exact,
                    label: Text('EXACT'),
                  ),
                ],
                selected: {numericMode},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  onNumericModeChanged(selection.first);
                },
              ),
              const SizedBox(height: 20),
              Text(
                strings.t('settings.domain'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<CalculationDomain>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<CalculationDomain>(
                    value: CalculationDomain.real,
                    label: Text('REAL'),
                  ),
                  ButtonSegment<CalculationDomain>(
                    value: CalculationDomain.complex,
                    label: Text('COMPLEX'),
                  ),
                ],
                selected: {calculationDomain},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  onCalculationDomainChanged(selection.first);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Complex mode allows i and complex-valued results.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.t('settings.unitMode'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<UnitMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<UnitMode>(
                    value: UnitMode.disabled,
                    label: Text('OFF'),
                  ),
                  ButtonSegment<UnitMode>(
                    value: UnitMode.enabled,
                    label: Text('ON'),
                  ),
                ],
                selected: {unitMode},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  onUnitModeChanged(selection.first);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Unit mode enables physical unit parsing such as 3 m + 20 cm.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.t('settings.precision'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final option in const [4, 6, 8, 10, 12, 16])
                    ChoiceChip(
                      key: Key('precision-option-$option'),
                      label: Text('P$option'),
                      selected: precision == option,
                      onSelected: (_) => onPrecisionChanged(option),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                strings.t('settings.resultFormat'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<NumberFormatStyle>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<NumberFormatStyle>(
                    value: NumberFormatStyle.auto,
                    label: Text('Auto'),
                  ),
                  ButtonSegment<NumberFormatStyle>(
                    value: NumberFormatStyle.decimal,
                    label: Text('Decimal'),
                  ),
                  ButtonSegment<NumberFormatStyle>(
                    value: NumberFormatStyle.fraction,
                    label: Text('Fraction'),
                  ),
                  ButtonSegment<NumberFormatStyle>(
                    value: NumberFormatStyle.symbolic,
                    label: Text('Symbolic'),
                  ),
                ],
                selected: {resultFormat},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  onResultFormatChanged(selection.first);
                },
              ),
              const SizedBox(height: 20),
              Text(
                strings.t('settings.theme'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<CalculatorThemePreference>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<CalculatorThemePreference>(
                    value: CalculatorThemePreference.system,
                    label: Text(strings.t('settings.themeSystem')),
                  ),
                  ButtonSegment<CalculatorThemePreference>(
                    value: CalculatorThemePreference.light,
                    label: Text(strings.t('settings.themeLight')),
                  ),
                  ButtonSegment<CalculatorThemePreference>(
                    value: CalculatorThemePreference.dark,
                    label: Text(strings.t('settings.themeDark')),
                  ),
                ],
                selected: {themePreference},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  onThemePreferenceChanged(selection.first);
                },
              ),
              const SizedBox(height: 20),
              Text(
                strings.t('settings.language'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<CalculatorAppLanguage>(
                key: const Key('language-toggle'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<CalculatorAppLanguage>(
                    value: CalculatorAppLanguage.en,
                    label: Text(strings.t('settings.english')),
                  ),
                  ButtonSegment<CalculatorAppLanguage>(
                    value: CalculatorAppLanguage.tr,
                    label: Text(strings.t('settings.turkish')),
                  ),
                ],
                selected: {language},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  onLanguageChanged(selection.first);
                },
              ),
              const SizedBox(height: 20),
              Text(
                strings.t('settings.accessibility'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                key: const Key('reduce-motion-switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(strings.t('settings.reduceMotion')),
                subtitle: Text(
                  strings.t('settings.reduceMotionSubtitle'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: reduceMotion,
                onChanged: onReduceMotionChanged,
              ),
              SwitchListTile(
                key: const Key('high-contrast-switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(strings.t('settings.highContrast')),
                subtitle: Text(
                  strings.t('settings.highContrastSubtitle'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: highContrast,
                onChanged: onHighContrastChanged,
              ),
              const SizedBox(height: 20),
              Text(
                'Data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    key: const Key('settings-export-backup-button'),
                    onPressed: onExportBackup,
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('Export backup'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('settings-restore-backup-button'),
                    onPressed: onRestoreBackup,
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('Restore backup'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('settings-sample-worksheets-button'),
                    onPressed: onLoadSampleWorksheets,
                    icon: const Icon(Icons.library_books_outlined),
                    label: const Text('Load samples'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('settings-clear-worksheets-button'),
                    onPressed: onClearWorksheets,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear worksheets'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Product',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    key: const Key('settings-open-examples-button'),
                    onPressed: onOpenExamples,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Examples'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('settings-open-help-button'),
                    onPressed: onOpenHelp,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Help'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('settings-open-privacy-button'),
                    onPressed: onOpenPrivacy,
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: const Text('Privacy'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('settings-reset-settings-button'),
                    onPressed: onResetSettings,
                    icon: const Icon(Icons.restart_alt_outlined),
                    label: const Text('Reset settings'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onClearHistory,
                icon: const Icon(Icons.history_toggle_off),
                label: Text(strings.t('settings.clearHistory')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
