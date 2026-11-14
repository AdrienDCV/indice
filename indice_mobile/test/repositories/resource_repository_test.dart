import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/http.dart';
import 'package:indice_mobile/models/resource/media_data.dart';
import 'package:indice_mobile/models/resource/media_type.dart';
import 'package:indice_mobile/models/resource/resource_level.dart';
import 'package:indice_mobile/models/resource/resource_type.dart';
import 'package:indice_mobile/repositories/resource_repository.dart';
import 'package:indice_mobile/storage/api_cache.dart';

import '../fakes/fake_http_client_adapter.dart';

const baseUrl = 'http://localhost:8080/api';

const resourcesJson = '''
{
  "content": [
    {
      "id": "00000000-0000-4000-8000-000000000003",
      "title": "La diversification",
      "description": "Pourquoi répartir son investissement.",
      "type": "VIDEO",
      "durationMinutes": 4,
      "level": "INTERMEDIATE",
      "media": { "url": "https://example.com/bee.mp4", "type": "VIDEO" },
      "favourite": true
    },
    {
      "id": "00000000-0000-4000-8000-000000000002",
      "title": "Comprendre les frais",
      "description": "Les frais d'un ETF.",
      "type": "ARTICLE",
      "durationMinutes": 7,
      "level": "BEGINNER",
      "media": null,
      "favourite": false
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 2,
  "totalPages": 1
}
''';

const resourceDetailJson = '''
{
  "id": "00000000-0000-4000-8000-000000000002",
  "title": "Comprendre les frais",
  "description": "Les frais d'un ETF.",
  "content": "Texte complet.",
  "type": "ARTICLE",
  "durationMinutes": 7,
  "level": "BEGINNER",
  "media": null,
  "favourite": false
}
''';

const feesId = '00000000-0000-4000-8000-000000000002';
const feesDownloadKey = 'resource_detail_$feesId';

final favouriteDetailJson = resourceDetailJson.replaceFirst(
  '"favourite": false',
  '"favourite": true',
);

void respondWith(String json, int statusCode) {
  http.httpClientAdapter = FakeHttpClientAdapter(
    (_) async => jsonBody(json, statusCode),
  );
}

void failWithoutResponse() {
  http.httpClientAdapter = FakeHttpClientAdapter(
    (options) async => throw DioException.connectionError(
      requestOptions: options,
      reason: 'Connection refused',
    ),
  );
}

