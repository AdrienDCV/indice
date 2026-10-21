import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/level.dart';
import 'package:indice_mobile/models/resource.dart';
import 'package:indice_mobile/utils/filter_resources.dart';

const beginnerFavorite = Resource(
  title: 'Débutant favori',
  description: '',
  duration: '1 min',
  level: Level.beginner,
  isFavorite: true,
);
const beginner = Resource(
  title: 'Débutant',
  description: '',
  duration: '1 min',
  level: Level.beginner,
  isFavorite: false,
);
const expertFavorite = Resource(
  title: 'Expérimenté favori',
  description: '',
  duration: '1 min',
  level: Level.experienced,
  isFavorite: true,
);
const resources = [beginnerFavorite, beginner, expertFavorite];

void main() {
  test('returns every resource when no filter is selected', () {
    final result = filterResources(resources, levels: {}, favoritesOnly: false);

    expect(result, resources);
  });

  test('keeps only the resources of the selected level', () {
    final result = filterResources(
      resources,
      levels: {Level.beginner},
      favoritesOnly: false,
    );

    expect(result, [beginnerFavorite, beginner]);
  });

  test('keeps the resources of any selected level', () {
    final result = filterResources(
      resources,
      levels: {Level.beginner, Level.experienced},
      favoritesOnly: false,
    );

    expect(result, resources);
  });

  test('keeps only the favorites', () {
    final result = filterResources(resources, levels: {}, favoritesOnly: true);

    expect(result, [beginnerFavorite, expertFavorite]);
  });

  test('combines the level and favorites filters', () {
    final result = filterResources(
      resources,
      levels: {Level.beginner},
      favoritesOnly: true,
    );

    expect(result, [beginnerFavorite]);
  });

  test('returns nothing when no resource matches', () {
    final result = filterResources(
      resources,
      levels: {Level.professional},
      favoritesOnly: false,
    );

    expect(result, isEmpty);
  });
}
