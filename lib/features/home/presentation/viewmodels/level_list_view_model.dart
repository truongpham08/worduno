import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/level.dart';
import '../../../../shared/word_state/application/services/i_word_state_service.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';

class LevelListViewModel extends ChangeNotifier {
  LevelListViewModel({
    IVocabularyService? vocabularyService,
    IWordStateService? wordStateService,
  })  : _vocabularyService = vocabularyService ?? getIt<IVocabularyService>(),
        _wordStateService = wordStateService ?? getIt<IWordStateService>();

  final IVocabularyService _vocabularyService;
  final IWordStateService _wordStateService;

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
  List<Level> levels = const [];

  Future<void> loadLevels() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final baseLevels = await _vocabularyService.getLevels();

      final futureLevels = baseLevels.map((lvl) async {
        final units = await _vocabularyService.getUnits(lvl.code);

        int totalTerms = 0;
        int knownTerms = 0;

        final futureUnitStats = units.asMap().entries.map((entry) async {
          final index = entry.key;
          final unit = entry.value;
          final unitId = '${lvl.code}-$index';

          try {
            final terms = await _vocabularyService.getTerms(
              levelCode: lvl.code,
              unitName: unit.name,
            );
            final states = await _wordStateService.getByUnit(unitId);
            final knownCount =
                states.where((s) => s.status == WordStatus.know).length;
            return (terms.length, knownCount);
          } catch (_) {
            return (0, 0);
          }
        });

        final statsList = await Future.wait(futureUnitStats);
        for (final stat in statsList) {
          totalTerms += stat.$1;
          knownTerms += stat.$2;
        }

        return Level(
          code: lvl.code,
          totalTerms: totalTerms,
          knownTerms: knownTerms,
        );
      });

      levels = await Future.wait(futureLevels);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
