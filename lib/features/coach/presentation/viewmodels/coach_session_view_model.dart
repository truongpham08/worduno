import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../application/services/i_coach_service.dart';
import '../../domain/entities/coach_entities.dart';

enum CoachSessionPhase {
  loading,
  explainLoading,
  explain,
  explainError,
  writing,
  evaluating,
  feedback,
  completed,
}

class _WordStepState {
  const _WordStepState({
    required this.userSentence,
    required this.explainResult,
    required this.evaluateResult,
    required this.phase,
    required this.skippedExplain,
  });

  final String userSentence;
  final CoachExplainResult? explainResult;
  final CoachEvaluateResult? evaluateResult;
  final CoachSessionPhase phase;
  final bool skippedExplain;
}

class CoachSessionViewModel extends ChangeNotifier {
  CoachSessionViewModel({
    ICoachService? coachService,
  }) : _coachService = coachService ?? getIt<ICoachService>();

  final ICoachService _coachService;
  final Map<int, _WordStepState> _stepCache = {};
  final Set<int> _skippedIndices = {};

  bool _isDisposed = false;
  CoachSessionPhase phase = CoachSessionPhase.loading;
  String? errorMessage;

  CoachSession? session;
  int currentIndex = 0;
  CoachExplainResult? explainResult;
  CoachEvaluateResult? evaluateResult;
  String userSentence = '';
  bool skippedExplain = false;

  int feedbackCount = 0;
  int skippedCount = 0;

  CoachWord? get currentWord {
    final words = session?.words;
    if (words == null || currentIndex >= words.length) return null;
    return words[currentIndex];
  }

  int get totalWords => session?.words.length ?? 0;
  bool get hasSession => session != null && totalWords > 0;
  bool get canGoBack => currentIndex > 0;
  bool get hasRemainingWords => currentIndex < totalWords - 1;
  bool get hasSkippedWords => _skippedIndices.isNotEmpty;

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

  Future<void> initSession() async {
    phase = CoachSessionPhase.loading;
    errorMessage = null;
    _stepCache.clear();
    _skippedIndices.clear();
    feedbackCount = 0;
    skippedCount = 0;
    notifyListeners();

    session = _coachService.currentSession;
    if (!hasSession) {
      errorMessage = 'No coach session found. Please configure again.';
      notifyListeners();
      return;
    }

    currentIndex = 0;
    userSentence = '';
    evaluateResult = null;
    skippedExplain = false;
    await _loadExplain();
  }

  void _cacheCurrentStep() {
    if (phase == CoachSessionPhase.loading ||
        phase == CoachSessionPhase.completed) {
      return;
    }
    _stepCache[currentIndex] = _WordStepState(
      userSentence: userSentence,
      explainResult: explainResult,
      evaluateResult: evaluateResult,
      phase: phase,
      skippedExplain: skippedExplain,
    );
  }

  void _restoreStep(int index) {
    final cached = _stepCache[index];
    if (cached != null) {
      userSentence = cached.userSentence;
      explainResult = cached.explainResult;
      evaluateResult = cached.evaluateResult;
      phase = cached.phase;
      skippedExplain = cached.skippedExplain;
      errorMessage = null;
      return;
    }

    userSentence = '';
    evaluateResult = null;
    skippedExplain = false;
    explainResult = null;
  }

  Future<void> _loadExplain() async {
    final word = currentWord;
    if (word == null) return;

    phase = CoachSessionPhase.explainLoading;
    errorMessage = null;
    notifyListeners();

    try {
      explainResult = await _coachService.getExplanation(word);
      skippedExplain = false;
      phase = CoachSessionPhase.explain;
    } catch (error) {
      errorMessage = messageFromError(error);
      phase = CoachSessionPhase.explainError;
    }
    notifyListeners();
  }

  Future<void> goToPreviousWord() async {
    if (!canGoBack) return;
    _cacheCurrentStep();
    currentIndex--;
    _restoreStep(currentIndex);
    if (!_stepCache.containsKey(currentIndex) ||
        phase == CoachSessionPhase.explainLoading) {
      await _loadExplain();
    } else {
      notifyListeners();
    }
  }

  void retryExplain() {
    _loadExplain();
  }

  void skipExplain() {
    skippedExplain = true;
    explainResult = null;
    phase = CoachSessionPhase.writing;
    notifyListeners();
  }

  void acknowledgeExplain() {
    phase = CoachSessionPhase.writing;
    notifyListeners();
  }

  void updateSentence(String value) {
    userSentence = value;
    notifyListeners();
  }

  Future<void> submitSentence() async {
    final word = currentWord;
    if (word == null) return;

    final sentence = userSentence.trim();
    if (sentence.isEmpty) {
      errorMessage = 'Please write a sentence before submitting.';
      notifyListeners();
      return;
    }

    phase = CoachSessionPhase.evaluating;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _coachService.evaluateSentence(
        word: word,
        sentence: sentence,
      );
      evaluateResult = result;
      await _coachService.saveCoachFeedback(
        word: word,
        userSentence: sentence,
        result: result,
      );
      _skippedIndices.remove(currentIndex);
      feedbackCount++;
      phase = CoachSessionPhase.feedback;
    } catch (error) {
      errorMessage = messageFromError(error);
      phase = CoachSessionPhase.writing;
    }
    notifyListeners();
  }

  Future<void> skipCurrentWord() async {
    if (currentWord == null) return;
    _cacheCurrentStep();
    if (!_skippedIndices.contains(currentIndex) &&
        phase != CoachSessionPhase.feedback) {
      _skippedIndices.add(currentIndex);
      skippedCount = _skippedIndices.length;
    }
    await _advanceWord();
  }

  Future<void> nextWord() async {
    _cacheCurrentStep();
    await _advanceWord();
  }

  Future<void> _advanceWord() async {
    if (currentIndex + 1 >= totalWords) {
      _completeSession();
      return;
    }

    currentIndex++;
    _restoreStep(currentIndex);
    if (_stepCache.containsKey(currentIndex) &&
        _stepCache[currentIndex]!.phase != CoachSessionPhase.explainLoading) {
      notifyListeners();
      return;
    }
    await _loadExplain();
  }

  void finishSessionEarly() {
    _completeSession();
  }

  void _completeSession() {
    phase = CoachSessionPhase.completed;
    _coachService.clearSession();
    notifyListeners();
  }

  void endSession() {
    _coachService.clearSession();
  }
}
