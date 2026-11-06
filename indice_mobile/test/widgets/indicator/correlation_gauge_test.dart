import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/animation/reveal_on_scroll_column.dart';
import 'package:indice_mobile/widgets/indicator/correlation_gauge.dart';

Future<void> pumpGauge(
  WidgetTester tester,
  double value, {
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: CorrelationGauge(value: value)),
      ),
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

  testWidgets('starts the marker at the center of the scale', (
    WidgetTester tester,
  ) async {
    await pumpGauge(tester, -0.5);

    expect(markerX(tester), 0);
  });

  testWidgets('slides the marker to the correlation value', (
    WidgetTester tester,
  ) async {
    await pumpGauge(tester, -0.5);
    await tester.pump(const Duration(milliseconds: 300));
    final halfway = markerX(tester);
    await tester.pumpAndSettle();

    expect(halfway, inExclusiveRange(-0.5, 0));
    expect(markerX(tester), -0.5);
  });

  testWidgets('keeps the marker at the center until its card appears', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              RevealOnScrollColumn(
                children: [
                  SizedBox(height: 2000),
                  CorrelationGauge(value: -0.5),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(markerX(tester), 0);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(markerX(tester), -0.5);
  });

  testWidgets('places the marker at the value when animations are disabled', (
    WidgetTester tester,
  ) async {
    await pumpGauge(tester, -0.5, disableAnimations: true);
    await tester.pump();

    expect(markerX(tester), -0.5);
  });
}
