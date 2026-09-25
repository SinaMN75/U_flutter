import "package:u/utilities.dart";

// =============================================================================
// UFileStorage — keyed file storage in four buckets, on every platform.
//
//   support  persistent and private (the default)
//   cache    re-creatable; capped at [UFileStorage.cacheMaxBytes], least recently
//            used entries are evicted first, and the OS may purge it
//   vault    encrypted at rest (see u_vault.dart); decrypted only in memory
//   temp     scratch space
//
// Each bucket keeps an index (key → file, size, times, expiry, MIME type,
// checksum, tags), so lookups like [contains] and [usage] are synchronous and
// keys may contain any characters — file names are hashes of the keys.
//
// Data lives in the app's private directories: never the user's Documents
// folder, which is what the previous implementation used on desktop.
// =============================================================================

class UStorageEntry {
  UStorageEntry({
    required this.key,
    required this.bucket,
    required this.file,
    required this.size,
    required this.created,
    required this.accessed,
    this.expires,
    this.mimeType,
    this.sha256,
    this.tags = const <String, String>{},
  });

  factory UStorageEntry.fromJson(Map<String, dynamic> json, UStorageBucket bucket) => UStorageEntry(
    key: json["k"] as String,
    bucket: bucket,
    file: json["f"] as String,
    size: (json["s"] as num).toInt(),
    created: DateTime.fromMillisecondsSinceEpoch((json["c"] as num).toInt()),
    accessed: DateTime.fromMillisecondsSinceEpoch((json["a"] as num).toInt()),
    expires: json["e"] == null ? null : DateTime.fromMillisecondsSinceEpoch((json["e"] as num).toInt()),
    mimeType: json["m"] as String?,
    sha256: json["h"] as String?,
    tags: (json["t"] as Map<String, dynamic>?)?.map((String k, dynamic v) => MapEntry<String, String>(k, "$v")) ?? const <String, String>{},
  );

  final String key;
  final UStorageBucket bucket;
  final String file;
  int size;
  final DateTime created;
  DateTime accessed;
  DateTime? expires;
  String? mimeType;
  String? sha256;
  Map<String, String> tags;

  bool get isExpired => expires != null && DateTime.now().isAfter(expires!);

  bool get isEncrypted => bucket == UStorageBucket.vault;

  Map<String, dynamic> toJson() => <String, dynamic>{
    "k": key,
    "f": file,
    "s": size,
    "c": created.millisecondsSinceEpoch,
    "a": accessed.millisecondsSinceEpoch,
    if (expires != null) "e": expires!.millisecondsSinceEpoch,
    if (mimeType != null) "m": mimeType,
    if (sha256 != null) "h": sha256,
    if (tags.isNotEmpty) "t": tags,
  };
}

enum UStorageEventType { written, removed, cleared }

class UStorageEvent {
  const UStorageEvent(this.type, this.bucket, [this.key]);

  final UStorageEventType type;
  final UStorageBucket bucket;
  final String? key;
}

class _BucketIndex {
  _BucketIndex(this.bucket, this.root);

  final UStorageBucket bucket;
  final String root;
  final Map<String, UStorageEntry> entries = <String, UStorageEntry>{};
  Timer? _saveTimer;

  /// False while the index could not be read (a locked vault). Writes are refused until
  /// [UFileStorage.retryVault] succeeds, so a partial index never overwrites the real one.
  bool available = true;

  String get indexPath => uJoinPath(root, bucket == UStorageBucket.vault ? ".index.uvlt" : ".index.json");

  int get usage => entries.values.fold(0, (int sum, UStorageEntry e) => sum + e.size);
}

abstract class UFileStorage {
  static final UStorageBackend _backend = UStorageBackend.instance;
  static final Map<UStorageBucket, _BucketIndex> _indexes = <UStorageBucket, _BucketIndex>{};
  static final StreamController<UStorageEvent> _events = StreamController<UStorageEvent>.broadcast();
  static Future<void>? _ready;
  static Future<UVaultKeys>? _vaultKeys;

