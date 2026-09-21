import "dart:collection";

import "package:flutter/widgets.dart";

class _RxObserver {
  static _RxObserver? active;
  final Set<URx<dynamic>> read = <URx<dynamic>>{};
}

class URx<T> extends ChangeNotifier {
  URx(this._value);

  T _value;

  T get value {
    _RxObserver.active?.read.add(this);
    return _value;
  }

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  T call(T newValue) {
    value = newValue;
    return _value;
  }

  void refresh() => notifyListeners();

  @override
  String toString() => _value.toString();
}

class URxInt extends URx<int> {
  URxInt(super.value);
}

class URxDouble extends URx<double> {
  URxDouble(super.value);
}

class URxNum extends URx<num> {
  URxNum(super.value);
}

class URxString extends URx<String> {
  URxString(super.value);
}

class URxBool extends URx<bool> {
  URxBool(super.value);

  bool get isTrue => value;

  bool get isFalse => !value;

  void toggle() => value = !_value;
}

class URxn<T> extends URx<T?> {
  URxn([super.initial]);
}

class URxnInt extends URx<int?> {
  URxnInt([super.initial]);
}

class URxnDouble extends URx<double?> {
  URxnDouble([super.initial]);
}

class URxnNum extends URx<num?> {
  URxnNum([super.initial]);
}

class URxnString extends URx<String?> {
  URxnString([super.initial]);
}

class URxnBool extends URx<bool?> {
  URxnBool([super.initial]);

  bool? get isTrue => value;

  bool? get isFalse => value == null ? null : !value!;

  void toggle() => value = !(value ?? false);
}

enum UPageState {
  initial,
  loading,
  loaded,
  error,
  empty,
  paging;

  bool isInitial() => this == UPageState.initial;

  bool isLoading() => this == UPageState.loading;

  bool isLoaded() => this == UPageState.loaded;

  bool isError() => this == UPageState.error;

  bool isPaging() => this == UPageState.paging;

  bool isEmpty() => this == UPageState.empty;
}

class URxState extends URx<UPageState> {
  URxState([super.initial = UPageState.initial]);

  bool isInitial() => value.isInitial();

  bool isLoading() => value.isLoading();

  bool isLoaded() => value.isLoaded();

  bool isError() => value.isError();

  bool isPaging() => value.isPaging();

  bool isEmpty() => value.isEmpty();

  UPageState initial() => this(UPageState.initial);

  UPageState loading() => this(UPageState.loading);

  UPageState loaded() => this(UPageState.loaded);

  UPageState error() => this(UPageState.error);

  UPageState paging() => this(UPageState.paging);

  UPageState emptying() => this(UPageState.empty);
}

class URxList<E> extends URx<List<E>> with ListMixin<E> {
  URxList([List<E>? initial]) : super(initial ?? <E>[]);

  @override
  int get length {
    _RxObserver.active?.read.add(this);
    return _value.length;
  }

  @override
  set length(int newLength) {
    _value.length = newLength;
    refresh();
  }

  @override
  E operator [](int index) {
    _RxObserver.active?.read.add(this);
    return _value[index];
  }

  @override
  void operator []=(int index, E element) {
    _value[index] = element;
    refresh();
  }

  @override
  void add(E element) {
    _value.add(element);
    refresh();
  }

  @override
  void addAll(Iterable<E> iterable) {
    _value.addAll(iterable);
    refresh();
  }

  void assignAll(Iterable<E> items) {
    _value
      ..clear()
      ..addAll(items);
    refresh();
  }

  void assign(E item) {
    _value
      ..clear()
      ..add(item);
    refresh();
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    _value.sort(compare);
    refresh();
  }

  @override
  void insert(int index, E element) {
    _value.insert(index, element);
    refresh();
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _value.insertAll(index, iterable);
    refresh();
  }

  @override
  E removeAt(int index) {
    final E removed = _value.removeAt(index);
    refresh();
    return removed;
  }

  @override
  E removeLast() {
    final E removed = _value.removeLast();
    refresh();
    return removed;
  }

  @override
  bool remove(Object? element) {
    final bool removed = _value.remove(element);
    if (removed) refresh();
    return removed;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _value.removeWhere(test);
    refresh();
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _value.retainWhere(test);
    refresh();
  }

  @override
  void removeRange(int start, int end) {
    _value.removeRange(start, end);
    refresh();
  }

  @override
  void clear() {
    _value.clear();
    refresh();
  }

  @override
  List<E> call([List<E>? newValue]) {
    if (newValue != null) value = newValue;
    return _value;
  }
}

/// Observable map. Mutating methods notify listeners; behaves like a normal
/// [Map] elsewhere thanks to [MapMixin].
class URxMap<K, V> extends URx<Map<K, V>> with MapMixin<K, V> {
  URxMap([Map<K, V>? initial]) : super(initial ?? <K, V>{});

  @override
  V? operator [](Object? key) {
    _RxObserver.active?.read.add(this);
    return _value[key];
  }

  @override
  void operator []=(K key, V value) {
    _value[key] = value;
    refresh();
  }

  @override
  Iterable<K> get keys {
    _RxObserver.active?.read.add(this);
    return _value.keys;
  }

