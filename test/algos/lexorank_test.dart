import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/algos/lexorank.dart';

void main() {
  group('LexoRank.middle', () {
    test('returns baseline when both empty', () {
      expect(LexoRank.middle('', ''), 'U');
    });

    test('returns rank before b when a is empty', () {
      final result = LexoRank.middle('', 'M');
      expect(LexoRank.toBase36(result), lessThan(LexoRank.toBase36('M')));
    });

    test('returns rank after a when b is empty', () {
      final result = LexoRank.middle('M', '');
      expect(LexoRank.toBase36(result), greaterThan(LexoRank.toBase36('M')));
    });

    test('returns rank between a and b', () {
      final result = LexoRank.middle('A', 'Z');
      final aNum = LexoRank.toBase36('A');
      final bNum = LexoRank.toBase36('Z');
      final midNum = LexoRank.toBase36(result);
      expect(midNum, greaterThan(aNum));
      expect(midNum, lessThan(bNum));
    });

    test('maintains order for sequential inserts', () {
      final first = LexoRank.middle('', '');
      final second = LexoRank.middle(first, '');
      final third = LexoRank.middle(second, '');

      expect(LexoRank.toBase36(first), lessThan(LexoRank.toBase36(second)));
      expect(LexoRank.toBase36(second), lessThan(LexoRank.toBase36(third)));
    });
  });

  group('LexoRank base36 conversion', () {
    test('round-trips through base36', () {
      const original = 'HELLO';
      final num = LexoRank.toBase36(original);
      expect(LexoRank.fromBase36(num), original);
    });

    test('throws on invalid characters', () {
      expect(() => LexoRank.toBase36('bad!'), throwsArgumentError);
    });
  });
}
