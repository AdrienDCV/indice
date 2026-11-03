import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../errors/error_messages.dart';
import '../../injection.dart';
import '../../models/etf/compared_etf_data.dart';
import '../../models/etf/etf_comparison_data.dart';
import '../../repositories/etf_repository.dart';
import '../../stores/etf/etf_comparison_state.dart';
import '../../stores/etf/etf_comparison_store.dart';
import '../../utils/date_formatting.dart';
import '../../utils/number_formatting.dart';
import '../../utils/page_padding.dart';
import '../../widgets/banner/stale_data_banner.dart';
import '../../widgets/card/content_card.dart';
import '../../widgets/chart/price_chart.dart';
import '../../widgets/field/etf_slot_field.dart';
import '../../widgets/indicator/comparison_table.dart';
import '../../widgets/indicator/correlation_gauge.dart';
import '../../widgets/info/info_message.dart';
import '../../widgets/info/info_tooltip_button.dart';
import 'etf_picker_screen.dart';

const _noHistoryMessage =
    'Aucun historique de cours disponible pour le moment.';
const _commonPeriodInfo =
    'Les indicateurs sont calculés sur les dates où les deux ETF ont un '
    'cours, pour les comparer sur la même période.';
const _totalReturnInfo =
    'Gain ou perte sur toute la période, dividendes réinvestis.';
const _annualizedReturnInfo =
    'Rendement moyen par an sur la période. Il permet de comparer des durées '
    'différentes.';
const _volatilityInfo =
    'Ampleur habituelle des variations du prix sur un an. Plus elle est '
    'élevée, plus le prix bouge fort, à la hausse comme à la baisse.';
const _returnToRiskRatioInfo =
    'Rendement obtenu pour une unité de volatilité. Il ne dit pas quel ETF '
    'choisir : chacun juge selon sa tolérance aux variations.';
const _maxDrawdownInfo =
    'Plus forte baisse entre un sommet et le creux qui a suivi. Elle montre '
    'ce qu’un investisseur aurait pu perdre au pire moment.';
const _correlationInfo =
    'Entre −1 et 1. Proche de 1 : les deux ETF montent et baissent souvent '
    'les mêmes jours, et se protègent peu l’un l’autre. Proche de 0 : leurs '
    'mouvements sont peu liés.';

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
        message: 'Choisis deux ETF pour les comparer.',
      );
    }
    if (errorKey != null) {
      return InfoMessage(
        icon: Icons.info_outline,
        message: errorMessage(errorKey, params: {'etfA': etfA, 'etfB': etfB}),
        action: errorKey == unexpectedErrorKey
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

    return Column(
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
                  axisLabel: (value) =>
                      value.toFrenchSignedPercent(fractionDigits: 0),
                  tooltipLabel: (index) => [
                    etfA.pricePoints[index].date.toFrenchDate(),
                    for (final etf in etfs) _pointLabel(etf, index),
                  ].join('\n'),
                ),
        ),
        ContentCard(
          title: 'Indicateurs',
          child: ComparisonTable(
            columns: [
              for (final (index, etf) in etfs.indexed)
                (label: etf.ticker, color: colors[index]),
            ],
            rows: [
              (
                label: 'Rendement total',
                infoText: _totalReturnInfo,
                values: [
                  for (final etf in etfs)
                    (
                      text: etf.performance.totalReturn.toFrenchSignedPercent(),
                      trend: etf.performance.totalReturn.trend,
                    ),
                ],
              ),
              (
                label: 'Rendement annualisé',
                infoText: _annualizedReturnInfo,
                values: [
                  for (final etf in etfs)
                    (
                      text: etf.performance.annualizedReturn
                          .toFrenchSignedPercent(),
                      trend: etf.performance.annualizedReturn.trend,
                    ),
                ],
              ),
              (
                label: 'Volatilité',
                infoText: _volatilityInfo,
                values: [
                  for (final etf in etfs)
                    (
                      text: etf.performance.volatility.toFrenchPercent(),
                      trend: ValueTrend.neutral,
                    ),
                ],
              ),
              (
                label: 'Ratio rendement/risque',
                infoText: _returnToRiskRatioInfo,
                values: [
                  for (final etf in etfs)
                    (
                      text: etf.performance.returnToRiskRatio.toFrenchDecimal(),
                      trend: ValueTrend.neutral,
                    ),
                ],
              ),
              (
                label: 'Perte maximale',
                infoText: _maxDrawdownInfo,
                values: [
                  for (final etf in etfs)
                    (
                      text: etf.performance.maxDrawdown.value
                          .toFrenchSignedPercent(),
                      trend: ValueTrend.neutral,
                    ),
                ],
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            Expanded(
              child: Text(
                'Les performances passées ne préjugent pas des performances '
                'futures.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
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
