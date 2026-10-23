import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indice_mobile/http.dart';

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

  test('extracts nothing when the api is unreachable', () {
    final error = DioException.connectionError(
      requestOptions: RequestOptions(path: '/etfs'),
      reason: 'Connection refused',
    );

    expect(extractErrorMessage(error), isNull);
  });

  test('extracts nothing from an error that does not come from dio', () {
    expect(extractErrorMessage(const FormatException()), isNull);
  });
}
