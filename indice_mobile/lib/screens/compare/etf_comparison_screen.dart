import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../errors/error_messages.dart';
import '../../injection.dart';
import '../../models/etf/compared_etf_data.dart';
import '../../models/etf/etf_comparison_data.dart';
import '../../models/etf/performance_data.dart';
import '../../repositories/etf_repository.dart';
import '../../stores/etf/etf_comparison_state.dart';
import '../../stores/etf/etf_comparison_store.dart';
import '../../utils/axis_scale.dart';
import '../../utils/date_formatting.dart';
import '../../utils/number_formatting.dart';
import '../../utils/page_padding.dart';
import '../../widgets/animation/reveal_on_scroll_column.dart';
import '../../widgets/banner/stale_data_banner.dart';
import '../../widgets/card/content_card.dart';
import '../../widgets/chart/price_chart.dart';
import '../../widgets/field/etf_slot_field.dart';
import '../../widgets/indicator/comparison_table.dart';
import '../../widgets/indicator/correlation_gauge.dart';
import '../../widgets/info/info_message.dart';
import '../../widgets/info/info_note.dart';
import '../../widgets/info/info_tooltip_button.dart';
import 'etf_picker_screen.dart';
import '../../texts/compare_texts.dart';

List<Color> _etfColors(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return [colorScheme.primary, colorScheme.secondary];
}

class EtfComparisonScreen extends StatelessWidget {
  const EtfComparisonScreen({super.key, this.etfA});

