import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/core/network/dio_error_message.dart';

void main() {
  group('messageFromDioException', () {
    test('returns API detail for 429 quota errors', () {
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

      expect(
        messageFromDioException(error),
        'Hết quota Gemini free tier. Đợi ~1 phút rồi thử lại.',
      );
    });

    test('does not hide timeout as generic network failure', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/coach/explain'),
        type: DioExceptionType.receiveTimeout,
        message: 'Receiving data timeout',
      );

      expect(
        messageFromDioException(error),
        contains('timed out'),
      );
    });
  });
}
