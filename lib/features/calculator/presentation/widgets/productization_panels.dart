import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../productization/examples_library.dart';
import '../../worksheet/worksheet_export.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';

class ProductOnboardingCard extends StatelessWidget {
  const ProductOnboardingCard({
    super.key,
    required this.onFinish,
    required this.onReduceMotion,
    required this.onOpenExamples,
    required this.onOpenHelp,
  });

  final VoidCallback onFinish;
  final VoidCallback onReduceMotion;
  final VoidCallback onOpenExamples;
  final VoidCallback onOpenHelp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      key: const Key('product-onboarding-card'),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome to your local-first math workspace',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Exact math, graphing, worksheets, units and CAS-lite all stay on this device. Start with examples or jump straight in.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: const <Widget>[
                _OnboardingChip(label: 'Exact / Approx'),
                _OnboardingChip(label: 'Graphing'),
                _OnboardingChip(label: 'Worksheet'),
                _OnboardingChip(label: 'Units'),
                _OnboardingChip(label: 'CAS-lite'),
                _OnboardingChip(label: 'Accessibility'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                FilledButton.icon(
                  key: const Key('onboarding-examples-button'),
                  onPressed: onOpenExamples,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Explore examples'),
                ),
                OutlinedButton.icon(
                  key: const Key('onboarding-help-button'),
                  onPressed: onOpenHelp,
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Open help'),
                ),
                OutlinedButton.icon(
                  key: const Key('onboarding-reduce-motion-button'),
                  onPressed: onReduceMotion,
                  icon: const Icon(Icons.motion_photos_off_outlined),
                  label: const Text('Reduce motion'),
                ),
                TextButton(
                  key: const Key('onboarding-skip-button'),
                  onPressed: onFinish,
                  child: const Text('Finish setup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingChip extends StatelessWidget {
  const _OnboardingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.check_circle_outline, size: 18),
    );
  }
}

class ExamplesLibraryDialog extends StatelessWidget {
  const ExamplesLibraryDialog({super.key, required this.onSelect});

  final ValueChanged<CalculatorExample> onSelect;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('examples-library-dialog'),
      title: const Text('Examples Library'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: CalculatorExamplesLibrary.examples
                .map(
                  (example) => Card(
                    child: ListTile(
                      key: Key('example-${example.id}'),
                      leading: Icon(_iconFor(example.target)),
                      title: Text(example.title),
                      subtitle: Text(
                        '${example.category} • ${example.description}\n${example.expression}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(example);
                      },
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  IconData _iconFor(CalculatorExampleTarget target) {
    return switch (target) {
      CalculatorExampleTarget.calculator => Icons.calculate_outlined,
      CalculatorExampleTarget.graph => Icons.show_chart,
      CalculatorExampleTarget.worksheet => Icons.menu_book_outlined,
    };
  }
}

class HelpReferenceDialog extends StatelessWidget {
  const HelpReferenceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <({String title, List<String> lines})>[
      (
        title: 'Syntax',
        lines: <String>[
          'Use +, -, *, /, ^ and parentheses.',
          'Use functions like sin(30), sqrt(2), solve(x^2-4=0,x).',
        ],
      ),
      (
        title: 'Functions',
        lines: <String>[
          'Trig: sin, cos, tan, asin, acos, atan.',
          'Log/exp: ln, log, exp, sqrt.',
        ],
      ),
      (
        title: 'Units',
        lines: <String>[
          'Enable unit mode, then use expressions like 3 m + 20 cm.',
          'Convert with to(72 km/h, m/s).',
        ],
      ),
      (
        title: 'Matrix',
        lines: <String>[
          'Use mat(rows, cols, values...) and vec(...).',
          'Helpers include det, inv and transpose.',
        ],
      ),
      (
        title: 'Statistics',
        lines: <String>[
          'Use data(...) with mean, median, variance, quantile.',
          'Regression: linreg(data(...), data(...)).',
        ],
      ),
      (
        title: 'Graphing',
        lines: <String>[
          'Use x as the graph variable, e.g. plot(sin(x), -pi, pi).',
          'Discontinuities are segmented instead of connected.',
        ],
      ),
      (
        title: 'Worksheet',
        lines: <String>[
          'Create calculation, graph, variable, function, solve and CAS blocks.',
          'Run all uses dependency ordering and keeps data local.',
        ],
      ),
      (
        title: 'CAS-lite',
        lines: <String>[
          'Use solve, diff, integral, simplify, expand and factor.',
          'This is intentionally limited and deterministic, not a full CAS.',
        ],
      ),
      (
        title: 'Keyboard shortcuts',
        lines: <String>[
          'Enter evaluate, Ctrl+L clear, Ctrl+K command palette.',
          'Ctrl+G graph, Ctrl+W worksheet, Ctrl+S save result.',
        ],
      ),
      (
        title: 'Launch notes',
        lines: <String>[
          'CAS-lite is intentionally limited; unsupported forms return typed errors.',
          'Exports are local preview/copy flows; no cloud, account or network upload is used.',
        ],
      ),
    ];
    return AlertDialog(
      key: const Key('help-reference-dialog'),
      title: const Text('Help / Reference'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sections
                .map(
                  (section) => ExpansionTile(
                    initiallyExpanded: section.title == 'Syntax',
                    title: Text(section.title),
                    children: section.lines
                        .map(
                          (line) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.circle, size: 8),
                            title: Text(line),
                          ),
                        )
                        .toList(growable: false),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class LocalDataPrivacyDialog extends StatelessWidget {
  const LocalDataPrivacyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('privacy-local-data-dialog'),
      title: const Text('Privacy / Local Data'),
      content: const Text(
        'This calculator is local-first. There is no account system, cloud sync, external API or network upload. Settings, history, worksheets and exports stay under your control on this device unless you copy or share them yourself.\n\nBackups are plain JSON text so you can inspect, store or delete them manually.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class BackupExportDialog extends StatelessWidget {
  const BackupExportDialog({super.key, required this.export});

  final WorksheetExportResult export;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('backup-export-dialog'),
      title: const Text('Local Backup JSON'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Copy this JSON to keep a local backup of settings, history and worksheets.',
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: AppRadii.control,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  export.contentText,
                  key: const Key('backup-export-preview-text'),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton.icon(
          key: const Key('backup-export-copy-button'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: export.contentText));
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Backup copied.')));
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({super.key, required this.onImport});

  final Future<String?> Function(String source) onImport;

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _message;
  bool _isImporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('backup-restore-dialog'),
      title: const Text('Restore Local Backup'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Paste a backup JSON exported by this app. Invalid or corrupt data is rejected safely.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('backup-import-field'),
              controller: _controller,
              minLines: 6,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Backup JSON',
                alignLabelWithHint: true,
              ),
            ),
            if (_message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _message!,
                key: const Key('backup-import-message'),
                style: TextStyle(
                  color: _message == 'Backup restored.'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        FilledButton.icon(
          key: const Key('backup-import-button'),
          onPressed: _isImporting
              ? null
              : () async {
                  setState(() {
                    _isImporting = true;
                    _message = null;
                  });
                  final error = await widget.onImport(_controller.text);
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _isImporting = false;
                    _message = error ?? 'Backup restored.';
                  });
                },
          icon: const Icon(Icons.restore_outlined),
          label: const Text('Import'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
