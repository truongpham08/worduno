import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/word_state/application/services/word_state_store.dart';
import '../../domain/entities/learn_session_data.dart';
import '../../domain/repositories/i_learn_repository.dart';

class LearnRepositoryImpl implements ILearnRepository {
  LearnRepositoryImpl(this._vocabularyService, this._wordStateStore);

  final IVocabularyService _vocabularyService;
  final WordStateStore _wordStateStore;

  @override
  Future<LearnSessionData> loadSessionData({
    required String levelCode,
    required String unitName,
    String? unitId,
  }) async {
    final terms = await _vocabularyService.getTerms(
      levelCode: levelCode,
      unitName: unitName,
    );

    final resolvedUnitId =
        await _resolveUnitId(levelCode: levelCode, unitName: unitName, unitId: unitId);

    // Force a reload so the session reflects any changes made on other screens.
    await _wordStateStore.ensureLoaded(resolvedUnitId, forceReload: true);

    final states = {
      for (final state in _wordStateStore.statesOf(resolvedUnitId))
        state.termId: state,
    };

    return LearnSessionData(
      unitId: resolvedUnitId,
      terms: terms,
      states: states,
    );
  }

  Future<String> _resolveUnitId({
    required String levelCode,
    required String unitName,
    String? unitId,
  }) async {
    if (unitId != null && unitId.isNotEmpty) {
      return unitId;
    }

    final units = await _vocabularyService.getUnits(levelCode);
    final index = units.indexWhere((unit) => unit.name == unitName);
    return index == -1 ? '' : units[index].id;
  }
}
