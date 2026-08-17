extension GenericIterableExtensions<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) sync* {
    int index = 0;
    for (final T item in this) {
      yield f(index, item);
      index++;
    }
  }

  void forEachIndexed(void Function(int index, T element) action) {
    int index = 0;
    for (final T element in this) {
      action(index++, element);
    }
  }

  List<T> insertFirstReturn(T item) => <T>[item, ...this];

  T? getFirstIfExist() => isEmpty ? null : first;

  T? firstOrDefault({T? defaultValue}) => isEmpty ? defaultValue : first;

  Iterable<T> takeIfPossible(int range) => take(range > length ? length : range);

  bool containsAll(Iterable<T> list) => toSet().containsAll(list);

  bool containsAny(Iterable<T> list) => list.any(contains);

  List<T> alternative(T main, T replace) => toList()
    ..remove(main)
    ..add(replace);

  List<T> addAndReturn(T t) => <T>[...this, t];

  List<T> addAllAndReturn(Iterable<T> t) => <T>[...this, ...t];

  List<T> insertAndReturn(int index, T t) => toList()..insert(index, t);

  T? firstWhereOrNull(bool Function(T element) test) {
    for (final T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension NullableIterableExtensions<T> on Iterable<T>? {
  bool isNullOrEmpty() => this == null || this!.isEmpty;

  bool isNotNullOrEmpty() => !isNullOrEmpty();

  bool containsAll(Iterable<T> list) => (this ?? const <Never>[]).toSet().containsAll(list);
}
