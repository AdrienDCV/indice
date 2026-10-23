import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../injection.dart';
import '../../models/etf/compared_etf_data.dart';
import '../../models/etf/etf_comparison_data.dart';
import '../../repositories/etf_repository.dart';
import '../../stores/etf/etf_catalog_state.dart';
import '../../stores/etf/etf_catalog_store.dart';
import '../../stores/etf/etf_comparison_state.dart';
import '../../stores/etf/etf_comparison_store.dart';
import '../../utils/date_formatting.dart';
import '../../utils/number_formatting.dart';
import '../../widgets/banner/stale_data_banner.dart';
import '../../widgets/chart/price_chart.dart';
import '../../widgets/error/error_view.dart';
import '../../widgets/field/select_field.dart';
import '../../widgets/indicator/comparison_table.dart';
import '../../widgets/indicator/correlation_gauge.dart';
import '../../widgets/info/info_tooltip_button.dart';

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
            padding: const EdgeInsets.all(16),
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
    final store = context.read<EtfComparisonStore>();
    final colors = _etfColors(context);

    return BlocBuilder<EtfCatalogStore, EtfCatalogState>(
      builder: (context, catalogState) {
        final errorKey = catalogState.errorKey;
        if (errorKey != null) {
          return ErrorView(
            message: errorMessage(errorKey),
            onRetry: context.read<EtfCatalogStore>().init,
          );
        }
        final etfs = catalogState.catalog?.etfs.content;
        final isReady = etfs != null && !catalogState.isLoading;

        List<({String value, String label})> optionsWithout(String? ticker) => [
          for (final etf in etfs ?? const [])
            if (etf.ticker != ticker)
              (value: etf.ticker, label: '${etf.ticker} · ${etf.name}'),
        ];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SelectField<String>(
                  label: 'Premier ETF',
                  leading: _ColorDot(color: colors[0]),
                  options: optionsWithout(state.etfB),
                  value: state.etfA,
                  onChanged: isReady && !isEtfALocked ? store.selectEtfA : null,
                ),
                const _VersusDivider(),
                SelectField<String>(
                  label: 'Second ETF',
                  leading: _ColorDot(color: colors[1]),
                  options: optionsWithout(state.etfA),
                  value: state.etfB,
                  onChanged: isReady ? store.selectEtfB : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VersusDivider extends StatelessWidget {
  const _VersusDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        spacing: 12,
        children: [
          const Expanded(child: Divider()),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                'VS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
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
      return const _Placeholder(
        icon: Icons.compare_arrows,
        message: 'Choisis deux ETF pour les comparer.',
      );
    }
    if (errorKey != null) {
      return _Placeholder(
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

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = this.action;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        spacing: 12,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.primary),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          ?action,
        ],
      ),
    );
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
        _SectionCard(
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
        _SectionCard(
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
        _SectionCard(
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.infoText});

  final String title;
  final Widget child;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final infoText = this.infoText;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (infoText != null)
                  InfoTooltipButton(title: title, text: infoText),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: 1,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
