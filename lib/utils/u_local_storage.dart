import "package:u/utilities.dart";

/// Fast key/value storage on all 6 platforms; tokens are encrypted automatically (Keychain/Keystore-backed key; web: sealed in IndexedDB). `ULocalStorage.set("name", "Sina"); ULocalStorage.getString("name")`
abstract class ULocalStorage {
  /// Loads storage from disk; initU() already does it.
  static Future<void> init() => UStorage.init();

  static UStore _storeFor(String key) => UStorage.secureKeys.contains(key) ? UStorage.secure : UStorage.instance;

  /// Every saved key (normal and encrypted).
  static Set<String> getKeys() => <String>{...UStorage.instance.keys, ...UStorage.secure.keys};

  /// Saves any JSON-able value (null deletes); [expireTime] auto-deletes; [encryptKeyIv] AES-encrypts a String. `ULocalStorage.set("cart", items, expireTime: 1.days)`
  static void set(String key, dynamic value, {Duration? expireTime, (String, String)? encryptKeyIv}) {
    final Object? stored = value is String && encryptKeyIv != null ? UEncryption.aesEncrypt(plainText: value, key: encryptKeyIv.$1, iv: encryptKeyIv.$2) : value as Object?;
    unawaited(_storeFor(key).set(key, stored, ttl: expireTime));
  }

  /// Reads an int. `ULocalStorage.getInt("count")`
  static int? getInt(String key) => _storeFor(key).get<int>(key);

  /// Reads a String; pass the same [encryptKeyIv] used in set() to decrypt. `ULocalStorage.getString("name")`
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

  /// Saves the auth token (encrypted); UHttpClient sends it automatically. `ULocalStorage.setToken(response.token)`
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

  /// Saves the app language code. `ULocalStorage.setLocale("fa")`
  static void setLocale(String value) => set(UConstants.locale, value);

  /// Saves the dark mode choice.
  static void setDarkMode(bool isDarkMode) => set(UConstants.isDarkMode, isDarkMode);

  /// Saves the user id.
  static void setUserId(String userId) => set(UConstants.userId, userId);

  /// Reads the auth token (null when logged out).
  static String? getToken() => getString(UConstants.token);

  /// Reads the refresh token.
  static String? getRefreshToken() => getString(UConstants.refreshToken);