  @override
  void addAll(Map<K, V> other) {
    _value.addAll(other);
    refresh();
  }

  @override
  V? remove(Object? key) {
    final V? removed = _value.remove(key);
    refresh();
    return removed;
  }

  @override
  void clear() {
    _value.clear();
    refresh();
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    _value.removeWhere(test);
    refresh();
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    _value.addEntries(newEntries);
    refresh();
  }

  void assignAll(Map<K, V> items) {
    _value
      ..clear()
      ..addAll(items);
    refresh();
  }

  @override
  Map<K, V> call([Map<K, V>? newValue]) {
    if (newValue != null) value = newValue;
    return _value;
  }
}

class URxSet<E> extends URx<Set<E>> with SetMixin<E> {
  URxSet([Set<E>? initial]) : super(initial ?? <E>{});

  @override
  bool add(E value) {
    final bool added = _value.add(value);
    if (added) refresh();
    return added;
  }

  @override
  bool contains(Object? element) {
    _RxObserver.active?.read.add(this);
    return _value.contains(element);
  }

  @override
  E? lookup(Object? element) {
    _RxObserver.active?.read.add(this);
    return _value.lookup(element);
  }

  @override
  bool remove(Object? value) {
    final bool removed = _value.remove(value);
    if (removed) refresh();
    return removed;
  }

  @override
  int get length {
    _RxObserver.active?.read.add(this);
    return _value.length;
  }

  @override
  Iterator<E> get iterator {
    _RxObserver.active?.read.add(this);
    return _value.iterator;
  }

  @override
  Set<E> toSet() => _value.toSet();

  @override
  void addAll(Iterable<E> elements) {
    _value.addAll(elements);
    refresh();
  }

  @override
  void clear() {
    _value.clear();
    refresh();
  }

  // Notify once instead of once-per-element (see RxList note).
  @override
  void removeWhere(bool Function(E element) test) {
    _value.removeWhere(test);
    refresh();
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _value.retainWhere(test);
    refresh();
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    _value.removeAll(elements);
    refresh();
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    _value.retainAll(elements);
    refresh();
  }

  void assignAll(Iterable<E> items) {
    _value
      ..clear()
      ..addAll(items);
    refresh();
  }

  @override
  Set<E> call([Set<E>? newValue]) {
    if (newValue != null) value = newValue;
    return _value;
  }
}

extension RxObjectExt<T> on T {
  URx<T> get obs => URx<T>(this);
}

extension RxIntExt on int {
  URxInt get obs => URxInt(this);
}

extension RxDoubleExt on double {
  URxDouble get obs => URxDouble(this);
}

extension RxNumExt on num {
  URxNum get obs => URxNum(this);
}

extension RxStringExt on String {
  URxString get obs => URxString(this);
}

extension RxBoolExt on bool {
  URxBool get obs => URxBool(this);
}

extension RxListExt<E> on List<E> {
  URxList<E> get obs => URxList<E>(this);
}

extension RxMapExt<K, V> on Map<K, V> {
  URxMap<K, V> get obs => URxMap<K, V>(this);
}

extension RxSetExt<E> on Set<E> {
  URxSet<E> get obs => URxSet<E>(this);
}

extension RxnListExt<E> on List<E>? {
  URxList<E> get obs => URxList<E>(this);
}

extension RxnMapExt<K, V> on Map<K, V>? {
  URxMap<K, V> get obs => URxMap<K, V>(this);
}

extension RxnSetExt<E> on Set<E>? {
  URxSet<E> get obs => URxSet<E>(this);
}

extension RxnIntExt on int? {
  URxnInt get obs => URxnInt(this);
}

extension RxnDoubleExt on double? {
  URxnDouble get obs => URxnDouble(this);
}

extension RxnNumExt on num? {
  URxnNum get obs => URxnNum(this);
}

extension RxnStringExt on String? {
  URxnString get obs => URxnString(this);
}

extension RxnBoolExt on bool? {
  URxnBool get obs => URxnBool(this);
}

class UObx extends StatefulWidget {
  const UObx(this.builder, {super.key});

  final Widget Function() builder;

  @override
  State<UObx> createState() => _ObxState();
}

class _ObxState extends State<UObx> {
  final Set<URx<dynamic>> _subscriptions = <URx<dynamic>>{};

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final _RxObserver observer = _RxObserver();
    final _RxObserver? previous = _RxObserver.active;
    _RxObserver.active = observer;
    final Widget child = widget.builder();
    _RxObserver.active = previous;
    _sync(observer.read);
    return child;
  }

  void _sync(Set<URx<dynamic>> next) {
    for (final URx<dynamic> rx in _subscriptions) {
      if (!next.contains(rx)) rx.removeListener(_onChange);
    }
    for (final URx<dynamic> rx in next) {
      if (!_subscriptions.contains(rx)) rx.addListener(_onChange);
    }
    _subscriptions
      ..clear()
      ..addAll(next);
  }

  @override
  void dispose() {
    for (final URx<dynamic> rx in _subscriptions) {
      rx.removeListener(_onChange);
    }
    super.dispose();
  }
}
