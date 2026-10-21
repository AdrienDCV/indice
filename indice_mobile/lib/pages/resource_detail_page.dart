import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../widgets/info/info_item.dart';
import '../widgets/resource_thumbnail.dart';
import '../widgets/video_player.dart';

class ResourceDetailPage extends StatelessWidget {
  const ResourceDetailPage({super.key, required this.resource});

  final Resource resource;

  static Route<void> route(Resource resource) {
    return MaterialPageRoute(
      builder: (context) => ResourceDetailPage(resource: resource),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoUrl = resource.videoUrl;

    return Scaffold(
      appBar: AppBar(title: Text(resource.type.label)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: videoUrl == null
                  ? ResourceThumbnail(type: resource.type, iconSize: 64)
                  : VideoPlayer(url: videoUrl),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: InfoItem(
                    icon: Icons.schedule,
                    text: resource.duration,
                  ),
                ),
                Flexible(
                  child: InfoItem(
                    icon: Icons.signal_cellular_alt,
                    text: resource.level.label,
                  ),
                ),
                Flexible(
                  child: InfoItem(
                    icon: resource.isFavorite
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    text: resource.isFavorite ? 'En favori' : 'Pas en favori',
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
      ),
    );
  }
}
