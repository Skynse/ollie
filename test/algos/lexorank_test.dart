import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/algos/lexorank.dart';

void main() {
  group('LexoRank.middle', () {
    test('returns a fixed-length baseline when both bounds are empty', () {
      final rank = LexoRank.middle('', '');
      expect(rank.length, LexoRank.precision);
      expect(rank, LexoRank.middle('', ''));
    });

    test('returns a rank before b when a is empty', () {
      final b = LexoRank.middle('', '');
      final result = LexoRank.middle('', b);
      expect(LexoRank.compare(result, b), lessThan(0));
    });

    test('returns a rank after a when b is empty', () {
      final a = LexoRank.middle('', '');
      final result = LexoRank.middle(a, '');
      expect(LexoRank.compare(result, a), greaterThan(0));
    });

    test('returns a rank between a and b', () {
      final a = LexoRank.minimum;
      final b = LexoRank.maximum;
      final result = LexoRank.middle(a, b);
      expect(LexoRank.compare(result, a), greaterThan(0));
      expect(LexoRank.compare(result, b), lessThan(0));
    });

    test('maintains order for 100 successive inserts at the top', () {
      var first = LexoRank.middle('', '');
      final ranks = <String>[first];
      for (var i = 0; i < 100; i++) {
        first = LexoRank.middle('', first);
        ranks.add(first);
      }

      for (var i = 1; i < ranks.length; i++) {
        expect(
          LexoRank.compare(ranks[i], ranks[i - 1]),
          lessThan(0),
          reason: 'insert $i should sort above insert ${i - 1}',
        );
        expect(ranks[i].length, LexoRank.precision);
      }
    });

    test('maintains order for 100 successive inserts at the bottom', () {
      var last = LexoRank.middle('', '');
      final ranks = <String>[last];
      for (var i = 0; i < 100; i++) {
        last = LexoRank.middle(last, '');
        ranks.add(last);
      }

      for (var i = 1; i < ranks.length; i++) {
        expect(LexoRank.compare(ranks[i], ranks[i - 1]), greaterThan(0));
      }
    });

    test('throws when the bounds are invalid', () {
      final a = LexoRank.middle('', '');
      expect(() => LexoRank.middle(a, a), throwsArgumentError);
      expect(
        () => LexoRank.middle(LexoRank.maximum, LexoRank.maximum),
        throwsArgumentError,
      );
    });
  });

  group('LexoRank.distribute', () {
    test('returns ordered ranks and guards empty counts', () {
      expect(LexoRank.distribute(0), isEmpty);

      final ranks = LexoRank.distribute(25);
      expect(ranks.length, 25);
      for (var i = 1; i < ranks.length; i++) {
        expect(LexoRank.compare(ranks[i], ranks[i - 1]), greaterThan(0));
      }
    });
  });

  group('LexoRank value conversion', () {
    test('legacy variable-length ranks compare as fractions', () {
      expect(LexoRank.compare('U', 'V'), lessThan(0));
      expect(LexoRank.compare('U', 'U0'), lessThanOrEqualTo(0));
      expect(LexoRank.compare('A', 'AB'), lessThan(0));
      expect(LexoRank.compare('0', LexoRank.minimum), 0);
    });

    test('rejects invalid characters', () {
      expect(() => LexoRank.valueOf('bad!'), throwsArgumentError);
      expect(() => LexoRank.toBase36('bad!'), throwsArgumentError);
    });

    test('base-36 helpers round-trip', () {
      const original = 'HELLO';
      expect(LexoRank.fromBase36(LexoRank.toBase36(original)), original);
    });
  });
}
