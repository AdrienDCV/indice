import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../widgets/resource_thumbnail.dart';
import '../widgets/resource_video_player.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(resource.type.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: resource.videoUrl == null
                ? ResourceThumbnail(type: resource.type, iconSize: 64)
                : ResourceVideoPlayer(url: resource.videoUrl!),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoItem(icon: Icons.schedule, text: resource.duration),
              _InfoItem(
                icon: Icons.signal_cellular_alt,
                text: resource.level.label,
              ),
              _InfoItem(
                icon: resource.isFavorite
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                text: resource.isFavorite ? 'En favori' : 'Pas en favori',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            resource.title,
            style: const TextStyle(
              color: Color(0xFF307A60),
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
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

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF336C4C)),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
