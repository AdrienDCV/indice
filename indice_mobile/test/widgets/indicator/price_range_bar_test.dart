import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/indicator/price_range_bar.dart';

void main() {
  testWidgets('displays the lowest and highest prices', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PriceRangeBar(
            low: '629,28 USD',
            high: '781,62 USD',
            position: 0.9,
          ),
        ),
      ),
    );

    expect(find.text('Plus bas : 629,28 USD'), findsOneWidget);
    expect(find.text('Plus haut : 781,62 USD'), findsOneWidget);
  });
}
