import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/level.dart';

class LevelListViewModel extends ChangeNotifier {
  LevelListViewModel({IVocabularyService? vocabularyService})
      : _vocabularyService =
            vocabularyService ?? getIt<IVocabularyService>();

  final IVocabularyService _vocabularyService;

  bool isLoading = false;
  String? errorMessage;
  List<Level> levels = const [];

  Future<void> loadLevels() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      levels = await _vocabularyService.getLevels();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
