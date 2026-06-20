import '../../domain/entities/user_word_state.dart';
import '../../domain/entities/word_status.dart';
import '../../domain/repositories/i_word_state_repository.dart';
import '../datasources/i_word_state_local_data_source.dart';

class WordStateRepositoryImpl implements IWordStateRepository {
  WordStateRepositoryImpl(this._localDataSource);

  final IWordStateLocalDataSource _localDataSource;

  @override
  Future<List<UserWordState>> getByUnit(String unitId) =>
      _localDataSource.getByUnit(unitId);

  @override
  Future<UserWordState?> getByTerm({
    required String unitId,
    required String termId,
  }) =>
      _localDataSource.getByTerm(unitId: unitId, termId: termId);

  @override
  Future<void> save(UserWordState state) => _localDataSource.upsert(state);

  @override
  Future<void> toggleStar({
    required String unitId,
    required String termId,
  }) async {
    final current = await getByTerm(unitId: unitId, termId: termId);
    final next = (current ??
            UserWordState(
              unitId: unitId,
              termId: termId,
              isStarred: false,
              status: WordStatus.newWord,
            ))
        .copyWith(isStarred: !(current?.isStarred ?? false));

    await save(next);
  }

  @override
  Future<void> updateStatus({
    required String unitId,
    required String termId,
    required WordStatus status,
  }) async {
    final current = await getByTerm(unitId: unitId, termId: termId);
    final next = (current ??
            UserWordState(
              unitId: unitId,
              termId: termId,
              isStarred: false,
              status: WordStatus.newWord,
            ))
        .copyWith(status: status);

    await save(next);
  }
}
