import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/core/utils/search_utils.dart';

void main() {
  group('SearchUtils (spec §10)', () {
    test('empty query matches everything', () {
      expect(SearchUtils.matches('', 'B1 Level'), isTrue);
      expect(SearchUtils.matches('   ', 'anything'), isTrue);
    });

    test('search is case-insensitive', () {
      expect(SearchUtils.matches('b1', 'B1 Intermediate'), isTrue);
      expect(SearchUtils.matches('TRAVEL', 'Unit Travel'), isTrue);
    });

    test('no match returns false', () {
      expect(SearchUtils.matches('xyz', 'B1 Level'), isFalse);
    });

    test('partial match returns true', () {
      expect(SearchUtils.matches('inter', 'Intermediate B1'), isTrue);
    });
  });
}
