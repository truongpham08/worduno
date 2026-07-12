import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/term.dart';
import '../../../../shared/word_state/application/services/word_state_store.dart';
import '../../../../shared/word_state/domain/entities/user_word_state.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';

class TermListViewModel extends ChangeNotifier {
  TermListViewModel({
    required this.levelCode,
    required this.unitName,
    String? unitId,
    IVocabularyService? vocabularyService,
    WordStateStore? wordStateStore,
  })  : _vocabularyService = vocabularyService ?? getIt<IVocabularyService>(),
        _store = wordStateStore ?? getIt<WordStateStore>(),
        _unitId = unitId ?? '' {
    _store.addListener(_onStoreChanged);
  }

  final String levelCode;
  final String unitName;
  final IVocabularyService _vocabularyService;
  final WordStateStore _store;

  String _unitId;
  String get unitId => _unitId;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  bool isLoading = false;
  String? errorMessage;
  List<Term> terms = const [];

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
          _unitId = units[idx].id;
        }
      }

      await _store.ensureLoaded(_unitId);
    } catch (error) {
      errorMessage = messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  UserWordState getWordState(String termId) =>
      _store.stateFor(unitId: _unitId, termId: termId);

  int get knownCount => terms
      .where((t) => getWordState(t.id).status == WordStatus.know)
      .length;

  Future<void> toggleStar(String termId) async {
    if (_unitId.isEmpty) return;
    try {
      await _store.toggleStar(unitId: _unitId, termId: termId);
    } catch (error) {
      debugPrint('TermList: failed to toggle star for $termId: $error');
    }
  }

  Future<void> updateStatus(String termId, WordStatus status) async {
    if (_unitId.isEmpty) return;
    try {
      await _store.updateStatus(
        unitId: _unitId,
        termId: termId,
        status: status,
      );
    } catch (error) {
      debugPrint('TermList: failed to update status for $termId: $error');
    }
  }
}
