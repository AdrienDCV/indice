import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/etf/etf_catalog_data.dart';
import 'package:indice_mobile/models/etf/etf_data.dart';
import 'package:indice_mobile/screens/compare/etf_catalog_screen.dart';
import 'package:indice_mobile/stores/etf/etf_catalog_store.dart';
import 'package:indice_mobile/utils/date_formatting.dart';
import 'package:indice_mobile/widgets/banner/stale_data_banner.dart';
import 'package:indice_mobile/widgets/card/etf_card.dart';

import '../../fakes/fake_etf_repository.dart';

Future<void> pumpScreen(WidgetTester tester, FakeEtfRepository repository) {
  return tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => EtfCatalogStore(repository)..init(),
        child: const EtfCatalogScreen(),
      ),
    ),
  );
}

Future<void> pumpScreenWith(WidgetTester tester, EtfCatalogData catalog) async {
  await pumpScreen(tester, FakeEtfRepository(() async => catalog));
  await tester.pump();
}

List<EtfData> manyEtfs(int count, {int from = 0}) => [
  for (var index = from; index < from + count; index++)
    EtfData(
      ticker: 'ETF$index',
      exchange: 'NYSE',
      name: 'ETF number $index',
      currency: 'USD',
      favourite: false,
      leveragedOrInverse: false,
    ),
];

final catalogList = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(EtfCatalogStore.searchDelay);
  await tester.pump();
}

