import "dart:math";
import "dart:typed_data";

import "package:u/utils/files/u_crypto_stream.dart";
import "package:u/utils/files/u_storage_backend.dart";

// =============================================================================
// u_vault — encrypted-at-rest files with streaming, random-access decryption.
//
// File layout (all integers little-endian):
//
//   "UVLT" | version:u8 | alg:u8 | chunkSize:u32 | noncePrefix[7] | keyLen:u16 | wrappedKey
//   chunk 0 | chunk 1 | ... | chunk n-1
//
//   * wrappedKey = seal(masterKey, random nonce, fileKey) — envelope encryption:
//     every file has its own random key, so the master key can be rotated by
//     re-wrapping 60 bytes per file instead of re-encrypting gigabytes.
//   * chunk i = seal(fileKey, noncePrefix ‖ u32be(i) ‖ lastFlag, plaintext[i]).
//     The index in the nonce stops chunks being reordered; the last-chunk flag
//     stops the file being silently truncated at a chunk boundary.
//   * Every chunk is independent, so the file can be written at any chunk
//     offset (segmented downloads) and read from any offset (video seeking).
// =============================================================================

const List<int> _magic = <int>[0x55, 0x56, 0x4C, 0x54];
const int _version = 1;
const int _tagLength = 16;
const int defaultVaultChunkSize = 65536;

final Random _random = Random.secure();

Uint8List uRandomBytes(int length) => Uint8List.fromList(List<int>.generate(length, (int _) => _random.nextInt(256)));

class UVaultHeader {
  UVaultHeader({required this.algorithmId, required this.chunkSize, required this.noncePrefix, required this.wrappedKey});

  final int algorithmId;
  final int chunkSize;
  final Uint8List noncePrefix;
  final Uint8List wrappedKey;

  int get length => 4 + 1 + 1 + 4 + 7 + 2 + wrappedKey.length;

  int get sealedChunkSize => chunkSize + _tagLength;

  Uint8List encode() {
    final Uint8List out = Uint8List(length);
    final ByteData view = ByteData.sublistView(out);
    out.setRange(0, 4, _magic);
    out[4] = _version;
    out[5] = algorithmId;
    view.setUint32(6, chunkSize, Endian.little);
    out.setRange(10, 17, noncePrefix);
    view.setUint16(17, wrappedKey.length, Endian.little);
    out.setRange(19, 19 + wrappedKey.length, wrappedKey);
    return out;
  }

  static UVaultHeader decode(Uint8List bytes) {
    if (bytes.length < 19 || bytes[0] != _magic[0] || bytes[1] != _magic[1] || bytes[2] != _magic[2] || bytes[3] != _magic[3]) {
      throw const FormatException("Not a vault file.");
    }
    if (bytes[4] != _version) throw FormatException("Unsupported vault version ${bytes[4]}.");
    final ByteData view = ByteData.sublistView(bytes);
    final int keyLength = view.getUint16(17, Endian.little);
    if (bytes.length < 19 + keyLength) throw const FormatException("Truncated vault header.");
    return UVaultHeader(
      algorithmId: bytes[5],
      chunkSize: view.getUint32(6, Endian.little),
      noncePrefix: Uint8List.fromList(bytes.sublist(10, 17)),
      wrappedKey: Uint8List.fromList(bytes.sublist(19, 19 + keyLength)),
    );
  }

  /// Plaintext length of a vault file whose total size is [fileLength].
  int plainLength(int fileLength) {
    final int body = fileLength - length;
    if (body <= 0) return 0;
    final int full = body ~/ sealedChunkSize;
    final int rest = body % sealedChunkSize;
    return full * chunkSize + (rest == 0 ? 0 : rest - _tagLength);
  }

  Uint8List nonce(int index, {required bool last}) {
    final Uint8List n = Uint8List(12)..setRange(0, 7, noncePrefix);
    ByteData.sublistView(n).setUint32(7, index);
    n[11] = last ? 1 : 0;
    return n;
  }
}

/// Holds the unwrapped master key and hands out per-file ciphers.
class UVaultKeys {
  UVaultKeys(this._master, this._backend);

  final UAead _master;
  final UStorageBackend _backend;

