import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'environment.dart';

final http = Dio();

void setupHttpClient() {
  http.options.baseUrl = Environment.apiUrl;
  http.options.headers['Content-Type'] = 'application/json';

  http.interceptors.add(LoggingInterceptor());
}

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logPrint('*** API Request - Start ***');

    printKV('URI', options.uri);
    printKV('METHOD', options.method);
    logPrint('HEADERS:');
    options.headers.forEach((key, v) => printKV(' - $key', v));
    logPrint('BODY:');
    printAll(options.data ?? '');

    logPrint('*** API Request - End ***');

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logPrint('*** Api Error - Start ***:');

    logPrint('URI: ${err.requestOptions.uri}');
    if (err.response != null) {
      logPrint('STATUS CODE: ${err.response?.statusCode?.toString()}');
    }
    logPrint('$err');
    if (err.response != null) {
      printKV('REDIRECT', err.response?.realUri ?? '');
      logPrint('BODY:');
      printAll(err.response?.data.toString());
    }

    logPrint('*** Api Error - End ***:');
    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logPrint('*** Api Response - Start ***');

    printKV('URI', response.requestOptions.uri);
    printKV('STATUS CODE', response.statusCode ?? '');
    printKV('REDIRECT', response.isRedirect);
    logPrint('BODY:');
    printAll(response.data ?? '');

    logPrint('*** Api Response - End ***');

    handler.next(response);
  }

  void printKV(String key, Object? v) {
    logPrint('$key: $v');
  }

  void printAll(Object? msg) {
    msg.toString().split('\n').forEach(logPrint);
  }

  void logPrint(String s) {
    debugPrint(s);
  }
}

String? extractErrorMessage(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
    return (data.first as Map<String, dynamic>)['message'] as String?;
  }
  return null;
}
