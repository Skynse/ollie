/// Thrown when two adjacent ranks have no representable value between them.
///
/// In practice this needs on the order of 200 successive inserts at the very
/// top of one column; callers can recover by rebalancing the column.
class RankSpaceExhausted implements Exception {
  const RankSpaceExhausted();

  @override
  String toString() =>
      'Ran out of room between card ranks. Rebalance the column and retry.';
}

/// Fixed-precision lexical ranks.
///
/// A rank is a 40-character base-36 fraction (implicit `0.` prefix). Fixed
/// length means lexicographic string comparison is identical to numeric
/// comparison, which removes the ordering bugs of variable-length ranks.
class LexoRank {
  static const String _charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const int _base = 36;

  /// 36^40 is about 1.3e62, leaving room for ~200 consecutive top inserts.
  static const int precision = 40;

  static final BigInt _max = BigInt.from(_base).pow(precision);

  /// Returns a rank strictly between [a] and [b].
  ///
  /// Empty [a] means "before everything", empty [b] means "after everything".
  /// Passing a value greater than or equal to [b] is a programming error.
  static String middle(String a, String b) {
    final left = a.isEmpty ? BigInt.zero : valueOf(a);
    final right = b.isEmpty ? _max : valueOf(b);
    if (right <= left) {
      throw ArgumentError('Rank $a must sort before $b');
    }
    final mid = (left + right) ~/ BigInt.two;
    if (mid <= left || mid >= right) {
      throw const RankSpaceExhausted();
    }
    return _format(mid);
  }

  /// Evenly distributes [count] ranks over the available space.
  ///
  /// Used for migrations and the explicit "rebalance" action.
  static List<String> distribute(int count) {
    if (count <= 0) return const [];
    final result = <String>[];
    for (var i = 1; i <= count; i++) {
      final value = _max * BigInt.from(i) ~/ BigInt.from(count + 1);
      result.add(_format(value));
    }
    return result;
  }

  /// Numeric value of a rank, preserving the order of legacy variable-length
  /// ranks by treating them as fractions (`'U'` == `'U' + zero padding`).
  static BigInt valueOf(String rank) {
    if (rank.isEmpty) return BigInt.zero;
    final upper = rank.toUpperCase();
    BigInt raw = BigInt.zero;
    for (final char in upper.split('')) {
      final digit = _charset.indexOf(char);
      if (digit == -1) {
        throw ArgumentError('Invalid character in rank string: $char');
      }
      raw = raw * BigInt.from(_base) + BigInt.from(digit);
    }
    if (upper.length == precision) return raw;
    if (upper.length < precision) {
      return raw * BigInt.from(_base).pow(precision - upper.length);
    }
    return raw ~/ BigInt.from(_base).pow(upper.length - precision);
  }

  /// Compares two ranks in their natural card order.
  static int compare(String a, String b) => valueOf(a).compareTo(valueOf(b));

  static String _format(BigInt value) {
    if (value < BigInt.zero || value >= _max) {
      throw const RankSpaceExhausted();
    }
    final digits = List<String>.filled(precision, '0');
    var remaining = value;
    for (var i = precision - 1; i >= 0; i--) {
      digits[i] = _charset[(remaining % BigInt.from(_base)).toInt()];
      remaining ~/= BigInt.from(_base);
    }
    return digits.join();
  }

  // Raw base-36 helpers kept for tests and diagnostics.
  static BigInt toBase36(String value) {
    if (value.isEmpty) return BigInt.zero;
    BigInt result = BigInt.zero;
    for (final char in value.toUpperCase().split('')) {
      final digit = _charset.indexOf(char);
      if (digit == -1) {
        throw ArgumentError('Invalid character in rank string: $char');
      }
      result = result * BigInt.from(_base) + BigInt.from(digit);
    }
    return result;
  }

  static String fromBase36(BigInt value) {
    if (value == BigInt.zero) return '0';
    var n = value;
    final buffer = StringBuffer();
    while (n > BigInt.zero) {
      final digit = (n % BigInt.from(_base)).toInt();
      buffer.write(_charset[digit]);
      n ~/= BigInt.from(_base);
    }
    return buffer.toString().split('').reversed.join();
  }

  /// The smallest representable rank. Useful in tests.
  static String get minimum => _format(BigInt.zero);

  /// The largest representable rank.
  static String get maximum => _format(_max - BigInt.one);

  /// Convenience for callers that need a rank guaranteed to sort after [a].
  static String after(String a) => middle(a, '');

  /// Convenience for callers that need a rank guaranteed to sort before [b].
  static String before(String b) => middle('', b);
}
