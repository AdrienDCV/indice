import 'package:flutter/material.dart';

import '../models/resource_type.dart';

/// Miniature provisoire, en attendant les vraies images de l'API.
class ResourceThumbnail extends StatelessWidget {
  const ResourceThumbnail({super.key, required this.type, this.iconSize = 40});

  final ResourceType type;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: const Color(0xFF61B396),
        child: Center(
          child: Icon(
            type == ResourceType.video
                ? Icons.play_circle_outline
                : Icons.article_outlined,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
