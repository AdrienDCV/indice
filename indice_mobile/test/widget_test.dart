import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/main.dart';

void main() {
  testWidgets('displays the home page on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const IndiceApp());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Prêt à découvrir\nl’investissement ?'), findsOneWidget);
    expect(find.text('Apprendre'), findsOneWidget);
    expect(
      find.text('Comprendre les bases des ETF et de la finance'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });
}
