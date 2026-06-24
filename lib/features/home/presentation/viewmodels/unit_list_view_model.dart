import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/unit.dart';

class UnitListViewModel extends ChangeNotifier {
  UnitListViewModel({
    required this.levelCode,
    IVocabularyService? vocabularyService,
  }) : _vocabularyService =
            vocabularyService ?? getIt<IVocabularyService>();

  final String levelCode;
  final IVocabularyService _vocabularyService;

  bool isLoading = false;
  String? errorMessage;
  List<Unit> units = const [];

  Future<void> loadUnits() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      units = await _vocabularyService.getUnits(levelCode);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
