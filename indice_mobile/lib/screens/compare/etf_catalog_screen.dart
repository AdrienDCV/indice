import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../errors/error_messages.dart';
import '../../stores/etf/etf_catalog_state.dart';
import '../../stores/etf/etf_catalog_store.dart';
import '../../texts/common_texts.dart';
import '../../texts/compare_texts.dart';
import '../../utils/offline_message.dart';
import '../../utils/page_padding.dart';
import '../../widgets/banner/offline_bar.dart';
import '../../widgets/banner/stale_data_banner.dart';
import '../../widgets/card/etf_card.dart';
import '../../widgets/error/error_view.dart';
import '../../widgets/field/search_with_filter.dart';
import '../../widgets/info/info_message.dart';
import '../../widgets/info/info_note.dart';
import '../../widgets/list/load_more_footer.dart';
import '../../widgets/list/paginated_list_view.dart';

class EtfCatalogScreen extends StatelessWidget {
  const EtfCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<EtfCatalogStore, EtfCatalogState>(
        listenWhen: (previous, current) =>
            current.favouriteErrorKey != null &&
            previous.favouriteErrorKey != current.favouriteErrorKey,
        listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(CommonTexts.favouriteErrorMessage)),
        ),
        child: BlocBuilder<EtfCatalogStore, EtfCatalogState>(
          builder: (context, state) {
            final offline = state.offline;
            return Column(
              children: [
                if (offline)
                  const OfflineBar(message: offlineFavouritesMessage),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: offline,
                    child: _CatalogView(state: state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CatalogView extends StatelessWidget {
  const _CatalogView({required this.state});

  final EtfCatalogState state;

  @override
  Widget build(BuildContext context) {
    final store = context.read<EtfCatalogStore>();
    final errorKey = state.errorKey;
    final offline = state.offline;
    final showsEtfs = errorKey == null && !state.isLoading;

    return RefreshIndicator(
      onRefresh: store.refresh,
      child: PaginatedListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: pagePadding(context),
        onLoadMore: store.loadMore,
        header: [
          SearchWithFilter(
            hintText: 'Rechercher un ETF par nom ou ticker',
            onSearchChanged: store.searchChanged,
            filterLabel: 'Mes favoris',
            filterIcon: Icons.star,
            isFilterSelected: state.favouritesOnly,
            onFilterChanged: store.favouritesOnlyChanged,
            enabled: !offline,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.push('/compare/comparison'),
            child: const Text('Comparer deux ETFs'),
          ),
          const SizedBox(height: 8),
          const InfoNote(text: EtfCatalogTexts.leverageInfo),
          const SizedBox(height: 12),
          if (errorKey != null)
            ErrorView(
              icon: errorIcon(errorKey),
              message: errorMessage(errorKey),
              onRetry: store.init,
            )
          else if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (!offline && state.stale)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StaleDataBanner(
                  message: EtfCatalogTexts.staleMessage(state.fetchedAt),
                ),
              ),
            if (state.etfs.isEmpty && offline)
              const InfoMessage(
                icon: Icons.cloud_off,
                message: EtfCatalogTexts.offlineEmptyMessage,
              )
            else if (state.etfs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(_emptyMessage(state), textAlign: TextAlign.center),
              ),
          ],
        ],
        itemCount: showsEtfs ? state.etfs.length : 0,
        itemBuilder: (context, index) {
          final etf = state.etfs[index];
          return EtfCard(
            name: etf.name,
            ticker: etf.ticker,
            exchange: etf.exchange,
            currency: etf.currency,
            isFavourite: etf.favourite,
            isLeveragedOrInverse: etf.leveragedOrInverse,
            onFavouriteTap: !offline
                ? () => store.toggleFavourite(etf.ticker)
                : null,
            onTap: () => context.push('/compare/etf/${etf.ticker}'),
          );
        },
        footer: showsEtfs
            ? LoadMoreFooter(
                isLoading: state.isLoadingMore,
                hasError: state.loadMoreErrorKey != null,
                onRetry: store.loadMore,
              )
            : null,
      ),
    );
  }
}

String _emptyMessage(EtfCatalogState state) {
  final search = state.search;
  return switch ((search.isEmpty, state.favouritesOnly)) {
    (true, false) => EtfCatalogTexts.noEtfMessage,
    (true, true) => EtfCatalogTexts.noFavouriteMessage,
    (false, false) => EtfCatalogTexts.noEtfMatchingMessage(search),
    (false, true) => EtfCatalogTexts.noFavouriteMatchingMessage(search),
  };
}
