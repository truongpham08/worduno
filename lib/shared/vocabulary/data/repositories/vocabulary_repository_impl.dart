import '../../domain/entities/level.dart';
import '../../domain/entities/term.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/i_vocabulary_repository.dart';
import '../datasources/i_vocabulary_remote_data_source.dart';
import '../mappers/level_mapper.dart';
import '../mappers/term_mapper.dart';
import '../mappers/unit_mapper.dart';

class VocabularyRepositoryImpl implements IVocabularyRepository {
  VocabularyRepositoryImpl(
    this._remoteDataSource, {
    LevelMapper? levelMapper,
    UnitMapper? unitMapper,
    TermMapper? termMapper,
  })  : _levelMapper = levelMapper ?? LevelMapper(),
        _unitMapper = unitMapper ?? UnitMapper(),
        _termMapper = termMapper ?? TermMapper();

  final IVocabularyRemoteDataSource _remoteDataSource;
  final LevelMapper _levelMapper;
  final UnitMapper _unitMapper;
  final TermMapper _termMapper;

  @override
  Future<List<Level>> getLevels() async {
    final dtos = await _remoteDataSource.getLevels();
    return dtos.map(_levelMapper.toEntity).toList(growable: false);
  }

  @override
  Future<List<Unit>> getUnits(String levelCode) async {
    final dtos = await _remoteDataSource.getUnits(levelCode);
    return dtos.map(_unitMapper.toEntity).toList(growable: false);
  }

  @override
  Future<List<Term>> getTerms({
    required String levelCode,
    required String unitName,
  }) async {
    final dtos = await _remoteDataSource.getTerms(
      levelCode: levelCode,
      unitName: unitName,
    );
    return dtos.map(_termMapper.toEntity).toList(growable: false);
  }
}
