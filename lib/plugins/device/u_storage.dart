import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:u/plugins/device/u_storage_legacy.dart";
import "package:u/utils/files/u_storage_backend.dart";
import "package:u/utils/files/u_vault.dart";
import "package:u/utils/u_constants.dart";

// =============================================================================
// u_storage — key/value storage for every platform. Replaces shared_preferences.
//
//   UStorage.set("name", "Sina");                       // any supported type
//   UStorage.get<String>("name");                        // sync, typed
//   UStorage.set("otp", "1234", ttl: Duration(minutes: 2));
//   UStorage.secure.set("token", jwt);                   // encrypted, key in Keychain/Keystore
//   final UStore cache = await UStorage.open("cache");   // separate, clearable store
//   UStorage.listenable<bool>("isDarkMode");             // for ValueListenableBuilder
//
// Design:
//   * Reads never touch the disk or a platform channel: every store lives in memory
//     after init, so get() is a map lookup.
//   * Writes are coalesced: any number of set() calls in the same event-loop turn
//     become one atomic file replace (write temp + rename), so a crash leaves the
//     old or the new file, never a torn one. The returned future completes when
//     the data is on disk; ignoring it is fine.
//   * Each entry is kept pre-encoded, so a flush only concatenates strings.
//   * Values keep their type across restarts: String, bool, int, double (incl. NaN),
//     DateTime, Duration, Uint8List, List<String>, JSON maps/lists, enums (by name)
//     and any object with toJson().
//   * Secure stores are sealed with ChaCha20-Poly1305 (AES-GCM on web) under a
//     master key held by the platform key store — one key-store access per launch.
//   * First launch after upgrading imports everything shared_preferences had saved,
//     moves the auth token into the secure store and deletes the old copy.
// =============================================================================

/// A change in a store. [value] is null when the key was removed, expired or cleared.
@immutable
class UStorageChange {
  const UStorageChange(this.key, this.value);

  final String key;
  final Object? value;

  @override
  String toString() => "UStorageChange($key: $value)";
}

/// Static entry point. Everything not store-specific delegates to the default store.
abstract final class UStorage {
  static const String defaultStoreName = "default";
  static const String secureStoreName = "secure";

  static final Map<String, UStore> _stores = <String, UStore>{};
  static final Map<String, Future<UStore>> _opening = <String, Future<UStore>>{};
  static Future<void>? _init;
  static AppLifecycleListener? _lifecycle;

  /// Keys that `ULocalStorage` routes to [secure] and that migration moves there.
  static Set<String> get secureKeys => <String>{UConstants.token, UConstants.refreshToken, UConstants.refreshTokenExpiresAt};

  /// Opens the default and the secure store and imports legacy shared_preferences data once.
  /// Idempotent and cheap to call again; `initU()` calls it for you.
  static Future<void> init() => _init ??= _initialize();

  static Future<void> _initialize() async {
    final bool firstRun = !await UStore._exists(defaultStoreName, secure: false);
    await Future.wait(<Future<UStore>>[open(defaultStoreName), open(secureStoreName, secure: true)]);
    if (firstRun) await _migrateLegacy();
    _lifecycle ??= AppLifecycleListener(
      onStateChange: (AppLifecycleState state) {
        if (state != AppLifecycleState.resumed) unawaited(flushAll());
      },
    );
  }

  static bool get isReady => _stores.containsKey(defaultStoreName);

  /// The default store.
  static UStore get instance => _require(defaultStoreName);

  /// Encrypted store for tokens, keys and other secrets.
  static UStore get secure => _require(secureStoreName);

  /// Opens (or returns the already open) store [name]. Each store is its own file, so it can be
  /// cleared or deleted without touching the others. Use [secure] for encrypted stores.
  static Future<UStore> open(String name, {bool secure = false}) {
    final UStore? open = _stores[name];
    if (open != null) return SynchronousFuture<UStore>(open);
    return _opening[name] ??= UStore._load(name, secure: secure).then((UStore store) {
      _stores[name] = store;
      _opening.remove(name);
      return store;
    });
  }

  /// A store already opened with [open].
  static UStore store(String name) => _require(name);

