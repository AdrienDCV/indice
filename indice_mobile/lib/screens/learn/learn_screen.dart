import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../errors/error_messages.dart';
import '../../models/resource/resource_level.dart';
import '../../stores/resource/resource_catalog_state.dart';
import '../../stores/resource/resource_catalog_store.dart';
import '../../utils/offline_message.dart';
import '../../utils/page_padding.dart';
import '../../utils/resource_formatting.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/banner/offline_bar.dart';
import '../../widgets/card/resource_card.dart';
import '../../widgets/error/error_view.dart';
import '../../widgets/filter_toggle.dart';
import '../../widgets/info/info_message.dart';
import '../../widgets/list/load_more_footer.dart';

const _favouriteErrorMessage = 'Impossible de modifier les favoris.';
const _loadMoreDistance = 300.0;

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ResourceCatalogStore, ResourceCatalogState>(
        listenWhen: (previous, current) =>
            current.favouriteErrorKey != null &&
            previous.favouriteErrorKey != current.favouriteErrorKey,
        listener: (context, _) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(_favouriteErrorMessage))),
        child: BlocBuilder<ResourceCatalogStore, ResourceCatalogState>(
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
                    child: _ResourcesView(state: state),
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

class _ResourcesView extends StatefulWidget {
  const _ResourcesView({required this.state});

  final ResourceCatalogState state;

  @override
  State<_ResourcesView> createState() => _ResourcesViewState();
}

class _ResourcesViewState extends State<_ResourcesView> {
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
      context.read<ResourceCatalogStore>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final store = context.read<ResourceCatalogStore>();
    final errorKey = state.errorKey;
    final offline = state.offline;

    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: pagePadding(context),
        children: [
          AppSearchBar(
            hintText: 'Rechercher une vidéo ou un article',
            onChanged: store.searchChanged,
            enabled: !offline,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                FilterToggle(
                  label: 'Favoris',
                  icon: Icons.star,
                  isSelected: state.favouritesOnly,
                  onSelected: offline ? null : store.favouritesOnlyChanged,
                ),
                for (final level in ResourceLevel.values)
                  FilterToggle(
                    label: level.label,
                    isSelected: state.levels.contains(level),
                    onSelected: offline
                        ? null
                        : (isSelected) => store.levelToggled(level, isSelected),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
            if (state.resources.isEmpty && offline)
              const InfoMessage(
                icon: Icons.cloud_off,
                message: _offlineEmptyMessage,
              )
            else if (state.resources.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(_emptyMessage(state), textAlign: TextAlign.center),
              ),
            for (final resource in state.resources)
              ResourceCard(
                title: resource.title,
                description: resource.description,
                duration: resource.durationMinutes.toFrenchDuration(),
                type: resource.type,
                isFavourite: resource.favourite,
                onTap: () => context.push('/resource/${resource.id}'),
                onFavouriteTap: offline
                    ? null
                    : () => store.toggleFavourite(resource.id),
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

const _offlineEmptyMessage =
    'Aucun favori disponible hors ligne. '
    'Épinglez une ressource pour la retrouver sans connexion.';

String _emptyMessage(ResourceCatalogState state) {
  final search = state.search;
  if (search.isNotEmpty) return 'Aucune ressource ne correspond à « $search ».';
  if (state.levels.isNotEmpty) {
    return 'Aucune ressource ne correspond à ces filtres.';
  }
  if (state.favouritesOnly) {
    return 'Aucun favori pour le moment. Touchez le marque-page d’une '
        'ressource pour l’ajouter.';
  }
  return 'Aucune ressource disponible pour le moment.';
}
