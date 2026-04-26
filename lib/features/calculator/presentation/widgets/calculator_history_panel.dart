import 'package:flutter/material.dart';

import '../../../../core/calculator/calculator.dart';
import '../../data/calculator_history_item.dart';

/// Displays persisted successful calculations and quick recall actions.
class CalculatorHistoryPanel extends StatelessWidget {
  const CalculatorHistoryPanel({
    super.key,
    required this.items,
    required this.onRecall,
    required this.onDelete,
    required this.onClearHistory,
    this.compact = false,
    this.onSaveToWorksheet,
  });

  final List<CalculatorHistoryItem> items;
  final ValueChanged<CalculatorHistoryItem> onRecall;
  final ValueChanged<CalculatorHistoryItem> onDelete;
  final VoidCallback onClearHistory;
  final bool compact;
  final ValueChanged<CalculatorHistoryItem>? onSaveToWorksheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      key: const Key('history-panel'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'History',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('clear-history-button'),
                  onPressed: items.isEmpty ? null : onClearHistory,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Hesap gecmisi henuz bos.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      key: Key('history-item-$index'),
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onRecall(item),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: colorScheme.surfaceContainerLow,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.expression,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.displayResult,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (item.decimalDisplayResult != null &&
                                      item.decimalDisplayResult !=
                                          item.displayResult) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Decimal ${item.decimalDisplayResult}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      _HistoryBadge(
                                        label:
                                            item.numericMode ==
                                                NumericMode.exact
                                            ? 'EXACT'
                                            : 'APPROX',
                                      ),
                                      _HistoryBadge(
                                        label:
                                            item.calculationDomain ==
                                                CalculationDomain.complex
                                            ? 'COMPLEX'
                                            : 'REAL',
                                      ),
                                      if (item.valueKind ==
                                          CalculatorValueKind.symbolic)
                                        const _HistoryBadge(label: 'SYMBOLIC'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.rational)
                                        const _HistoryBadge(label: 'RATIONAL'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.complex)
                                        const _HistoryBadge(label: 'COMPLEX'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.vector)
                                        const _HistoryBadge(label: 'VECTOR'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.matrix)
                                        const _HistoryBadge(label: 'MATRIX'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.dataset)
                                        const _HistoryBadge(label: 'DATASET'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.regression)
                                        const _HistoryBadge(
                                          label: 'REGRESSION',
                                        ),
                                      if (item.valueKind ==
                                          CalculatorValueKind.function)
                                        const _HistoryBadge(label: 'FUNCTION'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.plot)
                                        const _HistoryBadge(label: 'PLOT'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.equation)
                                        const _HistoryBadge(label: 'EQUATION'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.solveResult)
                                        const _HistoryBadge(label: 'SOLVE'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.expressionTransform)
                                        const _HistoryBadge(label: 'CAS-LITE'),
                                      if (item.valueKind ==
                                          CalculatorValueKind.unit)
                                        const _HistoryBadge(label: 'UNIT'),
                                      if (item.derivativeDisplayResult != null)
                                        const _HistoryBadge(label: 'DERIVATIVE'),
                                      if (item.integralDisplayResult != null)
                                        const _HistoryBadge(label: 'INTEGRAL'),
                                      if (item.valueKind ==
                                              CalculatorValueKind.solveResult &&
                                          item.isApproximate)
                                        const _HistoryBadge(
                                          label: 'NUMERIC SOLVE',
                                        ),
                                      if (item.graphDisplayResult != null ||
                                          item.traceDisplayResult != null ||
                                          item.rootDisplayResult != null ||
                                          item.intersectionDisplayResult != null)
                                        const _HistoryBadge(label: 'GRAPH'),
                                      if (item.statisticsDisplayResult != null)
                                        const _HistoryBadge(label: 'STATS'),
                                      if (item.probabilityDisplayResult != null)
                                        const _HistoryBadge(
                                          label: 'PROBABILITY',
                                        ),
                                      if (item.unitMode == UnitMode.enabled)
                                        const _HistoryBadge(label: 'UNITS'),
                                      Text(
                                        '${_labelForAngleMode(item.angleMode)}  |  P${item.precision}  |  ${_formatTimestamp(item.createdAt)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (item.polarDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Polar ${item.polarDisplayResult}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (item.shapeDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Shape ${item.shapeDisplayResult}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.baseUnitDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Base ${item.baseUnitDisplayResult}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.dimensionDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dim ${item.dimensionDisplayResult}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.sampleSize != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'n = ${item.sampleSize}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                  if (item.statisticsDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.statisticsDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.probabilityDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.probabilityDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.viewportDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.viewportDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.plotSeriesCount != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.plotSeriesCount} series | ${item.plotPointCount ?? 0} points | ${item.plotSegmentCount ?? 0} segments',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.graphDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.graphDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.equationDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.equationDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.solveDisplayResult != null &&
                                      item.solveDisplayResult !=
                                          item.displayResult) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.solveDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.solutionsDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Solutions ${item.solutionsDisplayResult!}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.derivativeDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.derivativeDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.integralDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.integralDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.traceDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.traceDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.rootDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.rootDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.intersectionDisplayResult != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.intersectionDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (item.summaryDisplayResult != null &&
                                      item.summaryDisplayResult !=
                                          item.statisticsDisplayResult &&
                                      item.summaryDisplayResult !=
                                          item.probabilityDisplayResult &&
                                      item.summaryDisplayResult !=
                                          item.graphDisplayResult) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.summaryDisplayResult!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              children: <Widget>[
                                if (onSaveToWorksheet != null)
                                  IconButton(
                                    key: Key('history-save-to-worksheet-$index'),
                                    tooltip: 'Save to worksheet',
                                    onPressed: () => onSaveToWorksheet!(item),
                                    icon: const Icon(Icons.save_outlined),
                                  ),
                                IconButton(
                                  tooltip: 'Delete history item',
                                  onPressed: () => onDelete(item),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _labelForAngleMode(AngleMode angleMode) {
    return switch (angleMode) {
      AngleMode.degree => 'DEG',
      AngleMode.radian => 'RAD',
      AngleMode.gradian => 'GRAD',
    };
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    if (compact) {
      return '$hour:$minute';
    }

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month $hour:$minute';
  }
}

class _HistoryBadge extends StatelessWidget {
  const _HistoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
