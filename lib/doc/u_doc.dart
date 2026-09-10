import "dart:ui" as ui;

import "package:u/utilities.dart";

enum UDocKind { pdf, epub, unknown }

enum UDocState { idle, opening, needsPassword, ready, error, closed }

enum UDocErrorCode { notFound, permission, password, corrupt, unsupported, network, timeout, outOfMemory, cancelled, io, unknown }

enum UDocScrollMode { verticalContinuous, horizontalContinuous, pagedVertical, pagedHorizontal, singlePage }

enum UDocSpread { none, two, coverFirst, auto }

enum UDocFit { width, page, height, actual, visible, custom }

enum UDocDirection { ltr, rtl }

enum UDocColorMode { normal, night, sepia, grayscale, highContrast, custom }

enum UDocPermission { print, printHighQuality, modify, copy, annotate, fillForms, accessibility, assemble }

enum UDocSaveMode { incremental, rewrite, optimize }

enum UDocSourceKind { file, memory, network, asset, blob }

enum UDocAnnotationKind {
  highlight,
  underline,
  strikeOut,
  squiggly,
  ink,
  text,
  freeText,
  line,
  square,
  circle,
  polygon,
  polyLine,
  stamp,
  caret,
  fileAttachment,
  sound,
  movie,
  widget,
  screen,
  popup,
  link,
  redact,
  unknown,
}

enum UDocFieldKind { text, checkBox, radioButton, comboBox, listBox, pushButton, signature, unknown }

enum UDocOcrEngine { none, appleVision, windowsOcr, mlKit, tesseract }

class UDocParseException implements Exception {
  const UDocParseException(this.message, {this.offset});

  final String message;
  final int? offset;

  @override
  String toString() => offset == null ? "UDocParseException: $message" : "UDocParseException: $message (at $offset)";
}

class UDocError implements Exception {
  const UDocError({required this.code, required this.message, this.detail, this.path});

  final UDocErrorCode code;
  final String message;
  final String? detail;
  final String? path;

  bool get isRecoverable => code == UDocErrorCode.network || code == UDocErrorCode.timeout;

  bool get needsPassword => code == UDocErrorCode.password;

  @override
  String toString() => "UDocError(${code.name}): $message${detail == null ? "" : " — $detail"}";
}

const int uDocBlockSize = 64 * 1024;
const int uDocMaxAllocation = 64 * 1024 * 1024;
const int uDocMaxStringLength = 4 * 1024 * 1024;
const int uDocMaxArrayLength = 500000;
const int uDocMaxDepth = 64;
const int uDocSourceCacheBytes = 16 * 1024 * 1024;
const int uDocObjectCacheBytes = 24 * 1024 * 1024;
const int uDocPictureCacheBytes = 96 * 1024 * 1024;
const int uDocImageCacheBytes = 64 * 1024 * 1024;
const int uDocThumbnailCacheBytes = 12 * 1024 * 1024;
const int uDocTextIndexFlushPages = 32;
const Duration uDocNetworkTimeout = Duration(seconds: 30);

class ULruCache<K, V> {
  ULruCache({required this.maxBytes, required this.sizeOf, this.onEvict});

  final int maxBytes;
  final int Function(V value) sizeOf;
  final void Function(K key, V value)? onEvict;

  final Map<K, V> _entries = <K, V>{};
  final Map<K, int> _sizes = <K, int>{};
  int _bytes = 0;

  int get bytes => _bytes;

  int get length => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  Iterable<K> get keys => _entries.keys;

  bool containsKey(K key) => _entries.containsKey(key);

  V? get(K key) {
    final V? value = _entries.remove(key);
    if (value == null) return null;
    _entries[key] = value;
    return value;
  }

  V? peek(K key) => _entries[key];

  void put(K key, V value) {
    final int size = sizeOf(value);
    if (size > maxBytes) return;
    remove(key);
    _entries[key] = value;
    _sizes[key] = size;
    _bytes += size;
    _trim();
  }

  V? remove(K key) {
    final V? existing = _entries.remove(key);
    if (existing == null) return null;
    _bytes -= _sizes.remove(key) ?? 0;
    onEvict?.call(key, existing);
    return existing;
  }

  void removeWhere(bool Function(K key) test) {
    final List<K> doomed = _entries.keys.where(test).toList();
    for (final K key in doomed) {
      remove(key);
    }
  }

  void _trim() {
    while (_bytes > maxBytes && _entries.isNotEmpty) {
      final K oldest = _entries.keys.first;
      remove(oldest);
    }
  }

  void clear() {
    final List<K> all = _entries.keys.toList();
    for (final K key in all) {
      remove(key);
    }
    _bytes = 0;
  }
}

abstract class UDocByteSource {
  String get id;

  int get length;

  UDocSourceKind get kind;

  bool get isSeekable => true;

  Future<Uint8List> read(int offset, int count);

  Future<void> close();

  Future<Uint8List> readAll({int cap = uDocMaxAllocation}) {
    if (length > cap) throw UDocParseException("Document of $length bytes exceeds the in-memory cap of $cap");
    return read(0, length);
  }

  int clampCount(int offset, int count) {
    if (offset < 0 || offset > length) throw UDocParseException("Offset $offset outside 0..$length");
    if (count < 0) throw const UDocParseException("Negative read length");
    final int available = length - offset;
    return count > available ? available : count;
  }
}

class UMemoryByteSource extends UDocByteSource {
  UMemoryByteSource(this.bytes, {String? id}) : id = id ?? "memory:${bytes.length}:${identityHashCode(bytes)}";

  final Uint8List bytes;

  @override
  final String id;

  @override
  int get length => bytes.length;

  @override
  UDocSourceKind get kind => UDocSourceKind.memory;

  @override
  Future<Uint8List> read(int offset, int count) async {
    final int safe = clampCount(offset, count);
    return Uint8List.sublistView(bytes, offset, offset + safe);
  }

  @override
  Future<void> close() async {}
}

class UFileByteSource extends UDocByteSource {
  UFileByteSource._(this.path, this._handle, this._length);

  static Future<UFileByteSource> open(String path) async {
    final File file = File(path);
    if (!file.existsSync()) throw UDocError(code: UDocErrorCode.notFound, message: "File not found", path: path);
    try {
      final RandomAccessFile handle = await file.open();
      final int size = await handle.length();
      return UFileByteSource._(path, handle, size);
    } on FileSystemException catch (e) {
      throw UDocError(code: UDocErrorCode.permission, message: "Cannot open file", detail: e.message, path: path);
    }
  }

  final String path;
  final RandomAccessFile _handle;
  final int _length;

  bool _closed = false;
  Future<void> _queue = Future<void>.value();

  @override
  String get id => "file:$path:$_length";

  @override
  int get length => _length;

  @override
  UDocSourceKind get kind => UDocSourceKind.file;

  @override
  Future<Uint8List> read(int offset, int count) {
    final int safe = clampCount(offset, count);
    if (safe == 0) return Future<Uint8List>.value(Uint8List(0));
    final Completer<Uint8List> completer = Completer<Uint8List>();
    _queue = _queue.then((void _) async {
      if (_closed) {
        completer.completeError(const UDocError(code: UDocErrorCode.io, message: "Source is closed"));
        return;
      }
      try {
        await _handle.setPosition(offset);
        completer.complete(await _handle.read(safe));
      } on Object catch (e) {
        completer.completeError(UDocError(code: UDocErrorCode.io, message: "Read failed", detail: "$e", path: path));
      }
    });
    return completer.future;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _queue;
    await _handle.close();
  }
}

class UHttpRangeByteSource extends UDocByteSource {
  UHttpRangeByteSource._(this.url, this._length, this._headers, this._client, {required this._ranges});

  static Future<UDocByteSource> open(String url, {Map<String, String>? headers, Directory? spillDirectory}) async {
    final Client client = Client();
    final Map<String, String> requestHeaders = <String, String>{...?headers};
    try {
      final Response head = await client.head(Uri.parse(url), headers: requestHeaders).timeout(uDocNetworkTimeout);
      final int size = int.tryParse(head.headers["content-length"] ?? "") ?? -1;
      final bool ranges = (head.headers["accept-ranges"] ?? "").toLowerCase().contains("bytes");
      if (ranges && size > 0) return UHttpRangeByteSource._(url, size, requestHeaders, client, ranges: true);
      final Response full = await client.get(Uri.parse(url), headers: requestHeaders).timeout(uDocNetworkTimeout);
      final Uint8List bytes = full.bodyBytes;
      client.close();
      if (spillDirectory != null && bytes.length > uDocSourceCacheBytes) {
        final File spill = File("${spillDirectory.path}${Platform.pathSeparator}u_doc_${bytes.length}_${DateTime.now().microsecondsSinceEpoch}.bin");
        await spill.writeAsBytes(bytes, flush: true);
        return await UFileByteSource.open(spill.path);
      }
      return UMemoryByteSource(bytes, id: "network:$url");
    } on TimeoutException {
      client.close();
      throw UDocError(code: UDocErrorCode.timeout, message: "Timed out opening document", path: url);
    } on Object catch (e) {
      client.close();
      throw UDocError(code: UDocErrorCode.network, message: "Cannot open document", detail: "$e", path: url);
    }
  }

