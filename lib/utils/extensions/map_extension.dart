/// Map helpers: add, typed reads, drop nulls, merge. `json.getOr<int>("count", 0)`
extension MapAddExtension<K, V> on Map<K, V> {
  /// New map with [key] set to [value]. `params.add("page", 2)`
  Map<K, V> add(K key, V value) => <K, V>{...this, key: value};

  /// Value of [key] as T, or [fallback] when missing or another type. `json.getOr<String>("name", "")`
  T getOr<T>(K key, T fallback) {
    final V? value = this[key];
    return value is T ? value as T : fallback;
  }

  /// New map without null values (handy before sending JSON). `body.removeNulls()`
  Map<K, V> removeNulls() => <K, V>{
    for (final MapEntry<K, V> e in entries)
      if (e.value != null) e.key: e.value,
  };

  /// New map where [other] wins and nested maps are merged too. `defaults.deepMerge(overrides)`
  Map<K, V> deepMerge(Map<K, V> other) {
    final Map<K, V> out = <K, V>{...this};
    other.forEach((K key, V value) {
      final V? mine = out[key];
      if (mine is Map<K, V> && value is Map<K, V>) {
        out[key] = mine.deepMerge(value) as V;
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  /// New map with only the listed keys. `user.pick(["id", "name"])`
  Map<K, V> pick(Iterable<K> keys) => <K, V>{
    for (final K k in keys)
      if (containsKey(k)) k: this[k] as V,
  };

  /// New map without the listed keys. `user.omit(["password"])`
  Map<K, V> omit(Iterable<K> keys) {
    final Set<K> drop = keys.toSet();
    return <K, V>{
      for (final MapEntry<K, V> e in entries)
        if (!drop.contains(e.key)) e.key: e.value,
    };
  }
}
