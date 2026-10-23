import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_interceptor.dart';

/// Единый HTTP-клиент приложения.
/// Dio создаётся ОДИН раз и переиспользуется всеми запросами.
class DioClient {
  DioClient._();

  static const baseUrl = 'https://jsonplaceholder.typicode.com';

  static final Dio instance = createDio();

  static Dio createDio({String baseUrl = baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors.add(ApiInterceptor());

    // Подробный лог запросов только в debug-сборке
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
    return dio;
  }
}