  static UStore _require(String name) {
    final UStore? store = _stores[name];
    if (store != null) return store;
    throw StateError(
      name == defaultStoreName || name == secureStoreName
          ? "UStorage is not initialized. Call `await initU()` (or `await UStorage.init()`) first."
          : "Store '$name' is not open. Call `await UStorage.open(\"$name\")` first.",
    );
  }

  /// Writes every pending change of every open store to disk.
  static Future<void> flushAll() => Future.wait(_stores.values.map((UStore s) => s.flush()));

  /// Closes store [name] and deletes its file.
  static Future<void> deleteStore(String name, {bool secure = false}) async {
    final UStore store = await open(name, secure: secure);
    await store.clear();
    await store.flush();
    _stores.remove(name);
    await store._deleteFile();
  }

  // --- default-store shortcuts ----------------------------------------------

  static T? get<T>(String key) => instance.get<T>(key);

  static T getOr<T>(String key, T fallback) => instance.getOr<T>(key, fallback);

  static Future<void> set(String key, Object? value, {Duration? ttl}) => instance.set(key, value, ttl: ttl);

  static Future<void> setAll(Map<String, Object?> entries, {Duration? ttl}) => instance.setAll(entries, ttl: ttl);

  static bool has(String key) => instance.has(key);

  static Future<void> remove(String key) => instance.remove(key);

  static Future<void> removeAll(Iterable<String> keys) => instance.removeAll(keys);

  static Future<void> clear() => instance.clear();

  static Iterable<String> get keys => instance.keys;

  static Map<String, Object> toMap() => instance.toMap();

  static int increment(String key, {int by = 1}) => instance.increment(key, by: by);

  static T? getEnum<T extends Enum>(String key, List<T> values) => instance.getEnum<T>(key, values);

  static T? getObject<T>(String key, T Function(Map<String, dynamic> json) fromJson) => instance.getObject<T>(key, fromJson);

  static List<T>? getObjects<T>(String key, T Function(Map<String, dynamic> json) fromJson) => instance.getObjects<T>(key, fromJson);

  static Duration? ttlOf(String key) => instance.ttlOf(key);

  static Stream<T?> watch<T>(String key, {bool emitCurrent = true}) => instance.watch<T>(key, emitCurrent: emitCurrent);

  static ValueListenable<T?> listenable<T>(String key) => instance.listenable<T>(key);

  static Stream<UStorageChange> get changes => instance.changes;

  // --- migration ------------------------------------------------------------

  static Future<void> _migrateLegacy() async {
    final Map<String, Object?> legacy;
    try {
      legacy = await UStorageLegacy.read();
    } catch (e) {
      debugPrint("UStorage: could not read legacy shared_preferences ($e).");
      return;
    }
    final int now = DateTime.now().millisecondsSinceEpoch;
    final Set<String> secretKeys = secureKeys;
    int moved = 0;
    for (final MapEntry<String, Object?> entry in legacy.entries) {
      final String key = entry.key;
      final Object? value = entry.value;
      if (key.startsWith("_expiry_") || value == null) continue;
      final int? expiresAt = switch (legacy["_expiry_$key"]) {
        final num n => n.toInt(),
        _ => null,
      };
      if (expiresAt != null && expiresAt <= now) continue;
      final UStore target = secretKeys.contains(key) ? secure : instance;
      try {
        target._put(key, value, expiresAt, notify: false);
        moved++;
      } catch (e) {
        debugPrint("UStorage: skipped legacy key '$key' ($e).");
      }
    }
    try {
      // Secure first: the default file doubles as the "migration done" marker, so if anything
      // fails before it exists, the next launch simply migrates again.
      await secure._writeOrThrow();
      await instance._writeOrThrow();
    } catch (e) {
      debugPrint("UStorage: migration could not be saved, will retry next launch ($e).");
      return;
    }
    if (legacy.isEmpty) return;
    // Only now that both stores are durably on disk: drop the plaintext copy (it held the token).
    try {
      await UStorageLegacy.clear();
    } catch (e) {
      debugPrint("UStorage: could not clear legacy shared_preferences ($e).");
    }
    debugPrint("UStorage: imported $moved value(s) from shared_preferences.");
  }
}

/// One key/value store. Obtain with [UStorage.instance], [UStorage.secure] or [UStorage.open].
class UStore {
  UStore._(this.name, this._path, this._aead);

  final String name;
  final String _path;
  final UAead? _aead;

