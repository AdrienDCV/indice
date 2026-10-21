import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/level.dart';
import 'package:indice_mobile/models/resource.dart';
import 'package:indice_mobile/models/resource_type.dart';
import 'package:indice_mobile/pages/learn_page.dart';
import 'package:indice_mobile/pages/resource_detail_page.dart';
import 'package:indice_mobile/widgets/filter_toggle.dart';

const resources = [
  Resource(
    title: 'Formation favorite',
    description: '',
    content: '',
    type: ResourceType.video,
    duration: '1 min',
    level: Level.beginner,
    isFavorite: true,
  ),
  Resource(
    title: 'Formation intermédiaire',
    description: '',
    content: '',
    type: ResourceType.video,
    duration: '1 min',
    level: Level.intermediate,
    isFavorite: false,
  ),
];

Future<void> pumpLearnPage(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(home: LearnPage(resources: resources)),
  );
}

Finder filter(String label) => find.widgetWithText(FilterToggle, label);

void main() {
  testWidgets('displays every filter and every resource by default', (
    WidgetTester tester,
  ) async {
    await pumpLearnPage(tester);

    expect(filter('Favoris'), findsOneWidget);
    for (final level in Level.values) {
      expect(filter(level.label), findsOneWidget);
    }
    expect(find.text('Formation favorite'), findsOneWidget);
    expect(find.text('Formation intermédiaire'), findsOneWidget);
  });

  testWidgets('shows only the favorites when the star filter is selected', (
    WidgetTester tester,
  ) async {
    await pumpLearnPage(tester);

    await tester.tap(filter('Favoris'));
    await tester.pump();

    expect(find.text('Formation favorite'), findsOneWidget);
    expect(find.text('Formation intermédiaire'), findsNothing);
  });

  testWidgets('shows only the selected level', (WidgetTester tester) async {
    await pumpLearnPage(tester);

    await tester.tap(filter('Intermédiaire'));
    await tester.pump();

    expect(find.text('Formation favorite'), findsNothing);
    expect(find.text('Formation intermédiaire'), findsOneWidget);
  });

  testWidgets('shows every resource again when a filter is unselected', (
    WidgetTester tester,
  ) async {
    await pumpLearnPage(tester);

    await tester.tap(filter('Intermédiaire'));
    await tester.pump();
    await tester.tap(filter('Intermédiaire'));
    await tester.pump();

    expect(find.text('Formation favorite'), findsOneWidget);
    expect(find.text('Formation intermédiaire'), findsOneWidget);
  });

  testWidgets('shows a message when no resource matches', (
    WidgetTester tester,
  ) async {
    await pumpLearnPage(tester);

    await tester.ensureVisible(filter('Professionnel'));
    await tester.tap(filter('Professionnel'));
    await tester.pump();

    expect(
      find.text('Aucune formation ne correspond à ces filtres.'),
      findsOneWidget,
    );
  });

  testWidgets('opens the detail page when a resource is tapped', (
    WidgetTester tester,
  ) async {
    await pumpLearnPage(tester);

    await tester.tap(find.text('Formation intermédiaire'));
    await tester.pumpAndSettle();

    expect(find.byType(ResourceDetailPage), findsOneWidget);
  });
}
