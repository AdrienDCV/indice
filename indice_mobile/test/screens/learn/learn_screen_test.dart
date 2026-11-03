import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:indice_mobile/injection.dart';
import 'package:indice_mobile/models/resource/resource_level.dart';
import 'package:indice_mobile/repositories/resource_repository.dart';
import 'package:indice_mobile/screens/learn/learn_screen.dart';
import 'package:indice_mobile/screens/learn/resource_detail_screen.dart';
import 'package:indice_mobile/stores/resource/resource_catalog_store.dart';
import 'package:indice_mobile/widgets/filter_toggle.dart';

import '../../fakes/fake_etf_repository.dart' show apiError;
import '../../fakes/fake_resource_repository.dart';

Future<void> pumpLearnScreen(
  WidgetTester tester,
  FakeResourceRepository repository,
) async {
  getIt.registerSingleton<ResourceRepository>(repository);
  addTearDown(getIt.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const LearnScreen()),
      GoRoute(
        path: '/resource/:id',
        builder: (_, state) =>
            ResourceDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => ResourceCatalogStore(repository)..init(),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Finder filter(String label) => find.widgetWithText(FilterToggle, label);

void main() {
  testWidgets('displays every filter and the resources of the api', (
    WidgetTester tester,
  ) async {
    await pumpLearnScreen(tester, FakeResourceRepository());

    expect(filter('Favoris'), findsOneWidget);
    for (final label in [
      'Débutant',
      'Intermédiaire',
      'Expérimenté',
      'Professionnel',
    ]) {
      expect(filter(label), findsOneWidget);
    }
    expect(find.text('Comprendre les frais'), findsOneWidget);
    expect(find.text('La diversification'), findsOneWidget);
    expect(find.text('7 min'), findsOneWidget);
  });

  testWidgets('asks the api for the selected level', (
    WidgetTester tester,
  ) async {
    final repository = FakeResourceRepository();
    await pumpLearnScreen(tester, repository);

    await tester.tap(filter('Intermédiaire'));
    await tester.pumpAndSettle();

    expect(repository.requests.last.levels, {ResourceLevel.intermediate});
  });

  testWidgets('asks the api for the favourites only', (
    WidgetTester tester,
  ) async {
    final repository = FakeResourceRepository();
    await pumpLearnScreen(tester, repository);

    await tester.tap(filter('Favoris'));
    await tester.pumpAndSettle();

    expect(repository.requests.last.favouritesOnly, isTrue);
  });

  testWidgets('asks the api for the typed search', (WidgetTester tester) async {
    final repository = FakeResourceRepository();
    await pumpLearnScreen(tester, repository);

    await tester.enterText(find.byType(SearchBar), 'frais');
    await tester.pump(ResourceCatalogStore.searchDelay);
    await tester.pumpAndSettle();

    expect(repository.requests.last.search, 'frais');
  });

  testWidgets('shows a message when no resource matches the filters', (
    WidgetTester tester,
  ) async {
    final repository = FakeResourceRepository(
      onRetrieveResources: () async => buildResourcePage(resources: []),
    );
    await pumpLearnScreen(tester, repository);

    await tester.ensureVisible(filter('Professionnel'));
    await tester.tap(filter('Professionnel'));
    await tester.pumpAndSettle();

    expect(
      find.text('Aucune ressource ne correspond à ces filtres.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the error with a retry button', (
    WidgetTester tester,
  ) async {
    var fail = true;
    final repository = FakeResourceRepository(
      onRetrieveResources: () async {
        if (fail) throw apiError('error.unexpected');
        return buildResourcePage();
      },
    );
    await pumpLearnScreen(tester, repository);

    expect(
      find.text(
        'Une erreur inattendue est survenue. Réessaie dans quelques instants.',
      ),
      findsOneWidget,
    );

    fail = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Comprendre les frais'), findsOneWidget);
  });

  testWidgets('pins a resource from its card', (WidgetTester tester) async {
    final repository = FakeResourceRepository();
    await pumpLearnScreen(tester, repository);

    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pumpAndSettle();

    expect(repository.addedFavourites, [feesArticle.id]);
    expect(find.byTooltip('Ajouter aux favoris'), findsNothing);
  });

  testWidgets('shows a message when pinning fails', (
    WidgetTester tester,
  ) async {
    final repository = FakeResourceRepository(
      onAddFavourite: (_) async => throw apiError('error.unexpected'),
    );
    await pumpLearnScreen(tester, repository);

    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pumpAndSettle();

    expect(find.text('Impossible de modifier les favoris.'), findsOneWidget);
    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
  });

  testWidgets('opens the detail of a tapped resource', (
    WidgetTester tester,
  ) async {
    final repository = FakeResourceRepository(
      onRetrieveResource: (id) async => buildResourceDetail(),
    );
    await pumpLearnScreen(tester, repository);

    await tester.tap(find.text('Comprendre les frais'));
    await tester.pumpAndSettle();

    expect(find.byType(ResourceDetailScreen), findsOneWidget);
    expect(repository.retrievedIds, [feesArticle.id]);
  });
}