  final Map<String, Object> _values = <String, Object>{};
  final Map<String, String> _encoded = <String, String>{};
  final Map<String, int> _expiry = <String, int>{};
  final StreamController<UStorageChange> _changes = StreamController<UStorageChange>.broadcast();
  final Map<String, ValueNotifier<Object?>> _notifiers = <String, ValueNotifier<Object?>>{};

  Timer? _timer;
  Completer<void>? _pending;
  Future<void>? _writing;

  bool get isSecure => _aead != null;

  // ---------------------------------------------------------------------------
  // Reading
  // ---------------------------------------------------------------------------

  /// The value of [key] as [T], or null when missing, expired or of another type.
  /// Numbers convert between int and double; JSON lists read as `List<String>` when asked.
  T? get<T>(String key) {
    final Object? value = _read(key);
    return value == null ? null : _cast<T>(key, value);
  }

  T getOr<T>(String key, T fallback) => get<T>(key) ?? fallback;

  bool has(String key) => _read(key) != null;

  /// Keys starting with "__u." belong to `u` itself (launch history, …) and are left out of
  /// [keys], [length], [toMap] and [clear], so clearing user data on logout never resets them.
  static bool isInternalKey(String key) => key.startsWith("__u.");

  Iterable<String> get keys {
    _purgeExpired();
    return List<String>.unmodifiable(_values.keys.where((String k) => !isInternalKey(k)));
  }

  int get length => keys.length;

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  /// A snapshot of every live entry.
  Map<String, Object> toMap() {
    _purgeExpired();
    return Map<String, Object>.unmodifiable(<String, Object>{
      for (final MapEntry<String, Object> e in _values.entries)
        if (!isInternalKey(e.key)) e.key: e.value,
    });
  }

