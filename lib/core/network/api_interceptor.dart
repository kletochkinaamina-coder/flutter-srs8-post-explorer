import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Свой interceptor: добавляет технические заголовки к каждому запросу
/// и пишет в лог все HTTP-ошибки в одном месте.
class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept'] = 'application/json';
    options.headers['X-App-Name'] = 'PostExplorer';
    options.headers['X-App-Version'] = '1.0.0';
    // Уникальный номер запроса — удобно искать в логах
    options.headers['X-Request-Id'] =
        DateTime.now().microsecondsSinceEpoch.toString();
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[API ERROR] ${err.requestOptions.method} ${err.requestOptions.uri} '
      '-> ${err.response?.statusCode ?? '-'} (${err.type.name})',
    );
    handler.next(err);
  }
}
