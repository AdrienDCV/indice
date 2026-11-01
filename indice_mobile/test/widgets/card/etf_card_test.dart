import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/badge/leverage_badge.dart';
import 'package:indice_mobile/widgets/card/etf_card.dart';

Future<void> pumpCard(
  WidgetTester tester, {
  bool isFavourite = false,
  bool isLeveragedOrInverse = false,
  VoidCallback? onFavouriteTap,
  VoidCallback? onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EtfCard(
          name: 'SPDR S&P 500 ETF Trust',
          ticker: 'SPY',
          exchange: 'NYSE ARCA',
          currency: 'USD',
          isFavourite: isFavourite,
          isLeveragedOrInverse: isLeveragedOrInverse,
          onFavouriteTap: onFavouriteTap ?? () {},
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('displays the name, ticker, exchange and currency', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('SPDR S&P 500 ETF Trust'), findsOneWidget);
    expect(find.text('SPY'), findsOneWidget);
    expect(find.text('NYSE ARCA · USD'), findsOneWidget);
  });

  testWidgets('calls onTap when tapped', (WidgetTester tester) async {
    var taps = 0;
    await pumpCard(tester, onTap: () => taps++);

    await tester.tap(find.text('SPDR S&P 500 ETF Trust'));

    expect(taps, 1);
  });

  testWidgets('shows an empty star when the etf is not a favourite', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester);

    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('shows a full star when the etf is a favourite', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, isFavourite: true);

    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('toggles the favourite without opening the etf', (
    WidgetTester tester,
  ) async {
    var favouriteTaps = 0;
    var taps = 0;
    await pumpCard(
      tester,
      onFavouriteTap: () => favouriteTaps++,
      onTap: () => taps++,
    );

    await tester.tap(find.byIcon(Icons.star_border));

    expect(favouriteTaps, 1);
    expect(taps, 0);
  });

  testWidgets('flags a leveraged or inverse etf', (WidgetTester tester) async {
    await pumpCard(tester, isLeveragedOrInverse: true);

    expect(find.byType(LeverageBadge), findsOneWidget);
    expect(find.text('Effet de levier ou inverse'), findsOneWidget);
  });

  testWidgets('does not flag an ordinary etf', (WidgetTester tester) async {
    await pumpCard(tester);

    expect(find.byType(LeverageBadge), findsNothing);
  });
}