  final String url;
  final int _length;
  final Map<String, String> _headers;
  final Client _client;
  final bool _ranges;

  @override
  String get id => "network:$url:$_length";

  @override
  int get length => _length;

  @override
  UDocSourceKind get kind => UDocSourceKind.network;

  @override
  bool get isSeekable => _ranges;

  @override
  Future<Uint8List> read(int offset, int count) async {
    final int safe = clampCount(offset, count);
    if (safe == 0) return Uint8List(0);
    try {
      final Response response = await _client.get(Uri.parse(url), headers: <String, String>{..._headers, "Range": "bytes=$offset-${offset + safe - 1}"}).timeout(uDocNetworkTimeout);
      if (response.statusCode != 206 && response.statusCode != 200) {
        throw UDocError(code: UDocErrorCode.network, message: "Unexpected status ${response.statusCode}", path: url);
      }
      final Uint8List bytes = response.bodyBytes;
      return bytes.length > safe ? Uint8List.sublistView(bytes, 0, safe) : bytes;
    } on TimeoutException {
      throw UDocError(code: UDocErrorCode.timeout, message: "Range request timed out", path: url);
    }
  }

  @override
  Future<void> close() async => _client.close();
}

class UCachedByteSource extends UDocByteSource {
  UCachedByteSource(this.inner, {int maxBytes = uDocSourceCacheBytes}) : _blocks = ULruCache<int, Uint8List>(maxBytes: maxBytes, sizeOf: _blockSize);

  static int _blockSize(Uint8List value) => value.length;

  final UDocByteSource inner;
  final ULruCache<int, Uint8List> _blocks;
  final Map<int, Future<Uint8List>> _inflight = <int, Future<Uint8List>>{};

  @override
  String get id => inner.id;

  @override
  int get length => inner.length;

  @override
  UDocSourceKind get kind => inner.kind;

  @override
  bool get isSeekable => inner.isSeekable;

  int get cachedBytes => _blocks.bytes;

  Uint8List? peek(int offset, int count) {
    final int safe = clampCount(offset, count);
    if (safe == 0) return Uint8List(0);
    final int first = offset ~/ uDocBlockSize;
    final int last = (offset + safe - 1) ~/ uDocBlockSize;
    final Uint8List out = Uint8List(safe);
    int written = 0;
    for (int index = first; index <= last; index++) {
      final Uint8List? block = _blocks.get(index);
      if (block == null) return null;
      final int blockStart = index * uDocBlockSize;
      final int from = offset > blockStart ? offset - blockStart : 0;
      final int to = (offset + safe) < (blockStart + block.length) ? offset + safe - blockStart : block.length;
      if (to <= from) return null;
      out.setRange(written, written + (to - from), block, from);
      written += to - from;
    }
    return written == safe ? out : null;
  }

  Future<Uint8List> _block(int index) {
    final Uint8List? cached = _blocks.get(index);
    if (cached != null) return Future<Uint8List>.value(cached);
    final Future<Uint8List>? pending = _inflight[index];
    if (pending != null) return pending;
    final Future<Uint8List> request = inner
        .read(index * uDocBlockSize, uDocBlockSize)
        .then(
          (Uint8List bytes) {
            _blocks.put(index, bytes);
            _inflight.remove(index);
            return bytes;
          },
          onError: (Object error) {
            _inflight.remove(index);
            throw error;
          },
        );
    _inflight[index] = request;
    return request;
  }

  @override
  Future<Uint8List> read(int offset, int count) async {
    final int safe = clampCount(offset, count);
    if (safe == 0) return Uint8List(0);
    if (safe > uDocBlockSize * 8) return inner.read(offset, safe);
    final Uint8List? hit = peek(offset, safe);
    if (hit != null) return hit;
    final int first = offset ~/ uDocBlockSize;
    final int last = (offset + safe - 1) ~/ uDocBlockSize;
    final Uint8List out = Uint8List(safe);
    int written = 0;
    for (int index = first; index <= last; index++) {
      final Uint8List block = await _block(index);
      final int blockStart = index * uDocBlockSize;
      final int from = offset > blockStart ? offset - blockStart : 0;
      final int to = (offset + safe) < (blockStart + block.length) ? offset + safe - blockStart : block.length;
      if (to <= from) break;
      out.setRange(written, written + (to - from), block, from);
      written += to - from;
    }
    return written == safe ? out : Uint8List.sublistView(out, 0, written);
  }

  Future<void> prefetch(int offset, int count) async {
    final int safe = clampCount(offset, count);
    if (safe == 0) return;
    final int first = offset ~/ uDocBlockSize;
    final int last = (offset + safe - 1) ~/ uDocBlockSize;
    for (int index = first; index <= last; index++) {
      if (!_blocks.containsKey(index)) await _block(index);
    }
  }

  void dropCache() => _blocks.clear();

  @override
  Future<void> close() async {
    _blocks.clear();
    _inflight.clear();
    await inner.close();
  }
}

typedef UDocBlobSourceBuilder = Future<UDocByteSource> Function(Object handle, {String? id});

abstract class UDocSources {
  static UDocBlobSourceBuilder? blobBuilder;

  static Future<UCachedByteSource> open({String? path, String? url, Uint8List? bytes, String? asset, Object? blob, Map<String, String>? headers, int cacheBytes = uDocSourceCacheBytes}) async {
    final UDocByteSource source = await _resolve(path: path, url: url, bytes: bytes, asset: asset, blob: blob, headers: headers);
    return UCachedByteSource(source, maxBytes: cacheBytes);
  }

  static Future<UDocByteSource> _resolve({String? path, String? url, Uint8List? bytes, String? asset, Object? blob, Map<String, String>? headers}) async {
    if (bytes != null) return UMemoryByteSource(bytes);
    if (blob != null) {
      final UDocBlobSourceBuilder? builder = blobBuilder;
      if (builder == null) throw const UDocError(code: UDocErrorCode.unsupported, message: "Blob sources are only available on web");
      return builder(blob);
    }
    if (asset != null) {
      final ByteData data = await rootBundle.load(asset);
      return UMemoryByteSource(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), id: "asset:$asset");
    }
    if (path != null) return UFileByteSource.open(path);
    if (url != null) {
      final Directory? spill = kIsWeb ? null : await getTemporaryDirectory();
      return UHttpRangeByteSource.open(url, headers: headers, spillDirectory: spill);
    }
    throw const UDocError(code: UDocErrorCode.notFound, message: "No document source was provided");
  }

  static Future<String> fingerprint(UDocByteSource source) async {
    final int head = source.length < uDocBlockSize ? source.length : uDocBlockSize;
    final Uint8List first = await source.read(0, head);
    final int tailOffset = source.length > head ? source.length - head : 0;
    final Uint8List last = tailOffset == 0 ? Uint8List(0) : await source.read(tailOffset, head);
    int hash = 0xcbf29ce484222325;
    void mix(int byte) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }

    for (final int byte in first) {
      mix(byte);
    }
    for (final int byte in last) {
      mix(byte);
    }
    mix(source.length & 0xFF);
    mix((source.length >> 8) & 0xFF);
    mix((source.length >> 16) & 0xFF);
    mix((source.length >> 24) & 0xFF);
    return "${source.length.toRadixString(16)}-${hash.toRadixString(16)}";
  }

  static UDocKind sniff(Uint8List head) {
    if (head.length >= 5 && head[0] == 0x25 && head[1] == 0x50 && head[2] == 0x44 && head[3] == 0x46 && head[4] == 0x2D) return UDocKind.pdf;
    if (head.length >= 4 && head[0] == 0x50 && head[1] == 0x4B && (head[2] == 0x03 || head[2] == 0x05 || head[2] == 0x07)) return UDocKind.epub;
    for (int i = 0; i + 4 < head.length && i < 1024; i++) {
      if (head[i] == 0x25 && head[i + 1] == 0x50 && head[i + 2] == 0x44 && head[i + 3] == 0x46) return UDocKind.pdf;
    }
    return UDocKind.unknown;
  }
}

class UDocCursor {
  UDocCursor(this.bytes, {this.base = 0, int start = 0, int? end}) : _pos = start, _end = end ?? bytes.length {
    if (start < 0 || _end > bytes.length || start > _end) throw const UDocParseException("Invalid cursor window");
  }

  final Uint8List bytes;
  final int base;
  final int _end;
  int _pos;

  int get position => _pos;

  int get absolute => base + _pos;

  int get end => _end;

