import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../injection.dart';
import '../../models/etf/etf_detail_data.dart';
import '../../models/etf/market_data.dart';
import '../../repositories/etf_repository.dart';
import '../../stores/etf/etf_detail_state.dart';
import '../../stores/etf/etf_detail_store.dart';
import '../../utils/date_formatting.dart';
import '../../utils/number_formatting.dart';
import '../../widgets/banner/stale_data_banner.dart';
import '../../widgets/chart/price_chart.dart';
import '../../widgets/error/error_view.dart';
import '../../widgets/indicator/indicator_tile.dart';
import '../../widgets/indicator/price_range_bar.dart';
import '../../widgets/indicator/returns_table.dart';
import '../../widgets/info/info_tooltip_button.dart';

const _noHistoryMessage =
    'Aucun historique de cours disponible pour le moment.';
const _returnInfo = 'Gain ou perte sur la période, dividendes réinvestis.';
const _annualizedReturnInfo =
    'Rendement moyen par an sur 5 ans. Il permet de comparer des durées '
    'différentes.';
const _volatilityInfo =
    'Ampleur habituelle des variations du prix sur un an. Plus elle est '
    'élevée, plus le prix bouge fort, à la hausse comme à la baisse.';
const _maxDrawdownInfo =
    'Plus forte baisse entre un sommet et le creux qui a suivi, sur 5 ans. '
    'Elle montre ce qu’un investisseur aurait pu perdre au pire moment.';
const _priceRangeInfo =
    'Plus bas et plus haut cours de clôture de la dernière année. Le curseur '
    'situe le dernier cours dans cette fourchette.';

String _priceChartInfo(DateTime historyStartDate) =>
    'Cours de clôture de chaque jour de bourse, ajustés des dividendes '
    'réinvestis : les cours passés sont corrigés pour rester comparables à '
    'celui d’aujourd’hui, ils peuvent donc différer du prix affiché à '
    'l’époque. Le pourcentage indique la variation depuis le '
    '${historyStartDate.toFrenchDate()}, début de l’historique.';

class EtfDetailScreen extends StatelessWidget {
  const EtfDetailScreen({super.key, required this.ticker});

  final String ticker;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EtfDetailStore(getIt<EtfRepository>(), ticker)..init(),
      child: Scaffold(
        appBar: AppBar(title: Text(ticker)),
        body: BlocBuilder<EtfDetailStore, EtfDetailState>(
          builder: (context, state) {
            final errorKey = state.errorKey;
            final etf = state.etf;
            if (errorKey != null) {
              return ErrorView(
                message: errorMessage(errorKey),
                onRetry: context.read<EtfDetailStore>().init,
              );
            }
            if (state.isLoading || etf == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _DetailView(etf: etf);
          },
        ),
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.etf});

  final EtfDetailData etf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marketData = etf.marketData;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(etf.name, style: theme.textTheme.headlineSmall),
        Text(
          '${etf.ticker} · ${etf.exchange} · ${etf.currency}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (marketData == null)
          const Text(_noHistoryMessage)
        else
          _MarketDataView(
            marketData: marketData,
            currency: etf.currency,
            stale: etf.stale,
          ),
        const SizedBox(height: 24),
        Text(
          'Les performances passées ne préjugent pas des performances futures.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MarketDataView extends StatelessWidget {
  const _MarketDataView({
    required this.marketData,
    required this.currency,
    required this.stale,
  });

  final MarketData marketData;
  final String currency;
  final bool stale;

  bool get _hasMissingIndicator {
    final returns = marketData.returns;
    return returns.oneYear == null ||
        returns.threeYears == null ||
        returns.fiveYears == null ||
        returns.fiveYearsAnnualized == null ||
        marketData.volatilityOneYear == null ||
        marketData.maxDrawdown == null ||
        marketData.fiftyTwoWeekRange == null;
  }

  @override
  Widget build(BuildContext context) {
    final returns = marketData.returns;
    final maxDrawdown = marketData.maxDrawdown;
    final fiftyTwoWeekRange = marketData.fiftyTwoWeekRange;
    final lastCloseDate = marketData.lastCloseDate.toFrenchDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (stale)
          StaleDataBanner(
            message: 'Données au $lastCloseDate, mise à jour impossible.',
          ),
        Text(
          '${marketData.lastClose.toFrenchPrice(currency)} au $lastCloseDate',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        _SectionTitle(
          title: 'Évolution du cours',
          infoText: _priceChartInfo(marketData.historyStartDate),
        ),
        if (marketData.pricePoints.length < 2)
          const Text(_noHistoryMessage)
        else
          PriceChart(
            points: [
              for (final point in marketData.pricePoints)
                (date: point.date, value: point.close),
            ],
            tooltipLabel: (index) {
              final point = marketData.pricePoints[index];
              return '${point.date.toFrenchDate()}\n'
                  '${point.close.toFrenchPrice(currency)}\n'
                  '${point.changeSinceStart.toFrenchSignedPercent()} depuis le '
                  '${marketData.historyStartDate.toFrenchDate()}';
            },
          ),
        const _SectionTitle(title: 'Rendements', infoText: _returnInfo),
        ReturnsTable(
          returns: [
            (
              period: '1 an',
              value: returns.oneYear.toFrenchSignedPercent(),
              trend: returns.oneYear.trend,
            ),
            (
              period: '3 ans',
              value: returns.threeYears.toFrenchSignedPercent(),
              trend: returns.threeYears.trend,
            ),
            (
              period: '5 ans',
              value: returns.fiveYears.toFrenchSignedPercent(),
              trend: returns.fiveYears.trend,
            ),
          ],
        ),
        IndicatorTile(
          label: 'Annualisé sur 5 ans',
          value: returns.fiveYearsAnnualized.toFrenchSignedPercent(),
          infoText: _annualizedReturnInfo,
          trend: returns.fiveYearsAnnualized.trend,
        ),
        const _SectionTitle(title: 'Risque'),
        IndicatorTile(
          label: 'Volatilité sur 1 an',
          value: marketData.volatilityOneYear.toFrenchPercent(),
          infoText: _volatilityInfo,
        ),
        IndicatorTile(
          label: 'Perte maximale sur 5 ans',
          value: maxDrawdown?.value.toFrenchSignedPercent() ?? '—',
          infoText: _maxDrawdownInfo,
          detail: maxDrawdown == null
              ? null
              : 'Du ${maxDrawdown.peakDate.toFrenchDate()} '
                    'au ${maxDrawdown.troughDate.toFrenchDate()}',
        ),
        const _SectionTitle(
          title: 'Fourchette sur 52 semaines',
          infoText: _priceRangeInfo,
        ),
        if (fiftyTwoWeekRange == null)
          const Text('—')
        else
          PriceRangeBar(
            low: fiftyTwoWeekRange.low.toFrenchPrice(currency),
            high: fiftyTwoWeekRange.high.toFrenchPrice(currency),
            position: fiftyTwoWeekRange.position,
          ),
        if (_hasMissingIndicator)
          Text(
            'Historique disponible depuis le '
            '${marketData.historyStartDate.toFrenchDate()}.',
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.infoText});

  final String title;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final infoText = this.infoText;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Flexible(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (infoText != null) InfoTooltipButton(title: title, text: infoText),
        ],
      ),
    );
  }
}
