import "dart:async";
import "dart:js_interop";
import "dart:js_interop_unsafe";
import "dart:typed_data";

import "package:u/utils/files/u_crypto_stream.dart";
import "package:u/utils/files/u_storage_backend.dart";
import "package:web/web.dart" as web;

// IndexedDB layout (database "u_storage", version 1):
//   files   : path            → {length, modified}
//   chunks  : [path, offset]  → Uint8Array
//   secrets : alias           → {iv, data}  (plus "__kek", a non-extractable AES-GCM CryptoKey)
//
// Records are keyed by their start offset, so a writer may fill any non-overlapping
// ranges in any order — exactly what segmented downloads and vault chunks do.

UStorageBackend createStorageBackend() => _WebStorageBackend();

const String _files = "files";
const String _chunks = "chunks";
const String _secrets = "secrets";

Future<JSAny?> _await(web.IDBRequest request) {
  final Completer<JSAny?> completer = Completer<JSAny?>();
  request
    ..onsuccess = ((web.Event _) => completer.complete(request.result)).toJS
    ..onerror = ((web.Event _) => completer.completeError(StateError("IndexedDB: ${request.error?.message ?? "request failed"}"))).toJS;
  return completer.future;
}

Future<void> _done(web.IDBTransaction tx) {
  final Completer<void> completer = Completer<void>();
  tx
    ..oncomplete = ((web.Event _) => completer.complete()).toJS
    ..onerror = ((web.Event _) => completer.completeError(StateError("IndexedDB: ${tx.error?.message ?? "transaction failed"}"))).toJS
    ..onabort = ((web.Event _) {
      if (!completer.isCompleted) completer.completeError(StateError("IndexedDB: transaction aborted"));
    }).toJS;
  return completer.future;
}

JSAny _chunkKey(String path, int offset) => <JSAny>[path.toJS, offset.toJS].toJS;

web.IDBKeyRange _chunkRange(String path) => web.IDBKeyRange.bound(_chunkKey(path, 0), _chunkKey(path, 9007199254740991));

class _WebStorageBackend implements UStorageBackend {
  Future<web.IDBDatabase>? _db;

  Future<web.IDBDatabase> get _database => _db ??= _open();

  Future<web.IDBDatabase> _open() {
    final Completer<web.IDBDatabase> completer = Completer<web.IDBDatabase>();
    final web.IDBOpenDBRequest request = web.window.indexedDB.open("u_storage", 1);
    request
      ..onupgradeneeded = ((web.Event _) {
        final web.IDBDatabase db = request.result! as web.IDBDatabase;
        final List<String> existing = <String>[for (int i = 0; i < db.objectStoreNames.length; i++) db.objectStoreNames.item(i)!];
        for (final String store in <String>[_files, _chunks, _secrets]) {
          if (!existing.contains(store)) db.createObjectStore(store);
        }
      }).toJS
      ..onsuccess = ((web.Event _) => completer.complete(request.result! as web.IDBDatabase)).toJS
      ..onerror = ((web.Event _) => completer.completeError(StateError("IndexedDB unavailable: ${request.error?.message}"))).toJS;
    return completer.future;
  }

  Future<web.IDBTransaction> _tx(List<String> stores, {bool write = false}) async =>
      (await _database).transaction(stores.map((String s) => s.toJS).toList().toJS, write ? "readwrite" : "readonly");

  @override
  bool get hasFileSystem => false;

  @override
  Future<String> root(UStorageBucket bucket) async => "/u_storage/${bucket.name}";

  Future<({int length, int modified})?> _meta(String path) async {
    final web.IDBTransaction tx = await _tx(<String>[_files]);
    final JSAny? raw = await _await(tx.objectStore(_files).get(path.toJS));
    if (raw == null) return null;
    final JSObject o = raw as JSObject;
    return (length: (o["length"]! as JSNumber).toDartInt, modified: (o["modified"]! as JSNumber).toDartInt);
  }

  JSObject _metaValue(int length) => JSObject()
    ..["length"] = length.toJS
    ..["modified"] = DateTime.now().millisecondsSinceEpoch.toJS;

