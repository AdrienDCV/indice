import 'package:flutter/material.dart';

import '../../models/resource/resource_type.dart';
import '../favourite/favourite_icon.dart';
import '../resource_thumbnail.dart';

class ResourceCard extends StatelessWidget {
  const ResourceCard({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
    required this.type,
    required this.isFavourite,
    required this.onTap,
    required this.onFavouriteTap,
  });

  final String title;
  final String description;
  final String duration;
  final ResourceType type;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;

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
                child: ResourceThumbnail(type: type),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
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
                          duration,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onFavouriteTap,
                          tooltip: isFavourite
                              ? 'Retirer des favoris'
                              : 'Ajouter aux favoris',
                          style: IconButton.styleFrom(
                            overlayColor: Colors.transparent,
                          ),
                          icon: FavouriteIcon(
                            isFavourite: isFavourite,
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
