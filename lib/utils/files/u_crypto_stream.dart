import "dart:typed_data";

// =============================================================================
// u_crypto_stream — the incremental primitives the download manager and the
// file vault need, that u_encrypt's one-shot helpers cannot provide:
//
//   * [UHasher]            MD5 / SHA-1 / SHA-256 fed chunk by chunk, so a
//                          multi-gigabyte download is verified without ever
//                          being held in memory. 32-bit only, so web-safe.
//   * [UChaCha20Poly1305]  RFC 8439 AEAD with allocation-free ChaCha20 and a
//                          26-bit-limb Poly1305. Roughly two orders of
//                          magnitude faster than u_encrypt's reference
//                          implementation, which is what makes encrypting
//                          whole files practical. Poly1305 relies on 64-bit
//                          integers, so this class is native-only; the web
//                          vault uses WebCrypto AES-GCM instead.
// =============================================================================

enum UHashAlgorithm { md5, sha1, sha256 }

const int _mask32 = 0xFFFFFFFF;

int _rotl(int x, int n) => ((x << n) | ((x & _mask32) >>> (32 - n))) & _mask32;

int _rotr(int x, int n) => (((x & _mask32) >>> n) | (x << (32 - n))) & _mask32;

/// Incremental message digest. Call [add] any number of times, then [close] once.
class UHasher {
  UHasher(this.algorithm) : _state = Uint32List(algorithm == UHashAlgorithm.sha256 ? 8 : (algorithm == UHashAlgorithm.sha1 ? 5 : 4)) {
    switch (algorithm) {
      case UHashAlgorithm.md5:
        _state.setAll(0, <int>[0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476]);
      case UHashAlgorithm.sha1:
        _state.setAll(0, <int>[0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]);
      case UHashAlgorithm.sha256:
        _state.setAll(0, <int>[0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]);
    }
  }

  final UHashAlgorithm algorithm;
  final Uint32List _state;
  final Uint8List _block = Uint8List(64);
  final Uint32List _w = Uint32List(80);
  int _blockLength = 0;
  int _totalLength = 0;
  bool _closed = false;

  void add(List<int> data) {
    if (_closed) throw StateError("UHasher is already closed.");
    _totalLength += data.length;
    int offset = 0;
    if (_blockLength > 0) {
      final int take = (64 - _blockLength) < data.length ? 64 - _blockLength : data.length;
      _block.setRange(_blockLength, _blockLength + take, data);
      _blockLength += take;
      offset = take;
      if (_blockLength < 64) return;
      _compress(_block, 0);
      _blockLength = 0;
    }
    final Uint8List bytes = data is Uint8List ? data : Uint8List.fromList(data);
    while (data.length - offset >= 64) {
      _compress(bytes, offset);
      offset += 64;
    }
    if (offset < data.length) {
      _block.setRange(0, data.length - offset, bytes, offset);
      _blockLength = data.length - offset;
    }
  }

  Uint8List close() {
    if (_closed) throw StateError("UHasher is already closed.");
    _closed = true;
    final int bitsLow = (_totalLength * 8) % 4294967296;
    final int bitsHigh = (_totalLength * 8) ~/ 4294967296;
    _block[_blockLength++] = 0x80;
    if (_blockLength > 56) {
      _block.fillRange(_blockLength, 64, 0);
      _compress(_block, 0);
      _blockLength = 0;
    }
    _block.fillRange(_blockLength, 56, 0);
    final ByteData tail = ByteData.sublistView(_block);
    if (algorithm == UHashAlgorithm.md5) {
      tail
        ..setUint32(56, bitsLow, Endian.little)
        ..setUint32(60, bitsHigh, Endian.little);
    } else {
      tail
        ..setUint32(56, bitsHigh)
        ..setUint32(60, bitsLow);
    }
    _compress(_block, 0);
    final ByteData out = ByteData(_state.length * 4);
    for (int i = 0; i < _state.length; i++) {
      out.setUint32(i * 4, _state[i], algorithm == UHashAlgorithm.md5 ? Endian.little : Endian.big);
    }
    return out.buffer.asUint8List();
  }

  String closeHex() {
    final Uint8List digest = close();
    final StringBuffer buffer = StringBuffer();
    for (final int b in digest) {
      buffer.write(b.toRadixString(16).padLeft(2, "0"));
    }
    return buffer.toString();
  }

