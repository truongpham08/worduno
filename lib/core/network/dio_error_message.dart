import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import 'network_exceptions.dart';

/// User-facing copy for offline / no connectivity.
const String kNoInternetMessage = 'No internet connection.';

/// User-facing copy when the AI model/quota/service is unavailable.
const String kAiUnavailableMessage = 'AI model is currently unavailable.';

/// User-facing copy for request timeouts.
const String kTimeoutMessage = 'Request timed out. Please try again.';

/// Maps a [DioException] to a safe user-facing message (never raw Dio text).
String messageFromDioException(DioException error) {
  final status = error.response?.statusCode;

  if (status == 429 || status == 503) {
    return kAiUnavailableMessage;
  }
  if (status != null && status >= 500) {
    return 'Server error. Please try again later.';
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      kTimeoutMessage,
    DioExceptionType.connectionError => kNoInternetMessage,
    DioExceptionType.cancel => 'Request was cancelled.',
    _ => 'Request failed. Please try again.',
  };
}

/// Maps any thrown [error] to a safe user-facing message for UI banners/views.
String messageFromError(Object error) {
  if (error is OfflineException) {
    return error.message;
  }
  if (error is AppException) {
    return error.message;
  }
  if (error is DioException) {
    return messageFromDioException(error);
  }
  if (error is StateError) {
    return _messageFromStateError(error);
  }

  final text = error.toString();
  if (text.startsWith('AppException')) {
    final stripped = text.replaceFirst(
      RegExp(r'^AppException(\([^)]*\))?: '),
      '',
    );
    // Nested DioException text must not reach the UI.
    if (stripped.contains('DioException') ||
        stripped.contains('SocketException')) {
      return kNoInternetMessage;
    }
    return stripped;
  }
  if (text.startsWith('Bad state:')) {
    return _messageFromStateErrorMessage(
      text.replaceFirst(RegExp(r'^Bad state:\s*'), ''),
    );
  }
  if (text.contains('DioException') || text.contains('SocketException')) {
    return kNoInternetMessage;
  }
  return 'Something went wrong. Please try again.';
}

String _messageFromStateError(StateError error) {
  return _messageFromStateErrorMessage(error.message);
}

String _messageFromStateErrorMessage(String message) {
  final notEnough = RegExp(
    r'Not enough words \((\d+)\) for (\d+) questions',
  ).firstMatch(message);
  if (notEnough != null) {
    return 'Not enough words (${notEnough.group(1)}) for '
        '${notEnough.group(2)} questions.';
  }

  final partial = RegExp(
    r'Could only generate (\d+) of (\d+) questions',
  ).firstMatch(message);
  if (partial != null) {
    return 'Could only generate ${partial.group(1)} of '
        '${partial.group(2)} questions. Try fewer questions or more words.';
  }

  if (message.contains('No words match the selected filters')) {
    return 'No words match the selected filters.';
  }
  if (message.contains('At least one question type must be enabled')) {
    return 'Select at least one question type.';
  }

  // Strip "Bad state:" prefix if present; avoid leaking raw internals.
  final cleaned = message.replaceFirst(RegExp(r'^Bad state:\s*'), '').trim();
  if (cleaned.isEmpty) {
    return 'Something went wrong. Please try again.';
  }
  return cleaned;
}
