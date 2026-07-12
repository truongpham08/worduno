import '../../domain/entities/level.dart';
import '../../domain/entities/term.dart';
import '../../domain/entities/unit.dart';

abstract class IVocabularyService {
  Future<List<Level>> getLevels();

  Future<List<Unit>> getUnits(String levelCode);

  Future<List<Term>> getTerms({
    required String levelCode,
    required String unitName,
  });

  Future<void> clearCache();
}
