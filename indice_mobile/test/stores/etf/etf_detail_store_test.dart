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
}
