import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/chart/price_chart.dart';

List<({DateTime date, double value})> dailyPoints(int count) => [
  for (var day = 0; day < count; day++)
    (date: DateTime(2022, 1, 3).add(Duration(days: day)), value: 100.0 + day),
];

Future<void> pumpChart(
  WidgetTester tester,
  List<({DateTime date, double value})> points, {
  String Function(int index)? tooltipLabel,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PriceChart(
          points: points,
          tooltipLabel: tooltipLabel ?? (index) => 'Point $index',
        ),
      ),
    ),
  );
}

double initialScale(WidgetTester tester) => tester
    .widget<LineChart>(find.byType(LineChart))
    .transformationConfig
    .transformationController!
    .value
    .getMaxScaleOnAxis();

void main() {
  testWidgets('opens on the last year of a longer history', (
    WidgetTester tester,
  ) async {
    await pumpChart(tester, dailyPoints(504));

    expect(find.byType(LineChart), findsOneWidget);
    expect(initialScale(tester), 2);
  });

  testWidgets('shows a history shorter than a year entirely', (
    WidgetTester tester,
  ) async {
    await pumpChart(tester, dailyPoints(100));

    expect(initialScale(tester), 1);
  });

  testWidgets('labels the first point of each year', (
    WidgetTester tester,
  ) async {
    await pumpChart(tester, dailyPoints(100));

    expect(find.text('2022'), findsOneWidget);
  });

  testWidgets('asks the tooltip label of the point held down', (
    WidgetTester tester,
  ) async {
    final requestedIndexes = <int>[];
    await pumpChart(
      tester,
      dailyPoints(100),
      tooltipLabel: (index) {
        requestedIndexes.add(index);
        return 'Point $index';
      },
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LineChart)),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(requestedIndexes, isNotEmpty);
    expect(requestedIndexes.last, inInclusiveRange(0, 99));

    await gesture.up();
  });
}
