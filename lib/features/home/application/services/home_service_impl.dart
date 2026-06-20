import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/word_state/application/services/i_word_state_service.dart';
import 'i_home_service.dart';

class HomeServiceImpl implements IHomeService {
  HomeServiceImpl(this.vocabularyService, this.wordStateService);

  final IVocabularyService vocabularyService;
  final IWordStateService wordStateService;
}
