import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/database/json_helpers.dart';

void main() {
  group('decodeStringList', () {
    test('returns empty list for null', () {
      expect(decodeStringList(null), isEmpty);
    });

    test('decodes JSON string array', () {
      expect(decodeStringList('["a","b"]'), ['a', 'b']);
    });

    test('decodes native list', () {
      expect(decodeStringList(['x', 'y']), ['x', 'y']);
    });

    test('returns empty for empty string', () {
      expect(decodeStringList(''), isEmpty);
    });
  });

  group('encodeStringList', () {
    test('encodes list to JSON', () {
      expect(encodeStringList(['a', 'b']), '["a","b"]');
    });
  });

  group('rowWithId', () {
    test('uses id field when present', () {
      final row = rowWithId({'id': 'abc', 'name': 'Board'});
      expect(row['id'], 'abc');
    });

    test('falls back to \$id field', () {
      final row = rowWithId({'\$id': 'xyz', 'name': 'Board'});
      expect(row['id'], 'xyz');
    });
  });
}
