import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/api_constants.dart';
import 'connectivity_service.dart';
import 'dio_error_message.dart';
import 'network_exceptions.dart';

/// On Flutter Web, direct cross-origin requests are blocked by the browser
/// (CORS policy). We transparently rewrite the base URL to go through
/// corsproxy.io, which adds the required headers on the server side.
///
/// On Android / iOS / desktop the API is called directly.
class DioClient {
  DioClient._();

  static Dio create({ConnectivityService? connectivity}) {
    final connectivityService = connectivity ?? ConnectivityService();
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 45),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            await connectivityService.ensureOnline();
          } on OfflineException catch (error) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: error,
                message: error.message,
              ),
            );
          }

          if (kIsWeb) {
            final originalUrl = options.uri.toString();
            options.baseUrl = '';
            options.path = 'https://corsproxy.io/?$originalUrl';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Normalize so callers always get a mapped user message when needed.
          if (error.error is OfflineException) {
            return handler.next(
              DioException(
                requestOptions: error.requestOptions,
                type: DioExceptionType.connectionError,
                error: error.error,
                message: kNoInternetMessage,
              ),
            );
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
