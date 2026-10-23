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

const etfDetailJson = '''
{
  "ticker": "SPY",
  "exchange": "NYSE",
  "name": "State Street SPDR S&P 500 ETF Trust",
  "currency": "USD",
  "marketData": {
    "lastClose": 766.48,
    "lastCloseDate": "2026-10-19",
    "historyStartDate": "2021-10-12",
    "returns": { "oneYear": 0.142, "threeYears": 0.51, "fiveYears": null, "fiveYearsAnnualized": null },
    "volatilityOneYear": 0.161,
    "maxDrawdown": { "value": -0.245, "peakDate": "2022-01-03", "troughDate": "2022-10-12" },
    "fiftyTwoWeekRange": { "low": 629.28, "high": 781.62, "position": 0.9 },
    "pricePoints": [
      { "date": "2021-10-12", "close": 450.00, "changeSinceStart": 0.0 },
      { "date": "2024-03-12", "close": 512.40, "changeSinceStart": 0.1387 }
    ]
  },
  "fetchedAt": "2026-10-20T09:00:00Z",
  "stale": false
}
''';

const comparisonJson = '''
{
  "commonPeriod": { "startDate": "2021-10-20", "endDate": "2026-10-19" },
  "correlation": null,
  "etfA": {
    "ticker": "SPY", "exchange": "NYSE", "name": "SPDR S&P 500 ETF Trust", "currency": "USD",
    "fetchedAt": "2026-10-20T08:00:00Z", "stale": false,
    "performance": {
      "totalReturn": 0.8123, "annualizedReturn": 0.1263, "volatility": 0.1712, "returnToRiskRatio": 0.7377,
      "maxDrawdown": { "value": -0.245, "peakDate": "2022-01-03", "troughDate": "2022-10-12" }
    },
    "pricePoints": [{ "date": "2021-10-20", "close": 450.00, "changeSinceStart": 0.0 }]
  },
  "etfB": {
    "ticker": "QQQ", "exchange": "NASDAQ", "name": "Invesco QQQ Trust", "currency": "USD",
    "fetchedAt": null, "stale": true,
    "performance": {
      "totalReturn": 0.9402, "annualizedReturn": null, "volatility": null, "returnToRiskRatio": null,
      "maxDrawdown": { "value": -0.3512, "peakDate": "2021-12-27", "troughDate": "2022-11-03" }
    },
    "pricePoints": [{ "date": "2021-10-20", "close": 380.00, "changeSinceStart": 0.0 }]
  }
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

  test('requests the detail of the etf by its ticker', () async {
    late Uri requestedUrl;
    http.httpClientAdapter = FakeHttpClientAdapter((options) async {
      requestedUrl = options.uri;
      return jsonBody(etfDetailJson, 200);
    });

    await EtfRepository().retrieveEtf('SPY');

    expect(requestedUrl, Uri.parse('$baseUrl/etfs/SPY'));
  });

  test('encodes the ticker in the requested path', () async {
    late Uri requestedUrl;
    http.httpClientAdapter = FakeHttpClientAdapter((options) async {
      requestedUrl = options.uri;
      return jsonBody(etfDetailJson, 200);
    });

    await EtfRepository().retrieveEtf('SP/Y');

    expect(requestedUrl.path, '/api/etfs/SP%2FY');
  });

  test('returns the etf detail sent by the api', () async {
    respondWith(etfDetailJson, 200);

    final etf = await EtfRepository().retrieveEtf('SPY');
    final marketData = etf.marketData!;

    expect(etf.ticker, 'SPY');
    expect(etf.name, 'State Street SPDR S&P 500 ETF Trust');
    expect(etf.fetchedAt, DateTime.utc(2026, 10, 20, 9));
    expect(etf.stale, isFalse);
    expect(marketData.lastClose, 766.48);
    expect(marketData.lastCloseDate, DateTime(2026, 10, 19));
    expect(marketData.historyStartDate, DateTime(2021, 10, 12));
    expect(marketData.returns.oneYear, 0.142);
    expect(marketData.returns.fiveYears, isNull);
    expect(marketData.returns.fiveYearsAnnualized, isNull);
    expect(marketData.volatilityOneYear, 0.161);
    expect(marketData.maxDrawdown!.value, -0.245);
    expect(marketData.maxDrawdown!.peakDate, DateTime(2022, 1, 3));
    expect(marketData.fiftyTwoWeekRange!.position, 0.9);
    expect(marketData.pricePoints, hasLength(2));
    expect(marketData.pricePoints.last.date, DateTime(2024, 3, 12));
    expect(marketData.pricePoints.last.close, 512.4);
    expect(marketData.pricePoints.last.changeSinceStart, 0.1387);
  });

  test('accepts an etf detail without market data', () async {
    respondWith('''
{
  "ticker": "SPY",
  "exchange": "NYSE",
  "name": "State Street SPDR S&P 500 ETF Trust",
  "currency": "USD",
  "marketData": null,
  "fetchedAt": null,
  "stale": true
}
''', 200);

    final etf = await EtfRepository().retrieveEtf('SPY');

    expect(etf.marketData, isNull);
    expect(etf.fetchedAt, isNull);
    expect(etf.stale, isTrue);
  });

  test('lets the dio error through when the etf is unknown', () {
    respondWith(
      '[{ "error": "Not Found", "message": "error.etfs.etf-not-found" }]',
      404,
    );

    expect(EtfRepository().retrieveEtf('ARKK'), throwsA(isA<DioException>()));
  });

  test('requests the comparison of the two etfs', () async {
    late Uri requestedUrl;
    http.httpClientAdapter = FakeHttpClientAdapter((options) async {
      requestedUrl = options.uri;
      return jsonBody(comparisonJson, 200);
    });

    await EtfRepository().compare('SPY', 'QQQ');

    expect(requestedUrl, Uri.parse('$baseUrl/etfs/compare?etfA=SPY&etfB=QQQ'));
  });

  test('returns the comparison sent by the api', () async {
    respondWith(comparisonJson, 200);

    final comparison = await EtfRepository().compare('SPY', 'QQQ');

    expect(comparison.commonPeriod.startDate, DateTime(2021, 10, 20));
    expect(comparison.commonPeriod.endDate, DateTime(2026, 10, 19));
    expect(comparison.correlation, isNull);
    expect(comparison.etfA.ticker, 'SPY');
    expect(comparison.etfA.fetchedAt, DateTime.utc(2026, 10, 20, 8));
    expect(comparison.etfA.performance.totalReturn, 0.8123);
    expect(comparison.etfA.performance.returnToRiskRatio, 0.7377);
    expect(comparison.etfA.performance.maxDrawdown.value, -0.245);
    expect(comparison.etfA.pricePoints.single.close, 450);
    expect(comparison.etfB.stale, isTrue);
    expect(comparison.etfB.fetchedAt, isNull);
    expect(comparison.etfB.performance.annualizedReturn, isNull);
    expect(comparison.etfB.performance.volatility, isNull);
  });

  test('lets the dio error through when the data is insufficient', () {
    respondWith(
      '[{ "error": "Unprocessable Entity", "message": "error.etfs.etf-a-insufficient-data" }]',
      422,
    );

    expect(EtfRepository().compare('SPY', 'QQQ'), throwsA(isA<DioException>()));
  });
}