  /// Upper bound for the cache bucket. Least recently used entries go first.
  static int cacheMaxBytes = 256 * 1024 * 1024;

  /// Emits whenever an entry is written or removed, so storage UIs can refresh.
  static Stream<UStorageEvent> get changes => _events.stream;

  /// True when entries are real files (not IndexedDB records) that can be opened by path.
  static bool get hasFileSystem => _backend.hasFileSystem;

  static UStorageBackend get backend => _backend;

  static Future<void> init({int? cacheMaxBytes}) {
    if (cacheMaxBytes != null) UFileStorage.cacheMaxBytes = cacheMaxBytes;
    return _ready ??= _init();
  }

  static Future<void> _init() async {
    for (final UStorageBucket bucket in UStorageBucket.values) {
      final _BucketIndex index = _BucketIndex(bucket, await _backend.root(bucket));
      _indexes[bucket] = index;
      await _loadIndex(index);
    }
    await _migrateLegacy();
    await evictExpired();
    await trimCache();
  }

  // Internal calls made while init() is still migrating must not wait on init() itself.
  static Future<void> _ensure() async {
    if (_indexes.length == UStorageBucket.values.length) return;
    await (_ready ?? init());
  }

  static _BucketIndex _index(UStorageBucket bucket) {
    final _BucketIndex? index = _indexes[bucket];
    if (index == null) throw StateError("UFileStorage.init() has not completed.");
    return index;
  }

  static _BucketIndex _writable(UStorageBucket bucket) {
    final _BucketIndex index = _index(bucket);
    if (!index.available) throw StateError("The ${bucket.name} bucket is locked; call UFileStorage.retryVault().");
    return index;
  }

  /// Whether the vault could be opened. False after a key-store failure at startup.
  static bool get isVaultAvailable => _indexes[UStorageBucket.vault]?.available ?? false;

  /// Retries opening a vault that was locked at startup. Returns true once it is usable.
  static Future<bool> retryVault() async {
    await _ensure();
    final _BucketIndex index = _index(UStorageBucket.vault);
    if (index.available) return true;
    index
      ..available = true
      ..entries.clear();
    await _loadIndex(index);
    return index.available;
  }

  static Future<UVaultKeys> get vaultKeys => _vaultKeys ??= UVaultKeys.load(_backend);

  // ---------------------------------------------------------------------------
  // Index persistence
  // ---------------------------------------------------------------------------

  static Future<void> _loadIndex(_BucketIndex index) async {
    Uint8List? raw;
    try {
      if (index.bucket == UStorageBucket.vault) {
        if (await _backend.exists(index.indexPath)) {
          final BytesBuilder builder = BytesBuilder(copy: false);
          await for (final Uint8List bytes in (await vaultKeys).read(index.indexPath)) {
            builder.add(bytes);
          }
          raw = builder.takeBytes();
        }
      } else {
        raw = await _backend.readAll(index.indexPath);
      }
    } catch (e) {
      // The vault key may be temporarily unreachable (e.g. an iOS keychain before first unlock).
      // Leave the files alone: sweeping now would destroy data that is merely locked.
      debugPrint("UFileStorage: ${index.bucket.name} index unavailable ($e).");
      index.available = false;
      if (index.bucket == UStorageBucket.vault) _vaultKeys = null;
      return;
    }
    try {
      if (raw != null) {
        final Map<String, dynamic> json = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
        for (final dynamic item in (json["entries"] as List<dynamic>? ?? <dynamic>[])) {
          final UStorageEntry entry = UStorageEntry.fromJson(item as Map<String, dynamic>, index.bucket);
          index.entries[entry.key] = entry;
        }
      }
    } on FormatException {
      debugPrint("UFileStorage: ${index.bucket.name} index corrupt, rebuilding.");
    }
    await _sweepOrphans(index);
  }

