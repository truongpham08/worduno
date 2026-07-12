import '../network/dio_error_message.dart';
import 'app_exception.dart';

sealed class Failure {
  const Failure(this.message);

  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

Failure mapExceptionToFailure(Object error) {
  if (error is AppException) {
    return ServerFailure(error.message);
  }
  return UnknownFailure(messageFromError(error));
}
