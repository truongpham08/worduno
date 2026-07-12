import '../../domain/entities/level.dart';
import '../../domain/entities/term.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/i_vocabulary_repository.dart';
import '../datasources/i_vocabulary_local_data_source.dart';
import '../datasources/i_vocabulary_remote_data_source.dart';
import '../mappers/level_mapper.dart';
import '../mappers/term_mapper.dart';
import '../mappers/unit_mapper.dart';

class VocabularyRepositoryImpl implements IVocabularyRepository {
  VocabularyRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource, {
    LevelMapper? levelMapper,
    UnitMapper? unitMapper,
    TermMapper? termMapper,
  })  : _levelMapper = levelMapper ?? LevelMapper(),
        _unitMapper = unitMapper ?? UnitMapper(),
        _termMapper = termMapper ?? TermMapper();

  final IVocabularyRemoteDataSource _remoteDataSource;
  final IVocabularyLocalDataSource _localDataSource;
  final LevelMapper _levelMapper;
  final UnitMapper _unitMapper;
  final TermMapper _termMapper;

  @override
  Future<List<Level>> getLevels() async {
    if (await _localDataSource.hasLevels()) {
      final cached = await _localDataSource.getLevels();
      return cached.map(_levelMapper.toEntity).toList(growable: false);
    }

    final dtos = await _remoteDataSource.getLevels();
    await _localDataSource.saveLevels(dtos);
    return dtos.map(_levelMapper.toEntity).toList(growable: false);
  }

  @override
  Future<List<Unit>> getUnits(String levelCode) async {
    if (await _localDataSource.hasUnits(levelCode)) {
      final cached = await _localDataSource.getUnits(levelCode);
      return cached.map(_unitMapper.toEntity).toList(growable: false);
    }

    final dtos = await _remoteDataSource.getUnits(levelCode);
    await _localDataSource.saveUnits(levelCode, dtos);
    return dtos.map(_unitMapper.toEntity).toList(growable: false);
  }

  @override
  Future<List<Term>> getTerms({
    required String levelCode,
    required String unitName,
  }) async {
    if (await _localDataSource.hasTerms(
      levelCode: levelCode,
      unitName: unitName,
    )) {
      final cached = await _localDataSource.getTerms(
        levelCode: levelCode,
        unitName: unitName,
      );
      return cached.map(_termMapper.toEntity).toList(growable: false);
    }

    final dtos = await _remoteDataSource.getTerms(
      levelCode: levelCode,
      unitName: unitName,
    );
    final units = await getUnits(levelCode);
    final unit = units.firstWhere(
      (item) => item.name == unitName,
      orElse: () => throw StateError('Unit "$unitName" not found in $levelCode'),
    );

    await _localDataSource.saveTerms(
      levelCode: levelCode,
      unitName: unitName,
      unitId: unit.id,
      terms: dtos,
    );
    return dtos.map(_termMapper.toEntity).toList(growable: false);
  }

  @override
  Future<void> clearCache() => _localDataSource.clearAll();
}
