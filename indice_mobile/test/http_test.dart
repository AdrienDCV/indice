import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/errors/error_messages.dart';
import 'package:indice_mobile/http.dart';

import 'fakes/fake_http_client_adapter.dart';

DioException badResponse(Object? data) {
  final requestOptions = RequestOptions(path: '/etfs');
  return DioException.badResponse(
    statusCode: 500,
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      statusCode: 500,
      data: data,
    ),
  );
}

Dio loggedClient(
  List<String> logs,
  Future<ResponseBody> Function(RequestOptions options) onFetch,
) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
    ..httpClientAdapter = FakeHttpClientAdapter(onFetch)
    ..interceptors.add(LoggingInterceptor(log: logs.add));
}

void main() {
  test('extracts the error key of the first error sent by the api', () {
    final error = badResponse([
      {'error': 'Not Found', 'message': 'error.etfs.etf-not-found'},
      {'error': 'Bad Request', 'message': 'error.etfs.invalid-ticker'},
    ]);

    expect(extractErrorMessage(error), 'error.etfs.etf-not-found');
  });

  test('extracts nothing from an empty error list', () {
    expect(extractErrorMessage(badResponse([])), isNull);
  });

  test('extracts nothing from an unreadable error body', () {
    expect(
      extractErrorMessage(badResponse('<html>Bad Gateway</html>')),
      isNull,
    );
  });

  test('tells when the connection cannot be opened', () {
    final error = DioException.connectionError(
      requestOptions: RequestOptions(path: '/etfs'),
      reason: 'Connection refused',
    );

    expect(extractErrorMessage(error), networkErrorKey);
  });

  test('tells when the connection takes too long to open', () {
    final error = DioException.connectionTimeout(
      timeout: const Duration(seconds: 10),
      requestOptions: RequestOptions(path: '/etfs'),
    );

    expect(extractErrorMessage(error), networkErrorKey);
  });

  test('tells when the api takes too long to answer', () {
    final error = DioException.receiveTimeout(
      timeout: const Duration(seconds: 20),
      requestOptions: RequestOptions(path: '/etfs'),
    );

    expect(extractErrorMessage(error), serverTimeoutErrorKey);
  });

  test('extracts nothing from an error that does not come from dio', () {
    expect(extractErrorMessage(const FormatException()), isNull);
  });

  test('gives up on an unreachable api so that the cache can take over', () {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:8080/api');

    setupHttpClient();
    addTearDown(http.interceptors.clear);

    expect(http.options.connectTimeout, const Duration(seconds: 10));
    expect(http.options.receiveTimeout, const Duration(seconds: 20));
  });

  test('logs the request and the status of a successful response', () async {
    final logs = <String>[];
    final client = loggedClient(logs, (_) async => jsonBody('{}', 200));

    await client.get<void>('/etfs', queryParameters: {'page': 0, 'size': 50});

    expect(logs, [
      '→ GET /api/etfs?page=0&size=50',
      '← 200 GET /api/etfs?page=0&size=50',
    ]);
  });

  test('logs the status and the error key of an api error', () async {
    final logs = <String>[];
    final client = loggedClient(
      logs,
      (_) async => jsonBody(
        '[{"error": "Not Found", "message": "error.etfs.etf-not-found"}]',
        404,
      ),
    );

    await expectLater(
      client.get<void>('/etfs/ARKK'),
      throwsA(isA<DioException>()),
    );

    expect(logs.last, '✕ 404 GET /api/etfs/ARKK : error.etfs.etf-not-found');
  });

  test('logs the kind of error when the api cannot be reached', () async {
    final logs = <String>[];
    final client = loggedClient(
      logs,
      (options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'refused',
      ),
    );

    await expectLater(client.get<void>('/etfs'), throwsA(isA<DioException>()));

    expect(logs.last, '✕ GET /api/etfs : connectionError');
  });
}
