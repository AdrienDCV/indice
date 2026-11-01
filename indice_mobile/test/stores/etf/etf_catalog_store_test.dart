import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/etf/etf_data.dart';
import 'package:indice_mobile/stores/etf/etf_catalog_state.dart';
import 'package:indice_mobile/stores/etf/etf_catalog_store.dart';

import '../../fakes/fake_etf_repository.dart';

const favouriteSpy = EtfData(
  ticker: 'SPY',
  exchange: 'NYSE ARCA',
  name: 'SPDR S&P 500 ETF Trust',
  currency: 'USD',
  favourite: true,
  leveragedOrInverse: false,
);

Future<void> waitForSearch() => Future<void>.delayed(
  EtfCatalogStore.searchDelay + const Duration(milliseconds: 50),
);

void main() {
  test('starts without etf', () {
    final store = EtfCatalogStore(
      FakeEtfRepository(() async => buildCatalog()),
    );

    expect(store.state, const EtfCatalogState());
  });

  test('loads the first page of the catalog', () async {
    final response = Completer<void>();
    final repository = FakeEtfRepository(() async {
      await response.future;
      return buildCatalog(fetchedAt: DateTime.utc(2026, 11, 1), stale: true);
    });
    final store = EtfCatalogStore(repository);

    final loading = store.init();

    expect(store.state.isLoading, isTrue);

    response.complete();
    await loading;

    expect(
      store.state,
      EtfCatalogState(
        etfs: const [spy, qqq],
        nextPage: 1,
        fetchedAt: DateTime.utc(2026, 11, 1),
        stale: true,
      ),
    );
    expect(repository.catalogRequests.single, (
      page: 0,
      size: EtfCatalogStore.pageSize,
      search: '',
      favouritesOnly: false,
    ));
  });

  test('keeps the error key sent by the api when loading fails', () async {
    final store = EtfCatalogStore(
      FakeEtfRepository(
        () async => throw apiError('error.pagination.invalid-sort'),
      ),
    );

    await store.init();

    expect(
      store.state,
      const EtfCatalogState(errorKey: 'error.pagination.invalid-sort'),
    );
  });

  test('falls back to the unexpected error key for any other error', () async {
    final store = EtfCatalogStore(
      FakeEtfRepository(() async => throw const FormatException()),
    );

    await store.init();

    expect(store.state, const EtfCatalogState(errorKey: 'error.unexpected'));
  });

  test('clears the error when loading again', () async {
    final repository = FakeEtfRepository(
      () async => throw apiError('error.unexpected'),
    );
    final store = EtfCatalogStore(repository);
    await store.init();
    repository.onRetrieveEtfs = () async => buildCatalog();

    await store.init();

    expect(store.state.errorKey, isNull);
    expect(store.state.etfs, [spy, qqq]);
  });

  test('appends the next page to the etfs already loaded', () async {
    final repository = FakeEtfRepository(
      () async => buildCatalog(etfs: [spy], totalPages: 2),
    );
    final store = EtfCatalogStore(repository);
    await store.init();
    repository.onRetrieveEtfs = () async =>
        buildCatalog(etfs: [qqq], page: 1, totalPages: 2);

    await store.loadMore();

    expect(store.state.etfs, [spy, qqq]);
    expect(store.state.hasMore, isFalse);
    expect(repository.catalogRequests.last.page, 1);
  });

  test('does not load more once the last page is loaded', () async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    final store = EtfCatalogStore(repository);
    await store.init();

    await store.loadMore();

    expect(repository.retrieveEtfsCalls, 1);
  });

  test('keeps the etfs already loaded when the next page fails', () async {
    final repository = FakeEtfRepository(
      () async => buildCatalog(etfs: [spy], totalPages: 2),
    );
    final store = EtfCatalogStore(repository);
    await store.init();
    repository.onRetrieveEtfs = () async => throw apiError('error.unexpected');

    await store.loadMore();

    expect(store.state.etfs, [spy]);
    expect(store.state.loadMoreErrorKey, 'error.unexpected');
    expect(store.state.hasMore, isTrue);
  });

  test('searches once, after the user stops typing', () async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    final store = EtfCatalogStore(repository);
    await store.init();

    store
      ..searchChanged('v')
      ..searchChanged('va')
      ..searchChanged(' van ');
    await waitForSearch();

    expect(repository.retrieveEtfsCalls, 2);
    expect(repository.catalogRequests.last.search, 'van');
    expect(repository.catalogRequests.last.page, 0);
    expect(store.state.search, 'van');
  });

  test('reloads the first page with the favourites filter', () async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    final store = EtfCatalogStore(repository);
    await store.init();

    await store.favouritesOnlyChanged(true);

    expect(store.state.favouritesOnly, isTrue);
    expect(repository.catalogRequests.last.favouritesOnly, isTrue);
    expect(repository.catalogRequests.last.page, 0);
  });

  test('ignores a response that arrives after the criteria changed', () async {
    final slowResponse = Completer<void>();
    final repository = FakeEtfRepository(() async {
      await slowResponse.future;
      return buildCatalog(etfs: [spy]);
    });
    final store = EtfCatalogStore(repository);
    final firstLoading = store.init();
    repository.onRetrieveEtfs = () async => buildCatalog(etfs: [qqq]);

    await store.favouritesOnlyChanged(true);
    slowResponse.complete();
    await firstLoading;

    expect(store.state.etfs, [qqq]);
  });

  test('pins an etf right away and asks the api to save it', () async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    final store = EtfCatalogStore(repository);
    await store.init();

    final saving = store.toggleFavourite('SPY');

    expect(store.state.etfs.first.favourite, isTrue);
    await saving;
    expect(repository.addedFavourites, ['SPY']);
    expect(store.state.favouriteErrorKey, isNull);
  });

  test('unpins a favourite', () async {
    final repository = FakeEtfRepository(
      () async => buildCatalog(etfs: [favouriteSpy, qqq]),
    );
    final store = EtfCatalogStore(repository);
    await store.init();

    await store.toggleFavourite('SPY');

    expect(store.state.etfs.first.favourite, isFalse);
    expect(repository.removedFavourites, ['SPY']);
  });

  test('restores the star when the api cannot save the favourite', () async {
    final repository = FakeEtfRepository(
      () async => buildCatalog(),
      onAddFavourite: (_) async => throw apiError('error.unexpected'),
    );
    final store = EtfCatalogStore(repository);
    await store.init();

    await store.toggleFavourite('SPY');

    expect(store.state.etfs.first.favourite, isFalse);
    expect(store.state.favouriteErrorKey, 'error.unexpected');
  });

  test('removes an unpinned etf from the favourites list', () async {
    final repository = FakeEtfRepository(
      () async => buildCatalog(etfs: [favouriteSpy]),
    );
    final store = EtfCatalogStore(repository);
    await store.favouritesOnlyChanged(true);

    await store.toggleFavourite('SPY');

    expect(store.state.etfs, isEmpty);
  });

  test(
    'puts an etf back in the favourites list when unpinning fails',
    () async {
      final repository = FakeEtfRepository(
        () async => buildCatalog(etfs: [favouriteSpy]),
        onRemoveFavourite: (_) async => throw apiError('error.unexpected'),
      );
      final store = EtfCatalogStore(repository);
      await store.favouritesOnlyChanged(true);

      await store.toggleFavourite('SPY');

      expect(store.state.etfs, [favouriteSpy]);
    },
  );

  test('updates an etf whose favourite changed elsewhere', () async {
    final store = EtfCatalogStore(
      FakeEtfRepository(() async => buildCatalog()),
    );
    await store.init();

    store.favouriteChanged('SPY', true);

    expect(store.state.etfs, [favouriteSpy, qqq]);
  });

  test('ignores a favourite change for an etf not loaded', () async {
    final store = EtfCatalogStore(
      FakeEtfRepository(() async => buildCatalog(etfs: [qqq])),
    );
    await store.init();

    store.favouriteChanged('SPY', true);

    expect(store.state.etfs, [qqq]);
  });

  test('refreshes the first page without showing the loading state', () async {
    final repository = FakeEtfRepository(() async => buildCatalog(etfs: [spy]));
    final store = EtfCatalogStore(repository);
    await store.init();
    repository.onRetrieveEtfs = () async => buildCatalog();

    final refreshing = store.refresh();

    expect(store.state.isLoading, isFalse);
    expect(store.state.etfs, [spy]);
    await refreshing;
    expect(store.state.etfs, [spy, qqq]);
    expect(repository.catalogRequests.last.page, 0);
  });
}
