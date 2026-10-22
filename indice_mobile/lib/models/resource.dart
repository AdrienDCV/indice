import 'level.dart';
import 'resource_type.dart';

class Resource {
  const Resource({
    required this.title,
    required this.description,
    required this.content,
    required this.type,
    required this.duration,
    required this.level,
    required this.isFavorite,
    this.videoUrl,
  });

  final String title;
  final String description;

  /// Texte de l'article, ou descriptif de la vidéo.
  final String content;
  final ResourceType type;
  final String duration;
  final Level level;
  final bool isFavorite;

  /// Lien de la vidéo, absent pour un article.
  final String? videoUrl;
}
