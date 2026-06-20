import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/app_exception.dart';

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
