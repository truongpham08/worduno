import '../dtos/level_dto.dart';
import '../dtos/term_dto.dart';
import '../dtos/unit_dto.dart';

abstract class IVocabularyRemoteDataSource {
  Future<List<LevelDto>> getLevels();

  Future<List<UnitDto>> getUnits(String levelCode);

  Future<List<TermDto>> getTerms({
    required String levelCode,
    required String unitName,
  });
}