  int get remaining => _end - _pos;

  bool get isEmpty => _pos >= _end;

  bool canRead(int count) => count >= 0 && remaining >= count;

  void require(int count) {
    if (count < 0) throw const UDocParseException("Negative read length");
    if (remaining < count) throw UDocParseException("Read of $count exceeds buffer", offset: absolute);
  }

  int guarded(int declared, {int cap = uDocMaxAllocation}) {
    if (declared < 0) return 0;
    final int limit = cap < remaining ? cap : remaining;
    return declared > limit ? limit : declared;
  }

  void seek(int offset) {
    if (offset < 0 || offset > _end) throw UDocParseException("Seek out of range", offset: offset);
    _pos = offset;
  }

  void seekAbsolute(int offset) => seek(offset - base);

  void skip(int count) {
    require(count);
    _pos += count;
  }

  int u8() {
    require(1);
    return bytes[_pos++];
  }

  int peekAt(int delta) {
    final int index = _pos + delta;
    if (index < 0 || index >= _end) return -1;
    return bytes[index];
  }

  int get peek => _pos < _end ? bytes[_pos] : -1;

  int u16() {
    require(2);
    final int value = (bytes[_pos] << 8) | bytes[_pos + 1];
    _pos += 2;
    return value;
  }

  int i16() {
    final int value = u16();
    return value >= 0x8000 ? value - 0x10000 : value;
  }

  int u24() {
    require(3);
    final int value = (bytes[_pos] << 16) | (bytes[_pos + 1] << 8) | bytes[_pos + 2];
    _pos += 3;
    return value;
  }

  int u32() {
    require(4);
    final int value = (bytes[_pos] << 24) | (bytes[_pos + 1] << 16) | (bytes[_pos + 2] << 8) | bytes[_pos + 3];
    _pos += 4;
    return value;
  }

  int i32() {
    final int value = u32();
    return value >= 0x80000000 ? value - 0x100000000 : value;
  }

  double f2dot14() => i16() / 16384;

  double fixed1616() => i32() / 65536;

  Uint8List take(int count) {
    require(count);
    final Uint8List slice = Uint8List.sublistView(bytes, _pos, _pos + count);
    _pos += count;
    return slice;
  }

  Uint8List takeGuarded(int declared, {int cap = uDocMaxAllocation}) => take(guarded(declared, cap: cap));

  String ascii(int count) {
    final Uint8List slice = take(count);
    final StringBuffer buffer = StringBuffer();
    for (final int byte in slice) {
      buffer.writeCharCode(byte);
    }
    return buffer.toString();
  }

  bool matches(List<int> pattern, {int delta = 0}) {
    if (_pos + delta + pattern.length > _end) return false;
    for (int i = 0; i < pattern.length; i++) {
      if (bytes[_pos + delta + i] != pattern[i]) return false;
    }
    return true;
  }

  int indexOf(List<int> pattern, {int from = -1}) {
    if (pattern.isEmpty) return -1;
    final int start = from < 0 ? _pos : from;
    final int limit = _end - pattern.length;
    for (int i = start; i <= limit; i++) {
      bool hit = true;
      for (int j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) {
          hit = false;
          break;
        }
      }
      if (hit) return i;
    }
    return -1;
  }

  int lastIndexOf(List<int> pattern, {int from = -1}) {
    if (pattern.isEmpty) return -1;
    final int start = from < 0 ? _end - pattern.length : from;
    for (int i = start; i >= 0; i--) {
      bool hit = true;
      for (int j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) {
          hit = false;
          break;
        }
      }
      if (hit) return i;
    }
    return -1;
  }
}

abstract class UDocText {
  static const String _formsBRuns =
      "FE70:1:064B|FE71:1:064B|FE72:1:064C|FE74:1:064D|FE76:2:064E|FE78:2:064F|FE7A:2:0650|FE7C:2:0651|FE7E:2:0652|"
      "FE80:1:0621|FE81:2:0622|FE83:2:0623|FE85:2:0624|FE87:2:0625|FE89:4:0626|FE8D:2:0627|FE8F:4:0628|FE93:2:0629|"
      "FE95:4:062A|FE99:4:062B|FE9D:4:062C|FEA1:4:062D|FEA5:4:062E|FEA9:2:062F|FEAB:2:0630|FEAD:2:0631|FEAF:2:0632|"
      "FEB1:4:0633|FEB5:4:0634|FEB9:4:0635|FEBD:4:0636|FEC1:4:0637|FEC5:4:0638|FEC9:4:0639|FECD:4:063A|FED1:4:0641|"
      "FED5:4:0642|FED9:4:0643|FEDD:4:0644|FEE1:4:0645|FEE5:4:0646|FEE9:4:0647|FEED:2:0648|FEEF:2:0649|FEF1:4:064A|"
      "FEF5:2:0644 0622|FEF7:2:0644 0623|FEF9:2:0644 0625|FEFB:2:0644 0627|"
      "FB56:4:067E|FB5A:4:0680|FB5E:4:067A|FB62:4:067F|FB66:4:0679|FB6A:4:06A4|FB6E:4:06A6|FB72:4:0684|FB76:4:0683|"
      "FB7A:4:0686|FB7E:4:0687|FB82:2:068D|FB84:2:068C|FB86:2:068E|FB88:2:0688|FB8A:2:0698|FB8C:2:0691|FB8E:4:06A9|"
      "FB92:4:06AF|FB96:4:06B3|FB9A:4:06B1|FB9E:2:06BA|FBA0:4:06BB|FBA4:2:06C0|FBA6:4:06C1|FBAA:4:06BE|FBAE:2:06D2|"
      "FBB0:2:06D3|FBD3:4:06AD|FBD7:2:06C7|FBD9:2:06C6|FBDB:2:06C8|FBDD:1:0677|FBDE:2:06CB|FBE0:2:06C5|FBE2:2:06C9|"
      "FBE4:4:06D0|FBFC:4:06CC";

  static const String _stripped = "ًٌٍَُِّْٰٕٖٓٔٗ٘ـ‌‍‎‏؜﻿­";

  static const Map<String, String> _letterFolds = <String, String>{
    "ي": "ی",
    "ى": "ی",
    "ے": "ی",
    "ك": "ک",
    "ڪ": "ک",
    "ة": "ه",
    "ۀ": "ه",
    "ہ": "ه",
    "أ": "ا",
    "إ": "ا",
    "آ": "ا",
    "ٱ": "ا",
    "ؤ": "و",
    "ئ": "ی",
    "ۍ": "ی",
    "ء": "",
  };

  static Map<int, String>? _formsCache;

  static Map<int, String> get _forms {
    final Map<int, String>? cached = _formsCache;
    if (cached != null) return cached;
    final Map<int, String> table = <int, String>{};
    for (final String run in _formsBRuns.split("|")) {
      final List<String> parts = run.split(":");
      if (parts.length != 3) continue;
      final int start = int.parse(parts[0], radix: 16);
      final int count = int.parse(parts[1]);
      final String replacement = parts[2].split(" ").map((String code) => String.fromCharCode(int.parse(code, radix: 16))).join();
      for (int i = 0; i < count; i++) {
        table[start + i] = replacement;
      }
    }
    _formsCache = table;
    return table;
  }

  static bool isRtlCode(int code) =>
      (code >= 0x0590 && code <= 0x08FF) || (code >= 0xFB1D && code <= 0xFDFF) || (code >= 0xFE70 && code <= 0xFEFF) || (code >= 0x10800 && code <= 0x10FFF) || (code >= 0x1E800 && code <= 0x1EFFF);

  static bool isNeutralCode(int code) => code <= 0x40 || (code >= 0x5B && code <= 0x60) || (code >= 0x7B && code <= 0xBF) || code == 0x00D7 || code == 0x00F7;

  static bool isRtl(String text) {
    for (final int code in text.runes) {
      if (isRtlCode(code)) return true;
      if (code >= 0x41 && code <= 0x5A) return false;
      if (code >= 0x61 && code <= 0x7A) return false;
    }
    return false;
  }

  static UDocDirection direction(String text) => isRtl(text) ? UDocDirection.rtl : UDocDirection.ltr;

