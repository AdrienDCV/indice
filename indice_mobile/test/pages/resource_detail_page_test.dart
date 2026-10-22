import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/level.dart';
import 'package:indice_mobile/models/resource.dart';
import 'package:indice_mobile/models/resource_type.dart';
import 'package:indice_mobile/pages/resource_detail_page.dart';
import 'package:indice_mobile/widgets/resource_thumbnail.dart';
import 'package:indice_mobile/widgets/video_player.dart';

const article = Resource(
  title: 'Comprendre les frais',
  description: 'Résumé',
  content: 'Texte complet de l’article.',
  type: ResourceType.article,
  duration: '7 min',
  level: Level.intermediate,
  isFavorite: true,
);

const video = Resource(
  title: 'Qu’est-ce qu’un ETF ?',
  description: 'Résumé',
  content: 'Descriptif de la vidéo.',
  type: ResourceType.video,
  duration: '5 min',
  level: Level.beginner,
  isFavorite: false,
);

Future<void> pumpDetailPage(WidgetTester tester, Resource resource) {
  // Taille d'un écran de téléphone (390 x 844), au lieu du 800 x 600 par défaut.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  return tester.pumpWidget(
    MaterialApp(home: ResourceDetailPage(resource: resource)),
  );
}

void main() {
  testWidgets('displays the information of an article', (
    WidgetTester tester,
  ) async {
    await pumpDetailPage(tester, article);

    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    expect(find.text('7 min'), findsOneWidget);
    expect(find.text('Intermédiaire'), findsOneWidget);
    expect(find.text('En favori'), findsOneWidget);
    expect(find.text('Comprendre les frais'), findsOneWidget);
    expect(find.text('Texte complet de l’article.'), findsOneWidget);
  });

  testWidgets('displays the information of a video', (
    WidgetTester tester,
  ) async {
    await pumpDetailPage(tester, video);

    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('Débutant'), findsOneWidget);
    expect(find.text('Pas en favori'), findsOneWidget);
    expect(find.text('Descriptif de la vidéo.'), findsOneWidget);
  });

  testWidgets('displays the thumbnail, then the information, then the title', (
    WidgetTester tester,
  ) async {
    await pumpDetailPage(tester, article);

    final thumbnailY = tester.getTopLeft(find.byType(AspectRatio)).dy;
    final durationY = tester.getTopLeft(find.text('7 min')).dy;
    final titleY = tester.getTopLeft(find.text('Comprendre les frais')).dy;
    final contentY = tester
        .getTopLeft(find.text('Texte complet de l’article.'))
        .dy;

    expect(thumbnailY, lessThan(durationY));
    expect(durationY, lessThan(titleY));
    expect(titleY, lessThan(contentY));
  });

  testWidgets('displays the video player when the video has a link', (
    WidgetTester tester,
  ) async {
    const videoWithLink = Resource(
      title: 'Vidéo avec lien',
      description: 'Résumé',
      content: 'Descriptif de la vidéo.',
      type: ResourceType.video,
      duration: '5 min',
      level: Level.beginner,
      isFavorite: false,
      videoUrl: 'https://example.com/video.mp4',
    );

    await pumpDetailPage(tester, videoWithLink);

    expect(find.byType(VideoPlayer), findsOneWidget);
    expect(find.byType(ResourceThumbnail), findsNothing);
  });

  testWidgets('keeps the video player when scrolling a long description', (
    WidgetTester tester,
  ) async {
    final videoWithLongDescription = Resource(
      title: 'Vidéo avec un long descriptif',
      description: 'Résumé',
      content: List.filled(100, 'Un paragraphe du descriptif.').join('\n\n'),
      type: ResourceType.video,
      duration: '5 min',
      level: Level.beginner,
      isFavorite: false,
      videoUrl: 'https://example.com/video.mp4',
    );

    await pumpDetailPage(tester, videoWithLongDescription);
    await tester.drag(find.byType(Scrollable), const Offset(0, -3000));
    await tester.pump();

    expect(find.byType(VideoPlayer, skipOffstage: false), findsOneWidget);
  });
}
