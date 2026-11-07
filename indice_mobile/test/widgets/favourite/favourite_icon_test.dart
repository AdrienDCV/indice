import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/favourite/favourite_icon.dart';

Future<void> pumpIcon(
  WidgetTester tester, {
  required bool isFavourite,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp(
        home: Scaffold(
          body: FavouriteIcon(isFavourite: isFavourite, color: Colors.teal),
        ),
      ),
    ),
  );
}

double iconScale(WidgetTester tester) {
  final transition = tester.widget<ScaleTransition>(
    find.descendant(
      of: find.byType(FavouriteIcon),
      matching: find.byType(ScaleTransition),
    ),
  );
  return transition.scale.value;
}

void main() {
  testWidgets('displays a filled star for a favourite', (
    WidgetTester tester,
  ) async {
    await pumpIcon(tester, isFavourite: true);

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNothing);
    expect(tester.widget<Icon>(find.byType(Icon)).color, Colors.teal);
  });

  testWidgets('displays an empty star for a non-favourite', (
    WidgetTester tester,
  ) async {
    await pumpIcon(tester, isFavourite: false);

    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('does not bounce on the first display', (
    WidgetTester tester,
  ) async {
    await pumpIcon(tester, isFavourite: true);
    await tester.pump(const Duration(milliseconds: 150));

    expect(iconScale(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('grows then returns to its size when the state changes', (
    WidgetTester tester,
  ) async {
    await pumpIcon(tester, isFavourite: false);

    await pumpIcon(tester, isFavourite: true);
    await tester.pump(const Duration(milliseconds: 150));

    expect(iconScale(tester), closeTo(1.3, 0.01));
    expect(find.byIcon(Icons.star), findsOneWidget);

    await tester.pumpAndSettle();

    expect(iconScale(tester), 1);
  });

  testWidgets('bounces again when the favourite is removed', (
    WidgetTester tester,
  ) async {
    await pumpIcon(tester, isFavourite: true);

    await pumpIcon(tester, isFavourite: false);
    await tester.pump(const Duration(milliseconds: 75));

    expect(iconScale(tester), greaterThan(1));
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });

  testWidgets('does not bounce when animations are disabled', (
    WidgetTester tester,
  ) async {
    await pumpIcon(tester, isFavourite: false, disableAnimations: true);

    await pumpIcon(tester, isFavourite: true, disableAnimations: true);
    await tester.pump(const Duration(milliseconds: 150));

    expect(iconScale(tester), 1);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
