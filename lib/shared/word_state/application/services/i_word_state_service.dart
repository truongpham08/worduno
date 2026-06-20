import '../../domain/entities/user_word_state.dart';
import '../../domain/entities/word_status.dart';

abstract class IWordStateService {
  Future<List<UserWordState>> getByUnit(String unitId);

  Future<UserWordState?> getByTerm({
    required String unitId,
    required String termId,
  });

  Future<void> toggleStar({
    required String unitId,
    required String termId,
  });

  Future<void> updateStatus({
    required String unitId,
    required String termId,
    required WordStatus status,
  });
}