  /// One-shot convenience for small inputs.
  static String hex(UHashAlgorithm algorithm, List<int> data) => (UHasher(algorithm)..add(data)).closeHex();

  void _compress(Uint8List data, int offset) {
    switch (algorithm) {
      case UHashAlgorithm.md5:
        _md5Block(data, offset);
      case UHashAlgorithm.sha1:
        _sha1Block(data, offset);
      case UHashAlgorithm.sha256:
        _sha256Block(data, offset);
    }
  }

  static const List<int> _md5Shift = <int>[
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, //
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
  ];

  static const List<int> _md5K = <int>[
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501, //
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
  ];

  void _md5Block(Uint8List data, int offset) {
    final ByteData view = ByteData.sublistView(data, offset, offset + 64);
    for (int i = 0; i < 16; i++) {
      _w[i] = view.getUint32(i * 4, Endian.little);
    }
    int a = _state[0];
    int b = _state[1];
    int c = _state[2];
    int d = _state[3];
    for (int i = 0; i < 64; i++) {
      int f;
      int g;
      if (i < 16) {
        f = (b & c) | (~b & d);
        g = i;
      } else if (i < 32) {
        f = (d & b) | (~d & c);
        g = (5 * i + 1) % 16;
      } else if (i < 48) {
        f = b ^ c ^ d;
        g = (3 * i + 5) % 16;
      } else {
        f = c ^ (b | (~d & _mask32));
        g = (7 * i) % 16;
      }
      f = (f + a + _md5K[i] + _w[g]) & _mask32;
      a = d;
      d = c;
      c = b;
      b = (b + _rotl(f, _md5Shift[i])) & _mask32;
    }
    _state[0] = (_state[0] + a) & _mask32;
    _state[1] = (_state[1] + b) & _mask32;
    _state[2] = (_state[2] + c) & _mask32;
    _state[3] = (_state[3] + d) & _mask32;
  }

  void _sha1Block(Uint8List data, int offset) {
    final ByteData view = ByteData.sublistView(data, offset, offset + 64);
    for (int i = 0; i < 16; i++) {
      _w[i] = view.getUint32(i * 4);
    }
    for (int i = 16; i < 80; i++) {
      _w[i] = _rotl(_w[i - 3] ^ _w[i - 8] ^ _w[i - 14] ^ _w[i - 16], 1);
    }
    int a = _state[0];
    int b = _state[1];
    int c = _state[2];
    int d = _state[3];
    int e = _state[4];
    for (int i = 0; i < 80; i++) {
      int f;
      int k;
      if (i < 20) {
        f = (b & c) | (~b & d);
        k = 0x5A827999;
      } else if (i < 40) {
        f = b ^ c ^ d;
        k = 0x6ED9EBA1;
      } else if (i < 60) {
        f = (b & c) | (b & d) | (c & d);
        k = 0x8F1BBCDC;
      } else {
        f = b ^ c ^ d;
        k = 0xCA62C1D6;
      }
      final int t = (_rotl(a, 5) + (f & _mask32) + e + k + _w[i]) & _mask32;
      e = d;
      d = c;
      c = _rotl(b, 30);
      b = a;
      a = t;
    }
    _state[0] = (_state[0] + a) & _mask32;
    _state[1] = (_state[1] + b) & _mask32;
    _state[2] = (_state[2] + c) & _mask32;
    _state[3] = (_state[3] + d) & _mask32;
    _state[4] = (_state[4] + e) & _mask32;
  }

