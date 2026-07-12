import 'package:connectivity_plus/connectivity_plus.dart';

import 'network_exceptions.dart';

/// Thin wrapper around [Connectivity] for online checks before API calls.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Returns `true` when at least one non-none connectivity result is present.
  ///
  /// Fail open (treat as online) if the platform check errors or hangs past
  /// a short deadline — Dio timeouts still protect the actual request.
  Future<bool> get isOnline async {
    try {
      final results = await _connectivity.checkConnectivity().timeout(
        const Duration(seconds: 2),
      );
      if (results.isEmpty) return false;
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  /// Throws [OfflineException] when the device appears offline.
  Future<void> ensureOnline() async {
    if (!await isOnline) {
      throw const OfflineException();
    }
  }
}
