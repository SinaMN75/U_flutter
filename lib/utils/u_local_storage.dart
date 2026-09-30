import "package:u/utilities.dart";

/// The original key/value API, now backed by [UStorage]. Signatures are unchanged.
/// Keys in [UStorage.secureKeys] (token, refresh token and its expiry) live in the
/// encrypted [UStorage.secure] store; everything else in the default store.
abstract class ULocalStorage {
  /// Loads storage from disk (initU() already does this).
  static Future<void> init() => UStorage.init();

  static UStore _storeFor(String key) => UStorage.secureKeys.contains(key) ? UStorage.secure : UStorage.instance;

  /// All saved keys.
  static Set<String> getKeys() => <String>{...UStorage.instance.keys, ...UStorage.secure.keys};

  /// Saves a value (null deletes it); optional expiry and encryption.
  static void set(String key, dynamic value, {Duration? expireTime, (String, String)? encryptKeyIv}) {
    final Object? stored = value is String && encryptKeyIv != null ? UEncryption.aesEncrypt(plainText: value, key: encryptKeyIv.$1, iv: encryptKeyIv.$2) : value as Object?;
    unawaited(_storeFor(key).set(key, stored, ttl: expireTime));
  }

  /// Reads an int.
  static int? getInt(String key) => _storeFor(key).get<int>(key);

  /// Reads a String (decrypts it when a key/iv is given).
  static String? getString(String key, {(String, String)? encryptKeyIv}) {
    final String? value = _storeFor(key).get<String>(key);
    if (value == null) return null;
    if (encryptKeyIv == null) return value;

    return UEncryption.aesDecrypt(
      base64Encrypted: value,
      key: encryptKeyIv.$1,
      iv: encryptKeyIv.$2,
    );
  }

  /// Reads a bool.
  static bool? getBool(String key) => _storeFor(key).get<bool>(key);

  /// Reads a double.
  static double? getDouble(String key) => _storeFor(key).get<double>(key);

  /// Reads a list of strings.
  static List<String>? getStringList(String key) => _storeFor(key).get<List<String>>(key);

  /// Saves the auth token (encrypted).
  static void setToken(String value, {Duration? expireTime}) => set(UConstants.token, value, expireTime: expireTime);

  /// Saves the refresh token (encrypted).
  static void setRefreshToken(String value) => set(UConstants.refreshToken, value);

  /// Saves when the refresh token expires (null deletes it).
  static void setRefreshTokenExpiresAt(DateTime? value) {
    if (value == null) {
      remove(UConstants.refreshTokenExpiresAt);
      return;
    }
    set(UConstants.refreshTokenExpiresAt, value.toUtc().millisecondsSinceEpoch);
  }

  /// Saves the app language.
  static void setLocale(String value) => set(UConstants.locale, value);

  /// Saves the dark mode choice.
  static void setDarkMode(bool isDarkMode) => set(UConstants.isDarkMode, isDarkMode);

  /// Saves the user id.
  static void setUserId(String userId) => set(UConstants.userId, userId);

  /// Reads the auth token.
  static String? getToken() => getString(UConstants.token);

  /// Reads the refresh token.
  static String? getRefreshToken() => getString(UConstants.refreshToken);

