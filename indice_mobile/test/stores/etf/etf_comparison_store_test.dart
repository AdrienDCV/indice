import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/models/etf/etf_comparison_data.dart';
import 'package:indice_mobile/stores/etf/etf_comparison_state.dart';
import 'package:indice_mobile/stores/etf/etf_comparison_store.dart';

import '../../fakes/fake_etf_repository.dart';

FakeEtfRepository repositoryWith(
  Future<EtfComparisonData> Function(String etfA, String etfB) onCompare,
) {
  return FakeEtfRepository(() async => buildCatalog(), onCompare: onCompare);
}

void main() {
  test('starts with the first etf it was given', () {
    final store = EtfComparisonStore(
      repositoryWith((_, _) async => buildComparison()),
      etfA: 'SPY',
    );

    expect(store.state, const EtfComparisonState(etfA: 'SPY'));
  });

  test('does not compare while an etf is missing', () async {
    final repository = repositoryWith((_, _) async => buildComparison());
    final store = EtfComparisonStore(repository);

    await store.selectEtfA('SPY');

    expect(repository.comparedPairs, isEmpty);
    expect(store.state, const EtfComparisonState(etfA: 'SPY'));
  });

  test('compares the two etfs once both are selected', () async {
    final response = Completer<void>();
    final comparison = buildComparison();
    final repository = repositoryWith((_, _) async {
      await response.future;
      return comparison;
    });
    final store = EtfComparisonStore(repository, etfA: 'SPY');

    final loading = store.selectEtfB('QQQ');

    expect(
      store.state,
      const EtfComparisonState(etfA: 'SPY', etfB: 'QQQ', isLoading: true),
    );

    response.complete();
    await loading;

    expect(repository.comparedPairs, [('SPY', 'QQQ')]);
    expect(
      store.state,
      EtfComparisonState(etfA: 'SPY', etfB: 'QQQ', comparison: comparison),
    );
  });

  test('compares again when an etf changes', () async {
    final repository = repositoryWith((_, _) async => buildComparison());
    final store = EtfComparisonStore(repository, etfA: 'SPY');
    await store.selectEtfB('QQQ');

    await store.selectEtfB('VGK');

    expect(repository.comparedPairs, [('SPY', 'QQQ'), ('SPY', 'VGK')]);
    expect(store.state.etfB, 'VGK');
  });

  test('ignores the answer for a pair that is no longer selected', () async {
    final firstResponse = Completer<EtfComparisonData>();
    final latestComparison = buildComparison(correlation: 0.5);
    final repository = repositoryWith(
      (_, etfB) =>
          etfB == 'QQQ' ? firstResponse.future : Future.value(latestComparison),
    );
    final store = EtfComparisonStore(repository, etfA: 'SPY');

    final firstLoading = store.selectEtfB('QQQ');
    await store.selectEtfB('VGK');
    firstResponse.complete(buildComparison());
    await firstLoading;

    expect(store.state.etfB, 'VGK');
    expect(store.state.comparison, latestComparison);
  });

  test('keeps the error key sent by the api', () async {
    final store = EtfComparisonStore(
      repositoryWith(
        (_, _) async => throw apiError('error.etfs.etf-a-insufficient-data'),
      ),
      etfA: 'SPY',
    );

    await store.selectEtfB('QQQ');

    expect(
      store.state,
      const EtfComparisonState(
        etfA: 'SPY',
        etfB: 'QQQ',
        errorKey: 'error.etfs.etf-a-insufficient-data',
      ),
    );
  });

  test('falls back to the unexpected error key for any other error', () async {
    final store = EtfComparisonStore(
      repositoryWith((_, _) async => throw const FormatException()),
      etfA: 'SPY',
    );

    await store.selectEtfB('QQQ');

    expect(store.state.errorKey, 'error.unexpected');
  });

  test('compares the same pair again on retry', () async {
    final repository = repositoryWith(
      (_, _) async => throw apiError('error.unexpected'),
    );
    final store = EtfComparisonStore(repository, etfA: 'SPY');
    await store.selectEtfB('QQQ');
    final comparison = buildComparison();
    repository.onCompare = (_, _) async => comparison;

    await store.retry();

    expect(repository.comparedPairs, [('SPY', 'QQQ'), ('SPY', 'QQQ')]);
    expect(store.state.comparison, comparison);
    expect(store.state.errorKey, isNull);
  });

  test('suggests the etfs matching a search', () async {
    final repository = FakeEtfRepository(() async => buildCatalog());
    final store = EtfComparisonStore(repository);

    final suggestions = await store.suggestEtfs('sp');

    expect(suggestions, [spy, qqq]);
    expect(repository.catalogRequests.single, (
      page: 0,
      size: EtfComparisonStore.suggestionCount,
      search: 'sp',
      favouritesOnly: false,
    ));
  });

  test('suggests nothing when the search fails', () async {
    final store = EtfComparisonStore(
      FakeEtfRepository(() async => throw apiError('error.unexpected')),
    );

    expect(await store.suggestEtfs('sp'), isEmpty);
  });
}
