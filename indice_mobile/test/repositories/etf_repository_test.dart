import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/http.dart';
import 'package:indice_mobile/repositories/etf_repository.dart';

import '../fakes/fake_http_client_adapter.dart';

const baseUrl = 'http://localhost:8080/api';

const catalogJson = '''
{
  "etfs": {
    "content": [
      { "ticker": "VGK", "exchange": "NYSE ARCA", "name": "Vanguard FTSE Europe ETF", "currency": "USD" }
    ],
    "page": 0,
    "size": 100,
    "totalElements": 1,
    "totalPages": 1
  },
  "fetchedAt": "2026-10-07T08:00:00Z",
  "stale": true
}
''';

void respondWith(String json, int statusCode) {
  http.httpClientAdapter = FakeHttpClientAdapter(
    (_) async => jsonBody(json, statusCode),
  );
}

void main() {
  setUp(() => http.options.baseUrl = baseUrl);

  test('requests the first 100 etfs of the catalog', () async {
    late Uri requestedUrl;
    http.httpClientAdapter = FakeHttpClientAdapter((options) async {
      requestedUrl = options.uri;
      return jsonBody(catalogJson, 200);
    });

    await EtfRepository().retrieveEtfs();

    expect(requestedUrl, Uri.parse('$baseUrl/etfs?size=100'));
  });

  test('returns the catalog sent by the api', () async {
    respondWith(catalogJson, 200);

    final catalog = await EtfRepository().retrieveEtfs();

    expect(catalog.etfs.content.single.ticker, 'VGK');
    expect(catalog.etfs.content.single.name, 'Vanguard FTSE Europe ETF');
    expect(catalog.etfs.content.single.exchange, 'NYSE ARCA');
    expect(catalog.etfs.content.single.currency, 'USD');
    expect(catalog.etfs.totalElements, 1);
    expect(catalog.fetchedAt, DateTime.utc(2026, 10, 7, 8));
    expect(catalog.stale, isTrue);
  });

  test('accepts a catalog that was never synchronized', () async {
    respondWith(
      catalogJson.replaceFirst(
        '"fetchedAt": "2026-10-07T08:00:00Z"',
        '"fetchedAt": null',
      ),
      200,
    );

    final catalog = await EtfRepository().retrieveEtfs();

    expect(catalog.fetchedAt, isNull);
  });

  test('decodes accented characters as utf-8', () async {
    respondWith(
      catalogJson.replaceFirst('Vanguard FTSE Europe ETF', 'Indice européen'),
      200,
    );

    final catalog = await EtfRepository().retrieveEtfs();

    expect(catalog.etfs.content.single.name, 'Indice européen');
  });

  test('lets the dio error through when the api answers with an error', () {
    respondWith(
      '[{ "error": "Internal Server Error", "message": "error.unexpected" }]',
      500,
    );

    expect(EtfRepository().retrieveEtfs(), throwsA(isA<DioException>()));
  });
}
