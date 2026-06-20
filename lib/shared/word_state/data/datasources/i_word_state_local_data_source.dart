import '../../domain/entities/user_word_state.dart';

abstract class IWordStateLocalDataSource {
  Future<List<UserWordState>> getByUnit(String unitId);

  Future<UserWordState?> getByTerm({
    required String unitId,
    required String termId,
  });

  Future<void> upsert(UserWordState state);
}
