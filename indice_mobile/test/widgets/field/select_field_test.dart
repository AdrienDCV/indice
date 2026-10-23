import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/field/select_field.dart';

Future<void> pumpField(
  WidgetTester tester, {
  String? value,
  ValueChanged<String>? onChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectField<String>(
          label: 'Premier ETF',
          options: const [
            (value: 'SPY', label: 'SPY · SPDR S&P 500 ETF Trust'),
            (value: 'QQQ', label: 'QQQ · Invesco QQQ Trust'),
          ],
          value: value,
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows its label and the selected option', (
    WidgetTester tester,
  ) async {
    await pumpField(tester, value: 'QQQ', onChanged: (_) {});

    expect(find.text('Premier ETF'), findsOneWidget);
    expect(find.text('QQQ · Invesco QQQ Trust'), findsOneWidget);
  });

  testWidgets('reports the chosen option', (WidgetTester tester) async {
    final chosen = <String>[];
    await pumpField(tester, onChanged: chosen.add);

    await tester.tap(find.byType(SelectField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SPY · SPDR S&P 500 ETF Trust').last);
    await tester.pumpAndSettle();

    expect(chosen, ['SPY']);
  });

  testWidgets('cannot be opened when disabled', (WidgetTester tester) async {
    await pumpField(tester, value: 'SPY');

    await tester.tap(find.byType(SelectField<String>));
    await tester.pumpAndSettle();

    expect(find.text('QQQ · Invesco QQQ Trust'), findsNothing);
    expect(find.text('SPY · SPDR S&P 500 ETF Trust'), findsOneWidget);
  });

  testWidgets('shows nothing selected for a value missing from the options', (
    WidgetTester tester,
  ) async {
    await pumpField(tester, value: 'VGK', onChanged: (_) {});

    expect(find.textContaining('·'), findsNothing);
  });
}
