import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/list/list_caption.dart';

void main() {
  testWidgets('displays its text in capitals', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ListCaption(text: 'Tous les ETF · par nom')),
      ),
    );

    expect(find.text('TOUS LES ETF · PAR NOM'), findsOneWidget);
  });
}
