import 'package:flutter/material.dart';

class ResourceCard extends StatelessWidget {
  const ResourceCard({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final String title;
  final String description;
  final String duration;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 110,
                height: 90,
                color: const Color(0xFF61B396),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 40,
                ),
              ),
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
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
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
                        onPressed: onFavoriteTap,
                        tooltip: 'Ajouter aux favoris',
                        icon: Icon(
                          isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          color: const Color(0xFF336C4C),
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
    );
  }
}