  static const String _alias = "u_vault_master_v1";

  /// Loads the master key from the platform key store, creating it on first use. When the
  /// platform has no key store the key falls back to a private file under the support bucket.
  static Future<UVaultKeys> load(UStorageBackend backend) async {
    Uint8List? key = await backend.loadSecret(_alias);
    final String fallback = uJoinPath(await backend.root(UStorageBucket.support), ".vault.key");
    key ??= await backend.readAll(fallback);
    if (key == null || key.length != 32) {
      key = uRandomBytes(32);
      if (!await backend.storeSecret(_alias, key)) await backend.writeAll(fallback, key);
    }
    return UVaultKeys(await backend.aead(key), backend);
  }

  Future<(UVaultHeader, UAead)> newFile({int chunkSize = defaultVaultChunkSize}) async {
    final Uint8List fileKey = uRandomBytes(32);
    final Uint8List wrapNonce = uRandomBytes(12);
    final Uint8List wrapped = Uint8List.fromList(<int>[...wrapNonce, ...await _master.seal(wrapNonce, fileKey)]);
    final UAead aead = await _backend.aead(fileKey);
    return (UVaultHeader(algorithmId: aead.algorithmId, chunkSize: chunkSize, noncePrefix: uRandomBytes(7), wrappedKey: wrapped), aead);
  }

  Future<UAead> openFile(UVaultHeader header) async {
    final Uint8List fileKey = await _master.open(Uint8List.sublistView(header.wrappedKey, 0, 12), Uint8List.sublistView(header.wrappedKey, 12));
    final UAead aead = await _backend.aead(fileKey);
    if (aead.algorithmId != header.algorithmId) throw const FormatException("Vault file was written by a different platform cipher.");
    return aead;
  }

  Future<UVaultHeader> readHeader(String path) async {
    final BytesBuilder head = BytesBuilder(copy: false);
    await for (final Uint8List bytes in _backend.read(path, end: 512)) {
      head.add(bytes);
    }
    return UVaultHeader.decode(head.takeBytes());
  }

  /// Opens a writer for a new vault file at [path]. Supports writes at any offset as long as
  /// every chunk is filled by exactly one sequential writer (true for download segments that
  /// are aligned to [UVaultHeader.chunkSize]).
  Future<UVaultWriter> create(String path, {int chunkSize = defaultVaultChunkSize}) async {
    final (UVaultHeader header, UAead aead) = await newFile(chunkSize: chunkSize);
    final UStorageSink sink = await _backend.open(path, truncate: true);
    await sink.writeAt(0, header.encode());
    return UVaultWriter._(header, aead, sink);
  }

  /// Re-opens a partially written vault file to continue a download.
  Future<UVaultWriter> resume(String path) async {
    final UVaultHeader header = await readHeader(path);
    final UAead aead = await openFile(header);
    return UVaultWriter._(header, aead, await _backend.open(path));
  }

  Future<int> plainLength(String path) async {
    final UVaultHeader header = await readHeader(path);
    return header.plainLength(await _backend.length(path) ?? header.length);
  }

  /// Decrypts `[start, end)` of the plaintext, touching only the chunks that overlap it.
  Stream<Uint8List> read(String path, {int start = 0, int? end}) async* {
    final UVaultHeader header = await readHeader(path);
    final UAead aead = await openFile(header);
    final int fileLength = await _backend.length(path) ?? header.length;
    final int plain = header.plainLength(fileLength);
    final int stop = end == null || end > plain ? plain : end;
    if (start >= stop) return;
    final int body = fileLength - header.length;
    final int chunkCount = body <= 0 ? 0 : (body + header.sealedChunkSize - 1) ~/ header.sealedChunkSize;
    for (int index = start ~/ header.chunkSize; index < chunkCount; index++) {
      final int plainStart = index * header.chunkSize;
      if (plainStart >= stop) break;
      final int sealedStart = header.length + index * header.sealedChunkSize;
      final int sealedEnd = min(sealedStart + header.sealedChunkSize, fileLength);
      final BytesBuilder sealed = BytesBuilder(copy: false);
      await for (final Uint8List bytes in _backend.read(path, start: sealedStart, end: sealedEnd)) {
        sealed.add(bytes);
      }
      final Uint8List chunk = await aead.open(header.nonce(index, last: index == chunkCount - 1), sealed.takeBytes());
      final int from = max(0, start - plainStart);
      final int to = min(chunk.length, stop - plainStart);
      if (to > from) yield Uint8List.sublistView(chunk, from, to);
    }
  }