  Future<List<int>> _offsets(String path) async {
    final web.IDBTransaction tx = await _tx(<String>[_chunks]);
    final JSArray<JSAny?> keys = (await _await(tx.objectStore(_chunks).getAllKeys(_chunkRange(path))))! as JSArray<JSAny?>;
    return keys.toDart.map((JSAny? k) => ((k! as JSArray<JSAny?>).toDart[1]! as JSNumber).toDartInt).toList()..sort();
  }

  Future<Uint8List?> _chunk(String path, int offset) async {
    final web.IDBTransaction tx = await _tx(<String>[_chunks]);
    final JSAny? raw = await _await(tx.objectStore(_chunks).get(_chunkKey(path, offset)));
    return raw == null ? null : (raw as JSUint8Array).toDart;
  }

  @override
  Future<bool> exists(String path) async => await _meta(path) != null;

  @override
  Future<int?> length(String path) async => (await _meta(path))?.length;

  @override
  Future<DateTime?> modified(String path) async {
    final ({int length, int modified})? meta = await _meta(path);
    return meta == null ? null : DateTime.fromMillisecondsSinceEpoch(meta.modified);
  }

  @override
  Future<Uint8List?> readAll(String path) async {
    final ({int length, int modified})? meta = await _meta(path);
    if (meta == null) return null;
    final web.IDBTransaction tx = await _tx(<String>[_chunks]);
    final web.IDBObjectStore store = tx.objectStore(_chunks);
    final Future<JSAny?> keysFuture = _await(store.getAllKeys(_chunkRange(path)));
    final Future<JSAny?> valuesFuture = _await(store.getAll(_chunkRange(path)));
    final List<JSAny?> keys = ((await keysFuture)! as JSArray<JSAny?>).toDart;
    final List<JSAny?> values = ((await valuesFuture)! as JSArray<JSAny?>).toDart;
    final Uint8List out = Uint8List(meta.length);
    for (int i = 0; i < keys.length; i++) {
      final int offset = ((keys[i]! as JSArray<JSAny?>).toDart[1]! as JSNumber).toDartInt;
      final Uint8List bytes = (values[i]! as JSUint8Array).toDart;
      if (offset >= meta.length) continue;
      final int n = offset + bytes.length > meta.length ? meta.length - offset : bytes.length;
      out.setRange(offset, offset + n, bytes);
    }
    return out;
  }

  @override
  Stream<Uint8List> read(String path, {int start = 0, int? end}) async* {
    final ({int length, int modified})? meta = await _meta(path);
    if (meta == null) throw StateError("No such file: $path");
    final int stop = end == null || end > meta.length ? meta.length : end;
    final List<int> offsets = await _offsets(path);
    for (int i = 0; i < offsets.length; i++) {
      final int offset = offsets[i];
      final int next = i + 1 < offsets.length ? offsets[i + 1] : meta.length;
      if (next <= start) continue;
      if (offset >= stop) break;
      final Uint8List? bytes = await _chunk(path, offset);
      if (bytes == null) continue;
      final int from = start > offset ? start - offset : 0;
      final int to = (stop - offset) < bytes.length ? stop - offset : bytes.length;
      if (to > from) yield Uint8List.sublistView(bytes, from, to);
    }
  }

  @override
  Future<void> writeAll(String path, List<int> bytes) async {
    // A single transaction replaces every record, which is atomic in IndexedDB.
    final web.IDBTransaction tx = await _tx(<String>[_files, _chunks], write: true);
    final Future<void> done = _done(tx);
    tx.objectStore(_chunks).delete(_chunkRange(path));
    tx.objectStore(_chunks).put(Uint8List.fromList(bytes).toJS, _chunkKey(path, 0));
    tx.objectStore(_files).put(_metaValue(bytes.length), path.toJS);
    await done;
  }

  @override
  Future<UStorageSink> open(String path, {bool truncate = false}) async {
    final ({int length, int modified})? meta = await _meta(path);
    if (meta == null || truncate) {
      final web.IDBTransaction tx = await _tx(<String>[_files, _chunks], write: true);
      final Future<void> done = _done(tx);
      tx.objectStore(_chunks).delete(_chunkRange(path));
      tx.objectStore(_files).put(_metaValue(0), path.toJS);
      await done;
    }
    return _WebSink(this, path, truncate ? 0 : (meta?.length ?? 0));
  }