  static const List<int> _sha256K = <int>[
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, //
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  void _sha256Block(Uint8List data, int offset) {
    final ByteData view = ByteData.sublistView(data, offset, offset + 64);
    for (int i = 0; i < 16; i++) {
      _w[i] = view.getUint32(i * 4);
    }
    for (int i = 16; i < 64; i++) {
      final int s0 = _rotr(_w[i - 15], 7) ^ _rotr(_w[i - 15], 18) ^ (_w[i - 15] >>> 3);
      final int s1 = _rotr(_w[i - 2], 17) ^ _rotr(_w[i - 2], 19) ^ (_w[i - 2] >>> 10);
      _w[i] = (_w[i - 16] + s0 + _w[i - 7] + s1) & _mask32;
    }
    int a = _state[0];
    int b = _state[1];
    int c = _state[2];
    int d = _state[3];
    int e = _state[4];
    int f = _state[5];
    int g = _state[6];
    int h = _state[7];
    for (int i = 0; i < 64; i++) {
      final int s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final int ch = (e & f) ^ (~e & g & _mask32);
      final int t1 = (h + s1 + ch + _sha256K[i] + _w[i]) & _mask32;
      final int s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final int maj = (a & b) ^ (a & c) ^ (b & c);
      final int t2 = (s0 + maj) & _mask32;
      h = g;
      g = f;
      f = e;
      e = (d + t1) & _mask32;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & _mask32;
    }
    _state[0] = (_state[0] + a) & _mask32;
    _state[1] = (_state[1] + b) & _mask32;
    _state[2] = (_state[2] + c) & _mask32;
    _state[3] = (_state[3] + d) & _mask32;
    _state[4] = (_state[4] + e) & _mask32;
    _state[5] = (_state[5] + f) & _mask32;
    _state[6] = (_state[6] + g) & _mask32;
    _state[7] = (_state[7] + h) & _mask32;
  }
}

/// Thrown when an AEAD tag does not verify: the data was modified, truncated,
/// reordered, or decrypted with the wrong key.
class UAuthenticationException implements Exception {
  const UAuthenticationException([this.message = "Authentication failed."]);

  final String message;

  @override
  String toString() => "UAuthenticationException: $message";
}

/// RFC 8439 ChaCha20-Poly1305 over raw bytes. Output of [seal] is `ciphertext ‖ tag(16)`.
/// Native only — see the file header.
class UChaCha20Poly1305 {
  UChaCha20Poly1305(Uint8List key) : _key = Uint32List(8) {
    if (key.length != 32) throw ArgumentError("ChaCha20-Poly1305 needs a 32-byte key.");
    final ByteData view = ByteData.sublistView(key);
    for (int i = 0; i < 8; i++) {
      _key[i] = view.getUint32(i * 4, Endian.little);
    }
  }

  static const int tagLength = 16;
  static const int nonceLength = 12;

  final Uint32List _key;
  final Uint32List _input = Uint32List(16);
  final Uint32List _x = Uint32List(16);
  final Uint8List _keystream = Uint8List(64);

  Uint8List seal(Uint8List nonce, Uint8List plain, [Uint8List? aad]) {
    final Uint8List out = Uint8List(plain.length + tagLength);
    _setNonce(nonce);
    _xor(plain, out, 1);
    final Uint8List tag = _tag(Uint8List.sublistView(out, 0, plain.length), aad ?? Uint8List(0));
    out.setRange(plain.length, out.length, tag);
    return out;
  }

  Uint8List open(Uint8List nonce, Uint8List cipherAndTag, [Uint8List? aad]) {
    if (cipherAndTag.length < tagLength) throw const UAuthenticationException("Ciphertext is shorter than the tag.");
    final int length = cipherAndTag.length - tagLength;
    final Uint8List cipher = Uint8List.sublistView(cipherAndTag, 0, length);
    _setNonce(nonce);
    final Uint8List expected = _tag(cipher, aad ?? Uint8List(0));
    int diff = 0;
    for (int i = 0; i < tagLength; i++) {
      diff |= expected[i] ^ cipherAndTag[length + i];
    }
    if (diff != 0) throw const UAuthenticationException();
    final Uint8List out = Uint8List(length);
    _xor(cipher, out, 1);
    return out;
  }

  void _setNonce(Uint8List nonce) {
    if (nonce.length != nonceLength) throw ArgumentError("ChaCha20-Poly1305 needs a 12-byte nonce.");
    final ByteData view = ByteData.sublistView(nonce);
    _input[0] = 0x61707865;
    _input[1] = 0x3320646e;
    _input[2] = 0x79622d32;
    _input[3] = 0x6b206574;
    _input.setRange(4, 12, _key);
    _input[13] = view.getUint32(0, Endian.little);
    _input[14] = view.getUint32(4, Endian.little);
    _input[15] = view.getUint32(8, Endian.little);
  }