  // Files with no index entry are unreachable, and entries with no file are stale.
  static Future<void> _sweepOrphans(_BucketIndex index) async {
    final List<String> names = await _backend.list(index.root);
    final Set<String> present = names.toSet();
    final Set<String> known = index.entries.values.map((UStorageEntry e) => e.file).toSet();
    for (final String name in names) {
      if ((name.endsWith(".bin") && !known.contains(name)) || name.endsWith(".tmp")) await _backend.delete(uJoinPath(index.root, name));
    }
    final int before = index.entries.length;
    index.entries.removeWhere((String _, UStorageEntry e) => !present.contains(e.file));
    if (index.entries.length != before) _scheduleSave(index);
  }

  static void _scheduleSave(_BucketIndex index, {Duration delay = const Duration(milliseconds: 400)}) {
    index._saveTimer?.cancel();
    index._saveTimer = Timer(delay, () => unawaited(_saveIndex(index)));
  }

  static Future<void> _saveIndex(_BucketIndex index) async {
    index._saveTimer?.cancel();
    index._saveTimer = null;
    if (!index.available) return;
    try {
      await _writeIndex(index);
    } catch (e) {
      debugPrint("UFileStorage: could not save the ${index.bucket.name} index ($e).");
    }
  }

  static Future<void> _writeIndex(_BucketIndex index) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonEncode(<String, dynamic>{
      "v": 1,
      "entries": index.entries.values.map((UStorageEntry e) => e.toJson()).toList(),
    })));
    if (index.bucket == UStorageBucket.vault) {
      final String staging = "${index.indexPath}.tmp";
      final UVaultWriter writer = await (await vaultKeys).create(staging);
      await writer.writeAt(0, bytes);
      await writer.finish(bytes.length);
      await writer.close();
      await _backend.move(staging, index.indexPath);
    } else {
      await _backend.writeAll(index.indexPath, bytes);
    }
  }

  /// Writes any pending index changes now. Call before the app is terminated if you have
  /// written in the last half second.
  static Future<void> flush() async {
    for (final _BucketIndex index in _indexes.values) {
      if (index._saveTimer != null) await _saveIndex(index);
    }
  }

  // ---------------------------------------------------------------------------
  // Keys & lookups
  // ---------------------------------------------------------------------------

  static String _fileName(String key) => "${UHasher.hex(UHashAlgorithm.sha256, utf8.encode(key)).substring(0, 40)}.bin";

  static String _pathFor(UStorageBucket bucket, String key) => uJoinPath(_index(bucket).root, _fileName(key));

  static UStorageEntry? _live(String key, UStorageBucket bucket) {
    final UStorageEntry? entry = _indexes[bucket]?.entries[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      unawaited(remove(key, bucket: bucket));
      return null;
    }
    return entry;
  }

  static void _touch(UStorageEntry entry) {
    entry.accessed = DateTime.now();
    _scheduleSave(_index(entry.bucket), delay: const Duration(seconds: 2));
  }

  static bool contains(String key, {UStorageBucket bucket = UStorageBucket.support}) => _live(key, bucket) != null;

  static UStorageEntry? entry(String key, {UStorageBucket bucket = UStorageBucket.support}) => _live(key, bucket);

  static List<UStorageEntry> entries({UStorageBucket? bucket}) => <UStorageEntry>[
    for (final _BucketIndex index in _indexes.values)
      if (bucket == null || index.bucket == bucket) ...index.entries.values.where((UStorageEntry e) => !e.isExpired),
  ];

  static List<String> keys({UStorageBucket bucket = UStorageBucket.support}) => entries(bucket: bucket).map((UStorageEntry e) => e.key).toList(growable: false);

  static int size(String key, {UStorageBucket bucket = UStorageBucket.support}) => _live(key, bucket)?.size ?? 0;

  /// Bytes used by one bucket, or by all of them.
  static int usage({UStorageBucket? bucket}) =>
      _indexes.values.where((_BucketIndex i) => bucket == null || i.bucket == bucket).fold(0, (int sum, _BucketIndex i) => sum + i.usage);

  /// The file behind [key] when it can be opened directly (native, non-vault). Useful for
  /// players and share sheets. Vault entries never expose a plaintext path.
  static String? pathOf(String key, {UStorageBucket bucket = UStorageBucket.support}) {
    if (!_backend.hasFileSystem || bucket == UStorageBucket.vault) return null;
    final UStorageEntry? entry = _live(key, bucket);
    return entry == null ? null : uJoinPath(_index(bucket).root, entry.file);
  }

  /// Where [key]'s bytes live inside [backend] — the ciphertext for vault entries, an IndexedDB
  /// key on the web. For diagnostics and tests; read entries through [getBytes] / [read].
  static String? storedPath(String key, {UStorageBucket bucket = UStorageBucket.support}) => _live(key, bucket) == null ? null : _pathFor(bucket, key);

  // ---------------------------------------------------------------------------
  // Writing
  // ---------------------------------------------------------------------------

  static Future<void> setBytes(
    String key,
    List<int> bytes, {
    UStorageBucket bucket = UStorageBucket.support,
    Duration? expireIn,
    String? mimeType,
    Map<String, String>? tags,
  }) async {
    await _ensure();
    _writable(bucket);
    final String path = _pathFor(bucket, key);
    if (bucket == UStorageBucket.vault) {
      final String staging = "$path.tmp";
      final UVaultWriter writer = await (await vaultKeys).create(staging);
      await writer.writeAt(0, bytes);
      await writer.finish(bytes.length);
      await writer.close();
      await _backend.move(staging, path);
    } else {
      await _backend.writeAll(path, bytes);
    }
    await _record(key, bucket, bytes.length, expireIn: expireIn, mimeType: mimeType, tags: tags);
  }

  /// Streams [data] into [key] without holding it in memory. Replaces the entry atomically.
  static Future<int> write(
    String key,
    Stream<List<int>> data, {
    UStorageBucket bucket = UStorageBucket.support,
    Duration? expireIn,
    String? mimeType,
    Map<String, String>? tags,
    UHashAlgorithm? hash,
  }) async {
    await _ensure();
    _writable(bucket);
    final String path = _pathFor(bucket, key);
    final String staging = "$path.${DateTime.now().microsecondsSinceEpoch}.tmp";
    final UStorageSink sink = bucket == UStorageBucket.vault ? await (await vaultKeys).create(staging) : await _backend.open(staging, truncate: true);
    final UHasher? hasher = hash == null ? null : UHasher(hash);
    int length = 0;
    try {
      await for (final List<int> chunk in data) {
        hasher?.add(chunk);
        await sink.writeAt(length, chunk);
        length += chunk.length;
      }
      if (sink is UVaultWriter) await sink.finish(length);
      await sink.close();
      await _backend.move(staging, path);
    } catch (_) {
      await sink.close();
      await _backend.delete(staging);
      rethrow;
    }
    await _record(key, bucket, length, expireIn: expireIn, mimeType: mimeType, tags: tags, sha256: hash == UHashAlgorithm.sha256 ? hasher?.closeHex() : null);
    return length;
  }

  /// Takes ownership of a file that is already in [bucket]'s format — plain bytes, or a vault
  /// file for the vault bucket — and files it under [key]. The download manager finishes
  /// downloads this way so they are never copied twice.
  static Future<void> adopt(
    String sourcePath,
    String key, {
    required int size,
    UStorageBucket bucket = UStorageBucket.support,
    Duration? expireIn,
    String? mimeType,
    String? sha256,
    Map<String, String>? tags,
  }) async {
    await _ensure();
    await _backend.move(sourcePath, _pathFor(bucket, key));
    await _record(key, bucket, size, expireIn: expireIn, mimeType: mimeType, sha256: sha256, tags: tags);
  }

  /// Copies (or moves) a file from anywhere on disk into storage. Encrypts it for the vault.
  static Future<void> importFile(
    String sourcePath,
    String key, {
    UStorageBucket bucket = UStorageBucket.support,
    bool deleteSource = false,
    String? mimeType,
    Map<String, String>? tags,
  }) async {
    if (!_backend.hasFileSystem) throw UnsupportedError("importFile needs a file system; use write() on the web.");
    await _ensure();
    if (bucket == UStorageBucket.vault) {
      await write(key, _backend.read(sourcePath), bucket: bucket, mimeType: mimeType, tags: tags);
      if (deleteSource) await _backend.delete(sourcePath);
      return;
    }
    final String path = _pathFor(bucket, key);
    if (deleteSource) {
      await _backend.move(sourcePath, path);
    } else {
      await _backend.copy(sourcePath, path);
    }
    await _record(key, bucket, await _backend.length(path) ?? 0, mimeType: mimeType, tags: tags);
  }

  /// Writes a plaintext copy of [key] to [destinationPath] (decrypting vault entries).
  static Future<bool> exportFile(String key, String destinationPath, {UStorageBucket bucket = UStorageBucket.support}) async {
    if (!_backend.hasFileSystem) throw UnsupportedError("exportFile needs a file system.");
    await _ensure();
    if (_live(key, bucket) == null) return false;
    if (bucket == UStorageBucket.vault) {
      final UStorageSink sink = await _backend.open(destinationPath, truncate: true);
      int position = 0;
      try {
        await for (final Uint8List chunk in read(key, bucket: bucket)) {
          await sink.writeAt(position, chunk);
          position += chunk.length;
        }
      } finally {
        await sink.close();
      }
    } else {
      await _backend.copy(_pathFor(bucket, key), destinationPath);
    }
    return true;
  }

  static Future<void> _record(
    String key,
    UStorageBucket bucket,
    int size, {
    Duration? expireIn,
    String? mimeType,
    String? sha256,
    Map<String, String>? tags,
  }) async {
    final _BucketIndex index = _writable(bucket);
    final DateTime now = DateTime.now();
    final UStorageEntry? previous = index.entries[key];
    index.entries[key] = UStorageEntry(
      key: key,
      bucket: bucket,
      file: _fileName(key),
      size: size,
      created: previous?.created ?? now,
      accessed: now,
      expires: expireIn == null ? null : now.add(expireIn),
      mimeType: mimeType ?? previous?.mimeType,
      sha256: sha256,
      tags: tags ?? previous?.tags ?? const <String, String>{},
    );
    _scheduleSave(index);
    _events.add(UStorageEvent(UStorageEventType.written, bucket, key));
    if (bucket == UStorageBucket.cache) await trimCache();
  }

  static Future<void> setString(String key, String value, {UStorageBucket bucket = UStorageBucket.support, Duration? expireIn}) =>
      setBytes(key, utf8.encode(value), bucket: bucket, expireIn: expireIn, mimeType: "text/plain; charset=utf-8");

  static Future<void> setJson(String key, Object? value, {UStorageBucket bucket = UStorageBucket.support, Duration? expireIn}) =>
      setBytes(key, utf8.encode(jsonEncode(value)), bucket: bucket, expireIn: expireIn, mimeType: "application/json");

  /// Updates expiry, MIME type or tags without rewriting the data.
  static Future<void> update(String key, {UStorageBucket bucket = UStorageBucket.support, Duration? expireIn, String? mimeType, Map<String, String>? tags}) async {
    await _ensure();
    final UStorageEntry? entry = _live(key, bucket);
    if (entry == null) return;
    if (expireIn != null) entry.expires = DateTime.now().add(expireIn);
    if (mimeType != null) entry.mimeType = mimeType;
    if (tags != null) entry.tags = tags;
    _scheduleSave(_index(bucket));
  }

  // ---------------------------------------------------------------------------
  // Reading
  // ---------------------------------------------------------------------------

  static Future<Uint8List?> getBytes(String key, {UStorageBucket bucket = UStorageBucket.support}) async {
    await _ensure();
    final UStorageEntry? entry = _live(key, bucket);
    if (entry == null) return null;
    _touch(entry);
    try {
      if (bucket != UStorageBucket.vault) return await _backend.readAll(_pathFor(bucket, key));
      final BytesBuilder builder = BytesBuilder(copy: false);
      await for (final Uint8List chunk in read(key, bucket: bucket)) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } on UAuthenticationException {
      debugPrint("UFileStorage: vault entry failed authentication and was removed.");
      await remove(key, bucket: bucket);
      return null;
    }
  }

  /// Streams `[start, end)` of an entry. Vault entries decrypt only the chunks in range,
  /// which is what lets encrypted video seek.
  static Stream<Uint8List> read(String key, {UStorageBucket bucket = UStorageBucket.support, int start = 0, int? end}) async* {
    await _ensure();
    final UStorageEntry? entry = _live(key, bucket);
    if (entry == null) throw StateError("No entry '$key' in ${bucket.name}.");
    _touch(entry);
    final String path = _pathFor(bucket, key);
    yield* bucket == UStorageBucket.vault ? (await vaultKeys).read(path, start: start, end: end) : _backend.read(path, start: start, end: end);
  }

  static Future<String?> getString(String key, {UStorageBucket bucket = UStorageBucket.support}) async {
    final Uint8List? bytes = await getBytes(key, bucket: bucket);
    return bytes == null ? null : utf8.decode(bytes, allowMalformed: true);
  }

  static Future<dynamic> getJson(String key, {UStorageBucket bucket = UStorageBucket.support}) async {
    final String? text = await getString(key, bucket: bucket);
    if (text == null) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  /// Re-checks integrity: every AEAD tag for vault entries, or the stored SHA-256 otherwise.
  static Future<bool> verify(String key, {UStorageBucket bucket = UStorageBucket.support}) async {
    await _ensure();
    final UStorageEntry? entry = _live(key, bucket);
    if (entry == null) return false;
    if (bucket == UStorageBucket.vault) return (await vaultKeys).verify(_pathFor(bucket, key));
    if (entry.sha256 == null) return true;
    final UHasher hasher = UHasher(UHashAlgorithm.sha256);
    await for (final Uint8List chunk in _backend.read(_pathFor(bucket, key))) {
      hasher.add(chunk);
    }
    return hasher.closeHex() == entry.sha256;
  }

  // ---------------------------------------------------------------------------
  // Removing
  // ---------------------------------------------------------------------------

  static Future<void> remove(String key, {UStorageBucket bucket = UStorageBucket.support}) async {
    await _ensure();
    final _BucketIndex index = _writable(bucket);
    if (index.entries.remove(key) == null) return;
    await _backend.delete(_pathFor(bucket, key));
    _scheduleSave(index);
    _events.add(UStorageEvent(UStorageEventType.removed, bucket, key));
  }

  /// Clears one bucket, or every bucket when [bucket] is null. Partial downloads survive
  /// unless [includeDownloads] is true.
  static Future<void> clear({UStorageBucket? bucket, bool includeDownloads = false}) async {
    await _ensure();
    for (final _BucketIndex index in _indexes.values) {
      if ((bucket != null && index.bucket != bucket) || !index.available) continue;
      for (final UStorageEntry entry in index.entries.values.toList()) {
        await _backend.delete(uJoinPath(index.root, entry.file));
      }
      index.entries.clear();
      if (includeDownloads) await _backend.deleteDirectory(uJoinPath(index.root, "parts"));
      await _saveIndex(index);
      _events.add(UStorageEvent(UStorageEventType.cleared, index.bucket));
    }
  }

  static Future<void> copy(String from, String to, {UStorageBucket bucket = UStorageBucket.support, UStorageBucket? toBucket}) async {
    await _ensure();
    final UStorageEntry? source = _live(from, bucket);
    if (source == null) return;
    final UStorageBucket target = toBucket ?? bucket;
    if (target == bucket) {
      await _backend.copy(_pathFor(bucket, from), _pathFor(target, to));
      await _record(to, target, source.size, mimeType: source.mimeType, sha256: source.sha256, tags: source.tags);
    } else {
      await write(to, read(from, bucket: bucket), bucket: target, mimeType: source.mimeType, tags: source.tags);
    }
  }

  static Future<void> move(String from, String to, {UStorageBucket bucket = UStorageBucket.support, UStorageBucket? toBucket}) async {
    await copy(from, to, bucket: bucket, toBucket: toBucket);
    await remove(from, bucket: bucket);
  }

  static Future<void> evictExpired() async {
    for (final _BucketIndex index in _indexes.values) {
      for (final UStorageEntry entry in index.entries.values.where((UStorageEntry e) => e.isExpired).toList()) {
        await remove(entry.key, bucket: index.bucket);
      }
    }
  }

  /// Evicts least-recently-used cache entries until the cache fits [cacheMaxBytes].
  static Future<void> trimCache() async {
    final _BucketIndex? index = _indexes[UStorageBucket.cache];
    if (index == null || index.usage <= cacheMaxBytes) return;
    final List<UStorageEntry> byAge = index.entries.values.toList()..sort((UStorageEntry a, UStorageEntry b) => a.accessed.compareTo(b.accessed));
    int usage = index.usage;
    for (final UStorageEntry entry in byAge) {
      if (usage <= cacheMaxBytes) break;
      usage -= entry.size;
      await remove(entry.key, bucket: UStorageBucket.cache);
    }
  }

  /// Directory for partial downloads that must survive restarts (inside [bucket]).
  static Future<String> partsDirectory(UStorageBucket bucket) async {
    await _ensure();
    return uJoinPath(_index(bucket).root, "parts");
  }

  // ---------------------------------------------------------------------------
  // One-time migration from the 2.x layout (Documents/big_files/*.dat, Documents/*.txt)
  // ---------------------------------------------------------------------------

  static Future<void> _migrateLegacy() async {
    if (kIsWeb) return;
    final String marker = uJoinPath(_index(UStorageBucket.support).root, ".migrated_v3");
    if (await _backend.exists(marker)) return;
    try {
      final Directory documents = await getApplicationDocumentsDirectory();
      final Directory big = Directory(uJoinPath(documents.path, "big_files"));
      if (big.existsSync()) {
        for (final File file in big.listSync().whereType<File>().where((File f) => f.path.endsWith(".dat"))) {
          final String name = file.uri.pathSegments.last;
          final String key = name.substring(0, name.length - 4);
          await importFile(file.path, key, bucket: _legacyBucket(key), deleteSource: true);
        }
        if (big.listSync().isEmpty) await big.delete();
      }
      // Only where Documents is private to the app. On desktop it is the user's own folder,
      // and a .txt there is far more likely to be theirs than ours.
      final bool privateDocuments = Platform.isAndroid || Platform.isIOS || (Platform.isMacOS && documents.path.contains("/Library/Containers/"));
      if (privateDocuments) {
        for (final File file in documents.listSync().whereType<File>().where((File f) => f.path.endsWith(".txt"))) {
          final String name = file.uri.pathSegments.last;
          final String key = name.substring(0, name.length - 4);
          await importFile(file.path, key, bucket: _legacyBucket(key), deleteSource: true, mimeType: "text/plain; charset=utf-8");
        }
      }
    } catch (e) {
      debugPrint("UFileStorage: legacy migration skipped ($e).");
    }
    await _backend.writeAll(marker, <int>[1]);
  }

  static UStorageBucket _legacyBucket(String key) => key.startsWith("img_") || key.startsWith("cache_") ? UStorageBucket.cache : UStorageBucket.support;

  // ---------------------------------------------------------------------------
  // 2.x names, kept so existing apps compile. Each maps onto the support bucket.
  // ---------------------------------------------------------------------------

  @Deprecated("Use setString")
  static Future<void> set(String key, String value) => setString(key, value);

  @Deprecated("Use keys()")
  static Future<List<String>> getKeys() async => keys();

  @Deprecated("Use contains()")
  static bool fileExists(String key) => contains(key);

  @Deprecated("Use size()")
  static Future<int> fileSize(String key) async => size(key);

  @Deprecated("Use usage()")
  static int totalStorageUsed() => usage();

  @Deprecated("Use entries()")
  static Map<String, int> allFilesStorageInfo() => <String, int>{for (final UStorageEntry e in entries(bucket: UStorageBucket.support)) e.key: e.size};

  @Deprecated("Use copy()")
  static Future<void> copyFile(String sourceKey, String destinationKey) => copy(sourceKey, destinationKey);
}
