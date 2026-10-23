import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/module_button.dart';

double buttonScale(WidgetTester tester) {
  final transition = tester.widget<ScaleTransition>(
    find.descendant(
      of: find.byType(ModuleButton),
      matching: find.byType(ScaleTransition),
    ),
  );
  return transition.scale.value;
}

void main() {
  testWidgets('shrinks when tapped, then runs the action once back to size', (
    WidgetTester tester,
  ) async {
    var tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModuleButton(
            title: 'Apprendre',
            subtitle: 'Sous-titre',
            onTap: () => tapCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ModuleButton));
    await tester.pump(); // démarre l'animation
    await tester.pump(const Duration(milliseconds: 60));

    expect(buttonScale(tester), lessThan(1));
    expect(tapCount, 0);

    await tester.pumpAndSettle();

    expect(buttonScale(tester), 1);
    expect(tapCount, 1);
  });

  testWidgets('uses the given background color, or primary by default', (
    WidgetTester tester,
  ) async {
    Color? backgroundOf(String title) => tester
        .widget<Material>(
          find
              .descendant(
                of: find.widgetWithText(ModuleButton, title),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ModuleButton(title: 'Apprendre', subtitle: 'A', onTap: () {}),
              ModuleButton(
                title: 'Comparer',
                subtitle: 'B',
                color: const Color(0xFF458C64),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      backgroundOf('Apprendre'),
      Theme.of(tester.element(find.byType(Scaffold))).colorScheme.primary,
    );
    expect(backgroundOf('Comparer'), const Color(0xFF458C64));
  });
}
