import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../errors/error_messages.dart';
import '../../models/resource/resource_level.dart';
import '../../stores/resource/resource_catalog_state.dart';
import '../../stores/resource/resource_catalog_store.dart';
import '../../texts/common_texts.dart';
import '../../texts/learn_texts.dart';
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
import '../../widgets/list/paginated_list_view.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ResourceCatalogStore, ResourceCatalogState>(
        listenWhen: (previous, current) =>
            current.favouriteErrorKey != null &&
            previous.favouriteErrorKey != current.favouriteErrorKey,
        listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(CommonTexts.favouriteErrorMessage)),
        ),
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

class _ResourcesView extends StatelessWidget {
  const _ResourcesView({required this.state});

  final ResourceCatalogState state;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ResourceCatalogStore>();
    final errorKey = state.errorKey;
    final offline = state.offline;
    final showsResources = errorKey == null && !state.isLoading;

    return RefreshIndicator(
      onRefresh: store.refresh,
      child: PaginatedListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: pagePadding(context),
        onLoadMore: store.loadMore,
        header: [
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
          else if (state.resources.isEmpty && offline)
            const InfoMessage(
              icon: Icons.cloud_off,
              message: LearnTexts.offlineEmptyMessage,
            )
          else if (state.resources.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text(_emptyMessage(state), textAlign: TextAlign.center),
            ),
        ],
        itemCount: showsResources ? state.resources.length : 0,
        itemBuilder: (context, index) {
          final resource = state.resources[index];
          return ResourceCard(
            title: resource.title,
            description: resource.description,
            duration: resource.durationMinutes.toFrenchDuration(),
            type: resource.type,
            isFavourite: resource.favourite,
            onTap: () => context.push('/resource/${resource.id}'),
            onFavouriteTap: offline
                ? null
                : () => store.toggleFavourite(resource.id),
          );
        },
        footer: showsResources
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

String _emptyMessage(ResourceCatalogState state) {
  final search = state.search;
  if (search.isNotEmpty) return LearnTexts.noResourceMatchingMessage(search);
  if (state.levels.isNotEmpty) {
    return LearnTexts.noResourceMatchingFiltersMessage;
  }
  if (state.favouritesOnly) {
    return LearnTexts.noFavouriteMessage;
  }
  return LearnTexts.noResourceMessage;
}
