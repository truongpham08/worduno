import '../../domain/entities/term.dart';
import '../dtos/term_dto.dart';
import 'i_mapper.dart';

class TermMapper implements IMapper<TermDto, Term> {
  @override
  Term toEntity(TermDto dto) {
    return Term(
      id: dto.id,
      text: dto.text,
      definition: dto.definition,
    );
  }

  @override
  TermDto toDto(Term entity) {
    return TermDto(
      id: entity.id,
      text: entity.text,
      definition: entity.definition,
    );
  }
}
