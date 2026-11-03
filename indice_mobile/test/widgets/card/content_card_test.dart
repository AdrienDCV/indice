import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/card/content_card.dart';
import 'package:indice_mobile/widgets/info/info_title.dart';

void main() {
  testWidgets('displays its content under an info title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentCard(
            title: 'Corrélation',
            infoText: 'Entre −1 et 1.',
            child: Text('0,93'),
          ),
        ),
      ),
    );

    final title = tester.widget<InfoTitle>(find.byType(InfoTitle));
    expect(title.title, 'Corrélation');
    expect(title.infoText, 'Entre −1 et 1.');
    expect(find.text('0,93'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
  });
}
