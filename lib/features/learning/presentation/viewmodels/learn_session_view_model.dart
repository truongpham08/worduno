import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/term.dart';
import '../../../../shared/word_state/application/services/i_word_state_service.dart';
import '../../../../shared/word_state/domain/entities/user_word_state.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';

class LearnSessionViewModel extends ChangeNotifier {
  LearnSessionViewModel({
    required this.levelCode,
    required this.unitName,
    String? unitId,
    this.initialTermId,
    IVocabularyService? vocabularyService,
    IWordStateService? wordStateService,
  })  : _vocabularyService = vocabularyService ?? getIt<IVocabularyService>(),
        _wordStateService = wordStateService ?? getIt<IWordStateService>(),
        _unitId = unitId ?? '';

  final String levelCode;
  final String unitName;
  final String? initialTermId;
  final IVocabularyService _vocabularyService;
  final IWordStateService _wordStateService;

  String _unitId;
  String get unitId => _unitId;

  bool _isDisposed = false;

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

  bool isLoading = false;
  String? errorMessage;
  List<Term> terms = [];
  Map<String, UserWordState> _wordStates = {};

  int currentIndex = 0;
  bool isFlipped = false;
  final List<int> history = [];

  bool get isCompleted => terms.isNotEmpty && currentIndex >= terms.length;

  Future<void> loadSession() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      terms = await _vocabularyService.getTerms(
        levelCode: levelCode,
        unitName: unitName,
      );

      if (_unitId.isEmpty) {
        final units = await _vocabularyService.getUnits(levelCode);
        final idx = units.indexWhere((u) => u.name == unitName);
        if (idx != -1) {
          _unitId = '$levelCode-$idx';
        }
      }

      if (_unitId.isNotEmpty) {
        final states = await _wordStateService.getByUnit(_unitId);
        _wordStates = {for (final s in states) s.termId: s};
      }

      if (initialTermId != null && initialTermId!.isNotEmpty) {
        final idx = terms.indexWhere((t) => t.id == initialTermId);
        if (idx != -1) {
          currentIndex = idx;
        }
      } else {
        // Find the first term that is not 'know' (not learned yet)
        final firstNotKnownIdx = terms.indexWhere((t) {
          final state = getWordState(t.id);
          return state.status != WordStatus.know;
        });
        if (firstNotKnownIdx != -1) {
          currentIndex = firstNotKnownIdx;
        } else {
          currentIndex = 0;
        }
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  UserWordState getWordState(String termId) {
    return _wordStates[termId] ??
        UserWordState(
          unitId: _unitId,
          termId: termId,
          isStarred: false,
          status: WordStatus.newWord,
        );
  }

  void flipCard() {
    isFlipped = !isFlipped;
    notifyListeners();
  }

  Future<void> toggleStar(String termId) async {
    if (_unitId.isEmpty) return;
    try {
      await _wordStateService.toggleStar(unitId: _unitId, termId: termId);
      final currentState = getWordState(termId);
      _wordStates[termId] =
          currentState.copyWith(isStarred: !currentState.isStarred);
      notifyListeners();
    } catch (e) {
      // Catch silently
    }
  }

  Future<void> stillLearning() async {
    if (currentIndex >= terms.length) return;
    final term = terms[currentIndex];

    try {
      await _wordStateService.updateStatus(
        unitId: _unitId,
        termId: term.id,
        status: WordStatus.learning,
      );
      final currentState = getWordState(term.id);
      _wordStates[term.id] = currentState.copyWith(status: WordStatus.learning);
    } catch (e) {
      // Catch silently
    }

    history.add(currentIndex);
    currentIndex++;
    isFlipped = false;
    notifyListeners();
  }

  Future<void> knowThis() async {
    if (currentIndex >= terms.length) return;
    final term = terms[currentIndex];

    try {
      await _wordStateService.updateStatus(
        unitId: _unitId,
        termId: term.id,
        status: WordStatus.know,
      );
      final currentState = getWordState(term.id);
      _wordStates[term.id] = currentState.copyWith(status: WordStatus.know);
    } catch (e) {
      // Catch silently
    }

    history.add(currentIndex);
    currentIndex++;
    isFlipped = false;
    notifyListeners();
  }

  void undo() {
    if (history.isNotEmpty) {
      currentIndex = history.removeLast();
      isFlipped = false;
      notifyListeners();
    }
  }

  void shuffle() {
    if (terms.isEmpty) return;
    terms = List.from(terms)..shuffle();
    currentIndex = 0;
    history.clear();
    isFlipped = false;
    notifyListeners();
  }
}
