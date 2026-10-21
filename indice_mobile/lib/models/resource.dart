import 'level.dart';

class Resource {
  const Resource({
    required this.title,
    required this.description,
    required this.duration,
    required this.level,
    required this.isFavorite,
  });

  final String title;
  final String description;
  final String duration;
  final Level level;
  final bool isFavorite;
}
