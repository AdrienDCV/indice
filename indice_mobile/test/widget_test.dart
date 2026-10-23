import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/data/fake_resources.dart';
import 'package:indice_mobile/injection.dart';
import 'package:indice_mobile/main.dart';
import 'package:indice_mobile/pages/home_page.dart';
import 'package:indice_mobile/pages/learn_page.dart';
import 'package:indice_mobile/pages/resource_detail_page.dart';
import 'package:indice_mobile/repositories/etf_repository.dart';
import 'package:indice_mobile/router.dart';
import 'package:indice_mobile/screens/compare/etf_catalog_screen.dart';
import 'package:indice_mobile/screens/compare/etf_detail_screen.dart';
import 'package:indice_mobile/widgets/app_search_bar.dart';
import 'package:indice_mobile/widgets/module_button.dart';

import 'fakes/fake_etf_repository.dart';

void main() {
  testWidgets('displays the home page on startup', (WidgetTester tester) async {
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Accueil'), findsOneWidget);
    expect(find.text('Prêt à découvrir\nl’investissement ?'), findsOneWidget);
    expect(find.widgetWithText(ModuleButton, 'Apprendre'), findsOneWidget);
    expect(
      find.text('Comprendre les bases des ETF et de la finance'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('Nouveauté pédagogique :'), findsOneWidget);
    expect(find.text(fakeResources.first.title), findsOneWidget);
    expect(find.text(fakeResources.first.duration), findsOneWidget);
    expect(
      find.byIcon(
        fakeResources.first.isFavorite ? Icons.bookmark : Icons.bookmark_border,
      ),
      findsWidgets,
    );
  });

  testWidgets('opens the learn page from the navigation bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(LearnPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(AppSearchBar), findsOneWidget);
  });

  testWidgets('opens the learn tab from the home learn button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    await tester.tap(find.byType(ModuleButton));
    await tester.pumpAndSettle();

    expect(find.byType(LearnPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });

  testWidgets('fades the new tab in when switching tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    double tabsOpacity() => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.byType(IndexedStack),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    expect(tabsOpacity(), 1);

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pump(); // démarre l'animation
    await tester.pump(const Duration(milliseconds: 100));

    expect(tabsOpacity(), allOf(greaterThan(0), lessThan(1)));

    await tester.pumpAndSettle();

    expect(tabsOpacity(), 1);
    expect(find.byType(LearnPage), findsOneWidget);
  });

  testWidgets('opens a resource detail above the navigation bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprendre les frais'));
    await tester.pumpAndSettle();

    expect(find.byType(ResourceDetailPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('loads the etf catalog once, when the compare tab is opened', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    getIt.registerSingleton<EtfRepository>(repository);
    addTearDown(getIt.reset);
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    expect(repository.retrieveEtfsCalls, 0);

    await tester.tap(find.byIcon(Icons.candlestick_chart_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(EtfCatalogScreen), findsOneWidget);
    expect(find.text('SPDR S&P 500 ETF Trust'), findsOneWidget);
    expect(repository.retrieveEtfsCalls, 1);

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.candlestick_chart_outlined));
    await tester.pumpAndSettle();

    expect(repository.retrieveEtfsCalls, 1);
  });

  testWidgets('opens the detail of an etf from the catalog and comes back', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(
      () async => buildCatalog(),
      onRetrieveEtf: (_) async => buildEtfDetail(marketData: spyMarketData),
    );
    getIt.registerSingleton<EtfRepository>(repository);
    addTearDown(getIt.reset);
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    await tester.tap(find.byIcon(Icons.candlestick_chart_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SPDR S&P 500 ETF Trust'));
    await tester.pumpAndSettle();

    expect(find.byType(EtfDetailScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'SPY'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(repository.retrievedTickers, ['SPY']);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(EtfDetailScreen), findsNothing);
    expect(find.byType(EtfCatalogScreen), findsOneWidget);
  });
}
