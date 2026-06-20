import '../../domain/entities/level.dart';
import '../../domain/entities/term.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/i_vocabulary_repository.dart';
import 'i_vocabulary_service.dart';

class VocabularyServiceImpl implements IVocabularyService {
  VocabularyServiceImpl(this._repository);

  final IVocabularyRepository _repository;

  @override
  Future<List<Level>> getLevels() => _repository.getLevels();

  @override
  Future<List<Unit>> getUnits(String levelCode) =>
      _repository.getUnits(levelCode);

  @override
  Future<List<Term>> getTerms({
    required String levelCode,
    required String unitName,
  }) =>
      _repository.getTerms(levelCode: levelCode, unitName: unitName);
}
