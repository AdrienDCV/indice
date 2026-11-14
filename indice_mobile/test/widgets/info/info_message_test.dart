import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/info/info_message.dart';

void main() {
  testWidgets('displays the message under its icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InfoMessage(
            icon: Icons.compare_arrows,
            message: 'Choisissez deux ETF pour les comparer.',
          ),
        ),
      ),
    );

    expect(find.text('Choisissez deux ETF pour les comparer.'), findsOneWidget);
    expect(find.byIcon(Icons.compare_arrows), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('displays its action under the message', (
    WidgetTester tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InfoMessage(
            icon: Icons.info_outline,
            message: 'Une erreur est survenue.',
            action: FilledButton(
              onPressed: () => taps++,
              child: const Text('Réessayer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Réessayer'));

    expect(taps, 1);
  });
}
