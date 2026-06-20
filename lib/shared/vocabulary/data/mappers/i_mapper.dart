abstract class IMapper<D, E> {
  E toEntity(D dto);
  D toDto(E entity);
}
