import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/animation/reveal_on_scroll_column.dart';

Future<void> pumpColumn(
  WidgetTester tester,
  Widget Function(Widget column) wrap, {
  required List<Widget> children,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: wrap(RevealOnScrollColumn(children: children))),
      ),
    ),
  );
}

Widget inListView(Widget column) => ListView(children: [column]);

double opacityOf(WidgetTester tester, String text) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
    )
    .opacity;

const tallBlock = SizedBox(height: 2000, child: Text('Haut'));

class RevealedLabel extends StatelessWidget {
  const RevealedLabel({super.key});

  @override
  Widget build(BuildContext context) =>
      Text(RevealOnScrollColumn.isRevealed(context) ? 'Apparu' : 'En attente');
}

void main() {
  testWidgets('hides its children before they appear', (
    WidgetTester tester,
  ) async {
    await pumpColumn(tester, inListView, children: const [Text('Carte')]);

    expect(opacityOf(tester, 'Carte'), 0);
  });

  testWidgets('reveals the visible children', (WidgetTester tester) async {
    await pumpColumn(tester, inListView, children: const [Text('Carte')]);
    await tester.pumpAndSettle();

    expect(opacityOf(tester, 'Carte'), 1);
  });

  testWidgets('reveals the visible children one after the other', (
    WidgetTester tester,
  ) async {
    await pumpColumn(
      tester,
      inListView,
      children: const [Text('Première'), Text('Seconde')],
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));

    expect(opacityOf(tester, 'Première'), greaterThan(0));
    expect(opacityOf(tester, 'Seconde'), 0);

    await tester.pumpAndSettle();

    expect(opacityOf(tester, 'Seconde'), 1);
  });

  testWidgets('waits for a child to be scrolled into view', (
    WidgetTester tester,
  ) async {
    await pumpColumn(
      tester,
      inListView,
      children: const [tallBlock, Text('Bas')],
    );
    await tester.pumpAndSettle();

    expect(opacityOf(tester, 'Bas'), 0);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(opacityOf(tester, 'Bas'), 1);
  });

  testWidgets('tells its children whether they have appeared', (
    WidgetTester tester,
  ) async {
    await pumpColumn(
      tester,
      inListView,
      children: const [tallBlock, RevealedLabel()],
    );
    await tester.pumpAndSettle();

    expect(find.text('En attente'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.text('Apparu'), findsOneWidget);
  });

  testWidgets('reveals its children when it is not in a scrollable', (
    WidgetTester tester,
  ) async {
    await pumpColumn(
      tester,
      (column) => column,
      children: const [Text('Carte')],
    );
    await tester.pumpAndSettle();

    expect(opacityOf(tester, 'Carte'), 1);
  });

  testWidgets('shows its children at once when animations are disabled', (
    WidgetTester tester,
  ) async {
    await pumpColumn(
      tester,
      inListView,
      children: const [tallBlock, Text('Bas')],
      disableAnimations: true,
    );

    expect(opacityOf(tester, 'Haut'), 1);
    expect(opacityOf(tester, 'Bas'), 1);
  });

  testWidgets('lays out its children with the given spacing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RevealOnScrollColumn(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Text('Carte')],
        ),
      ),
    );

    final column = tester.widget<Column>(find.byType(Column));
    expect(column.spacing, 12);
    expect(column.crossAxisAlignment, CrossAxisAlignment.stretch);
  });
}
