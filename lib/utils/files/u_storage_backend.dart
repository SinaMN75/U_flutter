import "dart:typed_data";

import "package:u/utils/files/u_storage_backend_io.dart" if (dart.library.js_interop) "package:u/utils/files/u_storage_backend_web.dart" as impl;

// =============================================================================
// u_storage_backend — the byte store underneath UFileStorage, the vault and the
// download manager. Two implementations sit behind one interface:
//
//   * io  — plain files under the app's private directories (dart:io).
//   * web — IndexedDB, with every file stored as position-keyed records so
//           random-offset writes (segmented downloads, vault chunks) work in
//           the browser exactly as they do on disk.
//
// Paths are "/"-separated strings. On io they are absolute file paths; on the
// web they are opaque keys that merely look like paths.
// =============================================================================

enum UStorageBucket {
  /// Persistent, private, never evicted by the OS. The default.
  support,

  /// Re-creatable data. Size-capped with LRU eviction; the OS may also purge it.
  cache,

  /// Encrypted at rest with a per-file key; the master key lives in the platform key store.
  vault,

  /// Scratch space: partial downloads and staging files.
  temp,
}

/// A handle that accepts writes at arbitrary offsets. Writes are serialised internally,
/// so concurrent callers (download segments) never interleave inside one write.
abstract class UStorageSink {
  Future<void> writeAt(int position, List<int> bytes);

  Future<int> length();

  Future<void> truncate(int length);

  Future<void> flush();

  Future<void> close();
}

abstract class UStorageBackend {
  static final UStorageBackend instance = impl.createStorageBackend();

  /// Returns the root "directory" of [bucket], creating it if needed.
  Future<String> root(UStorageBucket bucket);

  /// True when paths are real files that other code (players, share sheets) can open.
  bool get hasFileSystem;

  Future<bool> exists(String path);

  Future<int?> length(String path);

  Future<DateTime?> modified(String path);

  Future<Uint8List?> readAll(String path);

  /// Streams bytes in `[start, end)`; [end] defaults to the file length.
  Stream<Uint8List> read(String path, {int start = 0, int? end});

  /// Replaces the file atomically: a crash leaves either the old or the new content.
  Future<void> writeAll(String path, List<int> bytes);

  Future<UStorageSink> open(String path, {bool truncate = false});

  Future<void> delete(String path);

  /// Moves a file, falling back to copy + delete across volumes.
  Future<void> move(String from, String to);

  Future<void> copy(String from, String to);

  /// Names (not paths) of the files directly under [directory].
  Future<List<String>> list(String directory);

  Future<void> deleteDirectory(String directory);

  /// Bytes available on the volume holding [path], when the platform can tell.
  Future<int?> freeSpace(String path);

  /// Persists a small secret (the vault master key) in the platform key store.
  /// Returns false when no secure store exists and the caller must fall back.
  Future<bool> storeSecret(String alias, Uint8List secret);

  Future<Uint8List?> loadSecret(String alias);

  Future<void> deleteSecret(String alias);

  /// The authenticated cipher the vault uses on this platform.
  Future<UAead> aead(Uint8List key);
}

/// Authenticated encryption over raw bytes. [seal] returns `ciphertext ‖ tag(16)`.
abstract class UAead {
  /// Recorded in every vault header: 1 = ChaCha20-Poly1305 (native), 2 = AES-256-GCM (web).
  int get algorithmId;

  Future<Uint8List> seal(Uint8List nonce, Uint8List plain);

  /// Throws [UAuthenticationException] when the data was tampered with.
  Future<Uint8List> open(Uint8List nonce, Uint8List sealed);
}

/// Joins path segments with "/" and collapses duplicate separators.
String uJoinPath(String a, String b) => a.endsWith("/") || a.endsWith(r"\") ? "$a$b" : "$a/$b";
