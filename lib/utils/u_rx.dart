import "dart:collection";

import "package:flutter/widgets.dart";

class _RxObserver {
  static _RxObserver? active;
  final Set<URx<dynamic>> read = <URx<dynamic>>{};
}

/// A value that rebuilds UObx widgets when it changes (tiny GetX-style state). `final URxInt count = 0.obs; UObx(() => Text("${count.value}"))`
class URx<T> extends ChangeNotifier {
  /// Wraps a starting value.
  URx(this._value);

  T _value;

  /// The current value; setting it notifies listeners when it changed. `count.value++`
  T get value {
    _RxObserver.active?.read.add(this);
    return _value;
  }

  /// The current value; setting it notifies listeners when it changed. `count.value++`
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  /// Sets the value like a function and returns it. `count(5)`
  T call(T newValue) {
    value = newValue;
    return _value;
  }

  /// Notifies listeners without changing the value (after mutating an object inside).
  void refresh() => notifyListeners();

  @override
  String toString() => _value.toString();
}

/// Observable int. `final URxInt n = 0.obs;`
class URxInt extends URx<int> {
  /// Observable int.
  URxInt(super.value);
}

/// Observable double.
class URxDouble extends URx<double> {
  /// Observable double.
  URxDouble(super.value);
}

/// Observable num.
class URxNum extends URx<num> {
  /// Observable num.
  URxNum(super.value);
}

/// Observable String. `final URxString name = "".obs;`
class URxString extends URx<String> {
  /// Observable String.
  URxString(super.value);
}

/// Observable bool with toggle(). `final URxBool loading = false.obs;`
class URxBool extends URx<bool> {
  /// Observable bool.
  URxBool(super.value);

  /// True when the value is true.
  bool get isTrue => value;

  /// True when the value is false.
  bool get isFalse => !value;

  /// Flips the value. `visible.toggle()`
  void toggle() => value = !_value;
}

/// Observable nullable value. `final URxn<User> user = URxn<User>();`
class URxn<T> extends URx<T?> {
  /// Observable nullable value, null by default.
  URxn([super.initial]);
}

/// Observable int?.
class URxnInt extends URx<int?> {
  /// Observable int?, null by default.
  URxnInt([super.initial]);
}

/// Observable double?.
class URxnDouble extends URx<double?> {
  /// Observable double?, null by default.
  URxnDouble([super.initial]);
}

/// Observable num?.
class URxnNum extends URx<num?> {
  /// Observable num?, null by default.
  URxnNum([super.initial]);
}

/// Observable String?.
class URxnString extends URx<String?> {
  /// Observable String?, null by default.
  URxnString([super.initial]);
}

/// Observable bool?.
class URxnBool extends URx<bool?> {
  /// Observable bool?, null by default.
  URxnBool([super.initial]);

  /// True when the value is true (null when null).
  bool? get isTrue => value;

  /// True when the value is false (null when null).
  bool? get isFalse => value == null ? null : !value!;

  /// Flips the value (null becomes true).
  void toggle() => value = !(value ?? false);
}

/// Page loading states: initial, loading, loaded, error, empty, paging (loading more).
enum UPageState {
  initial,
  loading,
  loaded,
  error,
  empty,
  paging;

  /// True before the first load.
  bool isInitial() => this == UPageState.initial;

  /// True while loading.
  bool isLoading() => this == UPageState.loading;

  /// True when data is shown.
  bool isLoaded() => this == UPageState.loaded;

  /// True after a failure.
  bool isError() => this == UPageState.error;

  /// True while loading the next page.
  bool isPaging() => this == UPageState.paging;

  /// True when loaded but empty.
  bool isEmpty() => this == UPageState.empty;
}

/// Observable UPageState for a page's loading/error/empty UI. `final URxState state = URxState(); state.loading(); await load(); state.loaded();`
class URxState extends URx<UPageState> {
  /// Starts at UPageState.initial.
  URxState([super.initial = UPageState.initial]);

  /// True before the first load.
  bool isInitial() => value.isInitial();

  /// True while loading.
  bool isLoading() => value.isLoading();

  /// True when data is shown.
  bool isLoaded() => value.isLoaded();

  /// True after a failure.
  bool isError() => value.isError();

  /// True while loading the next page.
  bool isPaging() => value.isPaging();

  /// True when loaded but empty.
  bool isEmpty() => value.isEmpty();

  /// Switches to initial.
  UPageState initial() => this(UPageState.initial);

  /// Switches to loading.
  UPageState loading() => this(UPageState.loading);

  /// Switches to loaded.
  UPageState loaded() => this(UPageState.loaded);

  /// Switches to error.
  UPageState error() => this(UPageState.error);

