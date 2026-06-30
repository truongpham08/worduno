import '../../domain/entities/level.dart';
import '../../domain/entities/term.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/i_vocabulary_repository.dart';
import 'i_vocabulary_service.dart';

class VocabularyServiceImpl implements IVocabularyService {
  VocabularyServiceImpl(this._repository);

  final IVocabularyRepository _repository;

  List<Level>? _cachedLevels;
  final Map<String, List<Unit>> _cachedUnits = {};
  final Map<String, List<Term>> _cachedTerms = {};

  @override
  Future<List<Level>> getLevels() async {
    if (_cachedLevels != null) return _cachedLevels!;
    _cachedLevels = await _repository.getLevels();
    return _cachedLevels!;
  }

  @override
  Future<List<Unit>> getUnits(String levelCode) async {
    if (_cachedUnits.containsKey(levelCode)) return _cachedUnits[levelCode]!;
    final units = await _repository.getUnits(levelCode);
    _cachedUnits[levelCode] = units;
    return units;
  }

  @override
  Future<List<Term>> getTerms({
    required String levelCode,
    required String unitName,
  }) async {
    final key = '$levelCode|$unitName';
    if (_cachedTerms.containsKey(key)) return _cachedTerms[key]!;
    final terms = await _repository.getTerms(
      levelCode: levelCode,
      unitName: unitName,
    );
    _cachedTerms[key] = terms;
    return terms;
  }
}
