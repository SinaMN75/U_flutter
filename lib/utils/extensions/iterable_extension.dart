extension GenericIterableExtensions<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(final E Function(int index, T item) f) sync* {
    int index = 0;
    for (final T item in this) {
      yield f(index, item);
      index++;
    }
  }

  void forEachIndexed(final void Function(int index, T element) action) {
    int index = 0;
    for (final T element in this) action(index++, element);
  }

  List<T> insertFirstReturn(final T item) => <T>[item, ...this];

  T? getFirstIfExist() => isEmpty ? null : first;

  T? firstOrDefault({final T? defaultValue}) => isEmpty ? defaultValue : first;

  Iterable<T> takeIfPossible(final int range) => take(range > length ? length : range);

  bool containsAll(final Iterable<T> list) => toSet().containsAll(list);

  bool containsAny(final Iterable<T> list) => list.any(contains);

  List<T> alternative(final T main, final T replace) => toList()
    ..remove(main)
    ..add(replace);

  List<T> addAndReturn(final T t) => <T>[...this, t];

  List<T> addAllAndReturn(final Iterable<T> t) => <T>[...this, ...t];

  List<T> insertAndReturn(final int index, final T t) => toList()..insert(index, t);
}

extension NullableIterableExtensions<T> on Iterable<T>? {
  bool isNullOrEmpty() => this == null || this!.isEmpty;

  bool isNotNullOrEmpty() => !isNullOrEmpty();

  bool containsAll(final Iterable<T> list) => (this ?? const <Never>[]).toSet().containsAll(list);
}
