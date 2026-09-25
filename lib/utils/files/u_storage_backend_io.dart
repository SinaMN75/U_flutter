import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:path_provider/path_provider.dart";
import "package:u/plugins/files/u_files_channel.dart";
import "package:u/utils/files/u_crypto_stream.dart";
import "package:u/utils/files/u_storage_backend.dart";

UStorageBackend createStorageBackend() => _IoStorageBackend();

class _IoStorageBackend implements UStorageBackend {
  final Map<UStorageBucket, Future<String>> _roots = <UStorageBucket, Future<String>>{};

  @override
  bool get hasFileSystem => true;

  @override
  Future<String> root(UStorageBucket bucket) => _roots.putIfAbsent(bucket, () => _createRoot(bucket));

  // Never getApplicationDocumentsDirectory(): on Windows, Linux and unsandboxed macOS that
  // is the user's own ~/Documents folder, not a private app directory.
  Future<String> _createRoot(UStorageBucket bucket) async {
    final Directory base = switch (bucket) {
      UStorageBucket.support || UStorageBucket.vault => await getApplicationSupportDirectory(),
      UStorageBucket.cache => await getApplicationCacheDirectory(),
      UStorageBucket.temp => await getTemporaryDirectory(),
    };
    final Directory directory = Directory(uJoinPath(uJoinPath(base.path, "u_storage"), bucket.name));
    if (!directory.existsSync()) await directory.create(recursive: true);
    if (bucket != UStorageBucket.support) await UFilesChannel.excludeFromBackup(directory.path);
    return directory.path;
  }

  @override
  Future<bool> exists(String path) async => File(path).existsSync();

  @override
  Future<int?> length(String path) async {
    final File file = File(path);
    return file.existsSync() ? file.length() : null;
  }

  @override
  Future<DateTime?> modified(String path) async {
    final File file = File(path);
    return file.existsSync() ? file.lastModifiedSync() : null;
  }

  @override
  Future<Uint8List?> readAll(String path) async {
    final File file = File(path);
    if (!file.existsSync()) return null;
    try {
      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Stream<Uint8List> read(String path, {int start = 0, int? end}) async* {
    final RandomAccessFile raf = await File(path).open();
    try {
      final int stop = end ?? await raf.length();
      int position = start;
      await raf.setPosition(position);
      while (position < stop) {
        final int size = stop - position < 262144 ? stop - position : 262144;
        final Uint8List chunk = await raf.read(size);
        if (chunk.isEmpty) break;
        position += chunk.length;
        yield chunk;
      }
    } finally {
      await raf.close();
    }
  }

  @override
  Future<void> writeAll(String path, List<int> bytes) async {
    final File target = File(path);
    final Directory parent = target.parent;
    if (!parent.existsSync()) await parent.create(recursive: true);
    final File staging = File("$path.${DateTime.now().microsecondsSinceEpoch}.tmp");
    await staging.writeAsBytes(bytes, flush: true);
    await _replace(staging, target);
  }

  // rename() over an existing file is atomic on POSIX but can fail on Windows while
  // another handle is open, so retry a few times before giving up.
  Future<void> _replace(File staging, File target) async {
    for (int attempt = 0; attempt < 5; attempt++) {
      try {
        await staging.rename(target.path);
        return;
      } on FileSystemException {
        if (attempt == 4) {
          if (staging.existsSync()) await staging.delete();
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 40 * (attempt + 1)));
      }
    }
  }

  @override
  Future<UStorageSink> open(String path, {bool truncate = false}) async {
    final File file = File(path);
    if (!file.parent.existsSync()) await file.parent.create(recursive: true);
    final RandomAccessFile raf = await file.open(mode: truncate ? FileMode.write : FileMode.append);
    return _IoSink(raf);
  }

  @override
  Future<void> delete(String path) async {
    final File file = File(path);
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        if (file.existsSync()) await file.delete();
        return;
      } on FileSystemException {
        if (attempt == 2) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 100 * (attempt + 1)));
      }
    }
  }

  @override
  Future<void> move(String from, String to) async {
    final File source = File(from);
    final File target = File(to);
    if (!target.parent.existsSync()) await target.parent.create(recursive: true);
    try {
      await source.rename(to);
    } on FileSystemException {
      // Different volume (e.g. cache → external Downloads): copy, then remove the original.
      await source.copy(to);
      await delete(from);
    }
  }

  @override
  Future<void> copy(String from, String to) async {
    final File target = File(to);
    if (!target.parent.existsSync()) await target.parent.create(recursive: true);
    await File(from).copy(to);
  }

  @override
  Future<List<String>> list(String directory) async {
    final Directory dir = Directory(directory);
    if (!dir.existsSync()) return <String>[];
    return dir.listSync().whereType<File>().map((File f) => f.uri.pathSegments.last).toList(growable: false);
  }

  @override
  Future<void> deleteDirectory(String directory) async {
    final Directory dir = Directory(directory);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  @override
  Future<int?> freeSpace(String path) => UFilesChannel.freeSpace(path);

  @override
  Future<bool> storeSecret(String alias, Uint8List secret) => UFilesChannel.storeSecret(alias, secret);

  @override
  Future<Uint8List?> loadSecret(String alias) => UFilesChannel.loadSecret(alias);

  @override
  Future<void> deleteSecret(String alias) => UFilesChannel.deleteSecret(alias);

  @override
  Future<UAead> aead(Uint8List key) async => _ChaChaAead(UChaCha20Poly1305(key));
}

class _ChaChaAead implements UAead {
  _ChaChaAead(this._cipher);

  final UChaCha20Poly1305 _cipher;

  @override
  int get algorithmId => 1;

  @override
  Future<Uint8List> seal(Uint8List nonce, Uint8List plain) async => _cipher.seal(nonce, plain);

  @override
  Future<Uint8List> open(Uint8List nonce, Uint8List sealed) async => _cipher.open(nonce, sealed);
}

class _IoSink implements UStorageSink {
  _IoSink(this._raf);

  final RandomAccessFile _raf;
  Future<void> _tail = Future<void>.value();
  bool _closed = false;

  // RandomAccessFile rejects overlapping async calls, so every operation is chained.
  Future<T> _serial<T>(Future<T> Function() action) {
    final Future<T> result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<void> writeAt(int position, List<int> bytes) => _serial(() async {
    if (_closed) throw const FileSystemException("Sink is closed.");
    await _raf.setPosition(position);
    await _raf.writeFrom(bytes);
  });

  @override
  Future<int> length() => _serial(_raf.length);

  @override
  Future<void> truncate(int length) => _serial(() async => _raf.truncate(length));

  @override
  Future<void> flush() => _serial(() async => _raf.flush());

  @override
  Future<void> close() => _serial(() async {
    if (_closed) return;
    _closed = true;
    await _raf.flush();
    await _raf.close();
  });
}
