import '../../domain/entities/coach_entities.dart';
import '../../domain/repositories/i_coach_repository.dart';
import 'i_coach_service.dart';

class CoachServiceImpl implements ICoachService {
  CoachServiceImpl(this._repository);

  final ICoachRepository _repository;

  CoachSession? _currentSession;

  @override
  CoachSession? get currentSession => _currentSession;

  @override
  Future<int> countAvailableWords(CoachSessionConfig config) =>
      _repository.countAvailableWords(config);

  @override
  Future<void> startSession(CoachSessionConfig config) async {
    _currentSession = await _repository.buildSession(config);
  }

  @override
  void clearSession() {
    _currentSession = null;
  }

  @override
  Future<CoachExplainResult> getExplanation(CoachWord word) =>
      _repository.getExplanation(word);

  @override
  Future<CoachEvaluateResult> evaluateSentence({
    required CoachWord word,
    required String sentence,
  }) =>
      _repository.evaluateSentence(word: word, sentence: sentence);

  @override
  Future<void> saveCoachFeedback({
    required CoachWord word,
    required String userSentence,
    required CoachEvaluateResult result,
  }) =>
      _repository.saveCoachFeedback(
        word: word,
        userSentence: userSentence,
        result: result,
      );

  @override
  Future<List<CoachHistoryTerm>> loadCoachedTerms() =>
      _repository.loadCoachedTerms();

  @override
  Future<CoachHistoryTermDetail?> loadCoachedTermDetail({
    required String unitId,
    required String termId,
  }) =>
      _repository.loadCoachedTermDetail(unitId: unitId, termId: termId);

  @override
  Future<List<CoachFeedbackEntry>> loadFeedbacksForTerm({
    required String unitId,
    required String termId,
  }) =>
      _repository.loadFeedbacksForTerm(unitId: unitId, termId: termId);

  @override
  Future<CoachFeedbackEntry?> loadFeedback(String feedbackId) =>
      _repository.loadFeedback(feedbackId);

  @override
  Future<void> deleteFeedback(String feedbackId) =>
      _repository.deleteFeedback(feedbackId);

  @override
  Future<void> deleteAllFeedbacksForTerm({
    required String unitId,
    required String termId,
  }) =>
      _repository.deleteAllFeedbacksForTerm(
        unitId: unitId,
        termId: termId,
      );
}