  static String unfoldPresentationForms(String text) {
    bool needs = false;
    for (final int code in text.runes) {
      if (code >= 0xFB50 && code <= 0xFEFF) {
        needs = true;
        break;
      }
    }
    if (!needs) return text;
    final StringBuffer buffer = StringBuffer();
    for (final int code in text.runes) {
      final String? replacement = _forms[code];
      if (replacement != null) {
        buffer.write(replacement);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  static String normalize(String text) {
    if (text.isEmpty) return text;
    final String unfolded = unfoldPresentationForms(text);
    final StringBuffer buffer = StringBuffer();
    for (final int code in unfolded.runes) {
      final String character = String.fromCharCode(code);
      if (_stripped.contains(character)) continue;
      final String? folded = _letterFolds[character];
      buffer.write(folded ?? character);
    }
    return buffer.toString().toLatinNumber().toLowerCase();
  }

  static String forSearch(String text) => normalize(text).replaceAll(RegExp(r"\s+"), " ").trim();

  static String collapseWhitespace(String text) => text.replaceAll(RegExp(r"[ \t]+"), " ").trim();

  static String dehyphenate(String text) => text.replaceAll(RegExp(r"(\w)-\n(\w)"), r"$1$2").replaceAll("\n", " ");

  static List<int> findAll(String haystack, String needle, {bool wholeWord = false}) {
    final List<int> hits = <int>[];
    if (needle.isEmpty) return hits;
    int from = 0;
    while (true) {
      final int index = haystack.indexOf(needle, from);
      if (index < 0) break;
      if (!wholeWord || _isWordBoundary(haystack, index, needle.length)) hits.add(index);
      from = index + 1;
    }
    return hits;
  }

  static bool _isWordBoundary(String text, int start, int length) {
    final bool leftOk = start == 0 || !_isWordChar(text.codeUnitAt(start - 1));
    final int endIndex = start + length;
    final bool rightOk = endIndex >= text.length || !_isWordChar(text.codeUnitAt(endIndex));
    return leftOk && rightOk;
  }

  static bool _isWordChar(int code) => (code >= 0x30 && code <= 0x39) || (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A) || isRtlCode(code);

  static String decodeBytes(Uint8List bytes, {String? charset}) {
    final String name = (charset ?? "").toLowerCase().replaceAll("_", "-");
    if (name.contains("1256") || name.contains("arabic")) return Cp1256.decode(bytes);
    if (name.contains("latin") || name.contains("8859-1")) return latin1.decode(bytes, allowInvalid: true);
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) return _decodeUtf16(bytes, 2, bigEndian: true);
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) return _decodeUtf16(bytes, 2, bigEndian: false);
    final int start = bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF ? 3 : 0;
    try {
      return utf8.decode(start == 0 ? bytes : Uint8List.sublistView(bytes, start));
    } on FormatException {
      return _looksLikeCp1256(bytes) ? Cp1256.decode(bytes) : latin1.decode(bytes, allowInvalid: true);
    }
  }

  static bool _looksLikeCp1256(Uint8List bytes) {
    int arabic = 0;
    final int limit = bytes.length < 4096 ? bytes.length : 4096;
    for (int i = 0; i < limit; i++) {
      final int byte = bytes[i];
      if (byte >= 0xC0 && byte <= 0xF2) arabic++;
    }
    return limit > 0 && arabic / limit > 0.15;
  }

  static String _decodeUtf16(Uint8List bytes, int start, {required bool bigEndian}) {
    final StringBuffer buffer = StringBuffer();
    for (int i = start; i + 1 < bytes.length; i += 2) {
      buffer.writeCharCode(bigEndian ? (bytes[i] << 8) | bytes[i + 1] : (bytes[i + 1] << 8) | bytes[i]);
    }
    return buffer.toString();
  }
}

class UDocMetadata {
  const UDocMetadata({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator,
    this.producer,
    this.creationDate,
    this.modificationDate,
    this.language,
    this.publisher,
    this.identifier,
    this.series,
    this.seriesIndex,
    this.pageCount = 0,
    this.version,
    this.tagged = false,
    this.linearized = false,
    this.encrypted = false,
    this.custom = const <String, String>{},
  });

  final String? title;
  final String? author;
  final String? subject;
  final String? keywords;
  final String? creator;
  final String? producer;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final String? language;
  final String? publisher;
  final String? identifier;
  final String? series;
  final double? seriesIndex;
  final int pageCount;
  final String? version;
  final bool tagged;
  final bool linearized;
  final bool encrypted;
  final Map<String, String> custom;

  String get displayTitle => title == null || title!.trim().isEmpty ? "" : title!.trim();

  UDocMetadata copyWith({
    String? title,
    String? author,
    String? subject,
    String? keywords,
    String? creator,
    String? producer,
    DateTime? creationDate,
    DateTime? modificationDate,
    String? language,
    String? publisher,
    String? identifier,
    String? series,
    double? seriesIndex,
    int? pageCount,
    String? version,
    bool? tagged,
    bool? linearized,
    bool? encrypted,
    Map<String, String>? custom,
  }) => UDocMetadata(
    title: title ?? this.title,
    author: author ?? this.author,
    subject: subject ?? this.subject,
    keywords: keywords ?? this.keywords,
    creator: creator ?? this.creator,
    producer: producer ?? this.producer,
    creationDate: creationDate ?? this.creationDate,
    modificationDate: modificationDate ?? this.modificationDate,
    language: language ?? this.language,
    publisher: publisher ?? this.publisher,
    identifier: identifier ?? this.identifier,
    series: series ?? this.series,
    seriesIndex: seriesIndex ?? this.seriesIndex,
    pageCount: pageCount ?? this.pageCount,
    version: version ?? this.version,
    tagged: tagged ?? this.tagged,
    linearized: linearized ?? this.linearized,
    encrypted: encrypted ?? this.encrypted,
    custom: custom ?? this.custom,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    "title": title,
    "author": author,
    "subject": subject,
    "keywords": keywords,
    "creator": creator,
    "producer": producer,
    "creationDate": creationDate?.toIso8601String(),
    "modificationDate": modificationDate?.toIso8601String(),
    "language": language,
    "publisher": publisher,
    "identifier": identifier,
    "series": series,
    "seriesIndex": seriesIndex,
    "pageCount": pageCount,
    "version": version,
    "tagged": tagged,
    "linearized": linearized,
    "encrypted": encrypted,
    "custom": custom,
  };

  factory UDocMetadata.fromJson(Map<String, Object?> json) => UDocMetadata(
    title: json["title"] as String?,
    author: json["author"] as String?,
    subject: json["subject"] as String?,
    keywords: json["keywords"] as String?,
    creator: json["creator"] as String?,
    producer: json["producer"] as String?,
    creationDate: DateTime.tryParse((json["creationDate"] as String?) ?? ""),
    modificationDate: DateTime.tryParse((json["modificationDate"] as String?) ?? ""),
    language: json["language"] as String?,
    publisher: json["publisher"] as String?,
    identifier: json["identifier"] as String?,
    series: json["series"] as String?,
    seriesIndex: (json["seriesIndex"] as num?)?.toDouble(),
    pageCount: (json["pageCount"] as num?)?.toInt() ?? 0,
    version: json["version"] as String?,
    tagged: json["tagged"] as bool? ?? false,
    linearized: json["linearized"] as bool? ?? false,
    encrypted: json["encrypted"] as bool? ?? false,
    custom: <String, String>{...?(json["custom"] as Map<Object?, Object?>?)?.map((Object? k, Object? v) => MapEntry<String, String>("$k", "$v"))},
  );
}

class UDocDestination {
  const UDocDestination({required this.pageIndex, this.left, this.top, this.zoom, this.fitMode, this.anchor});

  final int pageIndex;
  final double? left;
  final double? top;
  final double? zoom;
  final UDocFit? fitMode;
  final String? anchor;

  Map<String, Object?> toJson() => <String, Object?>{"pageIndex": pageIndex, "left": left, "top": top, "zoom": zoom, "fitMode": fitMode?.name, "anchor": anchor};

  factory UDocDestination.fromJson(Map<String, Object?> json) => UDocDestination(
    pageIndex: (json["pageIndex"] as num?)?.toInt() ?? 0,
    left: (json["left"] as num?)?.toDouble(),
    top: (json["top"] as num?)?.toDouble(),
    zoom: (json["zoom"] as num?)?.toDouble(),
    fitMode: _fitFromName(json["fitMode"] as String?),
    anchor: json["anchor"] as String?,
  );
}

UDocFit? _fitFromName(String? name) {
  for (final UDocFit fit in UDocFit.values) {
    if (fit.name == name) return fit;
  }
  return null;
}

class UDocOutlineNode {
  const UDocOutlineNode({required this.title, this.destination, this.uri, this.children = const <UDocOutlineNode>[], this.expanded = false, this.color, this.bold = false, this.italic = false});

  final String title;
  final UDocDestination? destination;
  final String? uri;
  final List<UDocOutlineNode> children;
  final bool expanded;
  final Color? color;
  final bool bold;
  final bool italic;

  bool get hasChildren => children.isNotEmpty;

  int get descendantCount => children.fold(children.length, (int total, UDocOutlineNode child) => total + child.descendantCount);
}

class UDocLink {
  const UDocLink({required this.pageIndex, required this.rect, this.destination, this.uri, this.action});

  final int pageIndex;
  final Rect rect;
  final UDocDestination? destination;
  final String? uri;
  final String? action;

