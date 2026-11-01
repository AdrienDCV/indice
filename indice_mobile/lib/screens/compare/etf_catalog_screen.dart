import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../errors/error_messages.dart';
import '../../stores/etf/etf_catalog_state.dart';
import '../../stores/etf/etf_catalog_store.dart';
import '../../utils/date_formatting.dart';
import '../../utils/page_padding.dart';
import '../../widgets/banner/stale_data_banner.dart';
import '../../widgets/card/etf_card.dart';
import '../../widgets/error/error_view.dart';
import '../../widgets/field/search_with_filter.dart';
import '../../widgets/info/info_note.dart';
import '../../widgets/list/load_more_footer.dart';

const _leverageInfo =
    'Certains ETF amplifient (effet de levier) ou inversent les variations '
    'd’un indice : ils sont conçus pour des opérations de très court terme. '
    'Ceux repérés d’après leur nom portent une étiquette.';
const _favouriteErrorMessage = 'Impossible de modifier les favoris.';
const _loadMoreDistance = 300.0;

class EtfCatalogScreen extends StatelessWidget {
  const EtfCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<EtfCatalogStore, EtfCatalogState>(
        listenWhen: (previous, current) =>
            current.favouriteErrorKey != null &&
            previous.favouriteErrorKey != current.favouriteErrorKey,
        listener: (context, _) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(_favouriteErrorMessage))),
        child: BlocBuilder<EtfCatalogStore, EtfCatalogState>(
          builder: (context, state) => _CatalogView(state: state),
        ),
      ),
    );
  }
}

class _CatalogView extends StatefulWidget {
  const _CatalogView({required this.state});

  final EtfCatalogState state;

  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearTheEnd);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreNearTheEnd() {
    if (_scrollController.position.extentAfter < _loadMoreDistance) {
      context.read<EtfCatalogStore>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final store = context.read<EtfCatalogStore>();
    final errorKey = state.errorKey;

    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: pagePadding(context),
        children: [
          SearchWithFilter(
            hintText: 'Rechercher un ETF par nom ou ticker',
            onSearchChanged: store.searchChanged,
            filterLabel: 'Mes favoris',
            filterIcon: Icons.star,
            isFilterSelected: state.favouritesOnly,
            onFilterChanged: store.favouritesOnlyChanged,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.push('/compare/comparison'),
            child: const Text('Comparer deux ETFs'),
          ),
          const SizedBox(height: 8),
          const InfoNote(text: _leverageInfo),
          const SizedBox(height: 12),
          if (errorKey != null)
            ErrorView(message: errorMessage(errorKey), onRetry: store.init)
          else if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (state.stale)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StaleDataBanner(message: _staleMessage(state.fetchedAt)),
              ),
            if (state.etfs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(_emptyMessage(state), textAlign: TextAlign.center),
              ),
            for (final etf in state.etfs)
              EtfCard(
                name: etf.name,
                ticker: etf.ticker,
                exchange: etf.exchange,
                currency: etf.currency,
                isFavourite: etf.favourite,
                isLeveragedOrInverse: etf.leveragedOrInverse,
                onFavouriteTap: () => store.toggleFavourite(etf.ticker),
                onTap: () => context.push('/compare/etf/${etf.ticker}'),
              ),
            LoadMoreFooter(
              isLoading: state.isLoadingMore,
              hasError: state.loadMoreErrorKey != null,
              onRetry: store.loadMore,
            ),
          ],
        ],
      ),
    );
  }
}

String _staleMessage(DateTime? fetchedAt) => fetchedAt == null
    ? 'Le catalogue n’a pas pu être mis à jour.'
    : 'Le catalogue n’a pas pu être mis à jour. '
          'Dernière mise à jour le ${fetchedAt.toFrenchDate()}.';

String _emptyMessage(EtfCatalogState state) {
  final search = state.search;
  return switch ((search.isEmpty, state.favouritesOnly)) {
    (true, false) => 'Aucun ETF disponible pour le moment.',
    (true, true) =>
      'Aucun favori pour le moment. Touchez l’étoile d’un ETF pour l’ajouter.',
    (false, false) => 'Aucun ETF ne correspond à « $search ».',
    (false, true) => 'Aucun favori ne correspond à « $search ».',
  };
}
