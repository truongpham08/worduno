import 'dart:convert';
import 'dart:math';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/unit.dart';
import '../../../../shared/word_state/application/services/word_state_store.dart';
import '../../domain/entities/coach_entities.dart';
import '../../domain/entities/coach_star_filter.dart';
import '../../domain/repositories/i_coach_repository.dart';
import '../datasources/i_coach_ai_data_source.dart';
import '../datasources/i_coach_history_local_data_source.dart';

class CoachRepositoryImpl implements ICoachRepository {
  CoachRepositoryImpl(
    this._vocabularyService,
    this._wordStateStore,
    this._aiDataSource,
    this._historyDataSource,
  );

  final IVocabularyService _vocabularyService;
  final WordStateStore _wordStateStore;
  final ICoachAiDataSource _aiDataSource;
  final ICoachHistoryLocalDataSource _historyDataSource;

  final _random = Random();

  @override
  Future<int> countAvailableWords(CoachSessionConfig config) async {
    final pool = await _buildWordPool(config);
    return pool.length;
  }

  @override
  Future<CoachSession> buildSession(CoachSessionConfig config) async {
    final pool = await _buildWordPool(config);
    if (pool.isEmpty) {
      throw StateError('No words match the selected filters.');
    }

    final maxCount = pool.length < AppConstants.maxCoachWordCount
        ? pool.length
        : AppConstants.maxCoachWordCount;
    final count = config.wordCount.clamp(1, maxCount);
    final shuffled = List<CoachWord>.from(pool)..shuffle(_random);
    return CoachSession(
      words: shuffled.take(count).toList(growable: false),
      config: config,
    );
  }

  @override
  Future<CoachExplainResult> getExplanation(CoachWord word) async {
    await _wordStateStore.ensureLoaded(word.unitId, forceReload: true);
    final state = _wordStateStore.stateFor(
      unitId: word.unitId,
      termId: word.term.id,
    );

    if (state.explanation != null && state.explanation!.isNotEmpty) {
      final decoded = jsonDecode(state.explanation!) as Map<String, dynamic>;
      return CoachExplainResult.fromJson(decoded);
    }

    final response = await _aiDataSource.explainWord(
      word: word.term.text,
      definition: word.term.definition,
    );
    final result = CoachExplainResult.fromJson(response);
    final json = jsonEncode(result.toJson());

    await _wordStateStore.saveExplanation(
      unitId: word.unitId,
      termId: word.term.id,
      explanationJson: json,
    );

    return result;
  }

  @override
  Future<CoachEvaluateResult> evaluateSentence({
    required CoachWord word,
    required String sentence,
  }) async {
    final response = await _aiDataSource.evaluateSentence(
      word: word.term.text,
      sentence: sentence,
    );
    return CoachEvaluateResult.fromJson(response);
  }