void main() {
  testWidgets('shows a progress indicator while loading', (
    WidgetTester tester,
  ) async {
    final response = Completer<EtfCatalogData>();
    await pumpScreen(tester, FakeEtfRepository(() => response.future));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(EtfCard), findsNothing);

    response.complete(buildCatalog());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows one card per etf', (WidgetTester tester) async {
    await pumpScreenWith(tester, buildCatalog());

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(EtfCard), findsNWidgets(2));
    expect(find.text('SPDR S&P 500 ETF Trust'), findsOneWidget);
    expect(find.text('Invesco QQQ Trust'), findsOneWidget);
    expect(find.byType(StaleDataBanner), findsNothing);
  });

  testWidgets('warns that a stale catalog was last updated on a given date', (
    WidgetTester tester,
  ) async {
    final fetchedAt = DateTime.utc(2026, 10, 7, 8);
    await pumpScreenWith(
      tester,
      buildCatalog(stale: true, fetchedAt: fetchedAt),
    );

    expect(
      find.text(
        'Le catalogue n’a pas pu être mis à jour. '
        'Dernière mise à jour le ${fetchedAt.toFrenchDate()}.',
      ),
      findsOneWidget,
    );
    expect(find.byType(EtfCard), findsNWidgets(2));
  });

  testWidgets('warns that a stale catalog was never updated', (
    WidgetTester tester,
  ) async {
    await pumpScreenWith(tester, buildCatalog(stale: true));

    expect(
      find.text('Le catalogue n’a pas pu être mis à jour.'),
      findsOneWidget,
    );
  });

  testWidgets('tells when no etf is available', (WidgetTester tester) async {
    await pumpScreenWith(tester, buildCatalog(etfs: const [], stale: true));

    expect(find.text('Aucun ETF disponible pour le moment.'), findsOneWidget);
    expect(find.byType(EtfCard), findsNothing);
  });

  testWidgets('shows the error and reloads the catalog on retry', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(
      () async => throw apiError('error.unexpected'),
    );
    await pumpScreen(tester, repository);
    await tester.pump();

    expect(
      find.text(
        'Une erreur inattendue est survenue. Réessaie dans quelques instants.',
      ),
      findsOneWidget,
    );

    repository.onRetrieveEtfs = () async => buildCatalog();
    await tester.tap(find.text('Réessayer'));
    await tester.pump();

    expect(repository.retrieveEtfsCalls, 2);
    expect(find.text('Réessayer'), findsNothing);
    expect(find.byType(EtfCard), findsNWidgets(2));
  });

  testWidgets('offers to compare two etfs', (WidgetTester tester) async {
    await pumpScreenWith(tester, buildCatalog());

    expect(
      find.widgetWithText(FilledButton, 'Comparer deux ETFs'),
      findsOneWidget,
    );
  });

  testWidgets('offers a search, a favourites filter and a leverage reminder', (
    WidgetTester tester,
  ) async {
    await pumpScreenWith(tester, buildCatalog());

    expect(find.text('Rechercher un ETF par nom ou ticker'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Mes favoris'), findsOneWidget);
    expect(find.textContaining('effet de levier'), findsOneWidget);
  });

  testWidgets('searches the catalog once the user stops typing', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    await pumpScreen(tester, repository);
    await tester.pump();

    await search(tester, 'van');

    expect(repository.catalogRequests.last.search, 'van');
  });

  testWidgets('tells when no etf matches the search', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    await pumpScreen(tester, repository);
    await tester.pump();
    repository.onRetrieveEtfs = () async => buildCatalog(etfs: const []);

    await search(tester, 'van');

    expect(find.text('Aucun ETF ne correspond à « van ».'), findsOneWidget);
  });

  testWidgets('shows only favourites when the filter is selected', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    await pumpScreen(tester, repository);
    await tester.pump();
    repository.onRetrieveEtfs = () async => buildCatalog(etfs: const []);

    await tester.tap(find.text('Mes favoris'));
    await tester.pump();

    expect(repository.catalogRequests.last.favouritesOnly, isTrue);
    expect(
      find.text(
        'Aucun favori pour le moment. Touchez l’étoile d’un ETF pour l’ajouter.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tells when no favourite matches the search', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    await pumpScreen(tester, repository);
    await tester.pump();
    repository.onRetrieveEtfs = () async => buildCatalog(etfs: const []);

    await tester.tap(find.text('Mes favoris'));
    await search(tester, 'van');

    expect(find.text('Aucun favori ne correspond à « van ».'), findsOneWidget);
  });

  testWidgets('pins an etf from its card', (WidgetTester tester) async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    await pumpScreen(tester, repository);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pump();

    expect(repository.addedFavourites, ['SPY']);
    expect(find.byIcon(Icons.star), findsWidgets);
  });

  testWidgets('warns when a favourite cannot be saved', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(
      () async => buildCatalog(),
      onAddFavourite: (_) async => throw apiError('error.unexpected'),
    );
    await pumpScreen(tester, repository);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pump();

    expect(find.text('Impossible de modifier les favoris.'), findsOneWidget);
  });

  testWidgets('loads the next page when scrolling near the end', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(
      () async => buildCatalog(etfs: manyEtfs(50), totalPages: 2),
    );
    await pumpScreen(tester, repository);
    await tester.pump();
    repository.onRetrieveEtfs = () async =>
        buildCatalog(etfs: manyEtfs(1, from: 50), page: 1, totalPages: 2);

    await tester.drag(find.byType(ListView), const Offset(0, -10000));
    await tester.pumpAndSettle();

    expect(repository.catalogRequests.last.page, 1);
    await tester.scrollUntilVisible(
      find.text('ETF number 50'),
      200,
      scrollable: catalogList,
    );
    expect(find.text('ETF number 50'), findsOneWidget);
  });

  testWidgets('keeps the list and offers to retry when the next page fails', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(
      () async => buildCatalog(etfs: manyEtfs(50), totalPages: 2),
    );
    await pumpScreen(tester, repository);
    await tester.pump();
    repository.onRetrieveEtfs = () async => throw apiError('error.unexpected');

    await tester.drag(find.byType(ListView), const Offset(0, -10000));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Impossible de charger la suite.'),
      200,
      scrollable: catalogList,
    );
    expect(find.text('Impossible de charger la suite.'), findsOneWidget);
    expect(find.byType(EtfCard), findsWidgets);

    repository.onRetrieveEtfs = () async =>
        buildCatalog(etfs: manyEtfs(1, from: 50), page: 1, totalPages: 2);
    await tester.ensureVisible(find.text('Réessayer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Impossible de charger la suite.'), findsNothing);
    expect(find.text('ETF number 50', skipOffstage: false), findsOneWidget);
  });

  testWidgets('reloads the catalog when pulled down', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    await pumpScreen(tester, repository);
    await tester.pump();

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repository.retrieveEtfsCalls, 2);
    expect(find.byType(EtfCard), findsNWidgets(2));
  });
}