  /// Checks every tag. Returns false instead of throwing when the file is damaged.
  Future<bool> verify(String path) async {
    try {
      await for (final Uint8List _ in read(path)) {}
      return true;
    } on UAuthenticationException {
      return false;
    } on FormatException {
      return false;
    }
  }
}

class _PendingChunk {
  _PendingChunk(int size) : bytes = Uint8List(size);

  final Uint8List bytes;
  int filled = 0;
}

/// Encrypting sink. Plaintext offsets in, sealed chunks out.
class UVaultWriter implements UStorageSink {
  UVaultWriter._(this.header, this._aead, this._sink);

  final UVaultHeader header;
  final UAead _aead;
  final UStorageSink _sink;
  final Map<int, _PendingChunk> _pending = <int, _PendingChunk>{};
  int? _knownLength;
  int? _endOffset;

  int get chunkSize => header.chunkSize;

  /// Plaintext offsets below this are safely on disk; everything after must be re-downloaded
  /// after a crash. Used by the download engine to persist resumable progress.
  int durableOffset(int position) => position - position % chunkSize;

  /// When the total plaintext length is known up front, the final chunk can be sealed as soon
  /// as it fills instead of waiting for [finish].
  set expectedLength(int? value) => _knownLength = value;

  @override
  Future<void> writeAt(int position, List<int> bytes) async {
    int offset = 0;
    while (offset < bytes.length) {
      final int absolute = position + offset;
      final int index = absolute ~/ chunkSize;
      final int within = absolute % chunkSize;
      final _PendingChunk chunk = _pending.putIfAbsent(index, () => _PendingChunk(chunkSize));
      if (within != chunk.filled) throw StateError("Vault chunk $index must be written sequentially.");
      final int take = min(chunkSize - within, bytes.length - offset);
      chunk.bytes.setRange(within, within + take, bytes, offset);
      chunk.filled += take;
      offset += take;
      final int? known = _knownLength;
      final bool isLast = known != null && (index + 1) * chunkSize >= known;
      if (chunk.filled == chunkSize || (isLast && index * chunkSize + chunk.filled == known)) {
        await _seal(index, chunk.filled, last: isLast);
      }
    }
  }

  Future<void> _seal(int index, int length, {required bool last}) async {
    final _PendingChunk? chunk = _pending.remove(index);
    final Uint8List plain = chunk == null ? Uint8List(0) : Uint8List.sublistView(chunk.bytes, 0, length);
    final Uint8List sealed = await _aead.seal(header.nonce(index, last: last), plain);
    final int at = header.length + index * header.sealedChunkSize;
    await _sink.writeAt(at, sealed);
    if (last) _endOffset = at + sealed.length;
  }

  /// Seals the final chunk. [totalLength] is the full plaintext length.
  Future<void> finish(int totalLength) async {
    if (_endOffset == null) await _sealFinal(totalLength);
    // A resumed file may hold stale bytes past the new end from an earlier, longer attempt.
    await _sink.truncate(_endOffset!);
  }

  Future<void> _sealFinal(int totalLength) async {
    final int lastIndex = totalLength == 0 ? 0 : (totalLength - 1) ~/ chunkSize;
    final int tail = totalLength - lastIndex * chunkSize;
    if (tail == chunkSize && !_pending.containsKey(lastIndex)) {
      // The last chunk was full and already sealed without the flag: append an empty terminator.
      await _seal(lastIndex + 1, 0, last: true);
    } else {
      await _seal(lastIndex, tail, last: true);
    }
  }

  @override
  Future<int> length() => _sink.length();

  @override
  Future<void> truncate(int length) => _sink.truncate(header.length + (length ~/ chunkSize) * header.sealedChunkSize);

  @override
  Future<void> flush() => _sink.flush();

  @override
  Future<void> close() => _sink.close();
}
