import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/stores/resource/resource_detail_store.dart';

import '../../fakes/fake_etf_repository.dart' show apiError;
import '../../fakes/fake_resource_repository.dart';

void main() {
  test('loads the resource', () async {
    final response = Completer<void>();
    final repository = FakeResourceRepository(
      onRetrieveResource: (_) async {
        await response.future;
        return buildResourceDetail();
      },
    );
    final store = ResourceDetailStore(repository, feesArticle.id);

    final loading = store.init();

    expect(store.state.isLoading, isTrue);

    response.complete();
    await loading;

    expect(store.state.resource, buildResourceDetail());
    expect(store.state.isLoading, isFalse);
    expect(repository.retrievedIds, [feesArticle.id]);
  });

  test('keeps the error key when the resource cannot be loaded', () async {
    final store = ResourceDetailStore(
      FakeResourceRepository(
        onRetrieveResource: (_) async =>
            throw apiError('error.resources.resource-not-found'),
      ),
      'unknown',
    );

    await store.init();

    expect(store.state.errorKey, 'error.resources.resource-not-found');
    expect(store.state.resource, isNull);
  });

  test('pins the resource and returns its new favourite state', () async {
    final repository = FakeResourceRepository(
      onRetrieveResource: (_) async => buildResourceDetail(),
    );
    final store = ResourceDetailStore(repository, feesArticle.id);
    await store.init();

    final favourite = await store.toggleFavourite();

    expect(favourite, isTrue);
    expect(store.state.resource?.favourite, isTrue);
    expect(repository.addedFavourites, [feesArticle.id]);
  });

  test('unpins a favourite resource', () async {
    final repository = FakeResourceRepository(
      onRetrieveResource: (_) async =>
          buildResourceDetail(resource: diversificationVideo),
    );
    final store = ResourceDetailStore(repository, diversificationVideo.id);
    await store.init();

    final favourite = await store.toggleFavourite();

    expect(favourite, isFalse);
    expect(repository.removedFavourites, [diversificationVideo.id]);
  });

  test('restores the favourite when the api call fails', () async {
    final store = ResourceDetailStore(
      FakeResourceRepository(
        onRetrieveResource: (_) async => buildResourceDetail(),
        onAddFavourite: (_) async => throw apiError('error.unexpected'),
      ),
      feesArticle.id,
    );
    await store.init();

    final favourite = await store.toggleFavourite();

    expect(favourite, isNull);
    expect(store.state.resource?.favourite, isFalse);
    expect(store.state.favouriteErrorKey, 'error.unexpected');
  });
}