  bool get isExternal => uri != null;
}

class UDocGlyph {
  const UDocGlyph({required this.text, required this.rect, required this.rtl, this.fontSize = 0, this.spaceAfter = false});

  final String text;
  final Rect rect;
  final bool rtl;
  final double fontSize;
  final bool spaceAfter;
}

class UDocTextRun {
  const UDocTextRun({required this.text, required this.rect, required this.rtl, required this.glyphs, this.fontName, this.fontSize = 0, this.lineIndex = 0, this.blockIndex = 0});

  final String text;
  final Rect rect;
  final bool rtl;
  final List<UDocGlyph> glyphs;
  final String? fontName;
  final double fontSize;
  final int lineIndex;
  final int blockIndex;
}

class UDocTextPage {
  const UDocTextPage({required this.pageIndex, required this.runs, required this.text, required this.size});

  final int pageIndex;
  final List<UDocTextRun> runs;
  final String text;
  final Size size;

  static const UDocTextPage empty = UDocTextPage(pageIndex: -1, runs: <UDocTextRun>[], text: "", size: Size.zero);

  bool get isEmpty => runs.isEmpty;

  Rect? rectForRange(int start, int end) {
    Rect? union;
    int cursor = 0;
    for (final UDocTextRun run in runs) {
      final int runEnd = cursor + run.text.length;
      if (runEnd > start && cursor < end) union = union == null ? run.rect : union.expandToInclude(run.rect);
      cursor = runEnd + 1;
    }
    return union;
  }

  List<Rect> rectsForRange(int start, int end) {
    final List<Rect> rects = <Rect>[];
    int cursor = 0;
    for (final UDocTextRun run in runs) {
      final int runEnd = cursor + run.text.length;
      if (runEnd > start && cursor < end) {
        final int localStart = start > cursor ? start - cursor : 0;
        final int localEnd = end < runEnd ? end - cursor : run.text.length;
        rects.add(_glyphUnion(run, localStart, localEnd));
      }
      cursor = runEnd + 1;
    }
    return rects;
  }

  Rect _glyphUnion(UDocTextRun run, int start, int end) {
    Rect? union;
    for (int i = start; i < end && i < run.glyphs.length; i++) {
      final Rect rect = run.glyphs[i].rect;
      union = union == null ? rect : union.expandToInclude(rect);
    }
    return union ?? run.rect;
  }
}

class UDocSelection {
  const UDocSelection({required this.pageIndex, required this.start, required this.end, required this.text, this.rects = const <Rect>[]});

  static const UDocSelection none = UDocSelection(pageIndex: -1, start: 0, end: 0, text: "");

  final int pageIndex;
  final int start;
  final int end;
  final String text;
  final List<Rect> rects;

  bool get isEmpty => pageIndex < 0 || end <= start;

  bool get isNotEmpty => !isEmpty;
}

class UDocSearchOptions {
  const UDocSearchOptions({this.caseSensitive = false, this.wholeWord = false, this.regex = false, this.normalizePersian = true, this.maxHits = 5000, this.startPage = 0, this.endPage = -1});

  final bool caseSensitive;
  final bool wholeWord;
  final bool regex;
  final bool normalizePersian;
  final int maxHits;
  final int startPage;
  final int endPage;
}

class UDocSearchHit {
  const UDocSearchHit({required this.pageIndex, required this.start, required this.end, required this.snippet, required this.rects, this.matchIndex = 0});

  final int pageIndex;
  final int start;
  final int end;
  final String snippet;
  final List<Rect> rects;
  final int matchIndex;

  Rect get bounds => rects.isEmpty ? Rect.zero : rects.reduce((Rect a, Rect b) => a.expandToInclude(b));
}

class UDocPageInfo {
  const UDocPageInfo({required this.index, required this.size, this.rotation = 0, this.label, this.cropBox, this.mediaBox, this.hasText = true, this.isScanned = false});

  final int index;
  final Size size;
  final int rotation;
  final String? label;
  final Rect? cropBox;
  final Rect? mediaBox;
  final bool hasText;
  final bool isScanned;

  Size get rotatedSize => rotation == 90 || rotation == 270 ? Size(size.height, size.width) : size;

  double get aspectRatio => rotatedSize.height <= 0 ? 1 : rotatedSize.width / rotatedSize.height;
}

class UDocPermissions {
  const UDocPermissions({this.granted = const <UDocPermission>{}, this.ownerUnlocked = false});

  static const UDocPermissions all = UDocPermissions(
    granted: <UDocPermission>{
      UDocPermission.print,
      UDocPermission.printHighQuality,
      UDocPermission.modify,
      UDocPermission.copy,
      UDocPermission.annotate,
      UDocPermission.fillForms,
      UDocPermission.accessibility,
      UDocPermission.assemble,
    },
    ownerUnlocked: true,
  );

  final Set<UDocPermission> granted;
  final bool ownerUnlocked;

  bool allows(UDocPermission permission) => ownerUnlocked || granted.contains(permission);
}

class UDocTextIndex {
  UDocTextIndex._(this.fingerprint, this._file);

  static const String _folder = "u_doc_index";

  final String fingerprint;
  final File? _file;
  final Map<int, int> _offsets = <int, int>{};
  final Map<int, int> _lengths = <int, int>{};
  final Map<int, String> _memory = <int, String>{};
  final ULruCache<int, String> _cache = ULruCache<int, String>(maxBytes: 2 * 1024 * 1024, sizeOf: _textSize);

  RandomAccessFile? _writer;
  int _tail = 0;
  bool _closed = false;

  static int _textSize(String value) => value.length * 2;

  static Future<UDocTextIndex> open(String fingerprint) async {
    if (kIsWeb) return UDocTextIndex._(fingerprint, null);
    try {
      final Directory support = await getApplicationSupportDirectory();
      final Directory directory = Directory("${support.path}${Platform.pathSeparator}$_folder");
      if (!directory.existsSync()) directory.createSync(recursive: true);
      final File file = File("${directory.path}${Platform.pathSeparator}$fingerprint.jsonl");
      final UDocTextIndex index = UDocTextIndex._(fingerprint, file);
      if (file.existsSync()) await index._scan();
      return index;
    } on Object {
      return UDocTextIndex._(fingerprint, null);
    }
  }

  int get indexedPages => _file == null ? _memory.length : _offsets.length;

  bool hasPage(int pageIndex) => _file == null ? _memory.containsKey(pageIndex) : _offsets.containsKey(pageIndex);

  Future<void> _scan() async {
    final File? file = _file;
    if (file == null) return;
    int offset = 0;
    final List<int> line = <int>[];
    await for (final List<int> chunk in file.openRead()) {
      for (final int byte in chunk) {
        if (byte == 0x0A) {
          _register(line, offset - line.length, line.length);
          line.clear();
        } else {
          line.add(byte);
        }
        offset++;
      }
    }
    if (line.isNotEmpty) _register(line, offset - line.length, line.length);
    _tail = offset;
  }

  void _register(List<int> line, int offset, int length) {
    if (line.isEmpty) return;
    try {
      final Object? decoded = jsonDecode(utf8.decode(line));
      if (decoded is Map<String, Object?>) {
        final int page = (decoded["p"] as num?)?.toInt() ?? -1;
        if (page >= 0) {
          _offsets[page] = offset;
          _lengths[page] = length;
        }
      }
    } on Object {
      return;
    }
  }

  Future<void> writePage(int pageIndex, String text) async {
    if (_closed) return;
    final File? file = _file;
    if (file == null) {
      _memory[pageIndex] = text;
      return;
    }
    _writer ??= await file.open(mode: FileMode.append);
    final Uint8List line = Uint8List.fromList(utf8.encode("${jsonEncode(<String, Object?>{"p": pageIndex, "t": text})}\n"));
    await _writer!.writeFrom(line);
    _offsets[pageIndex] = _tail;
    _lengths[pageIndex] = line.length - 1;
    _tail += line.length;
    _cache.put(pageIndex, text);
  }

  Future<String?> readPage(int pageIndex) async {
    final String? cached = _cache.get(pageIndex);
    if (cached != null) return cached;
    final File? file = _file;
    if (file == null) return _memory[pageIndex];
    final int? offset = _offsets[pageIndex];
    final int? length = _lengths[pageIndex];
    if (offset == null || length == null) return null;
    try {
      await _writer?.flush();
      final RandomAccessFile handle = await file.open();
      await handle.setPosition(offset);
      final Uint8List bytes = await handle.read(length);
      await handle.close();
      final Object? decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, Object?>) return null;
      final String text = (decoded["t"] as String?) ?? "";
      _cache.put(pageIndex, text);
      return text;
    } on Object {
      return null;
    }
  }

  Future<void> clear() async {
    _offsets.clear();
    _lengths.clear();
    _memory.clear();
    _cache.clear();
    _tail = 0;
    await _writer?.close();
    _writer = null;
    final File? file = _file;
    if (file != null && file.existsSync()) await file.delete();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _writer?.flush();
    await _writer?.close();
    _writer = null;
    _cache.clear();
  }
}

