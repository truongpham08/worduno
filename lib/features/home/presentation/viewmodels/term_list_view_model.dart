import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/term.dart';
import '../../../../shared/word_state/application/services/i_word_state_service.dart';
import '../../../../shared/word_state/domain/entities/user_word_state.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';

class TermListViewModel extends ChangeNotifier {
  TermListViewModel({
    required this.levelCode,
    required this.unitName,
    String? unitId,
    IVocabularyService? vocabularyService,
    IWordStateService? wordStateService,
  })  : _vocabularyService = vocabularyService ?? getIt<IVocabularyService>(),
        _wordStateService = wordStateService ?? getIt<IWordStateService>(),
        _unitId = unitId ?? '';

  final String levelCode;
  final String unitName;
  final IVocabularyService _vocabularyService;
  final IWordStateService _wordStateService;

  String _unitId;
  String get unitId => _unitId;

  bool isLoading = false;
  String? errorMessage;
  List<Term> terms = const [];
  Map<String, UserWordState> _wordStates = {};

  Future<void> loadTerms() async {
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

  int get knownCount {
    return terms
        .where((t) => getWordState(t.id).status == WordStatus.know)
        .length;
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
      // Handle error if needed
    }
  }

  Future<void> updateStatus(String termId, WordStatus status) async {
    if (_unitId.isEmpty) return;
    try {
      await _wordStateService.updateStatus(
        unitId: _unitId,
        termId: termId,
        status: status,
      );
      final currentState = getWordState(termId);
      _wordStates[termId] = currentState.copyWith(status: status);
      notifyListeners();
    } catch (e) {
      // Handle error if needed
    }
  }
}
