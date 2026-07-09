import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/core/utils/sort_utils.dart';

void main() {
  group('SortUtils (spec §11)', () {
    const items = ['Zebra', 'apple', 'Mango'];

    test('original order preserves input sequence', () {
      final sorted = SortUtils.sortByName(
        items: items,
        nameSelector: (s) => s,
        order: SortOrder.original,
      );
      expect(sorted, items);
    });

    test('A-Z sorts case-insensitively', () {
      final sorted = SortUtils.sortByName(
        items: items,
        nameSelector: (s) => s,
        order: SortOrder.aToZ,
      );
      expect(sorted, ['apple', 'Mango', 'Zebra']);
    });

    test('Z-A sorts descending', () {
      final sorted = SortUtils.sortByName(
        items: items,
        nameSelector: (s) => s,
        order: SortOrder.zToA,
      );
      expect(sorted, ['Zebra', 'Mango', 'apple']);
    });

    test('does not mutate the original list', () {
      final copy = List<String>.from(items);
      SortUtils.sortByName(
        items: copy,
        nameSelector: (s) => s,
        order: SortOrder.aToZ,
      );
      expect(copy, items);
    });
  });
}
