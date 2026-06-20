enum SortOrder { original, aToZ, zToA }

class SortUtils {
  SortUtils._();

  static List<T> sortByName<T>({
    required List<T> items,
    required String Function(T item) nameSelector,
    required SortOrder order,
  }) {
    final sorted = List<T>.from(items);

    switch (order) {
      case SortOrder.original:
        return sorted;
      case SortOrder.aToZ:
        sorted.sort(
          (a, b) => nameSelector(a).toLowerCase().compareTo(
                nameSelector(b).toLowerCase(),
              ),
        );
        return sorted;
      case SortOrder.zToA:
        sorted.sort(
          (a, b) => nameSelector(b).toLowerCase().compareTo(
                nameSelector(a).toLowerCase(),
              ),
        );
        return sorted;
    }
  }
}
