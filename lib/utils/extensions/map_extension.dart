extension MapAddExtension<K, V> on Map<K, V> {
  Map<K, V> add(K key, V value) => <K, V>{...this, key: value};
}
