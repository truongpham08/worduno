import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/api_constants.dart';
import '../errors/app_exception.dart';

/// On Flutter Web, direct cross-origin requests are blocked by the browser
/// (CORS policy). We transparently rewrite the base URL to go through
/// corsproxy.io, which adds the required headers on the server side.
///
/// On Android / iOS / desktop the API is called directly.
class DioClient {
  DioClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    if (kIsWeb) {
      // Intercept every request and prepend the CORS proxy
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Build the full original URL
            final originalUrl = options.uri.toString();
            // Rewrite to go through corsproxy.io
            options.baseUrl = '';
            options.path = 'https://corsproxy.io/?$originalUrl';
            handler.next(options);
          },
        ),
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final message = error.message ?? 'Network request failed';
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: AppException(message),
            ),
          );
        },
      ),
    );

    return dio;
  }
}
