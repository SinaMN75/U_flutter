import "package:flutter/material.dart";

/// List helpers: indexes, safe lookups, grouping, sorting, chunks, sums. `users.groupBy((u) => u.city)`
extension GenericIterableExtensions<T> on Iterable<T> {
  /// map() that also gives the index. `items.mapIndexed((i, e) => "$i: $e")`
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) sync* {
    int index = 0;
    for (final T item in this) {
      yield f(index++, item);
    }
  }

  /// forEach() that also gives the index. `items.forEachIndexed((i, e) => print("$i $e"))`
  void forEachIndexed(void Function(int index, T element) action) {
    int index = 0;
    for (final T element in this) {
      action(index++, element);
    }
  }

  /// New list with [item] first. `[2, 3].insertFirstReturn(1)` → [1, 2, 3]
  List<T> insertFirstReturn(T item) => <T>[item, ...this];

  /// First item, or null when empty.
  T? getFirstIfExist() => isEmpty ? null : first;

  /// First item, or [defaultValue] when empty. `list.firstOrDefault(defaultValue: 0)`
  T? firstOrDefault({T? defaultValue}) => isEmpty ? defaultValue : first;

  /// take() that never throws. `list.takeIfPossible(5)`
  Iterable<T> takeIfPossible(int range) => take(range < 0 ? 0 : range);

  /// True when every item of [list] is in this one.
  bool containsAll(Iterable<T> list) => toSet().containsAll(list);

  /// True when at least one item of [list] is in this one.
  bool containsAny(Iterable<T> list) => list.any(contains);

  /// New list with [main] removed and [replace] added at the end. `tags.alternative("old", "new")`
  List<T> alternative(T main, T replace) => toList()
    ..remove(main)
    ..add(replace);

  /// New list with [t] added at the end.
  List<T> addAndReturn(T t) => <T>[...this, t];

  /// New list with all of [t] added at the end.
  List<T> addAllAndReturn(Iterable<T> t) => <T>[...this, ...t];

  /// New list with [t] inserted at [index].
  List<T> insertAndReturn(int index, T t) => toList()..insert(index, t);

  /// First item that passes [test], or null. `users.firstWhereOrNull((u) => u.id == id)`
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final T element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// Groups items by a key. `orders.groupBy((o) => o.status)` → {paid: [...], pending: [...]}
  Map<K, List<T>> groupBy<K>(K Function(T item) key) {
    final Map<K, List<T>> out = <K, List<T>>{};
    for (final T item in this) {
      (out[key(item)] ??= <T>[]).add(item);
    }
    return out;
  }

  /// New list sorted by a field; [descending] reverses it. `users.sortedBy((u) => u.name)`
  List<T> sortedBy<K extends Comparable<Object?>>(K Function(T item) key, {bool descending = false}) => toList()..sort((T a, T b) => descending ? key(b).compareTo(key(a)) : key(a).compareTo(key(b)));

  /// Removes duplicates by a field, keeping the first. `users.distinctBy((u) => u.id)`
  List<T> distinctBy<K>(K Function(T item) key) {
    final Set<K> seen = <K>{};
    return where((T item) => seen.add(key(item))).toList();
  }

  /// Splits into lists of [size]. `[1,2,3,4,5].chunked(2)` → [[1,2],[3,4],[5]]
  List<List<T>> chunked(int size) {
    final List<T> all = toList();
    return <List<T>>[for (int i = 0; i < all.length; i += size) all.sublist(i, i + size > all.length ? all.length : i + size)];
  }

  /// Adds up a number from each item. `cart.sumBy((i) => i.price * i.count)`
  num sumBy(num Function(T item) value) => fold<num>(0, (num sum, T item) => sum + value(item));

  /// Average of a number from each item (0 when empty). `scores.averageBy((s) => s.value)`
  double averageBy(num Function(T item) value) => isEmpty ? 0 : sumBy(value) / length;

  /// Item with the biggest value, or null when empty. `products.maxBy((p) => p.price)`
  T? maxBy(Comparable<Object?> Function(T item) value) => isEmpty ? null : reduce((T a, T b) => value(a).compareTo(value(b)) >= 0 ? a : b);

  /// Item with the smallest value, or null when empty. `products.minBy((p) => p.price)`
  T? minBy(Comparable<Object?> Function(T item) value) => isEmpty ? null : reduce((T a, T b) => value(a).compareTo(value(b)) <= 0 ? a : b);

  /// Puts [separator] between items. `[a, b, c].separatedBy(x)` → [a, x, b, x, c]
  List<T> separatedBy(T separator) {
    final List<T> out = <T>[];
    for (final T item in this) {
      if (out.isNotEmpty) out.add(separator);
      out.add(item);
    }
    return out;
  }
}

/// Null-safe checks on lists that may be null. `response.items.isNullOrEmpty()`
extension NullableIterableExtensions<T> on Iterable<T>? {
  /// True when null or empty.
  bool isNullOrEmpty() => this == null || this!.isEmpty;

  /// True when it has at least one item.
  bool isNotNullOrEmpty() => !isNullOrEmpty();

  /// True when every item of [list] is in this one (null counts as empty).
  bool containsAll(Iterable<T> list) => (this ?? const <Never>[]).toSet().containsAll(list);

  /// The list, or an empty one when null. `for (final e in maybeList.orEmpty()) …`
  List<T> orEmpty() => this?.toList() ?? <T>[];
}

/// Spacing helpers for widget lists. `children: [a, b, c].withSpacing(8)`
extension UWidgetListExtension on List<Widget> {
  /// Puts a gap of [size] between widgets (works in Row and Column). `[a, b].withSpacing(12)`
  List<Widget> withSpacing(double size) => GenericIterableExtensions<Widget>(this).separatedBy(SizedBox(width: size, height: size));

  /// Puts a divider between widgets. `tiles.withDividers()`
  List<Widget> withDividers({double height = 1}) => GenericIterableExtensions<Widget>(this).separatedBy(Divider(height: height, thickness: height));
}
