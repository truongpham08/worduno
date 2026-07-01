import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Maps a [DioException] to a user-facing message using HTTP status and body.
String messageFromDioException(DioException error) {
  final status = error.response?.statusCode;
  final data = error.response?.data;

  if (status == 429) {
    return _detailFromBody(data) ??
        'AI quota exceeded. Wait about a minute and retry.';
  }
  if (status == 503) {
    return _detailFromBody(data) ??
        'AI service is temporarily unavailable. Try again shortly.';
  }
  if (status != null && status >= 500) {
    return _detailFromBody(data) ?? 'Server error ($status). Try again later.';
  }
  if (data != null) {
    final detail = _detailFromBody(data);
    if (detail != null) return detail;
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'Request timed out. AI responses can take longer — try again.',
    DioExceptionType.connectionError =>
      'Could not connect to the server. Check your internet connection.',
    _ => error.message ?? 'Request failed',
  };
}

String? _detailFromBody(Object? data) {
  if (data is! Map) return null;
  final detail = data['detail'];
  if (detail is String && detail.isNotEmpty) return detail;
  if (detail != null) return detail.toString();
  return null;
}

String messageFromError(Object error) {
  if (error is AppException) return error.message;
  final text = error.toString();
  if (text.startsWith('AppException')) {
    return text.replaceFirst(RegExp(r'^AppException(\([^)]*\))?: '), '');
  }
  return text;
}
