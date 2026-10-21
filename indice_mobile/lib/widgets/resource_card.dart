import 'package:flutter/material.dart';

import '../models/resource.dart';
import 'resource_thumbnail.dart';

class ResourceCard extends StatelessWidget {
  const ResourceCard({
    super.key,
    required this.resource,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final Resource resource;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    // Couleur, bordure et angles viennent du thème (lib/theme/app_theme.dart).
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 90,
                child: ResourceThumbnail(type: resource.type),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          resource.duration,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onFavoriteTap,
                          tooltip: resource.isFavorite
                              ? 'Retirer des favoris'
                              : 'Ajouter aux favoris',
                          icon: Icon(
                            resource.isFavorite
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
