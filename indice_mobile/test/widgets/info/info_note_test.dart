import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/info/info_note.dart';

void main() {
  testWidgets('displays its text next to an info icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InfoNote(text: 'Une précision utile.')),
      ),
    );

    expect(find.text('Une précision utile.'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}
