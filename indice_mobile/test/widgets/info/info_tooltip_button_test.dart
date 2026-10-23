import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/info/info_tooltip_button.dart';

void main() {
  testWidgets('opens a dialog with the explanation and closes it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InfoTooltipButton(
            title: 'Volatilité sur 1 an',
            text: 'Ampleur habituelle des variations du prix sur un an.',
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InfoTooltipButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Volatilité sur 1 an'), findsOneWidget);
    expect(
      find.text('Ampleur habituelle des variations du prix sur un an.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
