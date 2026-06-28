import '../../../../shared/word_state/application/services/word_state_store.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';
import '../../domain/entities/learn_session_data.dart';
import '../../domain/repositories/i_learn_repository.dart';
import 'i_learn_service.dart';

class LearnServiceImpl implements ILearnService {
  LearnServiceImpl(this._repository, this._wordStateStore);

  final ILearnRepository _repository;
  final WordStateStore _wordStateStore;

  @override
  Future<LearnSessionData> loadSessionData({
    required String levelCode,
    required String unitName,
    String? unitId,
  }) {
    return _repository.loadSessionData(
      levelCode: levelCode,
      unitName: unitName,
      unitId: unitId,
    );
  }

  @override
  Future<void> markStatus({
    required String unitId,
    required String termId,
    required WordStatus status,
  }) {
    return _wordStateStore.updateStatus(
      unitId: unitId,
      termId: termId,
      status: status,
    );
  }

  @override
  Future<void> toggleStar({
    required String unitId,
    required String termId,
  }) {
    return _wordStateStore.toggleStar(unitId: unitId, termId: termId);
  }
}