  void _block(int counter) {
    _input[12] = counter & _mask32;
    _x.setAll(0, _input);
    for (int i = 0; i < 10; i++) {
      _qr(0, 4, 8, 12);
      _qr(1, 5, 9, 13);
      _qr(2, 6, 10, 14);
      _qr(3, 7, 11, 15);
      _qr(0, 5, 10, 15);
      _qr(1, 6, 11, 12);
      _qr(2, 7, 8, 13);
      _qr(3, 4, 9, 14);
    }
    for (int i = 0; i < 16; i++) {
      final int v = (_x[i] + _input[i]) & _mask32;
      final int o = i * 4;
      _keystream[o] = v & 0xFF;
      _keystream[o + 1] = (v >>> 8) & 0xFF;
      _keystream[o + 2] = (v >>> 16) & 0xFF;
      _keystream[o + 3] = (v >>> 24) & 0xFF;
    }
  }

  void _qr(int a, int b, int c, int d) {
    final Uint32List x = _x;
    x[a] = x[a] + x[b];
    int t = x[d] ^ x[a];
    x[d] = (t << 16) | (t >>> 16);
    x[c] = x[c] + x[d];
    t = x[b] ^ x[c];
    x[b] = (t << 12) | (t >>> 20);
    x[a] = x[a] + x[b];
    t = x[d] ^ x[a];
    x[d] = (t << 8) | (t >>> 24);
    x[c] = x[c] + x[d];
    t = x[b] ^ x[c];
    x[b] = (t << 7) | (t >>> 25);
  }

  void _xor(Uint8List input, Uint8List output, int counter) {
    int ctr = counter;
    for (int offset = 0; offset < input.length; offset += 64) {
      _block(ctr++);
      final int n = input.length - offset < 64 ? input.length - offset : 64;
      for (int j = 0; j < n; j++) {
        output[offset + j] = input[offset + j] ^ _keystream[j];
      }
    }
  }

  Uint8List _tag(Uint8List cipher, Uint8List aad) {
    _block(0);
    final _Poly1305 poly = _Poly1305(Uint8List.sublistView(_keystream, 0, 32));
    poly.updatePadded(aad);
    poly.updatePadded(cipher);
    final Uint8List lengths = Uint8List(16);
    final ByteData view = ByteData.sublistView(lengths)
      ..setUint32(0, aad.length % 4294967296, Endian.little)
      ..setUint32(4, aad.length ~/ 4294967296, Endian.little)
      ..setUint32(8, cipher.length % 4294967296, Endian.little)
      ..setUint32(12, cipher.length ~/ 4294967296, Endian.little);
    poly.updatePadded(view.buffer.asUint8List());
    return poly.finish();
  }
}

/// Poly1305 with five 26-bit limbs ("donna-32"). Every product fits in 58 bits.
class _Poly1305 {
  _Poly1305(Uint8List key) {
    final ByteData k = ByteData.sublistView(key);
    final int t0 = k.getUint32(0, Endian.little);
    final int t1 = k.getUint32(4, Endian.little);
    final int t2 = k.getUint32(8, Endian.little);
    final int t3 = k.getUint32(12, Endian.little);
    _r0 = t0 & 0x3ffffff;
    _r1 = ((t0 >>> 26) | (t1 << 6)) & 0x3ffff03;
    _r2 = ((t1 >>> 20) | (t2 << 12)) & 0x3ffc0ff;
    _r3 = ((t2 >>> 14) | (t3 << 18)) & 0x3f03fff;
    _r4 = (t3 >>> 8) & 0x00fffff;
    _pad = <int>[k.getUint32(16, Endian.little), k.getUint32(20, Endian.little), k.getUint32(24, Endian.little), k.getUint32(28, Endian.little)];
  }

  static const int _m26 = 0x3ffffff;

  late final int _r0;
  late final int _r1;
  late final int _r2;
  late final int _r3;
  late final int _r4;
  late final List<int> _pad;
  int _h0 = 0;
  int _h1 = 0;
  int _h2 = 0;
  int _h3 = 0;
  int _h4 = 0;
  final Uint8List _last = Uint8List(16);

  /// Absorbs [data] zero-padded to a 16-byte boundary, which is exactly how the
  /// AEAD construction lays out AAD, ciphertext and the length block.
  void updatePadded(Uint8List data) {
    int offset = 0;
    while (data.length - offset >= 16) {
      _blockAt(data, offset);
      offset += 16;
    }
    if (offset < data.length) {
      _last.fillRange(0, 16, 0);
      _last.setRange(0, data.length - offset, data, offset);
      _blockAt(_last, 0);
    }
  }