  @override
  Future<void> saveCoachFeedback({
    required CoachWord word,
    required String userSentence,
    required CoachEvaluateResult result,
  }) async {
    await _wordStateStore.ensurePersisted(
      unitId: word.unitId,
      termId: word.term.id,
    );

    final entry = CoachFeedbackEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}-${word.unitId}-${word.term.id}',
      date: DateTime.now(),
      unitId: word.unitId,
      termId: word.term.id,
      levelCode: word.levelCode,
      unitName: word.unitName,
      definition: word.term.definition,
      userSentence: userSentence,
      responseJson: jsonEncode(result.rawJson),
    );
    await _historyDataSource.insertFeedback(entry);
  }

  @override
  Future<CoachExplainResult?> getCachedExplanation({
    required String unitId,
    required String termId,
  }) async {
    await _wordStateStore.ensureLoaded(unitId);
    final state = _wordStateStore.stateFor(unitId: unitId, termId: termId);
    if (state.explanation == null || state.explanation!.isEmpty) {
      return null;
    }
    return CoachExplainResult.fromJson(
      jsonDecode(state.explanation!) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<CoachHistoryTerm>> loadCoachedTerms() =>
      _historyDataSource.getCoachedTerms();

  @override
  Future<CoachHistoryTermDetail?> loadCoachedTermDetail({
    required String unitId,
    required String termId,
  }) async {
    final term = await _historyDataSource.getCoachedTerm(
      unitId: unitId,
      termId: termId,
    );
    if (term == null) return null;

    final explanation = await getCachedExplanation(
      unitId: unitId,
      termId: termId,
    );

    return CoachHistoryTermDetail(
      unitId: term.unitId,
      termId: term.termId,
      levelCode: term.levelCode,
      unitName: term.unitName,
      definition: term.definition,
      explanation: explanation,
    );
  }

  @override
  Future<List<CoachFeedbackEntry>> loadFeedbacksForTerm({
    required String unitId,
    required String termId,
  }) =>
      _historyDataSource.getFeedbacksForTerm(
        unitId: unitId,
        termId: termId,
      );

  @override
  Future<CoachFeedbackEntry?> loadFeedback(String feedbackId) =>
      _historyDataSource.getFeedbackById(feedbackId);

  @override
  Future<void> deleteFeedback(String feedbackId) =>
      _historyDataSource.deleteFeedback(feedbackId);

  @override
  Future<void> deleteAllFeedbacksForTerm({
    required String unitId,
    required String termId,
  }) =>
      _historyDataSource.deleteAllFeedbacksForTerm(
        unitId: unitId,
        termId: termId,
      );

  Future<List<CoachWord>> _buildWordPool(CoachSessionConfig config) async {
    final targets = await _resolveUnitTargets(config);
    if (targets.isEmpty) return const [];

    final tolerateUnitErrors = targets.length > 1;
    final chunks = await Future.wait(
      targets.map(
        (target) => _loadWordsForUnit(
          target,
          config.starFilter,
          tolerateErrors: tolerateUnitErrors,
        ),
      ),
    );

    return chunks.expand((words) => words).toList(growable: false);
  }

  Future<List<CoachWord>> _loadWordsForUnit(
    _UnitTarget target,
    CoachStarFilter starFilter, {
    required bool tolerateErrors,
  }) async {
    try {
      await _wordStateStore.ensureLoaded(target.unitId, forceReload: true);
      final terms = await _vocabularyService.getTerms(
        levelCode: target.levelCode,
        unitName: target.unitName,
      );

      final words = <CoachWord>[];
      for (final term in terms) {
        final state = _wordStateStore.stateFor(
          unitId: target.unitId,
          termId: term.id,
        );
        if (!_matchesStarFilter(state.isStarred, starFilter)) {
          continue;
        }
        words.add(
          CoachWord(
            levelCode: target.levelCode,
            unitName: target.unitName,
            unitId: target.unitId,
            term: term,
          ),
        );
      }
      return words;
    } catch (error) {
      if (!tolerateErrors) {
        rethrow;
      }
      return const [];
    }
  }

  bool _matchesStarFilter(bool isStarred, CoachStarFilter filter) {
    return switch (filter) {
      CoachStarFilter.all => true,
      CoachStarFilter.starred => isStarred,
      CoachStarFilter.notStarred => !isStarred,
    };
  }

  Future<List<_UnitTarget>> _resolveUnitTargets(CoachSessionConfig config) async {
    if (config.isUnitScoped) {
      final unitId = config.fixedUnitId?.isNotEmpty == true
          ? config.fixedUnitId!
          : await _resolveUnitId(
              levelCode: config.fixedLevelCode!,
              unitName: config.fixedUnitName!,
            );
      return [
        _UnitTarget(
          levelCode: config.fixedLevelCode!,
          unitName: config.fixedUnitName!,
          unitId: unitId,
        ),
      ];
    }

    if (config.unitKeys.isNotEmpty) {
      return _targetsFromUnitKeys(config.unitKeys);
    }

    final levels = config.levelCodes.isEmpty
        ? (await _vocabularyService.getLevels()).map((l) => l.code).toList()
        : config.levelCodes;

    final unitLists = await Future.wait(
      levels.map(_vocabularyService.getUnits),
    );

    final targets = <_UnitTarget>[];
    for (var i = 0; i < levels.length; i++) {
      final levelCode = levels[i];
      for (final unit in unitLists[i]) {
        targets.add(
          _UnitTarget(
            levelCode: levelCode,
            unitName: unit.name,
            unitId: unit.id,
          ),
        );
      }
    }
    return targets;
  }

  Future<List<_UnitTarget>> _targetsFromUnitKeys(List<String> unitKeys) async {
    final levelsNeeded = <String>{};
    for (final key in unitKeys) {
      final (levelCode, _) = _splitUnitKey(key);
      if (levelCode.isNotEmpty) {
        levelsNeeded.add(levelCode);
      }
    }

    final unitsByLevel = <String, List<Unit>>{};
    await Future.wait(
      levelsNeeded.map((levelCode) async {
        unitsByLevel[levelCode] = await _vocabularyService.getUnits(levelCode);
      }),
    );

    final targets = <_UnitTarget>[];
    for (final key in unitKeys) {
      final (levelCode, unitName) = _splitUnitKey(key);
      if (levelCode.isEmpty || unitName.isEmpty) continue;

      final units = unitsByLevel[levelCode];
      if (units == null) continue;

      final index = units.indexWhere((unit) => unit.name == unitName);
      if (index == -1) continue;

      final unit = units[index];
      targets.add(
        _UnitTarget(
          levelCode: levelCode,
          unitName: unitName,
          unitId: unit.id,
        ),
      );
    }
    return targets;
  }

  (String levelCode, String unitName) _splitUnitKey(String key) {
    final separator = key.indexOf('|');
    if (separator <= 0) return ('', '');
    return (key.substring(0, separator), key.substring(separator + 1));
  }

  Future<String> _resolveUnitId({
    required String levelCode,
    required String unitName,
  }) async {
    final units = await _vocabularyService.getUnits(levelCode);
    final index = units.indexWhere((unit) => unit.name == unitName);
    return index == -1 ? '' : units[index].id;
  }

  static String unitKey(String levelCode, String unitName) =>
      '$levelCode|$unitName';

  static String unitLabel({
    required String levelCode,
    required String unitName,
    required bool showLevelPrefix,
  }) {
    return showLevelPrefix ? '$levelCode • $unitName' : unitName;
  }
}

class _UnitTarget {
  const _UnitTarget({
    required this.levelCode,
    required this.unitName,
    required this.unitId,
  });

  final String levelCode;
  final String unitName;
  final String unitId;
}
