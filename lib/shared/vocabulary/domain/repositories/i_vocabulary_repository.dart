import '../entities/level.dart';
import '../entities/term.dart';
import '../entities/unit.dart';

abstract class IVocabularyRepository {
  Future<List<Level>> getLevels();

  Future<List<Unit>> getUnits(String levelCode);

  Future<List<Term>> getTerms({
    required String levelCode,
    required String unitName,
  });

  Future<void> clearCache();
}
