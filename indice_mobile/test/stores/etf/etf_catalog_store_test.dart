import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/stores/etf/etf_catalog_state.dart';
import 'package:indice_mobile/stores/etf/etf_catalog_store.dart';

import '../../fakes/fake_etf_repository.dart';

void main() {
  test('starts without catalog', () {
    final store = EtfCatalogStore(
      FakeEtfRepository(() async => buildCatalog()),
    );

    expect(store.state, const EtfCatalogState());
  });

  test('loads the catalog', () async {
    final response = Completer<void>();
    final catalog = buildCatalog();
    final store = EtfCatalogStore(
      FakeEtfRepository(() async {
        await response.future;
        return catalog;
      }),
    );

    final loading = store.init();

    expect(store.state, const EtfCatalogState(isLoading: true));

    response.complete();
    await loading;

    expect(store.state, EtfCatalogState(catalog: catalog));
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

  test('clears the error when loading again', () async {
    final repository = FakeEtfRepository(
      () async => throw apiError('error.unexpected'),
    );
    final store = EtfCatalogStore(repository);
    await store.init();
    final catalog = buildCatalog();
    repository.onRetrieveEtfs = () async => catalog;

    await store.init();

    expect(store.state, EtfCatalogState(catalog: catalog));
  });

  test('falls back to the unexpected error key for any other error', () async {
    final store = EtfCatalogStore(
      FakeEtfRepository(() async => throw const FormatException()),
    );

    await store.init();

    expect(store.state, const EtfCatalogState(errorKey: 'error.unexpected'));
  });
}
