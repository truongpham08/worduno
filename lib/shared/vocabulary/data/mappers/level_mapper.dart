import '../../domain/entities/level.dart';
import '../dtos/level_dto.dart';
import 'i_mapper.dart';

class LevelMapper implements IMapper<LevelDto, Level> {
  @override
  Level toEntity(LevelDto dto) {
    return Level(
      code: dto.code,
      totalTerms: dto.totalTerms,
      knownTerms: dto.knownTerms,
    );
  }

  @override
  LevelDto toDto(Level entity) {
    return LevelDto(
      code: entity.code,
      totalTerms: entity.totalTerms,
      knownTerms: entity.knownTerms,
    );
  }
}
