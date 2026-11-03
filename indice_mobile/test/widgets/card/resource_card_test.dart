import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/resource/resource_type.dart';
import 'package:indice_mobile/widgets/card/resource_card.dart';

Future<void> pumpCard(
  WidgetTester tester, {
  bool isFavourite = false,
  VoidCallback? onTap,
  VoidCallback? onFavouriteTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ResourceCard(
          title: 'Comprendre les frais',
          description: 'Résumé',
          duration: '7 min',
          type: ResourceType.article,
          isFavourite: isFavourite,
          onTap: onTap ?? () {},
          onFavouriteTap: onFavouriteTap ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('displays the title, the description and the duration', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('Comprendre les frais'), findsOneWidget);
    expect(find.text('Résumé'), findsOneWidget);
    expect(find.text('7 min'), findsOneWidget);
    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
  });

  testWidgets('offers to add a resource that is not a favourite', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester);

    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
    expect(find.byTooltip('Retirer des favoris'), findsNothing);
  });

  testWidgets('offers to remove a resource that is a favourite', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, isFavourite: true);

    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
    expect(find.byTooltip('Ajouter aux favoris'), findsNothing);
  });

  testWidgets('signals a tap on the bookmark without opening the resource', (
    WidgetTester tester,
  ) async {
    var opened = false;
    var favouriteTapped = false;
    await pumpCard(
      tester,
      onTap: () => opened = true,
      onFavouriteTap: () => favouriteTapped = true,
    );

    await tester.tap(find.byTooltip('Ajouter aux favoris'));

    expect(favouriteTapped, isTrue);
    expect(opened, isFalse);
  });
}