  /// Switches to paging.
  UPageState paging() => this(UPageState.paging);

  /// Switches to empty.
  UPageState emptying() => this(UPageState.empty);
}

/// Observable List; add/remove/sort rebuild UObx. `final URxList<String> items = <String>[].obs; items.add("x");`
class URxList<E> extends URx<List<E>> with ListMixin<E> {
  /// Observable list, empty by default.
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

  /// Replaces every item and notifies once.
  void assignAll(Iterable<E> items) {
    _value
      ..clear()
      ..addAll(items);
    refresh();
  }

  /// Replaces the list with a single item.
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

/// Observable Map; changes rebuild UObx. `final URxMap<String, int> cart = <String, int>{}.obs;`
class URxMap<K, V> extends URx<Map<K, V>> with MapMixin<K, V> {
  /// Observable map, empty by default.
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

  /// Replaces every entry and notifies once.
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

/// Observable Set; changes rebuild UObx.
class URxSet<E> extends URx<Set<E>> with SetMixin<E> {
  /// Observable set, empty by default.
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

  /// Replaces every item and notifies once.
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

/// `.obs` on any value. `final URx<User> user = User().obs;`
extension RxObjectExt<T> on T {
  /// Wraps this value in a URx.
  URx<T> get obs => URx<T>(this);
}

/// `.obs` on int → URxInt.
extension RxIntExt on int {
  /// Wraps this int in a URxInt.
  URxInt get obs => URxInt(this);
}

/// `.obs` on double → URxDouble.
extension RxDoubleExt on double {
  /// Wraps this double in a URxDouble.
  URxDouble get obs => URxDouble(this);
}

/// `.obs` on num → URxNum.
extension RxNumExt on num {
  /// Wraps this num in a URxNum.
  URxNum get obs => URxNum(this);
}

/// `.obs` on String → URxString.
extension RxStringExt on String {
  /// Wraps this String in a URxString.
  URxString get obs => URxString(this);
}

/// `.obs` on bool → URxBool.
extension RxBoolExt on bool {
  /// Wraps this bool in a URxBool.
  URxBool get obs => URxBool(this);
}

/// `.obs` on List → URxList.
extension RxListExt<E> on List<E> {
  /// Wraps this list in a URxList.
  URxList<E> get obs => URxList<E>(this);
}

/// `.obs` on Map → URxMap.
extension RxMapExt<K, V> on Map<K, V> {
  /// Wraps this map in a URxMap.
  URxMap<K, V> get obs => URxMap<K, V>(this);
}

/// `.obs` on Set → URxSet.
extension RxSetExt<E> on Set<E> {
  /// Wraps this set in a URxSet.
  URxSet<E> get obs => URxSet<E>(this);
}

/// `.obs` on List? → URxList (null becomes empty).
extension RxnListExt<E> on List<E>? {
  /// Wraps this list (or an empty one) in a URxList.
  URxList<E> get obs => URxList<E>(this);
}

/// `.obs` on Map? → URxMap (null becomes empty).
extension RxnMapExt<K, V> on Map<K, V>? {
  /// Wraps this map (or an empty one) in a URxMap.
  URxMap<K, V> get obs => URxMap<K, V>(this);
}

/// `.obs` on Set? → URxSet (null becomes empty).
extension RxnSetExt<E> on Set<E>? {
  /// Wraps this set (or an empty one) in a URxSet.
  URxSet<E> get obs => URxSet<E>(this);
}

/// `.obs` on int? → URxnInt.
extension RxnIntExt on int? {
  /// Wraps this int? in a URxnInt.
  URxnInt get obs => URxnInt(this);
}

/// `.obs` on double? → URxnDouble.
extension RxnDoubleExt on double? {
  /// Wraps this double? in a URxnDouble.
  URxnDouble get obs => URxnDouble(this);
}

/// `.obs` on num? → URxnNum.
extension RxnNumExt on num? {
  /// Wraps this num? in a URxnNum.
  URxnNum get obs => URxnNum(this);
}

/// `.obs` on String? → URxnString.
extension RxnStringExt on String? {
  /// Wraps this String? in a URxnString.
  URxnString get obs => URxnString(this);
}

/// `.obs` on bool? → URxnBool.
extension RxnBoolExt on bool? {
  /// Wraps this bool? in a URxnBool.
  URxnBool get obs => URxnBool(this);
}

/// Rebuilds automatically when any URx read inside [builder] changes. `UObx(() => Text(name.value))`
class UObx extends StatefulWidget {
  /// Watches every URx the builder reads.
  const UObx(this.builder, {super.key});

  /// Builds the widget; reading .value inside subscribes to that URx.
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
