import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/error_messages.dart';
import '../../injection.dart';
import '../../models/resource/media_type.dart';
import '../../models/resource/resource_detail_data.dart';
import '../../repositories/resource_repository.dart';
import '../../stores/resource/resource_catalog_store.dart';
import '../../stores/resource/resource_detail_state.dart';
import '../../stores/resource/resource_detail_store.dart';
import '../../utils/resource_formatting.dart';
import '../../widgets/error/error_view.dart';
import '../../widgets/info/info_item.dart';
import '../../widgets/resource_thumbnail.dart';
import '../../widgets/video_player.dart';

const _favouriteErrorMessage = 'Impossible de modifier les favoris.';

class ResourceDetailScreen extends StatelessWidget {
  const ResourceDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ResourceDetailStore(getIt<ResourceRepository>(), id)..init(),
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ResourceDetailStore, ResourceDetailState>(
            builder: (context, state) => Text(state.resource?.type.label ?? ''),
          ),
          actions: const [_FavouriteButton()],
        ),
        body: BlocListener<ResourceDetailStore, ResourceDetailState>(
          listenWhen: (previous, current) =>
              current.favouriteErrorKey != null &&
              previous.favouriteErrorKey != current.favouriteErrorKey,
          listener: (context, _) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text(_favouriteErrorMessage))),
          child: BlocBuilder<ResourceDetailStore, ResourceDetailState>(
            builder: (context, state) {
              final errorKey = state.errorKey;
              final resource = state.resource;
              if (errorKey != null) {
                return ErrorView(
                  message: errorMessage(errorKey),
                  onRetry: context.read<ResourceDetailStore>().init,
                );
              }
              if (state.isLoading || resource == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return _DetailView(resource: resource);
            },
          ),
        ),
      ),
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton();

  Future<void> _toggle(BuildContext context, String id) async {
    final catalogStore = context.read<ResourceCatalogStore>();
    final favourite = await context
        .read<ResourceDetailStore>()
        .toggleFavourite();
    if (favourite != null) catalogStore.favouriteChanged(id, favourite);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResourceDetailStore, ResourceDetailState>(
      builder: (context, state) {
        final resource = state.resource;
        if (resource == null) return const SizedBox.shrink();
        return IconButton(
          onPressed: () => _toggle(context, resource.id),
          tooltip: resource.favourite
              ? 'Retirer des favoris'
              : 'Ajouter aux favoris',
          icon: Icon(
            resource.favourite ? Icons.bookmark : Icons.bookmark_border,
          ),
        );
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.resource});

  final ResourceDetailData resource;

  @override
  Widget build(BuildContext context) {
    final media = resource.media;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: media != null && media.type == MediaType.video
                ? VideoPlayer(url: media.url)
                : ResourceThumbnail(type: resource.type, iconSize: 64),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: InfoItem(
                  icon: Icons.schedule,
                  text: resource.durationMinutes.toFrenchDuration(),
                ),
              ),
              Flexible(
                child: InfoItem(
                  icon: Icons.signal_cellular_alt,
                  text: resource.level.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            resource.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            resource.content,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
