import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/term.dart';

class TermListViewModel extends ChangeNotifier {
  TermListViewModel({
    required this.levelCode,
    required this.unitName,
    IVocabularyService? vocabularyService,
  }) : _vocabularyService =
            vocabularyService ?? getIt<IVocabularyService>();

  final String levelCode;
  final String unitName;
  final IVocabularyService _vocabularyService;

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
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
