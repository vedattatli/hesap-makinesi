import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/calculator/calculator.dart';
import '../app_localizations.dart';
import '../design/app_motion.dart';
import '../design/app_radii.dart';
import '../design/app_shadows.dart';
import '../design/app_spacing.dart';
import 'expression_input_tools.dart';

/// Visual surface for editing the active expression and inspecting outcomes.
class CalculatorDisplayCard extends StatelessWidget {
  const CalculatorDisplayCard({
    super.key,
    required this.editorController,
    required this.focusNode,
    required this.outcome,
    required this.lastErrorMessage,
    required this.onSubmitted,
    required this.precision,
    this.reduceMotion = false,
    this.worksheetSuggestions = const <ExpressionSuggestion>[],
    this.onSuggestionSelected,
    this.onOpenFunctionPalette,
    this.onOpenMatrixEditor,
    this.onOpenVectorEditor,
    this.onOpenUnitConverter,
    this.onOpenDatasetEditor,
    this.onOpenSolveCasEditor,
    this.onSaveResultToWorksheet,
  });

  final TextEditingController editorController;
  final FocusNode focusNode;
  final CalculationOutcome? outcome;
  final String? lastErrorMessage;
  final ValueChanged<String> onSubmitted;
  final int precision;
  final bool reduceMotion;
  final List<ExpressionSuggestion> worksheetSuggestions;
  final ValueChanged<ExpressionSuggestion>? onSuggestionSelected;
  final VoidCallback? onOpenFunctionPalette;
  final VoidCallback? onOpenMatrixEditor;
  final VoidCallback? onOpenVectorEditor;
  final VoidCallback? onOpenUnitConverter;
  final VoidCallback? onOpenDatasetEditor;
  final VoidCallback? onOpenSolveCasEditor;
  final VoidCallback? onSaveResultToWorksheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = CalculatorLocalization.of(context);
    final result = outcome?.result;
    final error = outcome?.error;
    final warnings = result?.warnings ?? const <String>[];
    final statusMessage = error?.message ?? warnings.join('\n');
    final statusHint = error?.suggestion;
    final hasIssue = statusMessage.isNotEmpty;
    final badgeLabel =
        result != null &&
            result.numericMode == NumericMode.exact &&
            !result.isApproximate
        ? 'EXACT'
        : 'APPROX';
    final domainLabel = result?.calculationDomain == CalculationDomain.complex
        ? 'COMPLEX'
        : 'REAL';
    final valueKindLabel = switch (result?.valueKind) {
      CalculatorValueKind.rational => 'RATIONAL',
      CalculatorValueKind.symbolic => 'SYMBOLIC',
      CalculatorValueKind.complex => 'COMPLEX',
      CalculatorValueKind.unit => 'UNIT',
      CalculatorValueKind.vector => 'VECTOR',
      CalculatorValueKind.matrix => 'MATRIX',
      CalculatorValueKind.dataset => 'DATASET',
      CalculatorValueKind.regression => 'REGRESSION',
      CalculatorValueKind.function => 'FUNCTION',
      CalculatorValueKind.plot => 'PLOT',
      CalculatorValueKind.equation => 'EQUATION',
      CalculatorValueKind.solveResult => 'SOLVE',
      CalculatorValueKind.expressionTransform => 'CAS-LITE',
      _ => 'DOUBLE',
    };
    final analysisLabel =
        result?.valueKind == CalculatorValueKind.solveResult &&
            result?.isApproximate == true
        ? 'NUMERIC SOLVE'
        : result?.derivativeDisplayResult != null
        ? 'DERIVATIVE'
        : result?.integralDisplayResult != null
        ? 'INTEGRAL'
        : result?.valueKind == CalculatorValueKind.expressionTransform
        ? 'TRANSFORM'
        : result?.plotDisplayResult != null ||
              result?.graphDisplayResult != null ||
              result?.traceDisplayResult != null ||
              result?.rootDisplayResult != null ||
              result?.intersectionDisplayResult != null
        ? 'GRAPH'
        : result?.probabilityDisplayResult != null
        ? 'PROBABILITY'
        : result?.statisticsDisplayResult != null
        ? 'STATS'
        : null;

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        borderRadius: AppRadii.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: AppShadows.panel(colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.t('app.title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.t('app.subtitle'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'P$precision',
                  key: const Key('precision-indicator'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            strings.t('label.expression'),
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.6,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Semantics(
              textField: true,
              label: strings.t('semantics.expressionEditor'),
              hint: strings.t('hint.expression'),
              child: TextField(
                key: const Key('expression-input'),
                controller: editorController,
                focusNode: focusNode,
                textAlign: TextAlign.right,
                maxLines: 3,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.done,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: strings.t('hint.expression'),
                ),
                onSubmitted: onSubmitted,
              ),
            ),
          ),
          if (onSuggestionSelected != null &&
              onOpenFunctionPalette != null &&
              onOpenMatrixEditor != null &&
              onOpenVectorEditor != null &&
              onOpenUnitConverter != null &&
              onOpenDatasetEditor != null &&
              onOpenSolveCasEditor != null)
            ExpressionAssistStrip(
              expressionController: editorController,
              worksheetSuggestions: worksheetSuggestions,
              onSuggestionSelected: onSuggestionSelected!,
              onOpenPalette: onOpenFunctionPalette!,
              onOpenMatrixEditor: onOpenMatrixEditor!,
              onOpenVectorEditor: onOpenVectorEditor!,
              onOpenUnitConverter: onOpenUnitConverter!,
              onOpenDatasetEditor: onOpenDatasetEditor!,
              onOpenSolveCasEditor: onOpenSolveCasEditor!,
            ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Text(
                strings.t('label.result'),
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 0.6,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (result != null) ...<Widget>[
                _Badge(
                  label: badgeLabel,
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                ),
                _Badge(
                  label: domainLabel,
                  backgroundColor: colorScheme.tertiaryContainer,
                  foregroundColor: colorScheme.onTertiaryContainer,
                ),
                _Badge(
                  label: valueKindLabel,
                  backgroundColor: colorScheme.surfaceContainerLow,
                  foregroundColor: colorScheme.onSurface,
                ),
                if (analysisLabel != null) ...<Widget>[
                  _Badge(
                    label: analysisLabel,
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            label:
                '${strings.t('semantics.result')} ${_speakableMathText(result?.displayResult ?? '--')}',
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedSwitcher(
                duration: AppMotion.duration(
                  AppMotion.normal,
                  reduceMotion: reduceMotion,
                ),
                switchInCurve: AppMotion.standard,
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0.02, 0.16),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<String>(result?.displayResult ?? '--'),
                  child: Text(
                    result?.displayResult ?? '--',
                    key: const Key('result-text'),
                    textAlign: TextAlign.right,
                    style:
                        ((result?.valueKind == CalculatorValueKind.matrix ||
                                    result?.valueKind ==
                                        CalculatorValueKind.vector)
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.displaySmall)
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: error != null
                                  ? colorScheme.error
                                  : colorScheme.onSurface,
                            ),
                  ),
                ),
              ),
            ),
          ),
          if (result != null && onSaveResultToWorksheet != null) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    key: const Key('save-result-to-worksheet-button'),
                    onPressed: onSaveResultToWorksheet,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(strings.t('action.saveResult')),
                  ),
                  OutlinedButton.icon(
                    key: const Key('copy-result-button'),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: result.displayResult),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.t('snackbar.resultCopied')),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(strings.t('action.copyResult')),
                  ),
                ],
              ),
            ),
          ],
          if (result?.shapeDisplayResult != null) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                result!.shapeDisplayResult!,
                key: const Key('shape-display-text'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (result?.sampleSize != null) ...<Widget>[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'n = ${result!.sampleSize}',
                key: const Key('sample-size-text'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (result?.plotSeriesCount != null) ...<Widget>[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${result!.plotSeriesCount} series  |  ${result.plotPointCount ?? 0} points  |  ${result.plotSegmentCount ?? 0} segments',
                key: const Key('plot-counts-text'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 18),
            Text(
              strings.t('label.normalized'),
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 0.6,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.normalizedExpression,
              key: const Key('normalized-expression-text'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (_hasAlternatives(result)) ...<Widget>[
              const SizedBox(height: 18),
              Text(
                strings.t('label.alternatives'),
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 0.6,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (result.symbolicDisplayResult != null &&
                  result.symbolicDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Symbolic',
                  value: result.symbolicDisplayResult!,
                  keyName: 'symbolic-alternative-text',
                ),
              if (result.functionDisplayResult != null &&
                  result.functionDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Function',
                  value: result.functionDisplayResult!,
                  keyName: 'function-alternative-text',
                ),
              if (result.plotDisplayResult != null &&
                  result.plotDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Plot',
                  value: result.plotDisplayResult!,
                  keyName: 'plot-alternative-text',
                ),
              if (result.graphDisplayResult != null &&
                  result.graphDisplayResult != result.displayResult &&
                  result.graphDisplayResult != result.plotDisplayResult)
                _AlternativeRow(
                  label: 'Graph',
                  value: result.graphDisplayResult!,
                  keyName: 'graph-summary-text',
                ),
              if (result.equationDisplayResult != null)
                _AlternativeRow(
                  label: 'Equation',
                  value: result.equationDisplayResult!,
                  keyName: 'equation-alternative-text',
                ),
              if (result.solveDisplayResult != null &&
                  result.solveDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Solve',
                  value: result.solveDisplayResult!,
                  keyName: 'solve-alternative-text',
                ),
              if (result.solutionsDisplayResult != null)
                _AlternativeRow(
                  label: 'Solutions',
                  value: result.solutionsDisplayResult!,
                  keyName: 'solutions-alternative-text',
                ),
              if (result.derivativeDisplayResult != null)
                _AlternativeRow(
                  label: 'Derivative',
                  value: result.derivativeDisplayResult!,
                  keyName: 'derivative-alternative-text',
                ),
              if (result.integralDisplayResult != null)
                _AlternativeRow(
                  label: 'Integral',
                  value: result.integralDisplayResult!,
                  keyName: 'integral-alternative-text',
                ),
              if (result.transformDisplayResult != null &&
                  result.transformDisplayResult !=
                      result.derivativeDisplayResult &&
                  result.transformDisplayResult != result.integralDisplayResult)
                _AlternativeRow(
                  label: 'Transform',
                  value: result.transformDisplayResult!,
                  keyName: 'transform-alternative-text',
                ),
              if (result.traceDisplayResult != null)
                _AlternativeRow(
                  label: 'Trace',
                  value: result.traceDisplayResult!,
                  keyName: 'trace-alternative-text',
                ),
              if (result.rootDisplayResult != null)
                _AlternativeRow(
                  label: 'Roots',
                  value: result.rootDisplayResult!,
                  keyName: 'root-alternative-text',
                ),
              if (result.intersectionDisplayResult != null)
                _AlternativeRow(
                  label: 'Intersections',
                  value: result.intersectionDisplayResult!,
                  keyName: 'intersection-alternative-text',
                ),
              if (result.datasetDisplayResult != null &&
                  result.datasetDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Dataset',
                  value: result.datasetDisplayResult!,
                  keyName: 'dataset-alternative-text',
                ),
              if (result.statisticsDisplayResult != null)
                _AlternativeRow(
                  label: 'Statistic',
                  value: result.statisticsDisplayResult!,
                  keyName: 'statistics-summary-text',
                ),
              if (result.regressionDisplayResult != null &&
                  result.regressionDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Regression',
                  value: result.regressionDisplayResult!,
                  keyName: 'regression-alternative-text',
                ),
              if (result.probabilityDisplayResult != null)
                _AlternativeRow(
                  label: 'Probability',
                  value: result.probabilityDisplayResult!,
                  keyName: 'probability-summary-text',
                ),
              if (result.summaryDisplayResult != null &&
                  result.summaryDisplayResult !=
                      result.statisticsDisplayResult &&
                  result.summaryDisplayResult !=
                      result.probabilityDisplayResult)
                _AlternativeRow(
                  label: 'Summary',
                  value: result.summaryDisplayResult!,
                  keyName: 'summary-alternative-text',
                ),
              if (result.unitDisplayResult != null &&
                  result.unitDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Unit',
                  value: result.unitDisplayResult!,
                  keyName: 'unit-alternative-text',
                ),
              if (result.baseUnitDisplayResult != null)
                _AlternativeRow(
                  label: 'Base SI',
                  value: result.baseUnitDisplayResult!,
                  keyName: 'base-unit-alternative-text',
                ),
              if (result.dimensionDisplayResult != null)
                _AlternativeRow(
                  label: 'Dimension',
                  value: result.dimensionDisplayResult!,
                  keyName: 'dimension-alternative-text',
                ),
              if (result.rectangularDisplayResult != null &&
                  result.rectangularDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Rectangular',
                  value: result.rectangularDisplayResult!,
                  keyName: 'rectangular-alternative-text',
                ),
              if (result.vectorDisplayResult != null &&
                  result.vectorDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Vector',
                  value: result.vectorDisplayResult!,
                  keyName: 'vector-alternative-text',
                ),
              if (result.matrixDisplayResult != null &&
                  result.matrixDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Matrix',
                  value: result.matrixDisplayResult!,
                  keyName: 'matrix-alternative-text',
                ),
              if (result.fractionDisplayResult != null &&
                  result.fractionDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Fraction',
                  value: result.fractionDisplayResult!,
                  keyName: 'fraction-alternative-text',
                ),
              if (result.decimalDisplayResult != null &&
                  result.decimalDisplayResult != result.displayResult)
                _AlternativeRow(
                  label: 'Decimal',
                  value: result.decimalDisplayResult!,
                  keyName: 'decimal-alternative-text',
                ),
              if (result.polarDisplayResult != null)
                _AlternativeRow(
                  label: 'Polar',
                  value: result.polarDisplayResult!,
                  keyName: 'polar-alternative-text',
                ),
              if (result.magnitudeDisplayResult != null)
                _AlternativeRow(
                  label: 'Magnitude',
                  value: result.magnitudeDisplayResult!,
                  keyName: 'magnitude-alternative-text',
                ),
              if (result.argumentDisplayResult != null)
                _AlternativeRow(
                  label: 'Argument',
                  value: result.argumentDisplayResult!,
                  keyName: 'argument-alternative-text',
                ),
              if (result.viewportDisplayResult != null)
                _AlternativeRow(
                  label: 'Viewport',
                  value: result.viewportDisplayResult!,
                  keyName: 'viewport-alternative-text',
                ),
            ],
          ],
          if (hasIssue || lastErrorMessage != null) ...<Widget>[
            const SizedBox(height: 18),
            _StatusCard(
              message: statusMessage.isNotEmpty
                  ? statusMessage
                  : lastErrorMessage ?? 'Bir sorun olustu.',
              suggestion: statusHint,
              isError: error != null,
            ),
          ],
        ],
      ),
    );
  }

  bool _hasAlternatives(CalculationResult result) {
    return (result.functionDisplayResult != null &&
            result.functionDisplayResult != result.displayResult) ||
        (result.plotDisplayResult != null &&
            result.plotDisplayResult != result.displayResult) ||
        result.graphDisplayResult != null ||
        result.equationDisplayResult != null ||
        result.solveDisplayResult != null ||
        result.solutionsDisplayResult != null ||
        result.derivativeDisplayResult != null ||
        result.integralDisplayResult != null ||
        result.transformDisplayResult != null ||
        result.traceDisplayResult != null ||
        result.rootDisplayResult != null ||
        result.intersectionDisplayResult != null ||
        (result.symbolicDisplayResult != null &&
            result.symbolicDisplayResult != result.displayResult) ||
        (result.datasetDisplayResult != null &&
            result.datasetDisplayResult != result.displayResult) ||
        result.statisticsDisplayResult != null ||
        result.regressionDisplayResult != null ||
        result.probabilityDisplayResult != null ||
        result.summaryDisplayResult != null ||
        (result.rectangularDisplayResult != null &&
            result.rectangularDisplayResult != result.displayResult) ||
        (result.unitDisplayResult != null &&
            result.unitDisplayResult != result.displayResult) ||
        result.baseUnitDisplayResult != null ||
        result.dimensionDisplayResult != null ||
        (result.vectorDisplayResult != null &&
            result.vectorDisplayResult != result.displayResult) ||
        (result.matrixDisplayResult != null &&
            result.matrixDisplayResult != result.displayResult) ||
        (result.fractionDisplayResult != null &&
            result.fractionDisplayResult != result.displayResult) ||
        (result.decimalDisplayResult != null &&
            result.decimalDisplayResult != result.displayResult) ||
        result.polarDisplayResult != null ||
        result.magnitudeDisplayResult != null ||
        result.argumentDisplayResult != null ||
        result.viewportDisplayResult != null;
  }
}

String _speakableMathText(String value) {
  return value
      .replaceAll('âˆš', 'karekok ')
      .replaceAll('√', 'karekok ')
      .replaceAll('Ï€', 'pi')
      .replaceAll('π', 'pi')
      .replaceAll('∠', ' aci ')
      .replaceAll('^', ' ussu ')
      .replaceAll('/', ' bolu ')
      .replaceAllMapped(RegExp(r'(?<![a-zA-Z])i(?![a-zA-Z])'), (_) => ' i ');
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  const _AlternativeRow({
    required this.label,
    required this.value,
    required this.keyName,
  });

  final String label;
  final String value;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        label: '$label alternative ${_speakableMathText(value)}',
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                key: Key(keyName),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.message,
    required this.suggestion,
    required this.isError,
  });

  final String message;
  final String? suggestion;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = CalculatorLocalization.of(context);

    return Semantics(
      liveRegion: true,
      label: isError
          ? strings.t('semantics.error')
          : strings.t('semantics.warning'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError
              ? colorScheme.errorContainer.withValues(alpha: 0.9)
              : colorScheme.tertiaryContainer.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isError ? 'Issue' : 'Warning',
              key: const Key('status-title'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isError
                    ? colorScheme.onErrorContainer
                    : colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              key: const Key('status-message'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isError
                    ? colorScheme.onErrorContainer
                    : colorScheme.onTertiaryContainer,
              ),
            ),
            if (suggestion != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                suggestion!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isError
                      ? colorScheme.onErrorContainer
                      : colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
