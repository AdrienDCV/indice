import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/field/etf_slot_field.dart';

Future<void> pumpField(
  WidgetTester tester, {
  String? ticker,
  VoidCallback? onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EtfSlotField(
          label: 'Premier ETF',
          color: Colors.green,
          ticker: ticker,
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('invites to choose an etf while the slot is empty', (
    WidgetTester tester,
  ) async {
    await pumpField(tester, onTap: () {});

    expect(find.text('Premier ETF'), findsOneWidget);
    expect(find.text('Choisir un ETF'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('displays the chosen ticker', (WidgetTester tester) async {
    await pumpField(tester, ticker: 'SPY', onTap: () {});

    expect(find.text('SPY'), findsOneWidget);
    expect(find.text('Choisir un ETF'), findsNothing);
  });

  testWidgets('calls onTap when tapped', (WidgetTester tester) async {
    var taps = 0;
    await pumpField(tester, onTap: () => taps++);

    await tester.tap(find.byType(EtfSlotField));

    expect(taps, 1);
  });

  testWidgets('hides the search icon when the slot is locked', (
    WidgetTester tester,
  ) async {
    await pumpField(tester, ticker: 'SPY');

    expect(find.text('SPY'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsNothing);
  });
}
