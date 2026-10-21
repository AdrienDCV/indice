import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/data/fake_resources.dart';
import 'package:indice_mobile/main.dart';
import 'package:indice_mobile/pages/home_page.dart';
import 'package:indice_mobile/pages/learn_page.dart';
import 'package:indice_mobile/widgets/app_search_bar.dart';
import 'package:indice_mobile/widgets/module_button.dart';

void main() {
  testWidgets('displays the home page on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const IndiceApp());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Accueil'), findsOneWidget);
    expect(find.text('Prêt à découvrir\nl’investissement ?'), findsOneWidget);
    expect(find.widgetWithText(ModuleButton, 'Apprendre'), findsOneWidget);
    expect(
      find.text('Comprendre les bases des ETF et de la finance'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('Nouveauté pédagogique :'), findsOneWidget);
    expect(find.text(fakeResources.first.title), findsOneWidget);
    expect(find.text(fakeResources.first.duration), findsOneWidget);
    expect(
      find.byIcon(
        fakeResources.first.isFavorite ? Icons.bookmark : Icons.bookmark_border,
      ),
      findsWidgets,
    );
  });

  testWidgets('opens the learn page from the navigation bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IndiceApp());

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(LearnPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(AppSearchBar), findsOneWidget);
  });
}
