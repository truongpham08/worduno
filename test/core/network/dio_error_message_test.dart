import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/core/errors/app_exception.dart';
import 'package:worduno/core/network/dio_error_message.dart';
import 'package:worduno/core/network/network_exceptions.dart';

void main() {
  group('messageFromDioException', () {
    test('maps 429 quota to generic AI unavailable message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/coach/explain'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/coach/explain'),
          statusCode: 429,
          data: {
            'detail':
                'Hết quota Gemini free tier. Đợi ~1 phút rồi thử lại.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(messageFromDioException(error), kAiUnavailableMessage);
    });

    test('maps 503 to AI unavailable', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/exam/cloze'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/exam/cloze'),
          statusCode: 503,
          data: {'detail': 'Service unavailable'},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(messageFromDioException(error), kAiUnavailableMessage);
    });

    test('maps receive timeout to timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/coach/explain'),
        type: DioExceptionType.receiveTimeout,
        message: 'Receiving data timeout',
      );

      expect(messageFromDioException(error), kTimeoutMessage);
    });

    test('maps connection error to no internet', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/levels'),
        type: DioExceptionType.connectionError,
        message: 'Connection refused',
      );

      expect(messageFromDioException(error), kNoInternetMessage);
    });
  });

  group('messageFromError', () {
    test('keeps AppException message', () {
      expect(
        messageFromError(const AppException('Failed to load levels')),
        'Failed to load levels',
      );
    });

    test('maps Offline exception', () {
      expect(
        messageFromError(const OfflineException()),
        kNoInternetMessage,
      );
    });

    test('maps not enough words StateError', () {
      expect(
        messageFromError(
          StateError('Not enough words (0) for 10 questions.'),
        ),
        'Not enough words (0) for 10 questions.',
      );
    });

    test('strips nested DioException from AppException string', () {
      expect(
        messageFromError(
          Exception(
            'AppException(null): Failed to load levels: DioException [connection error]',
          ),
        ),
        kNoInternetMessage,
      );
    });
  });
}
