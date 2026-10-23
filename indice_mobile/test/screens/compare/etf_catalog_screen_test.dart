import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/etf/etf_catalog_data.dart';
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

    expect(find.widgetWithText(AppBar, 'Comparer'), findsOneWidget);
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
}
