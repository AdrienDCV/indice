import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/http.dart';
import 'package:indice_mobile/models/resource/media_data.dart';
import 'package:indice_mobile/models/resource/media_type.dart';
import 'package:indice_mobile/models/resource/resource_level.dart';
import 'package:indice_mobile/models/resource/resource_type.dart';
import 'package:indice_mobile/repositories/resource_repository.dart';

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

void main() {
  final repository = ResourceRepository();

  setUp(() => http.options.baseUrl = baseUrl);

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

    final page = await repository.retrieveResources();

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

    final resource = await repository.retrieveResource(
      '00000000-0000-4000-8000-000000000002',
    );

    expect(
      requestedUrl,
      Uri.parse('$baseUrl/resources/00000000-0000-4000-8000-000000000002'),
    );
    expect(resource.content, 'Texte complet.');
    expect(resource.level, ResourceLevel.beginner);
  });

  test('pins a resource with a put on its favourite', () async {
    final request = await requestSentBy(
      () => repository.addFavourite('fees'),
      json: resourceDetailJson,
    );

    expect(request.method, 'PUT');
    expect(request.uri, Uri.parse('$baseUrl/resources/fees/favourite'));
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
}
