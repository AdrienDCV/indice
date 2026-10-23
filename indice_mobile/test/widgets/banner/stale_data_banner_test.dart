import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/banner/stale_data_banner.dart';

void main() {
  testWidgets('displays the message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StaleDataBanner(message: 'Données peut-être pas à jour.'),
        ),
      ),
    );

    expect(find.text('Données peut-être pas à jour.'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}
