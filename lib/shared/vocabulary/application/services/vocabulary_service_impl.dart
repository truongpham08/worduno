import '../../domain/entities/level.dart';
import '../../domain/entities/term.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/i_vocabulary_repository.dart';
import 'i_vocabulary_service.dart';

class VocabularyServiceImpl implements IVocabularyService {
  VocabularyServiceImpl(this._repository);

  final IVocabularyRepository _repository;

  int _cacheGeneration = 0;
  List<Level>? _cachedLevels;
  final Map<String, List<Unit>> _cachedUnits = {};
  final Map<String, List<Term>> _cachedTerms = {};

  Future<List<Level>>? _levelsInFlight;
  final Map<String, Future<List<Unit>>> _unitsInFlight = {};
  final Map<String, Future<List<Term>>> _termsInFlight = {};

  @override
  Future<List<Level>> getLevels() async {
    final generation = _cacheGeneration;
    final cached = _cachedLevels;
    if (cached != null) {
      return cached;
    }

    final inFlight = _levelsInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<List<Level>> future;
    future = _repository.getLevels().then((levels) {
      if (generation == _cacheGeneration) {
        _cachedLevels = levels;
      }
      return levels;
    }).whenComplete(() {
      if (identical(_levelsInFlight, future)) {
        _levelsInFlight = null;
      }
    });
    _levelsInFlight = future;
    return future;
  }

  @override
  Future<List<Unit>> getUnits(String levelCode) async {
    final generation = _cacheGeneration;
    final cached = _cachedUnits[levelCode];
    if (cached != null) {
      return cached;
    }

    final inFlight = _unitsInFlight[levelCode];
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<List<Unit>> future;
    future = _repository.getUnits(levelCode).then((units) {
      if (generation == _cacheGeneration) {
        _cachedUnits[levelCode] = units;
      }
      return units;
    }).whenComplete(() {
      if (identical(_unitsInFlight[levelCode], future)) {
        _unitsInFlight.remove(levelCode);
      }
    });
    _unitsInFlight[levelCode] = future;
    return future;
  }

  @override
  Future<List<Term>> getTerms({
    required String levelCode,
    required String unitName,
  }) async {
    final generation = _cacheGeneration;
    final key = '$levelCode|$unitName';
    final cached = _cachedTerms[key];
    if (cached != null) {
      return cached;
    }

    final inFlight = _termsInFlight[key];
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<List<Term>> future;
    future = _repository
        .getTerms(levelCode: levelCode, unitName: unitName)
        .then((terms) {
      if (generation == _cacheGeneration) {
        _cachedTerms[key] = terms;
      }
      return terms;
    }).whenComplete(() {
      if (identical(_termsInFlight[key], future)) {
        _termsInFlight.remove(key);
      }
    });
    _termsInFlight[key] = future;
    return future;
  }

  @override
  Future<void> clearCache() async {
    _cacheGeneration++;
    _cachedLevels = null;
    _cachedUnits.clear();
    _cachedTerms.clear();
    _levelsInFlight = null;
    _unitsInFlight.clear();
    _termsInFlight.clear();
    await _repository.clearCache();
  }
}
