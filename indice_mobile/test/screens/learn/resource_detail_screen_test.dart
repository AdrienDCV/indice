import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:indice_mobile/injection.dart';
import 'package:indice_mobile/models/resource/media_data.dart';
import 'package:indice_mobile/models/resource/media_type.dart';
import 'package:indice_mobile/repositories/resource_repository.dart';
import 'package:indice_mobile/screens/learn/resource_detail_screen.dart';
import 'package:indice_mobile/stores/resource/resource_catalog_store.dart';
import 'package:indice_mobile/widgets/banner/offline_bar.dart';
import 'package:indice_mobile/widgets/favourite/favourite_icon.dart';
import 'package:indice_mobile/widgets/resource_thumbnail.dart';
import 'package:indice_mobile/widgets/video_player.dart';

import '../../fakes/fake_etf_repository.dart' show apiError;
import '../../fakes/fake_resource_repository.dart';
import '../../fakes/fake_webview_platform.dart';

Future<ResourceCatalogStore> pumpDetailScreen(
  WidgetTester tester,
  FakeResourceRepository repository, {
  String id = 'fees',
}) async {
  // Taille d'un écran de téléphone (390 x 844), au lieu du 800 x 600 par défaut.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  WebViewPlatform.instance = FakeWebViewPlatform();
  getIt.registerSingleton<ResourceRepository>(repository);
  addTearDown(getIt.reset);
  final catalogStore = ResourceCatalogStore(repository);
  await tester.pumpWidget(
    BlocProvider.value(
      value: catalogStore,
      child: MaterialApp(home: ResourceDetailScreen(id: id)),
    ),
  );
  await tester.pumpAndSettle();
  return catalogStore;
}

void main() {
  testWidgets('displays the information of an article', (
    WidgetTester tester,
  ) async {
    await pumpDetailScreen(
      tester,
      FakeResourceRepository(
        onRetrieveResource: (_) async => buildResourceDetail(),
      ),
    );

    expect(find.widgetWithText(AppBar, 'Article'), findsOneWidget);
    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    expect(find.text('7 min'), findsOneWidget);
    expect(find.text('Débutant'), findsOneWidget);
    expect(find.text('Comprendre les frais'), findsOneWidget);
    expect(find.text('Texte complet de l’article.'), findsOneWidget);
  });

  testWidgets('displays the thumbnail, then the information, then the title', (
    WidgetTester tester,
  ) async {
    await pumpDetailScreen(
      tester,
      FakeResourceRepository(
        onRetrieveResource: (_) async => buildResourceDetail(),
      ),
    );

    final thumbnailY = tester.getTopLeft(find.byType(AspectRatio)).dy;
    final durationY = tester.getTopLeft(find.text('7 min')).dy;
    final titleY = tester.getTopLeft(find.text('Comprendre les frais')).dy;
    final contentY = tester
        .getTopLeft(find.text('Texte complet de l’article.'))
        .dy;

    expect(thumbnailY, lessThan(durationY));
    expect(durationY, lessThan(titleY));
    expect(titleY, lessThan(contentY));
  });

  testWidgets('displays the video player for a video media', (
    WidgetTester tester,
  ) async {
    await pumpDetailScreen(
      tester,
      FakeResourceRepository(
        onRetrieveResource: (_) async =>
            buildResourceDetail(resource: diversificationVideo),
      ),
      id: diversificationVideo.id,
    );

    expect(find.byType(VideoPlayer), findsOneWidget);
    expect(find.byType(ResourceThumbnail), findsNothing);
  });

  testWidgets('displays the thumbnail for an image media', (
    WidgetTester tester,
  ) async {
    await pumpDetailScreen(
      tester,
      FakeResourceRepository(
        onRetrieveResource: (_) async => buildResourceDetail(
          resource: feesArticle.copyWith(
            media: const MediaData(
              url: 'https://example.com/cover.png',
              type: MediaType.image,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ResourceThumbnail), findsOneWidget);
    expect(find.byType(VideoPlayer), findsNothing);
  });

  testWidgets('keeps the video player when scrolling a long description', (
    WidgetTester tester,
  ) async {
    await pumpDetailScreen(
      tester,
      FakeResourceRepository(
        onRetrieveResource: (_) async => buildResourceDetail(
          resource: diversificationVideo,
          content: List.filled(
            100,
            'Un paragraphe du descriptif.',
          ).join('\n\n'),
        ),
      ),
      id: diversificationVideo.id,
    );
    await tester.drag(find.byType(Scrollable), const Offset(0, -3000));
    await tester.pump();

    expect(find.byType(VideoPlayer, skipOffstage: false), findsOneWidget);
  });

  testWidgets('shows the error of the api', (WidgetTester tester) async {
    await pumpDetailScreen(
      tester,
      FakeResourceRepository(
        onRetrieveResource: (_) async =>
            throw apiError('error.resources.resource-not-found'),
      ),
    );

    expect(find.text('Cette ressource est introuvable.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('pins the resource and tells the catalog', (
    WidgetTester tester,
  ) async {
    final repository = FakeResourceRepository(
      onRetrieveResource: (_) async => buildResourceDetail(),
    );
    final catalogStore = await pumpDetailScreen(tester, repository);
    await catalogStore.init();

    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pumpAndSettle();

    expect(repository.addedFavourites, [feesArticle.id]);
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
    expect(catalogStore.state.resources.first.favourite, isTrue);
  });

  testWidgets('shows a message when pinning fails', (
    WidgetTester tester,
  ) async {
    await pumpDetailScreen(
      tester,
      FakeResourceRepository(
        onRetrieveResource: (_) async => buildResourceDetail(),
        onAddFavourite: (_) async => throw apiError('error.unexpected'),
      ),
    );

    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pumpAndSettle();

    expect(find.text('Impossible de modifier les favoris.'), findsOneWidget);
    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
  });

  testWidgets('shows the downloaded resource offline, with its date', (
    WidgetTester tester,
  ) async {
    await pumpDetailScreen(
      tester,
      FakeResourceRepository(
        onRetrieveResource: (_) async =>
            buildResourceDetail(resource: diversificationVideo),
        detailCachedAt: DateTime(2026, 11, 2, 21, 17),
      ),
      id: diversificationVideo.id,
    );

    expect(find.byType(OfflineBar), findsOneWidget);
    expect(
      find.text('Hors ligne · données du 02/11/2026 à 21:17'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byType(FavouriteIcon),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('replaces the video by its thumbnail offline', (
    WidgetTester tester,
  ) async {
    await pumpDetailScreen(
      tester,
      FakeResourceRepository(
        onRetrieveResource: (_) async =>
            buildResourceDetail(resource: diversificationVideo),
        detailCachedAt: DateTime(2026, 11, 2, 21, 17),
      ),
      id: diversificationVideo.id,
    );

    expect(find.byType(VideoPlayer), findsNothing);
    expect(find.byType(ResourceThumbnail), findsOneWidget);
    expect(find.text('La vidéo demande une connexion.'), findsOneWidget);
    expect(find.text('Texte complet de l’article.'), findsOneWidget);
  });

  testWidgets('says nothing about the network for an offline article', (
    WidgetTester tester,
  ) async {
    await pumpDetailScreen(
      tester,
      FakeResourceRepository(
        onRetrieveResource: (_) async => buildResourceDetail(),
        detailCachedAt: DateTime(2026, 11, 2, 21, 17),
      ),
    );

    expect(find.text('La vidéo demande une connexion.'), findsNothing);
  });
}
