import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/injection.dart';
import 'package:indice_mobile/main.dart';
import 'package:indice_mobile/pages/home_page.dart';
import 'package:indice_mobile/repositories/etf_repository.dart';
import 'package:indice_mobile/repositories/resource_repository.dart';
import 'package:indice_mobile/router.dart';
import 'package:indice_mobile/screens/compare/etf_catalog_screen.dart';
import 'package:indice_mobile/screens/compare/etf_comparison_screen.dart';
import 'package:indice_mobile/screens/compare/etf_picker_screen.dart';
import 'package:indice_mobile/widgets/field/etf_slot_field.dart';
import 'package:indice_mobile/screens/compare/etf_detail_screen.dart';
import 'package:indice_mobile/screens/learn/learn_screen.dart';
import 'package:indice_mobile/screens/learn/resource_detail_screen.dart';
import 'package:indice_mobile/widgets/app_search_bar.dart';
import 'package:indice_mobile/widgets/module_button.dart';

import 'fakes/fake_etf_repository.dart';
import 'fakes/fake_resource_repository.dart';

void main() {
  late FakeResourceRepository resourceRepository;

  setUp(() {
    resourceRepository = FakeResourceRepository(
      onRetrieveResource: (_) async => buildResourceDetail(),
    );
    getIt.registerSingleton<ResourceRepository>(resourceRepository);
  });

  tearDown(getIt.reset);

  testWidgets('displays the home page on startup', (WidgetTester tester) async {
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Prêt à découvrir\nl’investissement ?'), findsOneWidget);
    expect(find.widgetWithText(ModuleButton, 'Apprendre'), findsOneWidget);
    expect(
      find.text('Comprendre les bases des ETF et de la finance'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ModuleButton, 'Comparer'), findsOneWidget);
    expect(
      find.text('Apprendre à lire et comparer les indicateurs des ETF'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_forward), findsNWidgets(2));
    expect(find.text('Nouveauté pédagogique :'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(feesArticle.title), findsOneWidget);
    expect(find.text('7\u00A0min'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('opens the learn page from the navigation bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(AppSearchBar), findsOneWidget);
  });

  testWidgets('opens the learn tab from the home learn button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    await tester.tap(find.widgetWithText(ModuleButton, 'Apprendre'));
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
  });

  testWidgets('opens the compare tab from the home compare button', (
    WidgetTester tester,
  ) async {
    getIt.registerSingleton<EtfRepository>(
      FakeEtfRepository(() async => buildCatalog()),
    );
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    await tester.tap(find.widgetWithText(ModuleButton, 'Comparer'));
    await tester.pumpAndSettle();

    expect(find.byType(EtfCatalogScreen), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
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
    expect(find.byType(LearnScreen), findsOneWidget);
  });

  testWidgets('opens a resource detail above the navigation bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprendre les frais'));
    await tester.pumpAndSettle();

    expect(find.byType(ResourceDetailScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('loads the etf catalog once, when the compare tab is opened', (
    WidgetTester tester,
  ) async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    getIt.registerSingleton<EtfRepository>(repository);
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

  testWidgets('opens an empty comparison from the catalog', (
    WidgetTester tester,
  ) async {
    getIt.registerSingleton<EtfRepository>(
      FakeEtfRepository(() async => buildCatalog()),
    );
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    await tester.tap(find.byIcon(Icons.candlestick_chart_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer deux ETFs'));
    await tester.pumpAndSettle();

    expect(find.byType(EtfComparisonScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester
          .widgetList<EtfSlotField>(find.byType(EtfSlotField))
          .map((selector) => selector.onTap != null),
      [true, true],
    );

    await tester.tap(find.text('Premier ETF'));
    await tester.pumpAndSettle();

    expect(find.byType(EtfPickerScreen), findsOneWidget);

    await tester.tap(find.text('SPDR S&P 500 ETF Trust'));
    await tester.pumpAndSettle();

    expect(find.byType(EtfPickerScreen), findsNothing);
    expect(
      find.descendant(
        of: find.byType(EtfSlotField).first,
        matching: find.text('SPY'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('compares an etf from its detail with the etf locked', (
    WidgetTester tester,
  ) async {
    getIt.registerSingleton<EtfRepository>(
      FakeEtfRepository(
        () async => buildCatalog(),
        onRetrieveEtf: (_) async => buildEtfDetail(marketData: spyMarketData),
      ),
    );
    await tester.pumpWidget(IndiceApp(router: buildRouter()));

    await tester.tap(find.byIcon(Icons.candlestick_chart_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SPDR S&P 500 ETF Trust'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer cet ETF'));
    await tester.pumpAndSettle();

    final firstSelector = find.byType(EtfSlotField).first;
    expect(find.byType(EtfComparisonScreen), findsOneWidget);
    expect(
      find.descendant(of: firstSelector, matching: find.text('SPY')),
      findsOneWidget,
    );
    expect(tester.widget<EtfSlotField>(firstSelector).onTap, isNull);
  });
}
