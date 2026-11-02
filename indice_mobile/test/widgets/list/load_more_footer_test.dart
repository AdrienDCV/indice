import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/widgets/list/load_more_footer.dart';

Future<void> pumpFooter(
  WidgetTester tester, {
  bool isLoading = false,
  bool hasError = false,
  VoidCallback? onRetry,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LoadMoreFooter(
          isLoading: isLoading,
          hasError: hasError,
          onRetry: onRetry ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a progress indicator while loading', (
    WidgetTester tester,
  ) async {
    await pumpFooter(tester, isLoading: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('offers to retry after an error', (WidgetTester tester) async {
    var retries = 0;
    await pumpFooter(tester, hasError: true, onRetry: () => retries++);

    expect(find.text('Impossible de charger la suite.'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));

    expect(retries, 1);
  });

  testWidgets('shows nothing otherwise', (WidgetTester tester) async {
    await pumpFooter(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Réessayer'), findsNothing);
  });
}
