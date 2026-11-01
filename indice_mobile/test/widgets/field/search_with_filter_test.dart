import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/field/search_with_filter.dart';

Future<void> pumpField(
  WidgetTester tester, {
  ValueChanged<String>? onSearchChanged,
  bool isFilterSelected = false,
  ValueChanged<bool>? onFilterChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SearchWithFilter(
          hintText: 'Rechercher',
          onSearchChanged: onSearchChanged ?? (_) {},
          filterLabel: 'Mes favoris',
          filterIcon: Icons.star,
          isFilterSelected: isFilterSelected,
          onFilterChanged: onFilterChanged ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('reports the typed search', (WidgetTester tester) async {
    final searches = <String>[];
    await pumpField(tester, onSearchChanged: searches.add);

    await tester.enterText(find.byType(TextField), 'van');

    expect(searches, ['van']);
  });

  testWidgets('reports the filter selection', (WidgetTester tester) async {
    final selections = <bool>[];
    await pumpField(tester, onFilterChanged: selections.add);

    await tester.tap(find.text('Mes favoris'));

    expect(selections, [true]);
  });

  testWidgets('shows the filter as selected', (WidgetTester tester) async {
    await pumpField(tester, isFilterSelected: true);

    expect(tester.widget<FilterChip>(find.byType(FilterChip)).selected, isTrue);
  });
}