  /// Enums are stored by name: `set("mode", ThemeMode.dark)` → `getEnum("mode", ThemeMode.values)`.
  T? getEnum<T extends Enum>(String key, List<T> values) {
    final String? name = get<String>(key);
    if (name == null) return null;
    for (final T value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  /// Reads an object saved with `set(key, object)` (anything with `toJson()`).
  T? getObject<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final Map<String, dynamic>? json = get<Map<String, dynamic>>(key);
    if (json == null) return null;
    try {
      return fromJson(json);
    } catch (e) {
      debugPrint("UStorage: '$key' could not be decoded as $T ($e).");
      return null;
    }
  }

  /// Reads a list of objects saved with `set(key, listOfObjects)`.
  List<T>? getObjects<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final List<dynamic>? list = get<List<dynamic>>(key);
    if (list == null) return null;
    try {
      return list.map((dynamic e) => fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))).toList();
    } catch (e) {
      debugPrint("UStorage: '$key' could not be decoded as List<$T> ($e).");
      return null;
    }
  }

  /// Time left before [key] expires; null when it has no ttl or does not exist.
  Duration? ttlOf(String key) {
    final int? at = _expiry[key];
    if (at == null || !has(key)) return null;
    return Duration(milliseconds: at - DateTime.now().millisecondsSinceEpoch);
  }

  // ---------------------------------------------------------------------------
  // Writing
  // ---------------------------------------------------------------------------

  /// Stores [value] under [key] (null removes it). With [ttl] the entry disappears once it elapses.
  /// Takes effect immediately for readers; the future completes once it is on disk.
  Future<void> set(String key, Object? value, {Duration? ttl}) {
    if (value == null) return remove(key);
    _put(key, value, ttl == null ? null : DateTime.now().add(ttl).millisecondsSinceEpoch);
    return _schedule();
  }

  /// Stores several entries with one disk write.
  Future<void> setAll(Map<String, Object?> entries, {Duration? ttl}) {
    final int? expiresAt = ttl == null ? null : DateTime.now().add(ttl).millisecondsSinceEpoch;
    for (final MapEntry<String, Object?> e in entries.entries) {
      if (e.value == null) {
        _delete(e.key);
      } else {
        _put(e.key, e.value!, expiresAt);
      }
    }
    return _schedule();
  }

  /// Sets or clears the ttl of an existing entry without rewriting its value.
  Future<void> expire(String key, Duration? ttl) {
    final Object? value = _read(key);
    if (value == null) return Future<void>.value();
    _put(key, value, ttl == null ? null : DateTime.now().add(ttl).millisecondsSinceEpoch, notify: false);
    return _schedule();
  }

  /// Adds [by] to the int under [key] (missing counts as 0) and returns the new value.
  int increment(String key, {int by = 1}) {
    final int next = (get<int>(key) ?? 0) + by;
    _put(key, next, _expiry[key]);
    unawaited(_schedule());
    return next;
  }

  /// Replaces the value of [key] with `update(current)`; returning null removes it.
  Future<void> update<T>(String key, T? Function(T? current) transform) => set(key, transform(get<T>(key)), ttl: ttlOf(key));

  Future<void> remove(String key) {
    if (!_delete(key)) return Future<void>.value();
    return _schedule();
  }

  Future<void> removeAll(Iterable<String> keys) {
    bool changed = false;
    for (final String key in keys.toList()) {
      changed = _delete(key) || changed;
    }
    return changed ? _schedule() : Future<void>.value();
  }

  /// Removes every entry for which [test] returns true.
  Future<void> removeWhere(bool Function(String key, Object value) test) =>
      removeAll(_values.entries.where((MapEntry<String, Object> e) => test(e.key, e.value)).map((MapEntry<String, Object> e) => e.key));

  /// Removes every entry except `u`'s internal "__u." keys.
  Future<void> clear() => removeAll(_values.keys.where((String k) => !isInternalKey(k)));

  // ---------------------------------------------------------------------------
  // Observing
  // ---------------------------------------------------------------------------

  /// Every change to this store, including expiries.
  Stream<UStorageChange> get changes => _changes.stream;

  /// The value of [key] now (when [emitCurrent]) and after every change.
  Stream<T?> watch<T>(String key, {bool emitCurrent = true}) async* {
    if (emitCurrent) yield get<T>(key);
    yield* _changes.stream.where((UStorageChange c) => c.key == key).map((UStorageChange c) => c.value == null ? null : _cast<T>(key, c.value!));
  }

  /// A [ValueListenable] for [key], ready for `ValueListenableBuilder`. Shared per key.
  ValueListenable<T?> listenable<T>(String key) => _UKeyListenable<T>(this, key, _notifiers.putIfAbsent(key, () => ValueNotifier<Object?>(get<Object>(key))));

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Writes pending changes now instead of at the end of the event-loop turn. Completes once
  /// everything set so far is on disk; costs nothing when there is nothing to write.
  Future<void> flush() {
    if (_pending == null) return _writing ?? Future<void>.value();
    _timer?.cancel();
    _timer = null;
    return _flushNow();
  }

  // Writes the whole store now, even when nothing changed, and reports failure to the caller
  // (normal writes only log). Used by migration, which must not delete the source on failure.
  Future<void> _writeOrThrow() async {
    _timer?.cancel();
    _timer = null;
    while (_writing != null) {
      await _writing;
    }
    final Completer<void>? pending = _pending;
    _pending = null;
    try {
      await _write();
    } finally {
      pending?.complete();
    }
  }

  Future<void> _schedule() {
    final Completer<void> pending = _pending ??= Completer<void>();
    _timer ??= Timer(Duration.zero, _flushNow);
    return pending.future;
  }

  Future<void> _flushNow() async {
    _timer = null;
    while (_writing != null) {
      await _writing;
    }
    final Completer<void>? done = _pending;
    if (done == null) return;
    _pending = null;
    final Future<void> write = _write();
    _writing = write;
    try {
      await write;
    } catch (e) {
      debugPrint("UStorage: writing store '$name' failed ($e).");
    } finally {
      _writing = null;
      done.complete();
    }
  }

  Future<void> _write() async {
    final StringBuffer out = StringBuffer('{"v":1,"d":{');
    bool first = true;
    for (final MapEntry<String, String> e in _encoded.entries) {
      if (!first) out.write(",");
      first = false;
      out
        ..write(jsonEncode(e.key))
        ..write(":")
        ..write(e.value);
    }
    out.write("}}");
    final Uint8List plain = utf8.encode(out.toString());
    await UStorageBackend.instance.writeAll(_path, _aead == null ? plain : await _seal(_aead, plain));
  }

  Future<void> _deleteFile() => UStorageBackend.instance.delete(_path);

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static Future<String> _pathOf(String name, {required bool secure}) async {
    final String safe = name.replaceAll(RegExp("[^A-Za-z0-9_.-]"), "_");
    return uJoinPath(uJoinPath(await UStorageBackend.instance.root(UStorageBucket.support), "u_store"), "$safe.${secure ? "sec" : "json"}");
  }

  static Future<bool> _exists(String name, {required bool secure}) async => UStorageBackend.instance.exists(await _pathOf(name, secure: secure));

  static Future<UStore> _load(String name, {required bool secure}) async {
    final String path = await _pathOf(name, secure: secure);
    final UAead? aead = secure ? await _masterAead() : null;
    final UStore store = UStore._(name, path, aead);
    final Uint8List? bytes = await UStorageBackend.instance.readAll(path);
    if (bytes == null || bytes.isEmpty) return store;
    try {
      final Uint8List plain = aead == null ? bytes : await _open(aead, bytes);
      store._decode(utf8.decode(plain));
    } catch (e) {
      // A corrupt file or a lost key (e.g. restored from a backup to a new device) must not
      // brick the app: keep the unreadable file aside for inspection and start empty.
      debugPrint("UStorage: store '$name' is unreadable, starting empty ($e).");
      await UStorageBackend.instance.copy(path, "$path.corrupt").catchError((Object _) {});
    }
    return store;
  }

  void _decode(String text) {
    final Object? root = jsonDecode(text);
    if (root is! Map) return;
    final Object? data = root["d"];
    if (data is! Map) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    for (final MapEntry<Object?, Object?> e in data.entries) {
      final Object? raw = e.value;
      if (raw is! List || raw.length < 2) continue;
      final int? expiresAt = raw.length > 2 && raw[2] is num ? (raw[2]! as num).toInt() : null;
      if (expiresAt != null && expiresAt <= now) continue;
      final Object? value = _UCodec.decode(raw);
      if (value == null) continue;
      final String key = "${e.key}";
      _values[key] = value;
      _encoded[key] = jsonEncode(raw);
      if (expiresAt != null) _expiry[key] = expiresAt;
    }
  }

  void _put(String key, Object value, int? expiresAt, {bool notify = true}) {
    final List<Object?> raw = _UCodec.encode(value);
    if (expiresAt != null) raw.add(expiresAt);
    final String encoded = jsonEncode(raw);
    final Object stored = _UCodec.decode(raw)!;
    _values[key] = stored;
    _encoded[key] = encoded;
    if (expiresAt == null) {
      _expiry.remove(key);
    } else {
      _expiry[key] = expiresAt;
    }
    if (notify) _emit(key, stored);
  }

  bool _delete(String key) {
    if (_values.remove(key) == null) return false;
    _encoded.remove(key);
    _expiry.remove(key);
    _emit(key, null);
    return true;
  }

  Object? _read(String key) {
    final int? at = _expiry[key];
    if (at != null && at <= DateTime.now().millisecondsSinceEpoch) {
      if (_delete(key)) unawaited(_schedule());
      return null;
    }
    return _values[key];
  }

  void _purgeExpired() {
    if (_expiry.isEmpty) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<String> expired = <String>[
      for (final MapEntry<String, int> e in _expiry.entries)
        if (e.value <= now) e.key,
    ];
    if (expired.isNotEmpty) unawaited(removeAll(expired));
  }

  void _emit(String key, Object? value) {
    if (_changes.hasListener) _changes.add(UStorageChange(key, value));
    _notifiers[key]?.value = value;
  }

  static T? _cast<T>(String key, Object value) {
    if (value is T) return value as T;
    if (value is int && 0.0 is T) return value.toDouble() as T;
    if (value is double && value.isFinite && value == value.roundToDouble() && 0 is T) return value.toInt() as T;
    if (value is List && <String>[] is T) return List<String>.unmodifiable(value.map((Object? e) => "$e")) as T;
    if (value is Map && <String, dynamic>{} is T) return Map<String, dynamic>.from(value) as T;
    debugPrint("UStorage: '$key' holds ${value.runtimeType}, not $T.");
    return null;
  }

  // --- secure envelope: "US1" | nonce(12) | ciphertext‖tag -------------------

  static const String _masterAlias = "u_store_master_v1";
  static Future<UAead>? _master;

  static Future<UAead> _masterAead() => _master ??= () async {
    final UStorageBackend backend = UStorageBackend.instance;
    Uint8List? key = await backend.loadSecret(_masterAlias);
    // No platform key store (e.g. Linux without libsecret): fall back to a private file, as the vault does.
    final String fallback = uJoinPath(uJoinPath(await backend.root(UStorageBucket.support), "u_store"), ".store.key");
    key ??= await backend.readAll(fallback);
    if (key == null || key.length != 32) {
      key = uRandomBytes(32);
      if (!await backend.storeSecret(_masterAlias, key)) await backend.writeAll(fallback, key);
    }
    return backend.aead(key);
  }();

  static const List<int> _magic = <int>[0x55, 0x53, 0x31];

  static Future<Uint8List> _seal(UAead aead, Uint8List plain) async {
    final Uint8List nonce = uRandomBytes(12);
    final Uint8List sealed = await aead.seal(nonce, plain);
    return (BytesBuilder(copy: false)
          ..add(_magic)
          ..add(nonce)
          ..add(sealed))
        .takeBytes();
  }

  static Future<Uint8List> _open(UAead aead, Uint8List bytes) async {
    if (bytes.length < 3 + 12 + 16 || bytes[0] != _magic[0] || bytes[1] != _magic[1] || bytes[2] != _magic[2]) {
      throw const FormatException("Not a secure store file.");
    }
    return aead.open(Uint8List.sublistView(bytes, 3, 15), Uint8List.sublistView(bytes, 15));
  }

  @override
  String toString() => "UStore($name${isSecure ? ", secure" : ""}, ${_values.length} keys)";
}

