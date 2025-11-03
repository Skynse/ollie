import 'dart:math';

class LexoRank {
  static const _charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _base = 36;
  static const _minChar = '0';
  static const _maxChar = 'Z';

  /// Returns a rank string that falls between [a] and [b].
  /// If [a] is empty, returns a rank before [b].
  /// If [b] is empty, returns a rank after [a].
  /// If both are empty, returns the middle baseline 'U'.
  static String middle(String a, String b) {
    // Handle empty strings
    if (a.isEmpty && b.isEmpty) {
      return 'U'; // Middle of alphabet (21st char)
    }

    if (a.isEmpty) {
      // Insert before b
      return _before(b);
    }

    if (b.isEmpty) {
      // Insert after a
      return _after(a);
    }

    // Both strings have values - find midpoint
    return _between(a, b);
  }

  /// Returns a rank before [s]
  static String _before(String s) {
    if (s.isEmpty) return 'U';

    // If first char is not minimum, just decrement it
    final firstChar = s[0];
    if (firstChar != _minChar) {
      final prevCharIndex = _charset.indexOf(firstChar) - 1;
      return _charset[prevCharIndex] + s.substring(1);
    }

    // First char is minimum, need to go one level deeper
    if (s.length == 1) {
      // Can't go before "0", so prepend "0" and use middle char
      return '0U';
    }

    // Recurse on remaining string
    return firstChar + _before(s.substring(1));
  }

  /// Returns a rank after [s]
  static String _after(String s) {
    if (s.isEmpty) return 'U';

    // If last char is not maximum, just increment it
    final lastChar = s[s.length - 1];
    if (lastChar != _maxChar) {
      final nextCharIndex = _charset.indexOf(lastChar) + 1;
      return s.substring(0, s.length - 1) + _charset[nextCharIndex];
    }

    // Last char is maximum, append middle char
    return '${s}U';
  }

  /// Returns a rank between [a] and [b]
  static String _between(String a, String b) {
    // Pad to same length for easier comparison
    final maxLen = max(a.length, b.length);
    final aa = a.padRight(maxLen, _minChar);
    final bb = b.padRight(maxLen, _maxChar);

    // Convert to numbers and find midpoint
    final aNum = _toBase36(aa);
    final bNum = _toBase36(bb);

    // If they're adjacent or same, we need more precision
    if (bNum - aNum <= BigInt.one) {
      // Append middle character to [a] to create space
      return '${a}U';
    }

    final midNum = (aNum + bNum) ~/ BigInt.from(2);
    var result = _fromBase36(midNum);

    // Ensure result has appropriate length (remove trailing zeros but keep reasonable length)
    result = result.padLeft(maxLen, _minChar);

    return result;
  }

  // Made public for rebalancing operations
  static BigInt toBase36(String s) {
    if (s.isEmpty) return BigInt.zero;

    BigInt num = BigInt.zero;
    for (var c in s.split('')) {
      final index = _charset.indexOf(c.toUpperCase());
      if (index == -1) {
        throw ArgumentError('Invalid character in rank string: $c');
      }
      num = num * BigInt.from(_base) + BigInt.from(index);
    }
    return num;
  }

  static String fromBase36(BigInt num) {
    if (num == BigInt.zero) return _minChar;

    var result = '';
    var n = num;
    while (n > BigInt.zero) {
      final rem = (n % BigInt.from(_base)).toInt();
      result = _charset[rem] + result;
      n = n ~/ BigInt.from(_base);
    }
    return result;
  }

  // Keep private versions for internal use
  static BigInt _toBase36(String s) => toBase36(s);
  static String _fromBase36(BigInt num) => fromBase36(num);
}
