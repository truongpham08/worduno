import '../../domain/entities/unit.dart';
import '../dtos/unit_dto.dart';
import 'i_mapper.dart';

class UnitMapper implements IMapper<UnitDto, Unit> {
  @override
  Unit toEntity(UnitDto dto) {
    return Unit(
      id: dto.id,
      name: dto.name,
      totalTerms: dto.totalTerms,
      knownTerms: dto.knownTerms,
    );
  }

  @override
  UnitDto toDto(Unit entity) {
    return UnitDto(
      id: entity.id,
      name: entity.name,
      totalTerms: entity.totalTerms,
      knownTerms: entity.knownTerms,
    );
  }
}
