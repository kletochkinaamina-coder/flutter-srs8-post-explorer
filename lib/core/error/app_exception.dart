import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

/// Типы ошибок, которые различает приложение.
enum AppErrorType { noConnection, timeout, client, server, parse, unknown }

/// Единая ошибка приложения.
/// [message] — понятный текст для пользователя,
/// технические подробности пишем только в лог (debugPrint).
class AppException implements Exception {
  final AppErrorType type;
  final String message;
  final int? statusCode;

  const AppException(this.type, this.message, {this.statusCode});

  /// Превращает любую ошибку (Dio, JSON, другую) в AppException.
  factory AppException.from(Object error) {
    if (error is AppException) return error;

    // Технические детали — только в лог разработчика
    debugPrint('[AppException] ${error.runtimeType}: $error');

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const AppException(
            AppErrorType.timeout,
            'Сервер долго не отвечает. Попробуйте ещё раз.',
          );
        case DioExceptionType.connectionError:
          return const AppException(
            AppErrorType.noConnection,
            'Нет подключения к интернету.',
          );
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode ?? 0;
          if (code >= 500) {
            return AppException(
              AppErrorType.server,
              'Ошибка сервера ($code). Попробуйте позже.',
              statusCode: code,
            );
          }
          if (code == 404) {
            return AppException(
              AppErrorType.client,
              'Данные не найдены (404).',
              statusCode: code,
            );
          }
          return AppException(
            AppErrorType.client,
            'Ошибка запроса ($code).',
            statusCode: code,
          );
        default:
          final inner = error.error;
          if (inner is SocketException) {
            return const AppException(
              AppErrorType.noConnection,
              'Нет подключения к интернету.',
            );
          }
          if (inner != null && _isParseError(inner)) {
            return const AppException(
              AppErrorType.parse,
              'Сервер вернул данные в неожиданном формате.',
            );
          }
      }
    }

    if (_isParseError(error)) {
      return const AppException(
        AppErrorType.parse,
        'Сервер вернул данные в неожиданном формате.',
      );
    }

    return const AppException(AppErrorType.unknown, 'Что-то пошло не так.');
  }

  // Ошибки разбора JSON: json_serializable (checked: true), неверный JSON, не тот тип
  static bool _isParseError(Object e) =>
      e is CheckedFromJsonException || e is FormatException || e is TypeError;

  @override
  String toString() => 'AppException($type, $statusCode): $message';
}
