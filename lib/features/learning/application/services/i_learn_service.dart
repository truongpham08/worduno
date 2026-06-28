import '../../../../shared/word_state/domain/entities/word_status.dart';
import '../../domain/entities/learn_session_data.dart';

abstract class ILearnService {
  /// Loads the data required to start a Learn session for a unit.
  Future<LearnSessionData> loadSessionData({
    required String levelCode,
    required String unitName,
    String? unitId,
  });

  /// Persists the learning [status] for a term.
  Future<void> markStatus({
    required String unitId,
    required String termId,
    required WordStatus status,
  });

  /// Toggles the starred flag for a term.
  Future<void> toggleStar({
    required String unitId,
    required String termId,
  });
}
