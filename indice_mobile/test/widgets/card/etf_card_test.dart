import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/card/etf_card.dart';

Future<void> pumpCard(WidgetTester tester, {VoidCallback? onTap}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EtfCard(
          name: 'SPDR S&P 500 ETF Trust',
          ticker: 'SPY',
          exchange: 'NYSE ARCA',
          currency: 'USD',
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

    await tester.tap(find.byType(EtfCard));

    expect(taps, 1);
  });
}