class UDocProgress {
  const UDocProgress({
    required this.fingerprint,
    required this.updatedAt,
    this.path,
    this.pageIndex = 0,
    this.pageOffset = 0,
    this.zoom = 1,
    this.percent = 0,
    this.cfi,
    this.scrollMode = UDocScrollMode.verticalContinuous,
    this.colorMode = UDocColorMode.normal,
    this.readingSeconds = 0,
  });

  final String fingerprint;
  final DateTime updatedAt;
  final String? path;
  final int pageIndex;
  final double pageOffset;
  final double zoom;
  final double percent;
  final String? cfi;
  final UDocScrollMode scrollMode;
  final UDocColorMode colorMode;
  final int readingSeconds;

  Map<String, Object?> toJson() => <String, Object?>{
    "fingerprint": fingerprint,
    "updatedAt": updatedAt.toIso8601String(),
    "path": path,
    "pageIndex": pageIndex,
    "pageOffset": pageOffset,
    "zoom": zoom,
    "percent": percent,
    "cfi": cfi,
    "scrollMode": scrollMode.name,
    "colorMode": colorMode.name,
    "readingSeconds": readingSeconds,
  };

  factory UDocProgress.fromJson(Map<String, Object?> json) => UDocProgress(
    fingerprint: (json["fingerprint"] as String?) ?? "",
    updatedAt: DateTime.tryParse((json["updatedAt"] as String?) ?? "") ?? DateTime.now(),
    path: json["path"] as String?,
    pageIndex: (json["pageIndex"] as num?)?.toInt() ?? 0,
    pageOffset: (json["pageOffset"] as num?)?.toDouble() ?? 0,
    zoom: (json["zoom"] as num?)?.toDouble() ?? 1,
    percent: (json["percent"] as num?)?.toDouble() ?? 0,
    cfi: json["cfi"] as String?,
    scrollMode: _enumByName(UDocScrollMode.values, json["scrollMode"] as String?) ?? UDocScrollMode.verticalContinuous,
    colorMode: _enumByName(UDocColorMode.values, json["colorMode"] as String?) ?? UDocColorMode.normal,
    readingSeconds: (json["readingSeconds"] as num?)?.toInt() ?? 0,
  );
}

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final T value in values) {
    if (value.name == name) return value;
  }
  return null;
}

class UDocProgressStore extends ChangeNotifier {
  UDocProgressStore._();

  static final UDocProgressStore instance = UDocProgressStore._();

  static const String _fileName = "u_doc_progress.json";

  final Map<String, UDocProgress> _entries = <String, UDocProgress>{};
  bool _loaded = false;
  Timer? _debounce;

  Map<String, UDocProgress> get entries => Map<String, UDocProgress>.unmodifiable(_entries);

  List<UDocProgress> get recent {
    final List<UDocProgress> list = _entries.values.toList()..sort((UDocProgress a, UDocProgress b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<File?> _file() async {
    if (kIsWeb) return null;
    final Directory directory = await getApplicationSupportDirectory();
    return File("${directory.path}${Platform.pathSeparator}$_fileName");
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final File? file = await _file();
      if (file == null || !file.existsSync()) return;
      final Object? decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) return;
      decoded.forEach((String key, Object? value) {
        if (value is Map<String, Object?>) _entries[key] = UDocProgress.fromJson(value);
      });
      notifyListeners();
    } on Object {
      return;
    }
  }

  UDocProgress? get(String fingerprint) => _entries[fingerprint];

  void put(UDocProgress progress) {
    _entries[progress.fingerprint] = progress;
    notifyListeners();
    _schedule();
  }

  void remove(String fingerprint) {
    _entries.remove(fingerprint);
    notifyListeners();
    _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => unawaited(flush()));
  }

