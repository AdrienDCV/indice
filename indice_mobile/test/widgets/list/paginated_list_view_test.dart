import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/list/paginated_list_view.dart';

Widget listOf({
  required int itemCount,
  VoidCallback? onLoadMore,
  Widget? footer,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PaginatedListView(
        header: const [Text('En-tête')],
        itemCount: itemCount,
        itemBuilder: (_, index) =>
            SizedBox(height: 100, child: Text('Élément $index')),
        footer: footer,
        onLoadMore: onLoadMore ?? () {},
      ),
    ),
  );
}

void main() {
  testWidgets('displays the header, the items and the footer', (tester) async {
    await tester.pumpWidget(listOf(itemCount: 2, footer: const Text('Pied')));

    expect(find.text('En-tête'), findsOneWidget);
    expect(find.text('Élément 0'), findsOneWidget);
    expect(find.text('Élément 1'), findsOneWidget);
    expect(find.text('Pied'), findsOneWidget);
  });

  testWidgets('builds only the items close to the screen', (tester) async {
    await tester.pumpWidget(listOf(itemCount: 1000));

    expect(find.text('Élément 0'), findsOneWidget);
    expect(find.text('Élément 999', skipOffstage: false), findsNothing);
  });

  testWidgets('asks for more items near the end of the list', (tester) async {
    var loadMoreCalls = 0;
    await tester.pumpWidget(
      listOf(itemCount: 50, onLoadMore: () => loadMoreCalls++),
    );

    await tester.drag(find.byType(PaginatedListView), const Offset(0, -100));
    expect(loadMoreCalls, 0);

    await tester.drag(find.byType(PaginatedListView), const Offset(0, -10000));
    expect(loadMoreCalls, greaterThan(0));
  });
}
