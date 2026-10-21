import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/level.dart';
import 'package:indice_mobile/models/resource.dart';
import 'package:indice_mobile/models/resource_type.dart';
import 'package:indice_mobile/widgets/resource_card.dart';

Resource buildResource({required bool isFavorite}) {
  return Resource(
    title: 'Comprendre les frais',
    description: 'Résumé',
    content: '',
    type: ResourceType.article,
    duration: '7 min',
    level: Level.beginner,
    isFavorite: isFavorite,
  );
}

Future<void> pumpCard(WidgetTester tester, Resource resource) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ResourceCard(
          resource: resource,
          onTap: () {},
          onFavoriteTap: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('offers to add a resource that is not a favorite', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, buildResource(isFavorite: false));

    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
    expect(find.byTooltip('Retirer des favoris'), findsNothing);
  });

  testWidgets('offers to remove a resource that is a favorite', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, buildResource(isFavorite: true));

    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
    expect(find.byTooltip('Ajouter aux favoris'), findsNothing);
  });
}
