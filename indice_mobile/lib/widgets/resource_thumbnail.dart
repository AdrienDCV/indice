import 'package:flutter/material.dart';

import '../models/resource/resource_type.dart';

/// Miniature provisoire, en attendant les vraies images de l'API.
class ResourceThumbnail extends StatelessWidget {
  const ResourceThumbnail({
    super.key,
    required this.type,
    this.iconSize = 40,
    this.icon,
    this.message,
  });

  final ResourceType type;
  final double iconSize;
  final IconData? icon;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: colorScheme.secondary,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Icon(
                  icon ??
                      (type == ResourceType.video
                          ? Icons.play_circle_outline
                          : Icons.article_outlined),
                  color: colorScheme.onSecondary,
                  size: iconSize,
                ),
                if (message != null)
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.onSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
