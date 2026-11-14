import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../errors/error_messages.dart';
import '../../injection.dart';
import '../../repositories/etf_repository.dart';
import '../../stores/etf/etf_catalog_state.dart';
import '../../stores/etf/etf_catalog_store.dart';
import '../../utils/offline_message.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/banner/offline_bar.dart';
import '../../widgets/card/etf_card.dart';
import '../../widgets/error/error_view.dart';
import '../../widgets/list/list_caption.dart';
import '../../widgets/list/load_more_footer.dart';

const _loadMoreDistance = 300.0;

enum EtfSlot {
  first('Choisir le premier ETF'),
  second('Choisir le second ETF');

  const EtfSlot(this.title);

  final String title;

  String get heroTag => 'etf-picker-$name';
}

String etfPickerLocation(EtfSlot slot, {String? excludedTicker}) => Uri(
  path: '/compare/comparison/etf-picker',
  queryParameters: {'slot': slot.name, 'exclude': ?excludedTicker},
).toString();

class EtfPickerScreen extends StatelessWidget {
  const EtfPickerScreen({super.key, required this.slot, this.excludedTicker});

  final EtfSlot slot;
  final String? excludedTicker;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EtfCatalogStore(getIt<EtfRepository>())..init(),
      child: Scaffold(
        appBar: AppBar(title: Text(slot.title)),
        body: BlocBuilder<EtfCatalogStore, EtfCatalogState>(
          builder: (context, state) => Column(
            children: [
              if (state.offline)
                const OfflineBar(message: offlineFavouritesMessage),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Hero(
                  tag: slot.heroTag,
                  child: AppSearchBar(
                    hintText: 'Rechercher un ETF par nom ou ticker',
                    onChanged: context.read<EtfCatalogStore>().searchChanged,
                    enabled: !state.offline,
                  ),
                ),
              ),
              Expanded(
                child: _EtfPickerList(
                  state: state,
                  excludedTicker: excludedTicker,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtfPickerList extends StatefulWidget {
  const _EtfPickerList({required this.state, required this.excludedTicker});

  final EtfCatalogState state;
  final String? excludedTicker;

  @override
  State<_EtfPickerList> createState() => _EtfPickerListState();
}

class _EtfPickerListState extends State<_EtfPickerList> {
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

    if (errorKey != null) {
      return ErrorView(message: errorMessage(errorKey), onRetry: store.init);
    }
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final etfs = [
      for (final etf in state.etfs)
        if (etf.ticker != widget.excludedTicker) etf,
    ];
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (etfs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(_emptyMessage(state), textAlign: TextAlign.center),
          )
        else ...[
          ListCaption(
            text: state.search.isEmpty ? 'Tous les ETF · par nom' : 'Résultats',
          ),
          for (final etf in etfs)
            EtfCard(
              name: etf.name,
              ticker: etf.ticker,
              exchange: etf.exchange,
              currency: etf.currency,
              isFavourite: etf.favourite,
              isLeveragedOrInverse: etf.leveragedOrInverse,
              onFavouriteTap: null,
              onTap: () => context.pop(etf.ticker),
            ),
        ],
        LoadMoreFooter(
          isLoading: state.isLoadingMore,
          hasError: state.loadMoreErrorKey != null,
          onRetry: store.loadMore,
        ),
      ],
    );
  }
}

String _emptyMessage(EtfCatalogState state) {
  if (state.offline) return 'Aucun favori disponible hors ligne.';
  final search = state.search;
  return search.isEmpty
      ? 'Aucun ETF disponible pour le moment.'
      : 'Aucun ETF ne correspond à « $search ».';
}
