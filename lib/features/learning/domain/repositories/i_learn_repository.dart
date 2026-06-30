import '../entities/learn_session_data.dart';

abstract class ILearnRepository {
  /// Resolves the unit id (if not supplied), loads the unit's terms and their
  /// persisted word states, and returns them bundled as [LearnSessionData].
  Future<LearnSessionData> loadSessionData({
    required String levelCode,
    required String unitName,
    String? unitId,
  });
}
