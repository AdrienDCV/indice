import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/error/error_view.dart';

void main() {
  testWidgets('displays the message and calls onRetry on retry', (
    WidgetTester tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'Cet ETF est introuvable.',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text('Cet ETF est introuvable.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.tap(find.text('Réessayer'));

    expect(retries, 1);
  });

  testWidgets('displays the icon it is given', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            icon: Icons.cloud_off,
            message: 'Connexion impossible pour le moment.',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });
}