Map<String, dynamic> decoded(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

void main() {
  late Directory cacheDirectory;
  late ApiCache apiCache;
  late ResourceRepository repository;
  final cachedAt = DateTime.utc(2026, 10, 30, 13, 5);

  setUp(() async {
    http.options.baseUrl = baseUrl;
    cacheDirectory = await Directory.systemTemp.createTemp('api_cache_test');
    apiCache = ApiCache(cacheDirectory, now: () => cachedAt);
    repository = ResourceRepository(apiCache);
  });

  tearDown(() => cacheDirectory.delete(recursive: true));

  Future<RequestOptions> requestSentBy(
    Future<void> Function() call, {
    String json = resourcesJson,
    int statusCode = 200,
  }) async {
    late RequestOptions request;
    http.httpClientAdapter = FakeHttpClientAdapter((options) async {
      request = options;
      return jsonBody(json, statusCode);
    });
    await call();
    return request;
  }

  test(
    'requests the first page of 20 resources without filter by default',
    () async {
      final request = await requestSentBy(repository.retrieveResources);

      expect(request.uri, Uri.parse('$baseUrl/resources?page=0&size=20'));
    },
  );

  test(
    'sends the page, the search, the levels and the favourites filter',
    () async {
      final request = await requestSentBy(
        () => repository.retrieveResources(
          page: 1,
          size: 10,
          search: 'frais',
          levels: {ResourceLevel.beginner, ResourceLevel.experienced},
          favouritesOnly: true,
        ),
      );

      expect(
        request.uri,
        Uri.parse(
          '$baseUrl/resources?page=1&size=10&search=frais'
          '&levels=BEGINNER%2CEXPERIENCED&favourites=true',
        ),
      );
    },
  );

  test('reads a page of resources, with or without media', () async {
    http.httpClientAdapter = FakeHttpClientAdapter(
      (_) async => jsonBody(resourcesJson, 200),
    );

    final page = (await repository.retrieveResources()).data;

    expect(page.totalElements, 2);
    final video = page.content.first;
    expect(video.id, '00000000-0000-4000-8000-000000000003');
    expect(video.type, ResourceType.video);
    expect(video.durationMinutes, 4);
    expect(video.level, ResourceLevel.intermediate);
    expect(
      video.media,
      const MediaData(
        url: 'https://example.com/bee.mp4',
        type: MediaType.video,
      ),
    );
    expect(video.favourite, isTrue);
    expect(page.content.last.media, isNull);
  });

  test('reads the detail of a resource', () async {
    late Uri requestedUrl;
    http.httpClientAdapter = FakeHttpClientAdapter((options) async {
      requestedUrl = options.uri;
      return jsonBody(resourceDetailJson, 200);
    });

    final resource = (await repository.retrieveResource(
      '00000000-0000-4000-8000-000000000002',
    )).data;

    expect(
      requestedUrl,
      Uri.parse('$baseUrl/resources/00000000-0000-4000-8000-000000000002'),
    );
    expect(resource.content, 'Texte complet.');
    expect(resource.level, ResourceLevel.beginner);
  });

  test('pins a resource with a put on its favourite', () async {
    final requests = <RequestOptions>[];
    http.httpClientAdapter = FakeHttpClientAdapter((options) async {
      requests.add(options);
      return jsonBody(favouriteDetailJson, 200);
    });

    await repository.addFavourite('fees');

    expect(requests.first.method, 'PUT');
    expect(requests.first.uri, Uri.parse('$baseUrl/resources/fees/favourite'));
  });

  test('unpins a resource with a delete on its favourite', () async {
    late RequestOptions request;
    http.httpClientAdapter = FakeHttpClientAdapter((options) async {
      request = options;
      return ResponseBody.fromString('', 204);
    });

    await repository.removeFavourite('fees');

    expect(request.method, 'DELETE');
    expect(request.uri, Uri.parse('$baseUrl/resources/fees/favourite'));
  });

  test('lets an api error reach the caller', () async {
    http.httpClientAdapter = FakeHttpClientAdapter(
      (_) async => jsonBody(
        '[{"error": "Not Found", "message": "error.resources.resource-not-found"}]',
        404,
      ),
    );

    await expectLater(
      repository.retrieveResource('unknown'),
      throwsA(
        isA<DioException>().having(
          extractErrorMessage,
          'error key',
          'error.resources.resource-not-found',
        ),
      ),
    );
  });

  test('downloads the detail of a resource once pinned', () async {
    respondWith(favouriteDetailJson, 200);

    await repository.addFavourite(feesId);

    expect((await apiCache.read(feesDownloadKey))!.response['id'], feesId);
  });

  test('keeps the favourite when its download fails', () async {
    http.httpClientAdapter = FakeHttpClientAdapter((options) async {
      if (options.method == 'PUT') return ResponseBody.fromString('', 204);
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Connection refused',
      );
    });

    await repository.addFavourite(feesId);

    expect(await apiCache.read(feesDownloadKey), isNull);
  });

  test('deletes the download when unpinning a resource', () async {
    await apiCache.write(feesDownloadKey, decoded(favouriteDetailJson));
    http.httpClientAdapter = FakeHttpClientAdapter(
      (_) async => ResponseBody.fromString('', 204),
    );

    await repository.removeFavourite(feesId);

    expect(await apiCache.read(feesDownloadKey), isNull);
  });

  test('keeps no download of a resource that is not a favourite', () async {
    await apiCache.write(feesDownloadKey, decoded(favouriteDetailJson));
    respondWith(resourceDetailJson, 200);

    final result = await repository.retrieveResource(feesId);

    expect(result.offline, isFalse);
    expect(await apiCache.read(feesDownloadKey), isNull);
  });

  test('reads the downloaded detail when the api cannot be reached', () async {
    respondWith(favouriteDetailJson, 200);
    await repository.retrieveResource(feesId);
    failWithoutResponse();

    final result = await repository.retrieveResource(feesId);

    expect(result.data.content, 'Texte complet.');
    expect(result.offline, isTrue);
    expect(result.cachedAt, cachedAt);
  });

  test('reads the downloaded detail when the api fails with a 500', () async {
    await apiCache.write(feesDownloadKey, decoded(favouriteDetailJson));
    respondWith(
      '[{ "error": "Internal Server Error", "message": "error.unexpected" }]',
      500,
    );

    expect((await repository.retrieveResource(feesId)).cachedAt, cachedAt);
  });

  test('lets the dio error through for a detail never downloaded', () {
    failWithoutResponse();

    expect(repository.retrieveResource(feesId), throwsA(isA<DioException>()));
  });

  test(
    'ignores the download when the api answers with a client error',
    () async {
      await apiCache.write(feesDownloadKey, decoded(favouriteDetailJson));
      respondWith(
        '[{ "error": "Not Found", "message": "error.resources.resource-not-found" }]',
        404,
      );

      expect(repository.retrieveResource(feesId), throwsA(isA<DioException>()));
    },
  );

  test(
    'lists the downloaded favourites by title when the api cannot be reached',
    () async {
      await apiCache.write(
        'resource_detail_tracking',
        decoded(
          favouriteDetailJson
              .replaceFirst('"id": "$feesId"', '"id": "tracking"')
              .replaceFirst(
                '"title": "Comprendre les frais"',
                '"title": "L’écart de suivi"',
              ),
        ),
      );
      await apiCache.write(feesDownloadKey, decoded(favouriteDetailJson));
      failWithoutResponse();

      final result = await repository.retrieveResources();

      expect(result.offline, isTrue);
      expect(result.data.content.map((resource) => resource.id), [
        feesId,
        'tracking',
      ]);
      expect(result.data.content.first.favourite, isTrue);
      expect(result.data.totalPages, 1);
    },
  );

  test('lets the dio error through for a search without network', () async {
    await apiCache.write(feesDownloadKey, decoded(favouriteDetailJson));
    failWithoutResponse();

    expect(
      repository.retrieveResources(search: 'frais'),
      throwsA(isA<DioException>()),
    );
  });

  test('lets the dio error through for a level filter without network', () {
    failWithoutResponse();

    expect(
      repository.retrieveResources(levels: {ResourceLevel.beginner}),
      throwsA(isA<DioException>()),
    );
  });

  test('lets the dio error through for a next page without network', () {
    failWithoutResponse();

    expect(repository.retrieveResources(page: 1), throwsA(isA<DioException>()));
  });

  test('downloads missing favourites and deletes the others on sync', () async {
    await apiCache.write(
      'resource_detail_tracking',
      decoded(
        favouriteDetailJson.replaceFirst('"id": "$feesId"', '"id": "tracking"'),
      ),
    );
    http.httpClientAdapter = FakeHttpClientAdapter((options) async {
      if (options.path == '/resources') {
        return jsonBody(
          resourcesJson.replaceFirst(
            '"id": "00000000-0000-4000-8000-000000000003"',
            '"id": "$feesId"',
          ),
          200,
        );
      }
      return jsonBody(favouriteDetailJson, 200);
    });

    await repository.syncFavouriteDownloads();

    expect(await apiCache.read(feesDownloadKey), isNotNull);
    expect(await apiCache.read('resource_detail_tracking'), isNull);
  });

  test('ignores the failures of the sync', () async {
    failWithoutResponse();

    await repository.syncFavouriteDownloads();

    expect(cacheDirectory.listSync(), isEmpty);
  });
}
