import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/etf/etf_detail_data.dart';
import 'package:indice_mobile/stores/etf/etf_detail_state.dart';
import 'package:indice_mobile/stores/etf/etf_detail_store.dart';

import '../../fakes/fake_etf_repository.dart';

FakeEtfRepository repositoryWith(
  Future<EtfDetailData> Function(String ticker) onRetrieveEtf,
) {
  return FakeEtfRepository(
    () async => buildCatalog(),
    onRetrieveEtf: onRetrieveEtf,
  );
}

const reconnectDelay = Duration(milliseconds: 20);

Future<void> waitForReconnect() => Future<void>.delayed(reconnectDelay * 3);

void main() {
  test('starts without etf', () {
    final store = EtfDetailStore(
      repositoryWith((_) async => buildEtfDetail()),
      'SPY',
    );

    expect(store.state, const EtfDetailState());
  });

  test('loads the detail of its etf', () async {
    final response = Completer<void>();
    final etf = buildEtfDetail(marketData: spyMarketData);
    final repository = repositoryWith((_) async {
      await response.future;
      return etf;
    });
    final store = EtfDetailStore(repository, 'SPY');

    final loading = store.init();

    expect(store.state, const EtfDetailState(isLoading: true));

    response.complete();
    await loading;

    expect(store.state, EtfDetailState(etf: etf));
    expect(repository.retrievedTickers, ['SPY']);
  });

  test('keeps the error key sent by the api when loading fails', () async {
    final store = EtfDetailStore(
      repositoryWith((_) async => throw apiError('error.etfs.etf-not-found')),
      'ARKK',
    );

    await store.init();

    expect(
      store.state,
      const EtfDetailState(errorKey: 'error.etfs.etf-not-found'),
    );
  });

  test('clears the error when loading again', () async {
    final repository = repositoryWith(
      (_) async => throw apiError('error.unexpected'),
    );
    final store = EtfDetailStore(repository, 'SPY');
    await store.init();
    final etf = buildEtfDetail();
    repository.onRetrieveEtf = (_) async => etf;

    await store.init();

    expect(store.state, EtfDetailState(etf: etf));
  });

  test('falls back to the unexpected error key for any other error', () async {
    final store = EtfDetailStore(
      repositoryWith((_) async => throw const FormatException()),
      'SPY',
    );

    await store.init();

    expect(store.state, const EtfDetailState(errorKey: 'error.unexpected'));
  });

  test('pins its etf only once the api has saved it', () async {
    final confirmation = Completer<void>();
    final repository = FakeEtfRepository(
      () async => buildCatalog(),
      onRetrieveEtf: (_) async => buildEtfDetail(),
      onAddFavourite: (_) => confirmation.future,
    );
    final store = EtfDetailStore(repository, 'SPY');
    await store.init();

    final saving = store.toggleFavourite();

    expect(store.state.etf?.favourite, isFalse);
    confirmation.complete();
    expect(await saving, isTrue);
    expect(store.state.etf?.favourite, isTrue);
    expect(repository.addedFavourites, ['SPY']);
  });

  test('ignores a second tap while the api is saving the favourite', () async {
    final confirmation = Completer<void>();
    final repository = FakeEtfRepository(
      () async => buildCatalog(),
      onRetrieveEtf: (_) async => buildEtfDetail(),
      onAddFavourite: (_) => confirmation.future,
    );
    final store = EtfDetailStore(repository, 'SPY');
    await store.init();

    final saving = store.toggleFavourite();
    expect(await store.toggleFavourite(), isNull);
    confirmation.complete();
    await saving;

    expect(repository.addedFavourites, ['SPY']);
    expect(repository.removedFavourites, isEmpty);
    expect(store.state.etf?.favourite, isTrue);
  });

  test('unpins its etf', () async {
    final repository = repositoryWith(
      (_) async => buildEtfDetail(favourite: true),
    );
    final store = EtfDetailStore(repository, 'SPY');
    await store.init();

    expect(await store.toggleFavourite(), isFalse);
    expect(store.state.etf?.favourite, isFalse);
    expect(repository.removedFavourites, ['SPY']);
  });

  test('keeps the star when the api cannot save the favourite', () async {
    final repository = FakeEtfRepository(
      () async => buildCatalog(),
      onRetrieveEtf: (_) async => buildEtfDetail(),
      onAddFavourite: (_) async => throw apiError('error.unexpected'),
    );
    final store = EtfDetailStore(repository, 'SPY');
    await store.init();

    expect(await store.toggleFavourite(), isNull);
    expect(store.state.etf?.favourite, isFalse);
    expect(store.state.favouriteErrorKey, 'error.unexpected');
  });

  test('refreshes its etf while keeping the current one displayed', () async {
    final repository = repositoryWith((_) async => buildEtfDetail());
    final store = EtfDetailStore(repository, 'SPY');
    await store.init();
    repository.onRetrieveEtf = (_) async => buildEtfDetail(favourite: true);

    final refreshing = store.refresh();

    expect(store.state.isLoading, isFalse);
    expect(store.state.etf?.favourite, isFalse);
    await refreshing;
    expect(store.state.etf?.favourite, isTrue);
    expect(repository.retrievedTickers, ['SPY', 'SPY']);
  });

  test('tells when the detail comes from the cache', () async {
    final cachedAt = DateTime.utc(2026, 10, 30, 13, 5);
    final repository = repositoryWith((_) async => buildEtfDetail())
      ..detailCachedAt = cachedAt;
    final store = EtfDetailStore(repository, 'SPY');

    await store.init();

    expect(store.state.cachedAt, cachedAt);
  });

  test('loads its etf from the api once it answers again', () async {
    final repository = repositoryWith((_) async => buildEtfDetail())
      ..detailCachedAt = DateTime.utc(2026, 10, 30, 13, 5);
    final store = EtfDetailStore(
      repository,
      'SPY',
      reconnectDelay: reconnectDelay,
    );
    await store.init();

    repository.detailCachedAt = null;
    await waitForReconnect();

    expect(store.state.cachedAt, isNull);
    await store.close();
  });

  test('does not load its etf again while online', () async {
    final repository = repositoryWith((_) async => buildEtfDetail());
    final store = EtfDetailStore(
      repository,
      'SPY',
      reconnectDelay: reconnectDelay,
    );
    await store.init();

    await waitForReconnect();

    expect(repository.retrievedTickers, ['SPY']);
    await store.close();
  });

  test('stops trying once closed', () async {
    final repository = repositoryWith((_) async => buildEtfDetail())
      ..detailCachedAt = DateTime.utc(2026, 10, 30, 13, 5);
    final store = EtfDetailStore(
      repository,
      'SPY',
      reconnectDelay: reconnectDelay,
    );
    await store.init();

    await store.close();
    await waitForReconnect();

    expect(repository.retrievedTickers, ['SPY']);
  });
}