  Future<void> _put(String path, int offset, Uint8List bytes, int newLength) async {
    final web.IDBTransaction tx = await _tx(<String>[_files, _chunks], write: true);
    final Future<void> done = _done(tx);
    tx.objectStore(_chunks).put(bytes.toJS, _chunkKey(path, offset));
    tx.objectStore(_files).put(_metaValue(newLength), path.toJS);
    await done;
  }

  Future<void> _truncate(String path, int length) async {
    final List<int> offsets = await _offsets(path);
    for (final int offset in offsets) {
      if (offset >= length) {
        final web.IDBTransaction tx = await _tx(<String>[_chunks], write: true);
        final Future<void> done = _done(tx);
        tx.objectStore(_chunks).delete(_chunkKey(path, offset));
        await done;
      } else {
        final Uint8List? bytes = await _chunk(path, offset);
        if (bytes != null && offset + bytes.length > length) await _put(path, offset, Uint8List.fromList(bytes.sublist(0, length - offset)), length);
      }
    }
    final web.IDBTransaction tx = await _tx(<String>[_files], write: true);
    final Future<void> done = _done(tx);
    tx.objectStore(_files).put(_metaValue(length), path.toJS);
    await done;
  }

  @override
  Future<void> delete(String path) async {
    final web.IDBTransaction tx = await _tx(<String>[_files, _chunks], write: true);
    final Future<void> done = _done(tx);
    tx.objectStore(_chunks).delete(_chunkRange(path));
    tx.objectStore(_files).delete(path.toJS);
    await done;
  }

  @override
  Future<void> move(String from, String to) async {
    await copy(from, to);
    await delete(from);
  }

  @override
  Future<void> copy(String from, String to) async {
    final ({int length, int modified})? meta = await _meta(from);
    if (meta == null) throw StateError("No such file: $from");
    await open(to, truncate: true);
    for (final int offset in await _offsets(from)) {
      final Uint8List? bytes = await _chunk(from, offset);
      if (bytes != null) await _put(to, offset, bytes, meta.length);
    }
  }

  @override
  Future<List<String>> list(String directory) async {
    final String prefix = directory.endsWith("/") ? directory : "$directory/";
    final web.IDBTransaction tx = await _tx(<String>[_files]);
    final JSArray<JSAny?> keys = (await _await(tx.objectStore(_files).getAllKeys(web.IDBKeyRange.bound(prefix.toJS, "$prefix￿".toJS))))! as JSArray<JSAny?>;
    return keys.toDart.map((JSAny? k) => (k! as JSString).toDart.substring(prefix.length)).where((String name) => !name.contains("/")).toList(growable: false);
  }

  @override
  Future<void> deleteDirectory(String directory) async {
    final String prefix = directory.endsWith("/") ? directory : "$directory/";
    final web.IDBTransaction tx = await _tx(<String>[_files]);
    final JSArray<JSAny?> keys = (await _await(tx.objectStore(_files).getAllKeys(web.IDBKeyRange.bound(prefix.toJS, "$prefix￿".toJS))))! as JSArray<JSAny?>;
    for (final JSAny? key in keys.toDart) {
      await delete((key! as JSString).toDart);
    }
  }

