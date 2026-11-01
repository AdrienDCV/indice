import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../errors/error_messages.dart';
import '../../stores/etf/etf_catalog_state.dart';
import '../../stores/etf/etf_catalog_store.dart';
import '../../utils/date_formatting.dart';
import '../../utils/page_padding.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/banner/stale_data_banner.dart';
import '../../widgets/card/etf_card.dart';
import '../../widgets/error/error_view.dart';
import '../../widgets/filter_toggle.dart';

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
          AppSearchBar(
            hintText: 'Rechercher un ETF par nom ou ticker',
            onChanged: store.searchChanged,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.push('/compare/comparison'),
            child: const Text('Comparer deux ETFs'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterToggle(
              label: 'Mes favoris',
              icon: Icons.star,
              isSelected: state.favouritesOnly,
              onSelected: store.favouritesOnlyChanged,
            ),
          ),
          const SizedBox(height: 8),
          const _LeverageInfo(),
          const SizedBox(height: 12),
          if (errorKey != null)
            ErrorView(message: errorMessage(errorKey), onRetry: store.init)
          else if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (state.stale) _StaleCatalogBanner(fetchedAt: state.fetchedAt),
            if (state.etfs.isEmpty) _EmptyCatalog(state: state),
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
            _CatalogFooter(state: state, onRetry: store.loadMore),
          ],
        ],
      ),
    );
  }
}

class _LeverageInfo extends StatelessWidget {
  const _LeverageInfo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Icon(Icons.info_outline, size: 16, color: color),
        Expanded(
          child: Text(
            _leverageInfo,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _StaleCatalogBanner extends StatelessWidget {
  const _StaleCatalogBanner({required this.fetchedAt});

  final DateTime? fetchedAt;

  @override
  Widget build(BuildContext context) {
    final fetchedAt = this.fetchedAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StaleDataBanner(
        message: fetchedAt == null
            ? 'Le catalogue n’a pas pu être mis à jour.'
            : 'Le catalogue n’a pas pu être mis à jour. '
                  'Dernière mise à jour le ${fetchedAt.toFrenchDate()}.',
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.state});

  final EtfCatalogState state;

  String get _message {
    final search = state.search;
    return switch ((search.isEmpty, state.favouritesOnly)) {
      (true, false) => 'Aucun ETF disponible pour le moment.',
      (true, true) => 'Aucun favori pour le moment. Touchez l’étoile d’un ETF pour l’ajouter.',
      (false, false) => 'Aucun ETF ne correspond à « $search ».',
      (false, true) => 'Aucun favori ne correspond à « $search ».',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Text(_message, textAlign: TextAlign.center),
    );
  }
}

class _CatalogFooter extends StatelessWidget {
  const _CatalogFooter({required this.state, required this.onRetry});

  final EtfCatalogState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreErrorKey != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 8,
          children: [
            const Text('Impossible de charger la suite.'),
            OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
