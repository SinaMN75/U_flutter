import "dart:collection";

import "package:flutter/widgets.dart";

class _RxObserver {
  static _RxObserver? active;
  final Set<Rx<dynamic>> read = <Rx<dynamic>>{};
}

class Rx<T> extends ChangeNotifier {
  Rx(this._value);

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

class RxInt extends Rx<int> {
  RxInt(super.value);
}

class RxDouble extends Rx<double> {
  RxDouble(super.value);
}

class RxNum extends Rx<num> {
  RxNum(super.value);
}

class RxString extends Rx<String> {
  RxString(super.value);
}

class RxBool extends Rx<bool> {
  RxBool(super.value);

  bool get isTrue => value;

  bool get isFalse => !value;

  void toggle() => value = !_value;
}

class Rxn<T> extends Rx<T?> {
  Rxn([super.initial]);
}

class RxnInt extends Rx<int?> {
  RxnInt([super.initial]);
}

class RxnDouble extends Rx<double?> {
  RxnDouble([super.initial]);
}

class RxnNum extends Rx<num?> {
  RxnNum([super.initial]);
}

class RxnString extends Rx<String?> {
  RxnString([super.initial]);
}

class RxnBool extends Rx<bool?> {
  RxnBool([super.initial]);

  bool? get isTrue => value;

  bool? get isFalse => value == null ? null : !value!;

  void toggle() => value = !(value ?? false);
}

enum PageState {
  initial,
  loading,
  loaded,
  error,
  empty,
  paging;

  bool isInitial() => this == PageState.initial;

  bool isLoading() => this == PageState.loading;

  bool isLoaded() => this == PageState.loaded;

  bool isError() => this == PageState.error;

  bool isPaging() => this == PageState.paging;

  bool isEmpty() => this == PageState.empty;
}

class RxState extends Rx<PageState> {
  RxState([super.initial = PageState.initial]);

  bool isInitial() => value.isInitial();

  bool isLoading() => value.isLoading();

  bool isLoaded() => value.isLoaded();

  bool isError() => value.isError();

  bool isPaging() => value.isPaging();

  bool isEmpty() => value.isEmpty();

  PageState initial() => this(PageState.initial);

  PageState loading() => this(PageState.loading);

  PageState loaded() => this(PageState.loaded);

  PageState error() => this(PageState.error);

  PageState paging() => this(PageState.paging);

  PageState emptying() => this(PageState.empty);
}

class RxList<E> extends Rx<List<E>> with ListMixin<E> {
  RxList([List<E>? initial]) : super(initial ?? <E>[]);

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
class RxMap<K, V> extends Rx<Map<K, V>> with MapMixin<K, V> {
  RxMap([Map<K, V>? initial]) : super(initial ?? <K, V>{});

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

class RxSet<E> extends Rx<Set<E>> with SetMixin<E> {
  RxSet([Set<E>? initial]) : super(initial ?? <E>{});

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
  Rx<T> get obs => Rx<T>(this);
}

extension RxIntExt on int {
  RxInt get obs => RxInt(this);
}

extension RxDoubleExt on double {
  RxDouble get obs => RxDouble(this);
}

extension RxNumExt on num {
  RxNum get obs => RxNum(this);
}

extension RxStringExt on String {
  RxString get obs => RxString(this);
}

extension RxBoolExt on bool {
  RxBool get obs => RxBool(this);
}

extension RxListExt<E> on List<E> {
  RxList<E> get obs => RxList<E>(this);
}

extension RxMapExt<K, V> on Map<K, V> {
  RxMap<K, V> get obs => RxMap<K, V>(this);
}

extension RxSetExt<E> on Set<E> {
  RxSet<E> get obs => RxSet<E>(this);
}

extension RxnListExt<E> on List<E>? {
  RxList<E> get obs => RxList<E>(this);
}

extension RxnMapExt<K, V> on Map<K, V>? {
  RxMap<K, V> get obs => RxMap<K, V>(this);
}

extension RxnSetExt<E> on Set<E>? {
  RxSet<E> get obs => RxSet<E>(this);
}

extension RxnIntExt on int? {
  RxnInt get obs => RxnInt(this);
}

extension RxnDoubleExt on double? {
  RxnDouble get obs => RxnDouble(this);
}

extension RxnNumExt on num? {
  RxnNum get obs => RxnNum(this);
}

extension RxnStringExt on String? {
  RxnString get obs => RxnString(this);
}

extension RxnBoolExt on bool? {
  RxnBool get obs => RxnBool(this);
}

class Obx extends StatefulWidget {
  const Obx(this.builder, {super.key});

  final Widget Function() builder;

  @override
  State<Obx> createState() => _ObxState();
}

class _ObxState extends State<Obx> {
  final Set<Rx<dynamic>> _subscriptions = <Rx<dynamic>>{};

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

  void _sync(Set<Rx<dynamic>> next) {
    for (final Rx<dynamic> rx in _subscriptions) {
      if (!next.contains(rx)) rx.removeListener(_onChange);
    }
    for (final Rx<dynamic> rx in next) {
      if (!_subscriptions.contains(rx)) rx.addListener(_onChange);
    }
    _subscriptions
      ..clear()
      ..addAll(next);
  }

  @override
  void dispose() {
    for (final Rx<dynamic> rx in _subscriptions) {
      rx.removeListener(_onChange);
    }
    super.dispose();
  }
}