  final String? etfA;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EtfComparisonStore(getIt<EtfRepository>(), etfA: etfA),
      child: Scaffold(
        appBar: AppBar(title: const Text('Comparer deux ETFs')),
        body: BlocBuilder<EtfComparisonStore, EtfComparisonState>(
          builder: (context, state) => ListView(
            padding: pagePadding(context),
            children: [
              _EtfSelectors(state: state, isEtfALocked: etfA != null),
              const SizedBox(height: 16),
              _ComparisonResult(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtfSelectors extends StatelessWidget {
  const _EtfSelectors({required this.state, required this.isEtfALocked});

  final EtfComparisonState state;
  final bool isEtfALocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.read<EtfComparisonStore>();
    final colors = _etfColors(context);

    return Column(
      spacing: 8,
      children: [
        _EtfSlotSelector(
          label: 'Premier ETF',
          color: colors[0],
          slot: EtfSlot.first,
          ticker: state.etfA,
          excludedTicker: state.etfB,
          onSelected: isEtfALocked ? null : store.selectEtfA,
        ),
        Text(
          'VS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        _EtfSlotSelector(
          label: 'Second ETF',
          color: colors[1],
          slot: EtfSlot.second,
          ticker: state.etfB,
          excludedTicker: state.etfA,
          onSelected: store.selectEtfB,
        ),
      ],
    );
  }
}

class _EtfSlotSelector extends StatelessWidget {
  const _EtfSlotSelector({
    required this.label,
    required this.color,
    required this.slot,
    required this.ticker,
    required this.excludedTicker,
    required this.onSelected,
  });

  final String label;
  final Color color;
  final EtfSlot slot;
  final String? ticker;
  final String? excludedTicker;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final onSelected = this.onSelected;

    return Hero(
      tag: slot.heroTag,
      child: EtfSlotField(
        label: label,
        color: color,
        ticker: ticker,
        onTap: onSelected == null
            ? null
            : () async {
                final picked = await context.push<String>(
                  etfPickerLocation(slot, excludedTicker: excludedTicker),
                );
                if (picked != null) onSelected(picked);
              },
      ),
    );
  }
}

class _ComparisonResult extends StatelessWidget {
  const _ComparisonResult({required this.state});

  final EtfComparisonState state;

  @override
  Widget build(BuildContext context) {
    final etfA = state.etfA;
    final etfB = state.etfB;
    final errorKey = state.errorKey;
    final comparison = state.comparison;

    if (etfA == null || etfB == null) {
      return const InfoMessage(
        icon: Icons.compare_arrows,
        message: EtfComparisonTexts.chooseTwoEtfsMessage,
      );
    }
    if (errorKey != null) {
      return InfoMessage(
        icon: errorKey == networkErrorKey
            ? Icons.cloud_off
            : Icons.info_outline,
        message: errorMessage(errorKey, params: {'etfA': etfA, 'etfB': etfB}),
        action:
            errorKey == unexpectedErrorKey ||
                errorKey == networkErrorKey ||
                errorKey == serverTimeoutErrorKey
            ? FilledButton(
                onPressed: context.read<EtfComparisonStore>().retry,
                child: const Text('Réessayer'),
              )
            : null,
      );
    }
    if (state.isLoading || comparison == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return _ComparisonView(comparison: comparison);
  }
}

class _ComparisonView extends StatelessWidget {
  const _ComparisonView({required this.comparison});

  final EtfComparisonData comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _etfColors(context);
    final etfA = comparison.etfA;
    final etfB = comparison.etfB;
    final etfs = [etfA, etfB];
    final commonPeriod = comparison.commonPeriod;
    final correlation = comparison.correlation;

    return RevealOnScrollColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Row(
          spacing: 8,
          children: [
            Icon(Icons.date_range, size: 20, color: theme.colorScheme.primary),
            Flexible(
              child: Text(
                'Comparaison du ${commonPeriod.startDate.toFrenchDate()} '
                'au ${commonPeriod.endDate.toFrenchDate()}',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const InfoTooltipButton(
              title: 'Période commune',
              text: EtfComparisonTexts.commonPeriodInfo,
            ),
          ],
        ),
        for (final etf in etfs)
          if (etf.stale)
            StaleDataBanner(
              message: EtfComparisonTexts.staleMessage(
                etf.ticker,
                etf.fetchedAt,
              ),
            ),
        ContentCard(
          title: 'Évolution',
          infoText: EtfComparisonTexts.priceChartInfo(commonPeriod.startDate),
          child: etfA.pricePoints.length < 2 || etfB.pricePoints.length < 2
              ? const Text(EtfComparisonTexts.noHistoryMessage)
              : PriceChart(
                  series: [
                    for (final (index, etf) in etfs.indexed)
                      (
                        label: etf.ticker,
                        color: colors[index],
                        points: [
                          for (final point in etf.pricePoints)
                            (date: point.date, value: point.changeSinceStart),
                        ],
                      ),
                  ],
                  axisLabel: (value, interval) => value.toFrenchSignedPercent(
                    fractionDigits: fractionDigitsOf(interval * 100),
                  ),
                  tooltipLabel: (index) => [
                    etfA.pricePoints[index].date.toFrenchDate(),
                    for (final etf in etfs) _pointLabel(etf, index),
                  ].join('\n'),
                ),
        ),
        ContentCard(
          title: 'Indicateurs',
          child: ComparisonTable<PerformanceData>(
            columns: [
              for (final (index, etf) in etfs.indexed)
                (
                  label: etf.ticker,
                  color: colors[index],
                  item: etf.performance,
                ),
            ],
            rows: [
              ComparisonTableRow(
                label: 'Rendement total',
                infoText: EtfComparisonTexts.totalReturnInfo,
                value: (performance) =>
                    performance.totalReturn.toFrenchSignedPercent(),
                trend: (performance) => performance.totalReturn.trend,
              ),
              ComparisonTableRow(
                label: 'Rendement annualisé',
                infoText: EtfComparisonTexts.annualizedReturnInfo,
                value: (performance) =>
                    performance.annualizedReturn.toFrenchSignedPercent(),
                trend: (performance) => performance.annualizedReturn.trend,
              ),
              ComparisonTableRow(
                label: 'Volatilité',
                infoText: EtfComparisonTexts.volatilityInfo,
                value: (performance) =>
                    performance.volatility.toFrenchPercent(),
              ),
              ComparisonTableRow(
                label: 'Ratio rendement/risque',
                infoText: EtfComparisonTexts.returnToRiskRatioInfo,
                value: (performance) =>
                    performance.returnToRiskRatio.toFrenchDecimal(),
              ),
              ComparisonTableRow(
                label: 'Perte maximale',
                infoText: EtfComparisonTexts.maxDrawdownInfo,
                value: (performance) =>
                    performance.maxDrawdown.value.toFrenchSignedPercent(),
              ),
            ],
          ),
        ),
        ContentCard(
          title: 'Corrélation',
          infoText: EtfComparisonTexts.correlationInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                correlation.toFrenchDecimal(),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              if (correlation != null) CorrelationGauge(value: correlation),
            ],
          ),
        ),
        const InfoNote(text: EtfComparisonTexts.pastPerformanceNote),
      ],
    );
  }

  String _pointLabel(ComparedEtfData etf, int index) {
    final point = etf.pricePoints[index];
    return '${etf.ticker} · ${point.close.toFrenchPrice(etf.currency)} · '
        '${point.changeSinceStart.toFrenchSignedPercent()}';
  }
}