  Future<void> flush() async {
    try {
      final File? file = await _file();
      if (file == null) return;
      final Map<String, Object?> payload = _entries.map((String key, UDocProgress value) => MapEntry<String, Object?>(key, value.toJson()));
      await file.writeAsString(jsonEncode(payload), flush: true);
    } on Object {
      return;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class UDocRecord {
  const UDocRecord({
    required this.fingerprint,
    required this.path,
    required this.kind,
    required this.sizeBytes,
    required this.addedAt,
    this.metadata = const UDocMetadata(),
    this.coverPath,
    this.lastOpenedAt,
    this.favorite = false,
    this.collections = const <String>[],
  });

  final String fingerprint;
  final String path;
  final UDocKind kind;
  final int sizeBytes;
  final DateTime addedAt;
  final UDocMetadata metadata;
  final String? coverPath;
  final DateTime? lastOpenedAt;
  final bool favorite;
  final List<String> collections;

  String get fileName => path.split(Platform.pathSeparator).last;

  String get displayTitle => metadata.displayTitle.isEmpty ? fileName : metadata.displayTitle;

  UDocRecord copyWith({UDocMetadata? metadata, String? coverPath, DateTime? lastOpenedAt, bool? favorite, List<String>? collections}) => UDocRecord(
    fingerprint: fingerprint,
    path: path,
    kind: kind,
    sizeBytes: sizeBytes,
    addedAt: addedAt,
    metadata: metadata ?? this.metadata,
    coverPath: coverPath ?? this.coverPath,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    favorite: favorite ?? this.favorite,
    collections: collections ?? this.collections,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    "fingerprint": fingerprint,
    "path": path,
    "kind": kind.name,
    "sizeBytes": sizeBytes,
    "addedAt": addedAt.toIso8601String(),
    "metadata": metadata.toJson(),
    "coverPath": coverPath,
    "lastOpenedAt": lastOpenedAt?.toIso8601String(),
    "favorite": favorite,
    "collections": collections,
  };

  factory UDocRecord.fromJson(Map<String, Object?> json) => UDocRecord(
    fingerprint: (json["fingerprint"] as String?) ?? "",
    path: (json["path"] as String?) ?? "",
    kind: _enumByName(UDocKind.values, json["kind"] as String?) ?? UDocKind.unknown,
    sizeBytes: (json["sizeBytes"] as num?)?.toInt() ?? 0,
    addedAt: DateTime.tryParse((json["addedAt"] as String?) ?? "") ?? DateTime.now(),
    metadata: json["metadata"] is Map<String, Object?> ? UDocMetadata.fromJson(json["metadata"]! as Map<String, Object?>) : const UDocMetadata(),
    coverPath: json["coverPath"] as String?,
    lastOpenedAt: DateTime.tryParse((json["lastOpenedAt"] as String?) ?? ""),
    favorite: json["favorite"] as bool? ?? false,
    collections: <String>[...?(json["collections"] as List<Object?>?)?.map((Object? e) => "$e")],
  );
}

class UDocLibrary extends ChangeNotifier {
  UDocLibrary._();

  static final UDocLibrary instance = UDocLibrary._();

  static const String _indexFileName = "u_doc_library.jsonl";
  static const List<String> extensions = <String>[".pdf", ".epub"];

  final List<UDocRecord> _records = <UDocRecord>[];

  bool _loaded = false;
  bool _scanning = false;
  int _scanned = 0;
  int _scanTotal = 0;

  List<UDocRecord> get records => List<UDocRecord>.unmodifiable(_records);

  bool get isLoaded => _loaded;

  bool get isScanning => _scanning;

  int get scannedCount => _scanned;

  int get scanTotal => _scanTotal;

  int get count => _records.length;

  Future<File> _indexFile() async {
    final Directory directory = await getApplicationSupportDirectory();
    return File("${directory.path}${Platform.pathSeparator}$_indexFileName");
  }

  Future<void> load() async {
    if (_loaded || kIsWeb) return;
    _loaded = true;
    try {
      final File file = await _indexFile();
      if (!file.existsSync()) return;
      for (final String line in const LineSplitter().convert(await file.readAsString())) {
        if (line.trim().isEmpty) continue;
        final Object? decoded = jsonDecode(line);
        if (decoded is Map<String, Object?>) _records.add(UDocRecord.fromJson(decoded));
      }
      notifyListeners();
    } on Object {
      return;
    }
  }

  Future<void> save() async {
    if (kIsWeb) return;
    try {
      final File file = await _indexFile();
      final StringBuffer buffer = StringBuffer();
      for (final UDocRecord record in _records) {
        buffer.writeln(jsonEncode(record.toJson()));
      }
      await file.writeAsString(buffer.toString(), flush: true);
    } on Object {
      return;
    }
  }

  UDocRecord? byFingerprint(String fingerprint) {
    for (final UDocRecord record in _records) {
      if (record.fingerprint == fingerprint) return record;
    }
    return null;
  }

  UDocRecord? byPath(String path) {
    for (final UDocRecord record in _records) {
      if (record.path == path) return record;
    }
    return null;
  }

  Future<void> scan(List<String> directories, {bool recursive = true}) async {
    if (kIsWeb || _scanning) return;
    _scanning = true;
    _scanned = 0;
    _scanTotal = 0;
    notifyListeners();
    try {
      final List<File> found = <File>[];
      for (final String path in directories) {
        final Directory directory = Directory(path);
        if (!directory.existsSync()) continue;
        await for (final FileSystemEntity entity in directory.list(recursive: recursive, followLinks: false)) {
          if (entity is! File) continue;
          final String lower = entity.path.toLowerCase();
          if (extensions.any(lower.endsWith)) found.add(entity);
        }
      }
      _scanTotal = found.length;
      notifyListeners();
      for (final File file in found) {
        await _ingest(file);
        _scanned++;
        if (_scanned % 16 == 0) notifyListeners();
      }
      await save();
    } on Object {
      return;
    } finally {
      _scanning = false;
      notifyListeners();
    }
  }

  Future<void> _ingest(File file) async {
    try {
      final FileStat stat = file.statSync();
      final UDocRecord? existing = byPath(file.path);
      if (existing != null && existing.sizeBytes == stat.size) return;
      final UCachedByteSource source = await UDocSources.open(path: file.path);
      final String fingerprint = await UDocSources.fingerprint(source);
      final Uint8List head = await source.read(0, 1024);
      final UDocKind kind = UDocSources.sniff(head);
      await source.close();
      final UDocRecord record = UDocRecord(fingerprint: fingerprint, path: file.path, kind: kind, sizeBytes: stat.size, addedAt: stat.modified);
      if (existing == null) {
        _records.add(record);
      } else {
        _records[_records.indexOf(existing)] = record;
      }
    } on Object {
      return;
    }
  }

  void upsert(UDocRecord record) {
    final UDocRecord? existing = byFingerprint(record.fingerprint);
    if (existing == null) {
      _records.add(record);
    } else {
      _records[_records.indexOf(existing)] = record;
    }
    notifyListeners();
    unawaited(save());
  }

  void toggleFavorite(String fingerprint) {
    final UDocRecord? record = byFingerprint(fingerprint);
    if (record == null) return;
    upsert(record.copyWith(favorite: !record.favorite));
  }

  void removeRecord(String fingerprint) {
    _records.removeWhere((UDocRecord record) => record.fingerprint == fingerprint);
    notifyListeners();
    unawaited(save());
  }

  List<UDocRecord> query({String? text, UDocKind? kind, bool favoritesOnly = false, String? collection}) {
    final String needle = UDocText.forSearch(text ?? "");
    return _records.where((UDocRecord record) {
      if (kind != null && record.kind != kind) return false;
      if (favoritesOnly && !record.favorite) return false;
      if (collection != null && !record.collections.contains(collection)) return false;
      if (needle.isEmpty) return true;
      final String haystack = UDocText.forSearch("${record.displayTitle} ${record.metadata.author ?? ""} ${record.fileName}");
      return haystack.contains(needle);
    }).toList();
  }
}

abstract class UDocColorFilters {
  static const List<double> _sepia = <double>[
    0.393,
    0.769,
    0.189,
    0,
    0,
    0.349,
    0.686,
    0.168,
    0,
    0,
    0.272,
    0.534,
    0.131,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _grayscale = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _night = <double>[
    -0.95,
    -0.02,
    -0.02,
    0,
    245,
    -0.02,
    -0.95,
    -0.02,
    0,
    242,
    -0.02,
    -0.02,
    -0.95,
    0,
    235,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _highContrast = <double>[
    1.6,
    0,
    0,
    0,
    -60,
    0,
    1.6,
    0,
    0,
    -60,
    0,
    0,
    1.6,
    0,
    -60,
    0,
    0,
    0,
    1,
    0,
  ];

  static ColorFilter? forMode(UDocColorMode mode, {List<double>? custom}) {
    switch (mode) {
      case UDocColorMode.normal:
        return null;
      case UDocColorMode.night:
        return const ColorFilter.matrix(_night);
      case UDocColorMode.sepia:
        return const ColorFilter.matrix(_sepia);
      case UDocColorMode.grayscale:
        return const ColorFilter.matrix(_grayscale);
      case UDocColorMode.highContrast:
        return const ColorFilter.matrix(_highContrast);
      case UDocColorMode.custom:
        return custom != null && custom.length == 20 ? ColorFilter.matrix(custom) : null;
    }
  }

  static Color pageBackground(UDocColorMode mode) {
    switch (mode) {
      case UDocColorMode.night:
        return const Color(0xFF12141A);
      case UDocColorMode.sepia:
        return const Color(0xFFF6ECD9);
      case UDocColorMode.grayscale:
      case UDocColorMode.highContrast:
      case UDocColorMode.custom:
      case UDocColorMode.normal:
        return const Color(0xFFFFFFFF);
    }
  }

  static Color surfaceBackground(UDocColorMode mode) {
    switch (mode) {
      case UDocColorMode.night:
        return const Color(0xFF07080B);
      case UDocColorMode.sepia:
        return const Color(0xFFE6D9BE);
      case UDocColorMode.grayscale:
      case UDocColorMode.highContrast:
      case UDocColorMode.custom:
      case UDocColorMode.normal:
        return const Color(0xFF2B2E34);
    }
  }
}

class UDocPictureCache {
  UDocPictureCache({int maxBytes = uDocPictureCacheBytes}) : _pictures = ULruCache<String, ui.Picture>(maxBytes: maxBytes, sizeOf: _pictureSize);

  static final UDocPictureCache instance = UDocPictureCache();

  final ULruCache<String, ui.Picture> _pictures;

  static int _pictureSize(ui.Picture picture) {
    final int reported = picture.approximateBytesUsed;
    return reported <= 0 ? 256 * 1024 : reported;
  }

  static String key(String documentId, int pageIndex, double scale) => "$documentId#$pageIndex@${(scale * 100).round()}";

  ui.Picture? get(String cacheKey) => _pictures.get(cacheKey);

  void put(String cacheKey, ui.Picture picture) => _pictures.put(cacheKey, picture);

  void evictDocument(String documentId) => _pictures.removeWhere((String cacheKey) => cacheKey.startsWith("$documentId#"));

  void evictPage(String documentId, int pageIndex) => _pictures.removeWhere((String cacheKey) => cacheKey.startsWith("$documentId#$pageIndex@"));

  void clear() => _pictures.clear();

  int get bytes => _pictures.bytes;
}

class UDocImageCache {
  UDocImageCache({int maxBytes = uDocImageCacheBytes}) : _images = ULruCache<String, ui.Image>(maxBytes: maxBytes, sizeOf: _imageSize, onEvict: _disposeImage);

  static final UDocImageCache instance = UDocImageCache();

  final ULruCache<String, ui.Image> _images;

  static int _imageSize(ui.Image image) => image.width * image.height * 4;

  static void _disposeImage(String key, ui.Image image) => image.dispose();

  ui.Image? get(String cacheKey) => _images.get(cacheKey);

  void put(String cacheKey, ui.Image image) => _images.put(cacheKey, image);

  void evictDocument(String documentId) => _images.removeWhere((String cacheKey) => cacheKey.startsWith("$documentId#"));

  void clear() => _images.clear();

  int get bytes => _images.bytes;
}

class UDocViewSettings {
  const UDocViewSettings({
    this.scrollMode = UDocScrollMode.verticalContinuous,
    this.spread = UDocSpread.none,
    this.direction = UDocDirection.ltr,
    this.fit = UDocFit.width,
    this.colorMode = UDocColorMode.normal,
    this.zoom = 1,
    this.minZoom = 0.25,
    this.maxZoom = 12,
    this.dim = 0,
    this.pageGap = 12,
    this.cropMargins = false,
    this.tileThreshold = 2.5,
    this.maxRenderScale = 4,
    this.renderAhead = 2,
    this.keepScreenOn = false,
    this.showAnnotations = true,
    this.showForms = true,
    this.customMatrix,
  });

  final UDocScrollMode scrollMode;
  final UDocSpread spread;
  final UDocDirection direction;
  final UDocFit fit;
  final UDocColorMode colorMode;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final double dim;
  final double pageGap;
  final bool cropMargins;
  final double tileThreshold;
  final double maxRenderScale;
  final int renderAhead;
  final bool keepScreenOn;
  final bool showAnnotations;
  final bool showForms;
  final List<double>? customMatrix;

  bool get isPaged => scrollMode == UDocScrollMode.pagedVertical || scrollMode == UDocScrollMode.pagedHorizontal || scrollMode == UDocScrollMode.singlePage;

  bool get isHorizontal => scrollMode == UDocScrollMode.horizontalContinuous || scrollMode == UDocScrollMode.pagedHorizontal;

  bool get isRtl => direction == UDocDirection.rtl;

  ColorFilter? get colorFilter => UDocColorFilters.forMode(colorMode, custom: customMatrix);

  UDocViewSettings copyWith({
    UDocScrollMode? scrollMode,
    UDocSpread? spread,
    UDocDirection? direction,
    UDocFit? fit,
    UDocColorMode? colorMode,
    double? zoom,
    double? minZoom,
    double? maxZoom,
    double? dim,
    double? pageGap,
    bool? cropMargins,
    double? tileThreshold,
    double? maxRenderScale,
    int? renderAhead,
    bool? keepScreenOn,
    bool? showAnnotations,
    bool? showForms,
    List<double>? customMatrix,
  }) => UDocViewSettings(
    scrollMode: scrollMode ?? this.scrollMode,
    spread: spread ?? this.spread,
    direction: direction ?? this.direction,
    fit: fit ?? this.fit,
    colorMode: colorMode ?? this.colorMode,
    zoom: zoom ?? this.zoom,
    minZoom: minZoom ?? this.minZoom,
    maxZoom: maxZoom ?? this.maxZoom,
    dim: dim ?? this.dim,
    pageGap: pageGap ?? this.pageGap,
    cropMargins: cropMargins ?? this.cropMargins,
    tileThreshold: tileThreshold ?? this.tileThreshold,
    maxRenderScale: maxRenderScale ?? this.maxRenderScale,
    renderAhead: renderAhead ?? this.renderAhead,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    showAnnotations: showAnnotations ?? this.showAnnotations,
    showForms: showForms ?? this.showForms,
    customMatrix: customMatrix ?? this.customMatrix,
  );
}

class UDocValue {
  const UDocValue({
    this.state = UDocState.idle,
    this.kind = UDocKind.unknown,
    this.pageCount = 0,
    this.pageIndex = 0,
    this.metadata = const UDocMetadata(),
    this.permissions = UDocPermissions.all,
    this.settings = const UDocViewSettings(),
    this.selection = UDocSelection.none,
    this.searchQuery = "",
    this.searchHits = const <UDocSearchHit>[],
    this.searchHitIndex = -1,
    this.isSearching = false,
    this.isBusy = false,
    this.loadedPercent = 0,
    this.hasUnsavedChanges = false,
    this.error,
  });

  final UDocState state;
  final UDocKind kind;
  final int pageCount;
  final int pageIndex;
  final UDocMetadata metadata;
  final UDocPermissions permissions;
  final UDocViewSettings settings;
  final UDocSelection selection;
  final String searchQuery;
  final List<UDocSearchHit> searchHits;
  final int searchHitIndex;
  final bool isSearching;
  final bool isBusy;
  final double loadedPercent;
  final bool hasUnsavedChanges;
  final UDocError? error;

  bool get isReady => state == UDocState.ready;

  bool get hasError => error != null;

  double get progress => pageCount <= 1 ? 0 : (pageIndex / (pageCount - 1)).clamp(0, 1).toDouble();

  UDocSearchHit? get currentHit => searchHitIndex >= 0 && searchHitIndex < searchHits.length ? searchHits[searchHitIndex] : null;

  UDocValue copyWith({
    UDocState? state,
    UDocKind? kind,
    int? pageCount,
    int? pageIndex,
    UDocMetadata? metadata,
    UDocPermissions? permissions,
    UDocViewSettings? settings,
    UDocSelection? selection,
    String? searchQuery,
    List<UDocSearchHit>? searchHits,
    int? searchHitIndex,
    bool? isSearching,
    bool? isBusy,
    double? loadedPercent,
    bool? hasUnsavedChanges,
    UDocError? error,
    bool clearError = false,
  }) => UDocValue(
    state: state ?? this.state,
    kind: kind ?? this.kind,
    pageCount: pageCount ?? this.pageCount,
    pageIndex: pageIndex ?? this.pageIndex,
    metadata: metadata ?? this.metadata,
    permissions: permissions ?? this.permissions,
    settings: settings ?? this.settings,
    selection: selection ?? this.selection,
    searchQuery: searchQuery ?? this.searchQuery,
    searchHits: searchHits ?? this.searchHits,
    searchHitIndex: searchHitIndex ?? this.searchHitIndex,
    isSearching: isSearching ?? this.isSearching,
    isBusy: isBusy ?? this.isBusy,
    loadedPercent: loadedPercent ?? this.loadedPercent,
    hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    error: clearError ? null : error ?? this.error,
  );
}

abstract class UDocController extends ValueNotifier<UDocValue> {
  UDocController() : super(const UDocValue());

  final StreamController<UDocValue> _states = StreamController<UDocValue>.broadcast();
  final ValueNotifier<List<UDocSearchHit>> liveHits = ValueNotifier<List<UDocSearchHit>>(const <UDocSearchHit>[]);

  bool _disposed = false;

  Stream<UDocValue> get stateStream => _states.stream;

  bool get isDisposed => _disposed;

  String get documentId;

  UDocKind get kind;

  int get pageCount => value.pageCount;

  UDocViewSettings get settings => value.settings;

  UDocPageInfo pageInfo(int pageIndex);

  Future<UDocTextPage> textPage(int pageIndex);

  Future<ui.Picture?> renderPage(int pageIndex, {double scale = 1, Rect? clip});

  Future<ui.Image?> renderThumbnail(int pageIndex, {int maxSize = 240});

  Future<void> close();

  void emit(UDocValue next) {
    if (_disposed) return;
    value = next;
    if (!_states.isClosed) _states.add(next);
  }

  void updateSettings(UDocViewSettings settings) => emit(value.copyWith(settings: settings));

  void setScrollMode(UDocScrollMode mode) => updateSettings(settings.copyWith(scrollMode: mode));

  void setSpread(UDocSpread spread) => updateSettings(settings.copyWith(spread: spread));

  void setDirection(UDocDirection direction) => updateSettings(settings.copyWith(direction: direction));

  void setColorMode(UDocColorMode mode) => updateSettings(settings.copyWith(colorMode: mode));

  void setFit(UDocFit fit) => updateSettings(settings.copyWith(fit: fit));

  void setDim(double dim) => updateSettings(settings.copyWith(dim: dim.clamp(0, 0.85).toDouble()));

  void setZoom(double zoom) => updateSettings(settings.copyWith(zoom: zoom.clamp(settings.minZoom, settings.maxZoom).toDouble(), fit: UDocFit.custom));

  void setCropMargins(bool crop) => updateSettings(settings.copyWith(cropMargins: crop));

  void goToPage(int pageIndex) {
    if (pageCount <= 0) return;
    emit(value.copyWith(pageIndex: pageIndex.clamp(0, pageCount - 1)));
  }

  void nextPage() => goToPage(value.pageIndex + 1);

  void previousPage() => goToPage(value.pageIndex - 1);

  void clearSelection() => emit(value.copyWith(selection: UDocSelection.none));

  void setSelection(UDocSelection selection) => emit(value.copyWith(selection: selection));

  void clearSearch() {
    liveHits.value = const <UDocSearchHit>[];
    emit(value.copyWith(searchQuery: "", searchHits: const <UDocSearchHit>[], searchHitIndex: -1, isSearching: false));
  }

  void nextHit() {
    if (value.searchHits.isEmpty) return;
    final int next = (value.searchHitIndex + 1) % value.searchHits.length;
    emit(value.copyWith(searchHitIndex: next, pageIndex: value.searchHits[next].pageIndex));
  }

  void previousHit() {
    if (value.searchHits.isEmpty) return;
    final int next = (value.searchHitIndex - 1 + value.searchHits.length) % value.searchHits.length;
    emit(value.copyWith(searchHitIndex: next, pageIndex: value.searchHits[next].pageIndex));
  }

  void failWith(UDocError error) => emit(value.copyWith(state: UDocState.error, error: error, isBusy: false));

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_states.close());
    liveHits.dispose();
    super.dispose();
  }
}

class UDocNormalizedText {
  const UDocNormalizedText(this.text, this.sourceIndices);

  final String text;
  final List<int> sourceIndices;

  int sourceAt(int index) {
    if (sourceIndices.isEmpty) return 0;
    final int safe = index < 0 ? 0 : (index >= sourceIndices.length ? sourceIndices.length - 1 : index);
    return sourceIndices[safe];
  }

  static UDocNormalizedText build(String source) {
    final StringBuffer buffer = StringBuffer();
    final List<int> indices = <int>[];
    final List<int> runes = source.runes.toList();
    int rawIndex = 0;
    for (final int code in runes) {
      final int charLength = code > 0xFFFF ? 2 : 1;
      final String piece = UDocText.normalize(String.fromCharCode(code));
      for (int i = 0; i < piece.length; i++) {
        buffer.write(piece[i]);
        indices.add(rawIndex);
      }
      rawIndex += charLength;
    }
    return UDocNormalizedText(buffer.toString(), indices);
  }
}
