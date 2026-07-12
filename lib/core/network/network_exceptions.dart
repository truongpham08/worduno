/// Thrown when the device has no usable network connection.
class OfflineException implements Exception {
  const OfflineException([this.message = 'No internet connection.']);

  final String message;

  @override
  String toString() => message;
}
