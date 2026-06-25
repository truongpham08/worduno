import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/unit.dart';
import '../../../../shared/word_state/application/services/i_word_state_service.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';

class UnitListViewModel extends ChangeNotifier {
  UnitListViewModel({
    required this.levelCode,
    IVocabularyService? vocabularyService,
    IWordStateService? wordStateService,
  })  : _vocabularyService = vocabularyService ?? getIt<IVocabularyService>(),
        _wordStateService = wordStateService ?? getIt<IWordStateService>();

  final String levelCode;
  final IVocabularyService _vocabularyService;
  final IWordStateService _wordStateService;

  bool isLoading = false;
  String? errorMessage;
  List<Unit> units = const [];

  Future<void> loadUnits() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final baseUnits = await _vocabularyService.getUnits(levelCode);

      final futureUnits = baseUnits.asMap().entries.map((entry) async {
        final index = entry.key;
        final unit = entry.value;
        final unitId = '$levelCode-$index';

        try {
          final terms = await _vocabularyService.getTerms(
            levelCode: levelCode,
            unitName: unit.name,
          );
          final states = await _wordStateService.getByUnit(unitId);
          final knownCount =
              states.where((s) => s.status == WordStatus.know).length;

          return Unit(
            id: unit.id,
            name: unit.name,
            totalTerms: terms.length,
            knownTerms: knownCount,
          );
        } catch (_) {
          return unit;
        }
      });

      units = await Future.wait(futureUnits);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
