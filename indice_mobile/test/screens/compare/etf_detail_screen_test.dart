import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/injection.dart';
import 'package:indice_mobile/models/etf/etf_detail_data.dart';
import 'package:indice_mobile/models/etf/price_point_data.dart';
import 'package:indice_mobile/models/etf/returns_data.dart';
import 'package:indice_mobile/repositories/etf_repository.dart';
import 'package:indice_mobile/screens/compare/etf_detail_screen.dart';
import 'package:indice_mobile/widgets/banner/stale_data_banner.dart';
import 'package:indice_mobile/widgets/chart/price_chart.dart';
import 'package:indice_mobile/widgets/indicator/price_range_bar.dart';

import '../../fakes/fake_etf_repository.dart';

Future<FakeEtfRepository> pumpScreen(
  WidgetTester tester,
  Future<EtfDetailData> Function(String ticker) onRetrieveEtf,
) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repository = FakeEtfRepository(
    () async => buildCatalog(),
    onRetrieveEtf: onRetrieveEtf,
  );
  getIt.registerSingleton<EtfRepository>(repository);
  addTearDown(getIt.reset);
  await tester.pumpWidget(
    const MaterialApp(home: EtfDetailScreen(ticker: 'SPY')),
  );
  return repository;
}

Future<void> pumpScreenWith(WidgetTester tester, EtfDetailData etf) async {
  await pumpScreen(tester, (_) async => etf);
  await tester.pump();
}

const noHistoryMessage = 'Aucun historique de cours disponible pour le moment.';

void main() {
  testWidgets('shows a progress indicator while loading', (
    WidgetTester tester,
  ) async {
    final response = Completer<EtfDetailData>();
    final repository = await pumpScreen(tester, (_) => response.future);

    expect(find.widgetWithText(AppBar, 'SPY'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.retrievedTickers, ['SPY']);

    response.complete(buildEtfDetail(marketData: spyMarketData));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the etf, its chart and its indicators', (
    WidgetTester tester,
  ) async {
    await pumpScreenWith(tester, buildEtfDetail(marketData: spyMarketData));

    expect(find.text('SPDR S&P 500 ETF Trust'), findsOneWidget);
    expect(find.text('SPY · NYSE ARCA · USD'), findsOneWidget);
    expect(find.text('766,48 USD au 19/10/2026'), findsOneWidget);
    expect(find.byType(PriceChart), findsOneWidget);
    expect(find.text('+14,20 %'), findsOneWidget);
    expect(find.text('+51,00 %'), findsOneWidget);
    expect(find.text('+88,00 %'), findsOneWidget);
    expect(find.text('+13,50 %'), findsOneWidget);
    expect(find.text('16,10 %'), findsOneWidget);
    expect(find.text('-24,50 %'), findsOneWidget);
    expect(find.text('Du 03/01/2022 au 12/10/2022'), findsOneWidget);
    expect(find.byType(PriceRangeBar), findsOneWidget);
    expect(find.text('Plus bas : 629,28 USD'), findsOneWidget);
    expect(
      find.text(
        'Les performances passées ne préjugent pas des performances futures.',
      ),
      findsOneWidget,
    );
    expect(find.byType(StaleDataBanner), findsNothing);
    expect(find.textContaining('Historique disponible depuis'), findsNothing);
  });

  testWidgets('warns that stale market data could not be updated', (
    WidgetTester tester,
  ) async {
    await pumpScreenWith(
      tester,
      buildEtfDetail(marketData: spyMarketData, stale: true),
    );

    expect(
      find.text('Données au 19/10/2026, mise à jour impossible.'),
      findsOneWidget,
    );
    expect(find.byType(PriceChart), findsOneWidget);
  });

  testWidgets('tells when no price history is available', (
    WidgetTester tester,
  ) async {
    await pumpScreenWith(tester, buildEtfDetail(stale: true));

    expect(find.text(noHistoryMessage), findsOneWidget);
    expect(find.byType(PriceChart), findsNothing);
    expect(find.byType(StaleDataBanner), findsNothing);
    expect(find.text('SPDR S&P 500 ETF Trust'), findsOneWidget);
  });

  testWidgets('replaces the chart when there is a single price', (
    WidgetTester tester,
  ) async {
    await pumpScreenWith(
      tester,
      buildEtfDetail(
        marketData: spyMarketData.copyWith(
          pricePoints: [
            PricePointData(
              date: DateTime(2026, 10, 19),
              close: 766.48,
              changeSinceStart: 0,
            ),
          ],
        ),
      ),
    );

    expect(find.text(noHistoryMessage), findsOneWidget);
    expect(find.byType(PriceChart), findsNothing);
  });

  testWidgets('shows a dash and the history start for missing indicators', (
    WidgetTester tester,
  ) async {
    await pumpScreenWith(
      tester,
      buildEtfDetail(
        marketData: spyMarketData.copyWith(
          returns: const ReturnsData(oneYear: 0.142, threeYears: 0.51),
          maxDrawdown: null,
          fiftyTwoWeekRange: null,
        ),
      ),
    );

    expect(find.text('—'), findsNWidgets(4));
    expect(find.byType(PriceRangeBar), findsNothing);
    expect(
      find.text('Historique disponible depuis le 12/10/2021.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the error and reloads the etf on retry', (
    WidgetTester tester,
  ) async {
    final repository = await pumpScreen(
      tester,
      (_) async => throw apiError('error.etfs.etf-not-found'),
    );
    await tester.pump();

    expect(find.text('Cet ETF est introuvable.'), findsOneWidget);

    repository.onRetrieveEtf = (_) async =>
        buildEtfDetail(marketData: spyMarketData);
    await tester.tap(find.text('Réessayer'));
    await tester.pump();

    expect(repository.retrievedTickers, ['SPY', 'SPY']);
    expect(find.text('Réessayer'), findsNothing);
    expect(find.byType(PriceChart), findsOneWidget);
  });
}
