import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/pages/home_page.dart';
import 'package:indice_mobile/stores/resource/resource_catalog_store.dart';
import 'package:indice_mobile/widgets/card/resource_card.dart';

import '../fakes/fake_resource_repository.dart';

Future<void> pumpHomePage(
  WidgetTester tester,
  FakeResourceRepository repository,
) async {
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => ResourceCatalogStore(repository)..init(),
      child: const MaterialApp(home: HomePage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the latest resources online', (WidgetTester tester) async {
    await pumpHomePage(tester, FakeResourceRepository());

    expect(find.byType(ResourceCard), findsNWidgets(2));
    expect(
      find.text('Hors ligne : retrouvez vos favoris dans Apprendre.'),
      findsNothing,
    );
  });

  testWidgets('points to the favourites in Apprendre offline', (
    WidgetTester tester,
  ) async {
    await pumpHomePage(tester, FakeResourceRepository(catalogOffline: true));

    expect(find.byType(ResourceCard), findsNothing);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(
      find.text('Hors ligne : retrouvez vos favoris dans Apprendre.'),
      findsOneWidget,
    );
  });
}
