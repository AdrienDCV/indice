import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/resource/resource_level.dart';
import 'package:indice_mobile/stores/resource/resource_catalog_state.dart';
import 'package:indice_mobile/stores/resource/resource_catalog_store.dart';

import '../../fakes/fake_etf_repository.dart' show apiError;
import '../../fakes/fake_resource_repository.dart';

Future<void> waitForSearch() => Future<void>.delayed(
  ResourceCatalogStore.searchDelay + const Duration(milliseconds: 50),
);

void main() {
  test('starts without resource', () {
    final store = ResourceCatalogStore(FakeResourceRepository());

    expect(store.state, const ResourceCatalogState());
  });

  test('loads the first page without filter', () async {
    final response = Completer<void>();
    final repository = FakeResourceRepository(
      onRetrieveResources: () async {
        await response.future;
        return buildResourcePage(totalPages: 2);
      },
    );
    final store = ResourceCatalogStore(repository);

    final loading = store.init();

    expect(store.state.isLoading, isTrue);

    response.complete();
    await loading;

    expect(
      store.state,
      const ResourceCatalogState(
        resources: [feesArticle, diversificationVideo],
        nextPage: 1,
        hasMore: true,
      ),
    );
    final request = repository.requests.single;
    expect(request.page, 0);
    expect(request.size, ResourceCatalogStore.pageSize);
    expect(request.search, isEmpty);
    expect(request.levels, isEmpty);
    expect(request.favouritesOnly, isFalse);
  });

  test('keeps the error key when the first page fails', () async {
    final store = ResourceCatalogStore(
      FakeResourceRepository(
        onRetrieveResources: () async => throw apiError('error.unexpected'),
      ),
    );

    await store.init();

    expect(store.state.errorKey, 'error.unexpected');
    expect(store.state.resources, isEmpty);
    expect(store.state.isLoading, isFalse);
  });

  test('adds the next page when loading more', () async {
    var call = 0;
    final repository = FakeResourceRepository(
      onRetrieveResources: () async => call++ == 0
          ? buildResourcePage(resources: [feesArticle], totalPages: 2)
          : buildResourcePage(
              resources: [diversificationVideo],
              page: 1,
              totalPages: 2,
            ),
    );
    final store = ResourceCatalogStore(repository);
    await store.init();

    await store.loadMore();

    expect(store.state.resources, [feesArticle, diversificationVideo]);
    expect(store.state.hasMore, isFalse);
    expect(repository.requests.last.page, 1);

    await store.loadMore();

    expect(repository.requests, hasLength(2));
  });

  test('keeps the list when the next page fails', () async {
    var call = 0;
    final store = ResourceCatalogStore(
      FakeResourceRepository(
        onRetrieveResources: () async {
          if (call++ == 0) {
            return buildResourcePage(resources: [feesArticle], totalPages: 2);
          }
          throw apiError('error.unexpected');
        },
      ),
    );
    await store.init();

    await store.loadMore();

    expect(store.state.resources, [feesArticle]);
    expect(store.state.loadMoreErrorKey, 'error.unexpected');
    expect(store.state.hasMore, isTrue);
  });

  test('searches once, after the last keystroke', () async {
    final repository = FakeResourceRepository();
    final store = ResourceCatalogStore(repository);
    await store.init();

    store.searchChanged('fr');
    store.searchChanged(' frais ');
    await waitForSearch();

    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.search, 'frais');
    expect(repository.requests.last.page, 0);
    expect(store.state.search, 'frais');
    await store.close();
  });

  test('reloads the first page with the toggled levels', () async {
    final repository = FakeResourceRepository();
    final store = ResourceCatalogStore(repository);
    await store.init();

    await store.levelToggled(ResourceLevel.beginner, true);
    await store.levelToggled(ResourceLevel.professional, true);
    await store.levelToggled(ResourceLevel.beginner, false);

    expect(store.state.levels, {ResourceLevel.professional});
    expect(repository.requests.last.levels, {ResourceLevel.professional});
    expect(repository.requests.last.page, 0);
  });

  test('reloads the first page with the favourites filter', () async {
    final repository = FakeResourceRepository();
    final store = ResourceCatalogStore(repository);
    await store.init();

    await store.favouritesOnlyChanged(true);

    expect(store.state.favouritesOnly, isTrue);
    expect(repository.requests.last.favouritesOnly, isTrue);
  });

  test('ignores a response that arrives after new criteria', () async {
    final slowResponse = Completer<void>();
    var call = 0;
    final store = ResourceCatalogStore(
      FakeResourceRepository(
        onRetrieveResources: () async {
          if (call++ == 0) {
            await slowResponse.future;
            return buildResourcePage(resources: [feesArticle]);
          }
          return buildResourcePage(resources: [diversificationVideo]);
        },
      ),
    );

    final firstLoading = store.init();
    await store.favouritesOnlyChanged(true);
    slowResponse.complete();
    await firstLoading;

    expect(store.state.resources, [diversificationVideo]);
  });

  test('pins a resource only once the api has saved it', () async {
    final confirmation = Completer<void>();
    final repository = FakeResourceRepository(
      onAddFavourite: (_) => confirmation.future,
    );
    final store = ResourceCatalogStore(repository);
    await store.init();

    final toggling = store.toggleFavourite(feesArticle.id);

    expect(store.state.resources.first.favourite, isFalse);

    confirmation.complete();
    await toggling;

    expect(repository.addedFavourites, [feesArticle.id]);
    expect(store.state.resources.first.favourite, isTrue);
    expect(store.state.favouriteErrorKey, isNull);
  });

  test('ignores a second tap while the api is saving the favourite', () async {
    final confirmation = Completer<void>();
    final repository = FakeResourceRepository(
      onAddFavourite: (_) => confirmation.future,
    );
    final store = ResourceCatalogStore(repository);
    await store.init();

    final toggling = store.toggleFavourite(feesArticle.id);
    await store.toggleFavourite(feesArticle.id);
    confirmation.complete();
    await toggling;

    expect(repository.addedFavourites, [feesArticle.id]);
    expect(repository.removedFavourites, isEmpty);
    expect(store.state.resources.first.favourite, isTrue);
  });

  test('unpins a favourite', () async {
    final repository = FakeResourceRepository();
    final store = ResourceCatalogStore(repository);
    await store.init();

    await store.toggleFavourite(diversificationVideo.id);

    expect(repository.removedFavourites, [diversificationVideo.id]);
    expect(store.state.resources.last.favourite, isFalse);
  });

  test('keeps the favourite unchanged when the api call fails', () async {
    final store = ResourceCatalogStore(
      FakeResourceRepository(
        onAddFavourite: (_) async => throw apiError('error.unexpected'),
      ),
    );
    await store.init();

    await store.toggleFavourite(feesArticle.id);

    expect(store.state.resources.first.favourite, isFalse);
    expect(store.state.favouriteErrorKey, 'error.unexpected');
  });

  test('removes an unpinned resource when only favourites are shown', () async {
    final store = ResourceCatalogStore(
      FakeResourceRepository(
        onRetrieveResources: () async =>
            buildResourcePage(resources: [diversificationVideo]),
      ),
    );
    await store.favouritesOnlyChanged(true);

    await store.toggleFavourite(diversificationVideo.id);

    expect(store.state.resources, isEmpty);
  });

  test(
    'puts the resource back when unpinning fails with the favourites filter',
    () async {
      final store = ResourceCatalogStore(
        FakeResourceRepository(
          onRetrieveResources: () async =>
              buildResourcePage(resources: [diversificationVideo]),
          onRemoveFavourite: (_) async => throw apiError('error.unexpected'),
        ),
      );
      await store.favouritesOnlyChanged(true);

      await store.toggleFavourite(diversificationVideo.id);

      expect(store.state.resources, [diversificationVideo]);
    },
  );

  test('updates a card when the favourite changes on the detail', () async {
    final store = ResourceCatalogStore(FakeResourceRepository());
    await store.init();

    store.favouriteChanged(feesArticle.id, true);

    expect(store.state.resources.first.favourite, isTrue);
  });
}
