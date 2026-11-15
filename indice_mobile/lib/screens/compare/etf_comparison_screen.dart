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

const _noHistoryMessage =
    'Aucun historique de cours disponible pour le moment.';
const _commonPeriodInfo =
    'Les indicateurs sont calculés sur les dates où les deux ETF ont un '
    'cours, pour les comparer sur la même période.';
const _totalReturnInfo =
    'Hausse ou baisse de la valeur de l’ETF entre le premier et le dernier '
    'jour de la période commune aux deux ETF. Les dividendes, la part des '
    'bénéfices versée par les entreprises, sont comptés comme s’ils avaient '
    'été réinvestis dans l’ETF. Par exemple, +20 % : 100 € placés au début '
    'vaudraient 120 € à la fin.';
const _annualizedReturnInfo =
    'Gain ou perte moyen par an sur la période commune aux deux ETF : c’est '
    'le taux qui, appliqué chaque année, donne le même rendement total. Par '
    'exemple, un ETF qui double en 5 ans a un rendement annualisé d’environ '
    '15 %.';
const _volatilityInfo =
    'Mesure à quel point le prix monte et descend d’un jour à l’autre, sur la '
    'période commune aux deux ETF, exprimée pour une année. Plus elle est '
    'élevée, plus le prix bouge fort, à la hausse comme à la baisse.';
const _returnToRiskRatioInfo =
    'Rendement annualisé divisé par la volatilité. Il indique le rendement '
    'obtenu pour chaque point de variation du prix : plus il est élevé, moins '
    'le prix a varié pour obtenir ce rendement. Par exemple, un rendement '
    'annualisé de 10 % avec une volatilité de 20 % donne un ratio de 0,5.';
const _maxDrawdownInfo =
    'Plus forte baisse entre un sommet et le creux qui a suivi. Elle montre '
    'ce qu’un investisseur aurait pu perdre au pire moment.';
const _correlationInfo =
    'Entre −1 et 1, elle indique si les deux ETF évoluent ensemble. Proche de '
    '1 : ils montent et baissent souvent les mêmes jours, donc détenir les '
    'deux réduit peu les variations. Proche de 0 : leurs mouvements sont peu '
    'liés. Proche de −1 : quand l’un monte, l’autre a tendance à baisser.';

List<Color> _etfColors(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return [colorScheme.primary, colorScheme.secondary];
}

String _priceChartInfo(DateTime startDate) =>
    'Cours de clôture ajustés des dividendes réinvestis. Les pourcentages '
    'indiquent la variation de chaque ETF depuis le ${startDate.toFrenchDate()}, '
    'début de la période commune : les deux courbes partent de 0 %.';

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
        message: 'Choisissez deux ETF pour les comparer.',
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
              text: _commonPeriodInfo,
            ),
          ],
        ),
        for (final etf in etfs)
          if (etf.stale) StaleDataBanner(message: _staleMessage(etf)),
        ContentCard(
          title: 'Évolution',
          infoText: _priceChartInfo(commonPeriod.startDate),
          child: etfA.pricePoints.length < 2 || etfB.pricePoints.length < 2
              ? const Text(_noHistoryMessage)
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
                infoText: _totalReturnInfo,
                value: (performance) =>
                    performance.totalReturn.toFrenchSignedPercent(),
                trend: (performance) => performance.totalReturn.trend,
              ),
              ComparisonTableRow(
                label: 'Rendement annualisé',
                infoText: _annualizedReturnInfo,
                value: (performance) =>
                    performance.annualizedReturn.toFrenchSignedPercent(),
                trend: (performance) => performance.annualizedReturn.trend,
              ),
              ComparisonTableRow(
                label: 'Volatilité',
                infoText: _volatilityInfo,
                value: (performance) =>
                    performance.volatility.toFrenchPercent(),
              ),
              ComparisonTableRow(
                label: 'Ratio rendement/risque',
                infoText: _returnToRiskRatioInfo,
                value: (performance) =>
                    performance.returnToRiskRatio.toFrenchDecimal(),
              ),
              ComparisonTableRow(
                label: 'Perte maximale',
                infoText: _maxDrawdownInfo,
                value: (performance) =>
                    performance.maxDrawdown.value.toFrenchSignedPercent(),
              ),
            ],
          ),
        ),
        ContentCard(
          title: 'Corrélation',
          infoText: _correlationInfo,
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
        const InfoNote(
          text:
              'Les performances passées ne préjugent pas des performances '
              'futures.',
        ),
      ],
    );
  }

  String _staleMessage(ComparedEtfData etf) {
    final fetchedAt = etf.fetchedAt;
    final message =
        'Les données de ${etf.ticker} n’ont pas pu être mises à jour.';
    return fetchedAt == null
        ? message
        : '$message Dernière mise à jour le ${fetchedAt.toFrenchDate()}.';
  }

  String _pointLabel(ComparedEtfData etf, int index) {
    final point = etf.pricePoints[index];
    return '${etf.ticker} · ${point.close.toFrenchPrice(etf.currency)} · '
        '${point.changeSinceStart.toFrenchSignedPercent()}';
  }
}
