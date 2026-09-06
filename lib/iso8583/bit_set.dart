/// A port of the subset of `java.util.BitSet` the ISO 8583 bitmap code uses.
///
/// As in the Java implementation, bit 0 is never used for a field: the bitmap
/// stores field `n` at bit `n`.
class IsoBitSet {
  IsoBitSet();

  factory IsoBitSet.from(Iterable<int> bits) {
    final IsoBitSet set = IsoBitSet();
    for (final int bit in bits) {
      set.set(bit);
    }
    return set;
  }

  final Set<int> _bits = <int>{};

  void set(int bit, [bool value = true]) {
    if (value) {
      _bits.add(bit);
    } else {
      _bits.remove(bit);
    }
  }

  void clear(int bit) => _bits.remove(bit);

  void clearRange(int fromInclusive, int toExclusive) => _bits.removeWhere((int bit) => bit >= fromInclusive && bit < toExclusive);

  bool get(int bit) => _bits.contains(bit);

  /// The index of the highest set bit plus one, or 0 when nothing is set.
  int get length => _bits.isEmpty ? 0 : _bits.reduce((int a, int b) => a > b ? a : b) + 1;

  bool get isEmpty => _bits.isEmpty;

  int get cardinality => _bits.length;

  /// A new set holding bits `[fromInclusive, toExclusive)` shifted down so that
  /// `fromInclusive` becomes bit 0 — the Java `BitSet.get(int, int)` contract.
  IsoBitSet range(int fromInclusive, int toExclusive) {
    final IsoBitSet out = IsoBitSet();
    for (final int bit in _bits) {
      if (bit >= fromInclusive && bit < toExclusive) out.set(bit - fromInclusive);
    }
    return out;
  }

  IsoBitSet copy() => IsoBitSet.from(_bits);

  List<int> toSortedList() => _bits.toList()..sort();

  @override
  String toString() => "{${toSortedList().join(", ")}}";
}