/// Tagged JSON encoding that keeps Dart types across restarts: `[tag, value, expiresAt?]`.
abstract final class _UCodec {
  static List<Object?> encode(Object value) {
    if (value is String) return <Object?>["s", value];
    if (value is bool) return <Object?>["b", value];
    if (value is int) return <Object?>["i", value];
    if (value is double) {
      final Object number = value.isFinite ? value : value.toString();
      return <Object?>["d", number];
    }
    if (value is DateTime) {
      final String tag = value.isUtc ? "T" : "t";
      return <Object?>[tag, value.microsecondsSinceEpoch];
    }
    if (value is Duration) return <Object?>["u", value.inMicroseconds];
    if (value is Uint8List) return <Object?>["x", base64Encode(value)];
    if (value is Enum) return <Object?>["s", value.name];
    if (value is List<String>) return <Object?>["l", List<String>.of(value)];
    if (value is Set<String>) return <Object?>["l", value.toList()];
    if (value is Map || value is List) return <Object?>["j", _json(value)];
    try {
      // Models: anything with toJson(), including lists of them handled above via jsonEncode.
      return <Object?>["j", _json((value as dynamic).toJson())];
    } on NoSuchMethodError {
      throw ArgumentError.value(value, "value", "UStorage cannot store ${value.runtimeType}; give it a toJson() or store a Map");
    }
  }

