import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/main.dart';

void main() {
  testWidgets('displays the home page on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const IndiceApp());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
  });
}
