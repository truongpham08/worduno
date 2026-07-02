import '../../domain/entities/coach_entities.dart';

abstract class ICoachRepository {
  Future<int> countAvailableWords(CoachSessionConfig config);

  Future<CoachSession> buildSession(CoachSessionConfig config);

  Future<CoachExplainResult> getExplanation(CoachWord word);

  Future<CoachExplainResult?> getCachedExplanation({
    required String unitId,
    required String termId,
  });

  Future<CoachEvaluateResult> evaluateSentence({
    required CoachWord word,
    required String sentence,
  });

  Future<void> saveCoachFeedback({
    required CoachWord word,
    required String userSentence,
    required CoachEvaluateResult result,
  });

  Future<List<CoachHistoryTerm>> loadCoachedTerms();

  Future<CoachHistoryTermDetail?> loadCoachedTermDetail({
    required String unitId,
    required String termId,
  });

  Future<List<CoachFeedbackEntry>> loadFeedbacksForTerm({
    required String unitId,
    required String termId,
  });

  Future<CoachFeedbackEntry?> loadFeedback(String feedbackId);

  Future<void> deleteFeedback(String feedbackId);

  Future<void> deleteAllFeedbacksForTerm({
    required String unitId,
    required String termId,
  });
}
