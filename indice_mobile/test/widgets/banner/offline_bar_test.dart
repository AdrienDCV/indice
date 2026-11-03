import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/banner/offline_bar.dart';

void main() {
  testWidgets('displays its message next to an offline icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OfflineBar(message: 'Hors ligne')),
      ),
    );

    expect(find.text('Hors ligne'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });
}
