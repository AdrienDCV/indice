import '../models/level.dart';
import '../models/resource.dart';

/// Garde les ressources d'un des [levels] choisis (toutes si aucun),
/// et seulement les favoris si [favoritesOnly] est vrai.
List<Resource> filterResources(
  List<Resource> resources, {
  required Set<Level> levels,
  required bool favoritesOnly,
}) {
  return resources
      .where((resource) => levels.isEmpty || levels.contains(resource.level))
      .where((resource) => !favoritesOnly || resource.isFavorite)
      .toList();
}