  static int _le32(Uint8List m, int o) => m[o] | (m[o + 1] << 8) | (m[o + 2] << 16) | (m[o + 3] << 24);

  void _blockAt(Uint8List m, int o) {
    final int s1 = _r1 * 5;
    final int s2 = _r2 * 5;
    final int s3 = _r3 * 5;
    final int s4 = _r4 * 5;
    final int h0 = _h0 + (_le32(m, o) & _m26);
    final int h1 = _h1 + ((_le32(m, o + 3) >>> 2) & _m26);
    final int h2 = _h2 + ((_le32(m, o + 6) >>> 4) & _m26);
    final int h3 = _h3 + ((_le32(m, o + 9) >>> 6) & _m26);
    final int h4 = _h4 + ((_le32(m, o + 12) >>> 8) | (1 << 24));

    final int d0 = h0 * _r0 + h1 * s4 + h2 * s3 + h3 * s2 + h4 * s1;
    int d1 = h0 * _r1 + h1 * _r0 + h2 * s4 + h3 * s3 + h4 * s2;
    int d2 = h0 * _r2 + h1 * _r1 + h2 * _r0 + h3 * s4 + h4 * s3;
    int d3 = h0 * _r3 + h1 * _r2 + h2 * _r1 + h3 * _r0 + h4 * s4;
    int d4 = h0 * _r4 + h1 * _r3 + h2 * _r2 + h3 * _r1 + h4 * _r0;

    int c = d0 >> 26;
    _h0 = d0 & _m26;
    d1 += c;
    c = d1 >> 26;
    _h1 = d1 & _m26;
    d2 += c;
    c = d2 >> 26;
    _h2 = d2 & _m26;
    d3 += c;
    c = d3 >> 26;
    _h3 = d3 & _m26;
    d4 += c;
    c = d4 >> 26;
    _h4 = d4 & _m26;
    _h0 += c * 5;
    c = _h0 >> 26;
    _h0 &= _m26;
    _h1 += c;
  }

  Uint8List finish() {
    int h0 = _h0;
    int h1 = _h1;
    int h2 = _h2;
    int h3 = _h3;
    int h4 = _h4;
    int c = h1 >> 26;
    h1 &= _m26;
    h2 += c;
    c = h2 >> 26;
    h2 &= _m26;
    h3 += c;
    c = h3 >> 26;
    h3 &= _m26;
    h4 += c;
    c = h4 >> 26;
    h4 &= _m26;
    h0 += c * 5;
    c = h0 >> 26;
    h0 &= _m26;
    h1 += c;

    int g0 = h0 + 5;
    c = g0 >> 26;
    g0 &= _m26;
    int g1 = h1 + c;
    c = g1 >> 26;
    g1 &= _m26;
    int g2 = h2 + c;
    c = g2 >> 26;
    g2 &= _m26;
    int g3 = h3 + c;
    c = g3 >> 26;
    g3 &= _m26;
    final int g4 = h4 + c - (1 << 26);

    // g4 < 0 means h < p, so keep h; otherwise h - p (= g) is the reduced value.
    final int keepH = g4 >> 63;
    h0 = (h0 & keepH) | (g0 & ~keepH);
    h1 = (h1 & keepH) | (g1 & ~keepH);
    h2 = (h2 & keepH) | (g2 & ~keepH);
    h3 = (h3 & keepH) | (g3 & ~keepH);
    h4 = (h4 & keepH) | (g4 & ~keepH);

    final int w0 = (h0 | (h1 << 26)) & _mask32;
    final int w1 = ((h1 >> 6) | (h2 << 20)) & _mask32;
    final int w2 = ((h2 >> 12) | (h3 << 14)) & _mask32;
    final int w3 = ((h3 >> 18) | (h4 << 8)) & _mask32;

    int f = w0 + _pad[0];
    final ByteData out = ByteData(16)..setUint32(0, f & _mask32, Endian.little);
    f = w1 + _pad[1] + (f >> 32);
    out.setUint32(4, f & _mask32, Endian.little);
    f = w2 + _pad[2] + (f >> 32);
    out.setUint32(8, f & _mask32, Endian.little);
    f = w3 + _pad[3] + (f >> 32);
    out.setUint32(12, f & _mask32, Endian.little);
    return out.buffer.asUint8List();
  }
}
