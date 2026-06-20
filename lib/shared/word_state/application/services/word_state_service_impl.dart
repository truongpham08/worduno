import '../../domain/entities/user_word_state.dart';
import '../../domain/entities/word_status.dart';
import '../../domain/repositories/i_word_state_repository.dart';
import 'i_word_state_service.dart';

class WordStateServiceImpl implements IWordStateService {
  WordStateServiceImpl(this._repository);

  final IWordStateRepository _repository;

  @override
  Future<List<UserWordState>> getByUnit(String unitId) =>
      _repository.getByUnit(unitId);

  @override
  Future<UserWordState?> getByTerm({
    required String unitId,
    required String termId,
  }) =>
      _repository.getByTerm(unitId: unitId, termId: termId);

  @override
  Future<void> toggleStar({
    required String unitId,
    required String termId,
  }) =>
      _repository.toggleStar(unitId: unitId, termId: termId);

  @override
  Future<void> updateStatus({
    required String unitId,
    required String termId,
    required WordStatus status,
  }) =>
      _repository.updateStatus(
        unitId: unitId,
        termId: termId,
        status: status,
      );
}
