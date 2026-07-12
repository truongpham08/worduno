import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/unit.dart';
import '../../../../shared/word_state/application/services/word_state_store.dart';

class UnitListViewModel extends ChangeNotifier {
  UnitListViewModel({
    required this.levelCode,
    IVocabularyService? vocabularyService,
    WordStateStore? wordStateStore,
  })  : _vocabularyService = vocabularyService ?? getIt<IVocabularyService>(),
        _store = wordStateStore ?? getIt<WordStateStore>() {
    _store.addListener(_onStoreChanged);
  }

  final String levelCode;
  final IVocabularyService _vocabularyService;
  final WordStateStore _store;

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

  /// Static unit metadata (id, name, total terms) loaded once from the API.
  /// Known counts are read reactively from the [WordStateStore].
  List<Unit> _baseUnits = const [];

  /// Units with up-to-date known counts pulled from the store.
  List<Unit> get units => _baseUnits
      .map(
        (unit) => Unit(
          id: unit.id,
          name: unit.name,
          totalTerms: unit.totalTerms,
          knownTerms: _store.knownCount(unit.id),
        ),
      )
      .toList(growable: false);

  Future<void> loadUnits() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final baseUnits = await _vocabularyService.getUnits(levelCode);

      final futureUnits = baseUnits.map((unit) async {
        try {
          final terms = await _vocabularyService.getTerms(
            levelCode: levelCode,
            unitName: unit.name,
          );
          await _store.ensureLoaded(unit.id);
          return Unit(
            id: unit.id,
            name: unit.name,
            totalTerms: terms.length,
            knownTerms: 0,
          );
        } catch (_) {
          return unit;
        }
      });

      _baseUnits = await Future.wait(futureUnits);
    } catch (error) {
      errorMessage = messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