  @override
  Future<int?> freeSpace(String path) async {
    try {
      final web.StorageEstimate estimate = await web.window.navigator.storage.estimate().toDart;
      return estimate.quota - estimate.usage;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Secrets: wrapped with a non-extractable AES-GCM key that page script can use
  // but never read out, so a dump of IndexedDB alone does not reveal them.
  // ---------------------------------------------------------------------------

  Future<web.CryptoKey> _kek() async {
    final web.IDBTransaction tx = await _tx(<String>[_secrets]);
    final JSAny? existing = await _await(tx.objectStore(_secrets).get("__kek".toJS));
    if (existing != null) return existing as web.CryptoKey;
    final JSObject algorithm = JSObject()
      ..["name"] = "AES-GCM".toJS
      ..["length"] = 256.toJS;
    final web.CryptoKey key = (await web.window.crypto.subtle.generateKey(algorithm, false, <JSString>["encrypt".toJS, "decrypt".toJS].toJS).toDart)! as web.CryptoKey;
    final web.IDBTransaction write = await _tx(<String>[_secrets], write: true);
    final Future<void> done = _done(write);
    write.objectStore(_secrets).put(key, "__kek".toJS);
    await done;
    return key;
  }

  @override
  Future<bool> storeSecret(String alias, Uint8List secret) async {
    try {
      final web.CryptoKey kek = await _kek();
      final Uint8List iv = Uint8List(12);
      web.window.crypto.getRandomValues(iv.toJS);
      final JSObject params = JSObject()
        ..["name"] = "AES-GCM".toJS
        ..["iv"] = iv.toJS;
      final JSArrayBuffer data = (await web.window.crypto.subtle.encrypt(params, kek, secret.toJS).toDart)! as JSArrayBuffer;
      final JSObject record = JSObject()
        ..["iv"] = iv.toJS
        ..["data"] = data;
      final web.IDBTransaction tx = await _tx(<String>[_secrets], write: true);
      final Future<void> done = _done(tx);
      tx.objectStore(_secrets).put(record, alias.toJS);
      await done;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Uint8List?> loadSecret(String alias) async {
    try {
      final web.IDBTransaction tx = await _tx(<String>[_secrets]);
      final JSAny? raw = await _await(tx.objectStore(_secrets).get(alias.toJS));
      if (raw == null) return null;
      final JSObject record = raw as JSObject;
      final JSObject params = JSObject()
        ..["name"] = "AES-GCM".toJS
        ..["iv"] = record["iv"];
      final JSArrayBuffer plain = (await web.window.crypto.subtle.decrypt(params, await _kek(), record["data"]! as JSArrayBuffer).toDart)! as JSArrayBuffer;
      return plain.toDart.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UAead> aead(Uint8List key) => _WebCryptoAead.create(key);

  @override
  Future<void> deleteSecret(String alias) async {
    final web.IDBTransaction tx = await _tx(<String>[_secrets], write: true);
    final Future<void> done = _done(tx);
    tx.objectStore(_secrets).delete(alias.toJS);
    await done;
  }
}

class _WebCryptoAead implements UAead {
  _WebCryptoAead(this._key);

  final web.CryptoKey _key;

  static Future<_WebCryptoAead> create(Uint8List raw) async {
    final JSObject algorithm = JSObject()..["name"] = "AES-GCM".toJS;
    final web.CryptoKey key = await web.window.crypto.subtle.importKey("raw", raw.toJS, algorithm, false, <JSString>["encrypt".toJS, "decrypt".toJS].toJS).toDart;
    return _WebCryptoAead(key);
  }

  JSObject _params(Uint8List nonce) => JSObject()
    ..["name"] = "AES-GCM".toJS
    ..["iv"] = nonce.toJS;

  @override
  int get algorithmId => 2;

  @override
  Future<Uint8List> seal(Uint8List nonce, Uint8List plain) async =>
      ((await web.window.crypto.subtle.encrypt(_params(nonce), _key, plain.toJS).toDart)! as JSArrayBuffer).toDart.asUint8List();

  @override
  Future<Uint8List> open(Uint8List nonce, Uint8List sealed) async {
    try {
      return ((await web.window.crypto.subtle.decrypt(_params(nonce), _key, sealed.toJS).toDart)! as JSArrayBuffer).toDart.asUint8List();
    } catch (_) {
      throw const UAuthenticationException();
    }
  }
}

class _WebSink implements UStorageSink {
  _WebSink(this._backend, this._path, this._length);

  final _WebStorageBackend _backend;
  final String _path;
  int _length;
  Future<void> _tail = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final Future<T> result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<void> writeAt(int position, List<int> bytes) => _serial(() async {
    final int end = position + bytes.length;
    if (end > _length) _length = end;
    // Copied because callers recycle their buffers once the future completes.
    await _backend._put(_path, position, Uint8List.fromList(bytes), _length);
  });

  @override
  Future<int> length() => _serial(() async => _length);

  @override
  Future<void> truncate(int length) => _serial(() async {
    _length = length;
    await _backend._truncate(_path, length);
  });

  @override
  Future<void> flush() => _serial(() async {});

  @override
  Future<void> close() => flush();
}
