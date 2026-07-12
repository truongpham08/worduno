import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../application/services/i_coach_service.dart';
import '../../domain/entities/coach_entities.dart';

class CoachHistoryViewModel extends ChangeNotifier {
  CoachHistoryViewModel({ICoachService? coachService})
      : _coachService = coachService ?? getIt<ICoachService>();

  final ICoachService _coachService;

  bool _isDisposed = false;
  bool isLoading = false;
  String? errorMessage;
  List<CoachHistoryTerm> terms = const [];

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> loadTerms() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      terms = await _coachService.loadCoachedTerms();
    } catch (error) {
      errorMessage = messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAllFeedbacks(CoachHistoryTerm term) async {
    await _coachService.deleteAllFeedbacksForTerm(
      unitId: term.unitId,
      termId: term.termId,
    );
    terms = terms
        .where((t) => !(t.unitId == term.unitId && t.termId == term.termId))
        .toList(growable: false);
    notifyListeners();
  }

  static String formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class CoachWordHistoryViewModel extends ChangeNotifier {
  CoachWordHistoryViewModel({
    required this.unitId,
    required this.termId,
    ICoachService? coachService,
  }) : _coachService = coachService ?? getIt<ICoachService>();

  final String unitId;
  final String termId;
  final ICoachService _coachService;

  bool _isDisposed = false;
  bool isLoading = false;
  String? errorMessage;
  CoachHistoryTermDetail? term;
  List<CoachFeedbackEntry> feedbacks = const [];

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      term = await _coachService.loadCoachedTermDetail(
        unitId: unitId,
        termId: termId,
      );
      feedbacks = await _coachService.loadFeedbacksForTerm(
        unitId: unitId,
        termId: termId,
      );
      if (term == null) {
        errorMessage = 'Term not found in coach history.';
      }
    } catch (error) {
      errorMessage = messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFeedback(String feedbackId) async {
    await _coachService.deleteFeedback(feedbackId);
    feedbacks = feedbacks.where((f) => f.id != feedbackId).toList(growable: false);
    notifyListeners();
  }

  Future<void> deleteAllFeedbacks() async {
    await _coachService.deleteAllFeedbacksForTerm(
      unitId: unitId,
      termId: termId,
    );
    feedbacks = const [];
    notifyListeners();
  }
}

class CoachFeedbackDetailViewModel extends ChangeNotifier {
  CoachFeedbackDetailViewModel({
    required this.feedbackId,
    ICoachService? coachService,
  }) : _coachService = coachService ?? getIt<ICoachService>();

  final String feedbackId;
  final ICoachService _coachService;

  bool _isDisposed = false;
  bool isLoading = false;
  String? errorMessage;
  CoachFeedbackEntry? feedback;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      feedback = await _coachService.loadFeedback(feedbackId);
      if (feedback == null) {
        errorMessage = 'Feedback not found.';
      }
    } catch (error) {
      errorMessage = messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFeedback() async {
    if (feedback == null) return;
    await _coachService.deleteFeedback(feedback!.id);
  }
}
