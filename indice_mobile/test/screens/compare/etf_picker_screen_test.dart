import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/injection.dart';
import 'package:indice_mobile/models/etf/etf_catalog_data.dart';
import 'package:indice_mobile/repositories/etf_repository.dart';
import 'package:indice_mobile/screens/compare/etf_picker_screen.dart';
import 'package:indice_mobile/stores/etf/etf_catalog_store.dart';
import 'package:indice_mobile/widgets/app_search_bar.dart';
import 'package:indice_mobile/widgets/badge/leverage_badge.dart';
import 'package:indice_mobile/widgets/banner/offline_bar.dart';
import 'package:indice_mobile/widgets/card/etf_card.dart';

import '../../fakes/compare_router.dart';
import '../../fakes/fake_etf_repository.dart';

Future<FakeEtfRepository> pumpScreen(
  WidgetTester tester, {
  EtfSlot slot = EtfSlot.first,
  String? excludedTicker,
  Future<EtfCatalogData> Function()? onRetrieveEtfs,
  bool catalogOffline = false,
}) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repository = FakeEtfRepository(
    onRetrieveEtfs ?? () async => buildCatalog(),
    catalogOffline: catalogOffline,
  );
  getIt.registerSingleton<EtfRepository>(repository);
  addTearDown(getIt.reset);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: buildCompareRouter(
        etfPickerLocation(slot, excludedTicker: excludedTicker),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('lists the whole catalog by name before any search', (
    WidgetTester tester,
  ) async {
    final repository = await pumpScreen(tester);

    expect(
      find.widgetWithText(AppBar, 'Choisir le premier ETF'),
      findsOneWidget,
    );
    expect(find.text('TOUS LES ETF · PAR NOM'), findsOneWidget);
    expect(repository.catalogRequests.single, (
      page: 0,
      size: EtfCatalogStore.pageSize,
      search: '',
      favouritesOnly: false,
    ));
    expect(find.byType(EtfCard), findsNWidgets(2));
  });

  testWidgets('names the slot being chosen', (WidgetTester tester) async {
    await pumpScreen(tester, slot: EtfSlot.second);

    expect(
      find.widgetWithText(AppBar, 'Choisir le second ETF'),
      findsOneWidget,
    );
  });

  testWidgets('searches the catalog with the typed text', (
    WidgetTester tester,
  ) async {
    final repository = await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'tr');
    await tester.pump(EtfCatalogStore.searchDelay);
    await tester.pumpAndSettle();

    expect(repository.catalogRequests.last.search, 'tr');
    expect(find.text('RÉSULTATS'), findsOneWidget);
  });

  testWidgets('says when no etf matches the search', (
    WidgetTester tester,
  ) async {
    final repository = await pumpScreen(tester);
    repository.onRetrieveEtfs = () async => buildCatalog(etfs: const []);

    await tester.enterText(find.byType(TextField), 'zz');
    await tester.pump(EtfCatalogStore.searchDelay);
    await tester.pumpAndSettle();

    expect(find.text('Aucun ETF ne correspond à « zz ».'), findsOneWidget);
  });

  testWidgets('loads the next page of the catalog while scrolling', (
    WidgetTester tester,
  ) async {
    final etfs = [
      for (var index = 0; index < 50; index++)
        spy.copyWith(ticker: 'ETF$index', name: 'ETF $index'),
    ];
    final repository = await pumpScreen(
      tester,
      onRetrieveEtfs: () async => buildCatalog(etfs: etfs, totalPages: 2),
    );
    repository.onRetrieveEtfs = () async =>
        buildCatalog(etfs: [qqq], page: 1, totalPages: 2);

    await tester.drag(find.byType(ListView), const Offset(0, -10000));
    await tester.pumpAndSettle();

    expect(repository.catalogRequests.map((request) => request.page), [0, 1]);
  });

  testWidgets('leaves out the etf chosen on the other side', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, excludedTicker: 'SPY');

    expect(find.text('Invesco QQQ Trust'), findsOneWidget);
    expect(find.text('SPDR S&P 500 ETF Trust'), findsNothing);
  });

  testWidgets('flags leveraged or inverse etfs', (WidgetTester tester) async {
    await pumpScreen(
      tester,
      onRetrieveEtfs: () async =>
          buildCatalog(etfs: [spy.copyWith(leveragedOrInverse: true)]),
    );

    expect(find.byType(LeverageBadge), findsOneWidget);
  });

  testWidgets('shows the favourites without letting them be changed', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      onRetrieveEtfs: () async =>
          buildCatalog(etfs: [spy.copyWith(favourite: true), qqq]),
    );

    final favouriteButtons = find.ancestor(
      of: find.byIcon(Icons.star),
      matching: find.byType(IconButton),
    );
    expect(favouriteButtons, findsOneWidget);
    expect(tester.widget<IconButton>(favouriteButtons).onPressed, isNull);
  });

  testWidgets('lists only the downloaded favourites when offline', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, catalogOffline: true);

    expect(find.byType(OfflineBar), findsOneWidget);
    expect(
      tester.widget<AppSearchBar>(find.byType(AppSearchBar)).enabled,
      isFalse,
    );
  });

  testWidgets('offers to retry when the catalog cannot be loaded', (
    WidgetTester tester,
  ) async {
    final repository = await pumpScreen(
      tester,
      onRetrieveEtfs: () async => throw apiError('error.unexpected'),
    );
    repository.onRetrieveEtfs = () async => buildCatalog();

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.byType(EtfCard), findsNWidgets(2));
  });
}
