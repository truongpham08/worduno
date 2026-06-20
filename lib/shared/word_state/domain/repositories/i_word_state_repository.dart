import '../entities/user_word_state.dart';
import '../entities/word_status.dart';

abstract class IWordStateRepository {
  Future<List<UserWordState>> getByUnit(String unitId);

  Future<UserWordState?> getByTerm({
    required String unitId,
    required String termId,
  });

  Future<void> save(UserWordState state);

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