  /// Reads when the refresh token expires.
  static DateTime? getRefreshTokenExpiresAt() {
    final int? value = getInt(UConstants.refreshTokenExpiresAt);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  /// Reads the saved app language code.
  static String? getLocale() => getString(UConstants.locale);

  /// True when an auth token is saved (logged in). `home: ULocalStorage.hasToken() ? HomePage() : LoginPage()`
  static bool hasToken() => getToken() != null;

  /// Reads the saved dark mode choice (false when never set).
  static bool isDarkMode() => getBool(UConstants.isDarkMode) ?? false;

  /// Reads the saved user id.
  static String? getUserId() => getString(UConstants.userId);

  /// True when [key] is saved and not expired.
  static bool containsKey(String key) => _storeFor(key).has(key);

  /// Deletes [key]. `await ULocalStorage.remove("cart")`
  static Future<void> remove(String key) => _storeFor(key).remove(key);

  /// Deletes everything, tokens included (logout). `await ULocalStorage.clear()`
  static Future<void> clear() => Future.wait(<Future<void>>[UStorage.instance.clear(), UStorage.secure.clear()]);

  /// Every key and value (for debugging).
  static Map<String, dynamic> getAll() => <String, dynamic>{...UStorage.instance.toMap(), ...UStorage.secure.toMap()};

  // --- UStorage, one wrapper each ------------------------------------------------------------

  /// Reads a value as any type, incl. DateTime, Duration, Uint8List. `ULocalStorage.get<DateTime>("lastSync")`
  static T? get<T>(String key) => _storeFor(key).get<T>(key);

  /// Reads a value, or [fallback] when missing. `ULocalStorage.getOr<int>("volume", 50)`
  static T getOr<T>(String key, T fallback) => _storeFor(key).getOr<T>(key, fallback);

  /// Reads a DateTime saved with set().
  static DateTime? getDateTime(String key) => get<DateTime>(key);

  /// Reads a Duration saved with set().
  static Duration? getDuration(String key) => get<Duration>(key);

  /// Reads bytes saved with set().
  static Uint8List? getBytes(String key) => get<Uint8List>(key);

  /// Reads a JSON map.
  static Map<String, dynamic>? getMap(String key) => get<Map<String, dynamic>>(key);

  /// Reads a JSON list.
  static List<dynamic>? getList(String key) => get<List<dynamic>>(key);

  /// Reads an enum saved with set(). `ULocalStorage.getEnum("theme", ThemeMode.values)`
  static T? getEnum<T extends Enum>(String key, List<T> values) => _storeFor(key).getEnum<T>(key, values);

  /// Reads a model saved with set() (anything with toJson), via its fromJson. `ULocalStorage.getObject("user", UUserResponse.fromJson)`
  static T? getObject<T>(String key, T Function(Map<String, dynamic> json) fromJson) => _storeFor(key).getObject<T>(key, fromJson);

  /// Reads a list of models, via fromJson. `ULocalStorage.getObjects("addresses", Address.fromJson)`
  static List<T>? getObjects<T>(String key, T Function(Map<String, dynamic> json) fromJson) => _storeFor(key).getObjects<T>(key, fromJson);

  /// Like set() but waits until the value is on disk (before exit/logout). `await ULocalStorage.setAndWait("done", true)`
  static Future<void> setAndWait(String key, Object? value, {Duration? expireTime}) => _storeFor(key).set(key, value, ttl: expireTime);

  /// Saves many values and waits until they are on disk. `await ULocalStorage.setAll({"a": 1, "b": 2})`
  static Future<void> setAll(Map<String, Object?> entries, {Duration? expireTime}) async {
    for (final MapEntry<String, Object?> e in entries.entries) {
      unawaited(_storeFor(e.key).set(e.key, e.value, ttl: expireTime));
    }
    await UStorage.flushAll();
  }

  /// Time left before [key] expires; null when it never expires.
  static Duration? ttlOf(String key) => _storeFor(key).ttlOf(key);

  /// Sets (or with null removes) the expiry of a saved key. `ULocalStorage.expire("otp", 2.minutes)`
  static Future<void> expire(String key, Duration? expireTime) => _storeFor(key).expire(key, expireTime);

  /// Adds [by] to a saved int and returns the new value. `ULocalStorage.increment("opens")`
  static int increment(String key, {int by = 1}) => _storeFor(key).increment(key, by: by);

  /// Changes a value based on its current value. `ULocalStorage.update<int>("score", (v) => (v ?? 0) + 10)`
  static Future<void> update<T>(String key, T? Function(T? current) transform) => _storeFor(key).update<T>(key, transform);

  /// Deletes several keys.
  static Future<void> removeAll(Iterable<String> keys) => Future.wait(keys.map(remove));

  /// Deletes every key that matches [test]. `ULocalStorage.removeWhere((k, v) => k.startsWith("cache_"))`
  static Future<void> removeWhere(bool Function(String key, Object value) test) => Future.wait(<Future<void>>[UStorage.instance.removeWhere(test), UStorage.secure.removeWhere(test)]);

  /// Number of saved keys.
  static int get length => UStorage.instance.length + UStorage.secure.length;

  /// True when nothing is saved.
  static bool get isEmpty => length == 0;

  /// Emits the value of [key] now and on every change. `ULocalStorage.watch<int>("cartCount").listen(updateBadge)`
  static Stream<T?> watch<T>(String key, {bool emitCurrent = true}) => _storeFor(key).watch<T>(key, emitCurrent: emitCurrent);

  /// Value of [key] for ValueListenableBuilder (rebuilds when it changes). `ValueListenableBuilder(valueListenable: ULocalStorage.listenable<int>("cartCount"), builder: (c, n, _) => Text("${n ?? 0}"))`
  static ValueListenable<T?> listenable<T>(String key) => _storeFor(key).listenable<T>(key);

  /// Every change in normal storage.
  static Stream<UStorageChange> get changes => UStorage.changes;

  /// Every change in encrypted storage.
  static Stream<UStorageChange> get secureChanges => UStorage.secure.changes;

  /// Writes pending changes to disk now (they are written automatically too).
  static Future<void> flush() => UStorage.flushAll();

  // Secure store, for any key (tokens are routed there automatically).

  /// Saves a value encrypted. `await ULocalStorage.setSecure("pin", "1234")`
  static Future<void> setSecure(String key, Object? value, {Duration? expireTime}) => UStorage.secure.set(key, value, ttl: expireTime);

  /// Reads an encrypted value. `ULocalStorage.getSecure<String>("pin")`
  static T? getSecure<T>(String key) => UStorage.secure.get<T>(key);

  /// True when [key] is saved encrypted.
  static bool containsSecure(String key) => UStorage.secure.has(key);

  /// Deletes an encrypted value.
  static Future<void> removeSecure(String key) => UStorage.secure.remove(key);

  /// Deletes every encrypted value.
  static Future<void> clearSecure() => UStorage.secure.clear();

  // Named stores: separate files, cleared or deleted independently.

  /// Opens a separate storage file you can clear on its own; [secure] encrypts it. `final UStore cache = await ULocalStorage.openStore("cache");`
  static Future<UStore> openStore(String name, {bool secure = false}) => UStorage.open(name, secure: secure);

  /// A store already opened with openStore(). `ULocalStorage.store("cache").set("k", v)`
  static UStore store(String name) => UStorage.store(name);

  /// Deletes a separate store and all its data. `ULocalStorage.deleteStore("cache")`
  static Future<void> deleteStore(String name, {bool secure = false}) => UStorage.deleteStore(name, secure: secure);
}
