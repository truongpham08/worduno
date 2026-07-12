import '../dtos/level_dto.dart';
import '../dtos/term_dto.dart';
import '../dtos/unit_dto.dart';

abstract class IVocabularyLocalDataSource {
  Future<bool> hasLevels();

  Future<List<LevelDto>> getLevels();

  Future<void> saveLevels(List<LevelDto> levels);

  Future<bool> hasUnits(String levelCode);

  Future<List<UnitDto>> getUnits(String levelCode);

  Future<void> saveUnits(String levelCode, List<UnitDto> units);

  Future<bool> hasTerms({
    required String levelCode,
    required String unitName,
  });

  Future<List<TermDto>> getTerms({
    required String levelCode,
    required String unitName,
  });

  Future<void> saveTerms({
    required String levelCode,
    required String unitName,
    required String unitId,
    required List<TermDto> terms,
  });

  Future<void> clearAll();
}
