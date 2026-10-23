import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/indicator/correlation_gauge.dart';

Future<void> pumpGauge(WidgetTester tester, double value) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: CorrelationGauge(value: value)),
    ),
  );
}

double markerX(WidgetTester tester) =>
    (tester.widget<Align>(find.byType(Align).last).alignment as Alignment).x;

void main() {
  testWidgets('labels both ends and the middle of the scale', (
    WidgetTester tester,
  ) async {
    await pumpGauge(tester, 0.93);

    expect(find.text('−1 · Opposés'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1 · Liés'), findsOneWidget);
  });

  testWidgets('places the marker at the correlation value', (
    WidgetTester tester,
  ) async {
    await pumpGauge(tester, -0.5);

    expect(markerX(tester), -0.5);
  });
}
