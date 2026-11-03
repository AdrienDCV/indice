import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/info/info_title.dart';
import 'package:indice_mobile/widgets/info/info_tooltip_button.dart';

Future<void> pumpTitle(WidgetTester tester, {String? infoText}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: InfoTitle(title: 'Rendements', infoText: infoText),
      ),
    ),
  );
}

void main() {
  testWidgets('displays the title with its explanation', (
    WidgetTester tester,
  ) async {
    await pumpTitle(tester, infoText: 'Gain ou perte sur la période.');

    expect(find.text('Rendements'), findsOneWidget);
    expect(find.byType(InfoTooltipButton), findsOneWidget);
  });

  testWidgets('displays the title alone without explanation', (
    WidgetTester tester,
  ) async {
    await pumpTitle(tester);

    expect(find.text('Rendements'), findsOneWidget);
    expect(find.byType(InfoTooltipButton), findsNothing);
  });
}