  // Round-trips through JSON so the stored copy is detached from the caller and matches what a
  // restart would read back; also rejects values JSON cannot represent up front.
  static Object? _json(Object? value) => jsonDecode(jsonEncode(value));

  static Object? decode(List<Object?> raw) {
    final Object? v = raw[1];
    switch (raw[0]) {
      case "s":
        return v is String ? v : null;
      case "b":
        return v is bool ? v : null;
      case "i":
        return v is num ? v.toInt() : null;
      case "d":
        if (v is num) return v.toDouble();
        return v is String ? double.tryParse(v) : null;
      case "t":
      case "T":
        return v is num ? DateTime.fromMicrosecondsSinceEpoch(v.toInt(), isUtc: raw[0] == "T") : null;
      case "u":
        return v is num ? Duration(microseconds: v.toInt()) : null;
      case "x":
        return v is String ? base64Decode(v) : null;
      case "l":
        return v is List ? List<String>.unmodifiable(v.map((Object? e) => "$e")) : null;
      case "j":
        return v;
    }
    return null;
  }
}

class _UKeyListenable<T> implements ValueListenable<T?> {
  _UKeyListenable(this._store, this._key, this._notifier);

  final UStore _store;
  final String _key;
  final ValueNotifier<Object?> _notifier;

  @override
  T? get value => _store.get<T>(_key);

  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _notifier.removeListener(listener);
}
