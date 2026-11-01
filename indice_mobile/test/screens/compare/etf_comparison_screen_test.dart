import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/injection.dart';
import 'package:indice_mobile/models/etf/etf_comparison_data.dart';
import 'package:indice_mobile/repositories/etf_repository.dart';
import 'package:indice_mobile/screens/compare/etf_comparison_screen.dart';
import 'package:indice_mobile/widgets/banner/stale_data_banner.dart';
import 'package:indice_mobile/widgets/chart/price_chart.dart';
import 'package:indice_mobile/widgets/indicator/comparison_table.dart';
import 'package:indice_mobile/widgets/indicator/correlation_gauge.dart';

import '../../fakes/fake_etf_repository.dart';

Future<FakeEtfRepository> pumpScreen(
  WidgetTester tester, {
  String? etfA,
  Future<EtfComparisonData> Function(String etfA, String etfB)? onCompare,
}) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repository = FakeEtfRepository(
    () async => buildCatalog(),
    onCompare: onCompare ?? (_, _) async => buildComparison(),
  );
  getIt.registerSingleton<EtfRepository>(repository);
  addTearDown(getIt.reset);
  await tester.pumpWidget(MaterialApp(home: EtfComparisonScreen(etfA: etfA)));
  await tester.pump();
  return repository;
}

Finder selector(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(SearchAnchor));

bool isEnabled(WidgetTester tester, String label) =>
    tester.widget<SearchAnchor>(selector(label)).enabled;

Finder selectedTicker(String label, String ticker) =>
    find.descendant(of: selector(label), matching: find.text(ticker));

Future<void> openSelector(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String label, String option) async {
  await openSelector(tester, label);
  await tester.enterText(find.byType(TextField).last, option.substring(0, 2));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

const spyOption = 'SPY · SPDR S&P 500 ETF Trust';
const qqqOption = 'QQQ · Invesco QQQ Trust';

void main() {
  testWidgets('starts with two empty selectors from the catalog', (
    WidgetTester tester,
  ) async {
    final repository = await pumpScreen(tester);

    expect(find.widgetWithText(AppBar, 'Comparer deux ETFs'), findsOneWidget);
    expect(isEnabled(tester, 'Premier ETF'), isTrue);
    expect(isEnabled(tester, 'Second ETF'), isTrue);
    expect(find.text('SPY'), findsNothing);
    expect(find.text('Choisis deux ETF pour les comparer.'), findsOneWidget);
    expect(repository.comparedPairs, isEmpty);
  });

  testWidgets('locks the first etf when it comes from a detail', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, etfA: 'SPY');

    expect(selectedTicker('Premier ETF', 'SPY'), findsOneWidget);
    expect(isEnabled(tester, 'Premier ETF'), isFalse);
    expect(isEnabled(tester, 'Second ETF'), isTrue);
  });

  testWidgets('removes the etf chosen on one side from the other side', (
    WidgetTester tester,
  ) async {
    final repository = await pumpScreen(tester, etfA: 'SPY');

    await openSelector(tester, 'Second ETF');
    await tester.enterText(find.byType(TextField).last, 'tr');
    await tester.pumpAndSettle();

    expect(repository.catalogRequests.last.search, 'tr');
    expect(repository.catalogRequests.last.size, 10);
    expect(find.text(qqqOption), findsOneWidget);
    expect(find.text(spyOption), findsNothing);
  });

  testWidgets('does not search an etf before something is typed', (
    WidgetTester tester,
  ) async {
    final repository = await pumpScreen(tester);

    await openSelector(tester, 'Premier ETF');

    expect(repository.catalogRequests, isEmpty);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('shows a progress indicator while comparing', (
    WidgetTester tester,
  ) async {
    final response = Completer<EtfComparisonData>();
    await pumpScreen(tester, etfA: 'SPY', onCompare: (_, _) => response.future);

    await openSelector(tester, 'Second ETF');
    await tester.enterText(find.byType(TextField).last, 'QQ');
    await tester.pumpAndSettle();
    await tester.tap(find.text(qqqOption).last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete(buildComparison());
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('compares the two etfs once both are chosen', (
    WidgetTester tester,
  ) async {
    final repository = await pumpScreen(tester);

    await choose(tester, 'Premier ETF', spyOption);
    await choose(tester, 'Second ETF', qqqOption);

    expect(repository.comparedPairs, [('SPY', 'QQQ')]);
    expect(selectedTicker('Premier ETF', 'SPY'), findsOneWidget);
    expect(selectedTicker('Second ETF', 'QQQ'), findsOneWidget);
    expect(
      find.text('Comparaison du 20/10/2021 au 19/10/2026'),
      findsOneWidget,
    );
    expect(find.byType(PriceChart), findsOneWidget);
    expect(find.byType(ComparisonTable), findsOneWidget);
    expect(find.text('+81,23\u00A0%'), findsOneWidget);
    expect(find.text('-5,00\u00A0%'), findsOneWidget);
    expect(find.text('0,74'), findsNWidgets(2));
    expect(find.text('0,93'), findsOneWidget);
    expect(find.byType(CorrelationGauge), findsOneWidget);
    expect(find.byType(StaleDataBanner), findsNothing);
    expect(
      find.text(
        'Les performances passées ne préjugent pas des performances futures.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('warns about each etf whose data could not be updated', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      etfA: 'SPY',
      onCompare: (_, _) async => buildComparison(
        etfB: buildComparedEtf(
          qqq,
          stale: true,
          fetchedAt: DateTime(2026, 10, 18, 12),
        ),
      ),
    );

    await choose(tester, 'Second ETF', qqqOption);

    expect(
      find.text(
        'Les données de QQQ n’ont pas pu être mises à jour. '
        'Dernière mise à jour le 18/10/2026.',
      ),
      findsOneWidget,
    );
    expect(find.byType(StaleDataBanner), findsOneWidget);
  });

  testWidgets('names the etf without enough history', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      etfA: 'SPY',
      onCompare: (_, _) async =>
          throw apiError('error.etfs.etf-b-insufficient-data'),
    );

    await choose(tester, 'Second ETF', qqqOption);

    expect(
      find.text(
        'Comparaison impossible : QQQ n’a pas assez d’historique '
        '(au moins un an est nécessaire).',
      ),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('offers to retry after an unexpected error', (
    WidgetTester tester,
  ) async {
    final repository = await pumpScreen(
      tester,
      etfA: 'SPY',
      onCompare: (_, _) async => throw apiError('error.unexpected'),
    );
    await choose(tester, 'Second ETF', qqqOption);
    repository.onCompare = (_, _) async => buildComparison();

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(repository.comparedPairs, [('SPY', 'QQQ'), ('SPY', 'QQQ')]);
    expect(find.byType(ComparisonTable), findsOneWidget);
  });

  testWidgets('shows a dash and no gauge without correlation', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      etfA: 'SPY',
      onCompare: (_, _) async => buildComparison(correlation: null),
    );

    await choose(tester, 'Second ETF', qqqOption);

    expect(find.byType(CorrelationGauge), findsNothing);
    expect(find.text('—'), findsOneWidget);
  });
}