  /// Reads when the refresh token expires.
  static DateTime? getRefreshTokenExpiresAt() {
    final int? value = getInt(UConstants.refreshTokenExpiresAt);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  /// Reads the saved app language.
  static String? getLocale() => getString(UConstants.locale);

  /// True when an auth token is saved.
  static bool hasToken() => getToken() != null;

  /// Reads the saved dark mode choice.
  static bool isDarkMode() => getBool(UConstants.isDarkMode) ?? false;

  /// Reads the saved user id.
  static String? getUserId() => getString(UConstants.userId);

  /// True when [key] is saved.
  static bool containsKey(String key) => _storeFor(key).has(key);

  /// Deletes [key].
  static Future<void> remove(String key) => _storeFor(key).remove(key);

  /// Deletes everything (token included).
  static Future<void> clear() => Future.wait(<Future<void>>[UStorage.instance.clear(), UStorage.secure.clear()]);

  /// All saved keys and values.
  static Map<String, dynamic> getAll() => <String, dynamic>{...UStorage.instance.toMap(), ...UStorage.secure.toMap()};

  // --- UStorage, one wrapper each ------------------------------------------------------------

  /// Reads a value as type T, e.g. `get<DateTime>("seen")`.
  static T? get<T>(String key) => _storeFor(key).get<T>(key);

  /// Reads a value, or [fallback] when missing.
  static T getOr<T>(String key, T fallback) => _storeFor(key).getOr<T>(key, fallback);

  /// Reads a DateTime.
  static DateTime? getDateTime(String key) => get<DateTime>(key);

  /// Reads a Duration.
  static Duration? getDuration(String key) => get<Duration>(key);

  /// Reads raw bytes.
  static Uint8List? getBytes(String key) => get<Uint8List>(key);

  /// Reads a JSON map.
  static Map<String, dynamic>? getMap(String key) => get<Map<String, dynamic>>(key);

  /// Reads a JSON list.
  static List<dynamic>? getList(String key) => get<List<dynamic>>(key);

  /// Reads an enum saved with set().
  static T? getEnum<T extends Enum>(String key, List<T> values) => _storeFor(key).getEnum<T>(key, values);

  /// Reads a model saved with set(), using its fromJson.
  static T? getObject<T>(String key, T Function(Map<String, dynamic> json) fromJson) => _storeFor(key).getObject<T>(key, fromJson);

  /// Reads a list of models saved with set(), using fromJson.
  static List<T>? getObjects<T>(String key, T Function(Map<String, dynamic> json) fromJson) => _storeFor(key).getObjects<T>(key, fromJson);

  /// Saves a value and waits until it is on disk.
  static Future<void> setAndWait(String key, Object? value, {Duration? expireTime}) => _storeFor(key).set(key, value, ttl: expireTime);

  /// Saves many values at once and waits until they are on disk.
  static Future<void> setAll(Map<String, Object?> entries, {Duration? expireTime}) async {
    for (final MapEntry<String, Object?> e in entries.entries) {
      unawaited(_storeFor(e.key).set(e.key, e.value, ttl: expireTime));
    }
    await UStorage.flushAll();
  }

  /// Time left before [key] expires (null if it never does).
  static Duration? ttlOf(String key) => _storeFor(key).ttlOf(key);

  /// Sets or removes the expiry of an existing key.
  static Future<void> expire(String key, Duration? expireTime) => _storeFor(key).expire(key, expireTime);

  /// Adds [by] to a saved int and returns the new value.
  static int increment(String key, {int by = 1}) => _storeFor(key).increment(key, by: by);

  /// Replaces a value using its current value.
  static Future<void> update<T>(String key, T? Function(T? current) transform) => _storeFor(key).update<T>(key, transform);

  /// Deletes several keys.
  static Future<void> removeAll(Iterable<String> keys) => Future.wait(keys.map(remove));

  /// Deletes every key that matches [test].
  static Future<void> removeWhere(bool Function(String key, Object value) test) =>
      Future.wait(<Future<void>>[UStorage.instance.removeWhere(test), UStorage.secure.removeWhere(test)]);

  /// Number of saved keys.
  static int get length => UStorage.instance.length + UStorage.secure.length;

  /// True when nothing is saved.
  static bool get isEmpty => length == 0;

  /// Emits the value of [key] now and every time it changes.
  static Stream<T?> watch<T>(String key, {bool emitCurrent = true}) => _storeFor(key).watch<T>(key, emitCurrent: emitCurrent);

  /// Value of [key] for ValueListenableBuilder.
  static ValueListenable<T?> listenable<T>(String key) => _storeFor(key).listenable<T>(key);

  /// Emits every change in normal storage.
  static Stream<UStorageChange> get changes => UStorage.changes;

  /// Emits every change in encrypted storage.
  static Stream<UStorageChange> get secureChanges => UStorage.secure.changes;

  /// Writes pending changes to disk now.
  static Future<void> flush() => UStorage.flushAll();

  // Secure store, for any key (tokens are routed there automatically).

  /// Saves a value encrypted.
  static Future<void> setSecure(String key, Object? value, {Duration? expireTime}) => UStorage.secure.set(key, value, ttl: expireTime);

  /// Reads an encrypted value.
  static T? getSecure<T>(String key) => UStorage.secure.get<T>(key);

  /// True when [key] is saved encrypted.
  static bool containsSecure(String key) => UStorage.secure.has(key);

  /// Deletes an encrypted value.
  static Future<void> removeSecure(String key) => UStorage.secure.remove(key);

  /// Deletes all encrypted values.
  static Future<void> clearSecure() => UStorage.secure.clear();

  // Named stores: separate files, cleared or deleted independently.

  /// Opens a separate storage file, e.g. openStore("cache").
  static Future<UStore> openStore(String name, {bool secure = false}) => UStorage.open(name, secure: secure);

  /// Returns a storage file already opened with openStore().
  static UStore store(String name) => UStorage.store(name);

  /// Deletes a separate storage file and all its data.
  static Future<void> deleteStore(String name, {bool secure = false}) => UStorage.deleteStore(name, secure: secure);
}
