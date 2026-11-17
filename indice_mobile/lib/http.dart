import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'environment.dart';
import 'errors/error_messages.dart';

final http = Dio();

void setupHttpClient() {
  http.options.baseUrl = Environment.apiUrl;
  http.options.headers['Content-Type'] = 'application/json';
  http.options.connectTimeout = const Duration(seconds: 10);
  http.options.receiveTimeout = const Duration(seconds: 20);

  http.interceptors.add(LoggingInterceptor());
}

void _debugLog(String message) => debugPrint(message);

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({this.log = _debugLog});

  final void Function(String message) log;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('→ ${_describe(options)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('← ${response.statusCode} ${_describe(response.requestOptions)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = _describe(err.requestOptions);
    final statusCode = err.response?.statusCode;
    if (statusCode == null) {
      log('✕ $request : ${err.type.name}');
    } else {
      final errorKey = _apiErrorKey(err.response?.data);
      log('✕ $statusCode $request${errorKey == null ? '' : ' : $errorKey'}');
    }
    handler.next(err);
  }

  String _describe(RequestOptions options) {
    final uri = options.uri;
    return '${options.method} ${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
  }
}

String? extractErrorMessage(Object error) {
  if (error is! DioException) return null;
  return switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout => networkErrorKey,
    DioExceptionType.receiveTimeout => serverTimeoutErrorKey,
    _ => _apiErrorKey(error.response?.data),
  };
}

String? _apiErrorKey(Object? data) {
  if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
    return (data.first as Map<String, dynamic>)['message'] as String?;
  }
  return null;
}
