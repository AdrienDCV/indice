import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../errors/error_messages.dart';
import '../../injection.dart';
import '../../models/etf/etf_detail_data.dart';
import '../../models/etf/market_data.dart';
import '../../repositories/etf_repository.dart';
import '../../stores/etf/etf_catalog_store.dart';
import '../../stores/etf/etf_detail_state.dart';
import '../../stores/etf/etf_detail_store.dart';
import '../../utils/axis_scale.dart';
import '../../utils/date_formatting.dart';
import '../../utils/number_formatting.dart';
import '../../utils/offline_message.dart';
import '../../utils/page_padding.dart';
import '../../widgets/animation/reveal_on_scroll_column.dart';
import '../../widgets/badge/leverage_badge.dart';
import '../../widgets/banner/offline_bar.dart';
import '../../widgets/banner/stale_data_banner.dart';
import '../../widgets/card/content_card.dart';
import '../../widgets/chart/price_chart.dart';
import '../../widgets/error/error_view.dart';
import '../../widgets/indicator/indicator_tile.dart';
import '../../widgets/indicator/price_range_bar.dart';
import '../../widgets/indicator/returns_table.dart';
import '../../widgets/info/info_note.dart';
import '../../widgets/info/info_tooltip_button.dart';

const _leverageInfo =
    'D’après son nom, cet ETF amplifie (effet de levier) ou inverse les '
    'variations d’un indice, chaque jour. Sur plusieurs jours, sa performance '
    'peut fortement s’écarter de celle de l’indice. Il est conçu pour des '
    'opérations de très court terme.';
const _favouriteErrorMessage = 'Impossible de modifier les favoris.';
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
        appBar: AppBar(
          title: Text(ticker),
          actions: const [_FavouriteButton()],
        ),
        body: BlocListener<EtfDetailStore, EtfDetailState>(
          listenWhen: (previous, current) =>
              current.favouriteErrorKey != null &&
              previous.favouriteErrorKey != current.favouriteErrorKey,
          listener: (context, _) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text(_favouriteErrorMessage))),
          child: BlocBuilder<EtfDetailStore, EtfDetailState>(
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
              final cachedAt = state.cachedAt;
              return Column(
                children: [
                  if (cachedAt != null)
                    OfflineBar(message: offlineMessage(cachedAt)),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: context.read<EtfDetailStore>().refresh,
                      child: _DetailView(etf: etf, cachedAt: cachedAt),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton();

  Future<void> _toggle(BuildContext context, String ticker) async {
    final catalogStore = context.read<EtfCatalogStore>();
    final favourite = await context.read<EtfDetailStore>().toggleFavourite();
    if (favourite != null) catalogStore.favouriteChanged(ticker, favourite);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EtfDetailStore, EtfDetailState>(
      builder: (context, state) {
        final etf = state.etf;
        if (etf == null) return const SizedBox.shrink();
        return IconButton(
          onPressed: state.cachedAt == null
              ? () => _toggle(context, etf.ticker)
              : null,
          icon: Icon(etf.favourite ? Icons.star : Icons.star_border),
        );
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.etf, required this.cachedAt});

  final EtfDetailData etf;
  final DateTime? cachedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marketData = etf.marketData;
    final cachedAt = this.cachedAt;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: pagePadding(context),
      children: [
        Text(etf.name, style: theme.textTheme.headlineSmall),
        Text(
          '${etf.ticker} · ${etf.exchange} · ${etf.currency}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (etf.leveragedOrInverse)
          const Row(
            children: [
              Flexible(child: LeverageBadge()),
              InfoTooltipButton(
                title: 'Effet de levier ou inverse',
                text: _leverageInfo,
              ),
            ],
          ),
        if (marketData != null) ...[
          const SizedBox(height: 12),
          Text(
            '${marketData.lastClose.toFrenchPrice(etf.currency)} au '
            '${marketData.lastCloseDate.toFrenchDate()}',
            style: theme.textTheme.titleLarge,
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () =>
              context.push('/compare/comparison?etfA=${etf.ticker}'),
          child: const Text('Comparer cet ETF'),
        ),
        const SizedBox(height: 16),
        if (marketData == null)
          const Text(_noHistoryMessage)
        else
          _MarketDataView(
            marketData: marketData,
            ticker: etf.ticker,
            currency: etf.currency,
            stale: etf.stale && cachedAt == null,
          ),
        const SizedBox(height: 12),
        const InfoNote(
          text:
              'Les performances passées ne préjugent pas des performances '
              'futures.',
        ),
      ],
    );
  }
}

class _MarketDataView extends StatelessWidget {
  const _MarketDataView({
    required this.marketData,
    required this.ticker,
    required this.currency,
    required this.stale,
  });

  final MarketData marketData;
  final String ticker;
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

    return RevealOnScrollColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (stale)
          StaleDataBanner(
            message:
                'Données au ${marketData.lastCloseDate.toFrenchDate()}, '
                'mise à jour impossible.',
          ),
        ContentCard(
          title: 'Évolution du cours',
          infoText: _priceChartInfo(marketData.historyStartDate),
          child: marketData.pricePoints.length < 2
              ? const Text(_noHistoryMessage)
              : PriceChart(
                  series: [
                    (
                      label: ticker,
                      color: Theme.of(context).colorScheme.primary,
                      points: [
                        for (final point in marketData.pricePoints)
                          (date: point.date, value: point.close),
                      ],
                    ),
                  ],
                  axisLabel: (value, interval) => value.toFrenchDecimal(
                    fractionDigits: fractionDigitsOf(interval),
                  ),
                  tooltipLabel: (index) {
                    final point = marketData.pricePoints[index];
                    return '${point.date.toFrenchDate()}\n'
                        '${point.close.toFrenchPrice(currency)}\n'
                        '${point.changeSinceStart.toFrenchSignedPercent()} '
                        'depuis le '
                        '${marketData.historyStartDate.toFrenchDate()}';
                  },
                ),
        ),
        ContentCard(
          title: 'Rendements',
          infoText: _returnInfo,
          child: Column(
            spacing: 8,
            children: [
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
            ],
          ),
        ),
        ContentCard(
          title: 'Risque',
          child: Column(
            spacing: 8,
            children: [
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
            ],
          ),
        ),
        ContentCard(
          title: 'Fourchette sur 52 semaines',
          infoText: _priceRangeInfo,
          child: fiftyTwoWeekRange == null
              ? const Text('—')
              : PriceRangeBar(
                  low: fiftyTwoWeekRange.low.toFrenchPrice(currency),
                  high: fiftyTwoWeekRange.high.toFrenchPrice(currency),
                  position: fiftyTwoWeekRange.position,
                ),
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
