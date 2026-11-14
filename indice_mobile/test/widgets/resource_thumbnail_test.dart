import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/resource/resource_type.dart';
import 'package:indice_mobile/widgets/resource_thumbnail.dart';

Future<void> pumpThumbnail(WidgetTester tester, Widget thumbnail) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: 360, height: 200, child: thumbnail)),
    ),
  );
}

void main() {
  testWidgets('shows the icon of its type, without text', (
    WidgetTester tester,
  ) async {
    await pumpThumbnail(
      tester,
      const ResourceThumbnail(type: ResourceType.video),
    );

    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('shows the icon and the message it is given', (
    WidgetTester tester,
  ) async {
    await pumpThumbnail(
      tester,
      const ResourceThumbnail(
        type: ResourceType.video,
        icon: Icons.cloud_off,
        message: 'La vidéo demande une connexion.',
      ),
    );

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline), findsNothing);
    expect(find.text('La vidéo demande une connexion.'), findsOneWidget);
  });
}
