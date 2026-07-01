import '../../domain/entities/coach_entities.dart';

abstract class ICoachHistoryLocalDataSource {
  Future<void> insertFeedback(CoachFeedbackEntry entry);

  Future<List<CoachHistoryTerm>> getCoachedTerms();

  Future<CoachHistoryTerm?> getCoachedTerm({
    required String unitId,
    required String termId,
  });

  Future<List<CoachFeedbackEntry>> getFeedbacksForTerm({
    required String unitId,
    required String termId,
  });

  Future<CoachFeedbackEntry?> getFeedbackById(String id);

  Future<void> deleteFeedback(String feedbackId);

  Future<void> deleteAllFeedbacksForTerm({
    required String unitId,
    required String termId,
  });
}
