import "dart:convert";
import "dart:math";
import "dart:typed_data";

// =============================================================================
// u_encrypt — zero-dependency cryptography for the `u` plugin. Pure Dart, no
// packages: hashing, HMAC, key derivation, symmetric ciphers (AES with several
// modes, ChaCha20/Salsa20 stream ciphers), authenticated encryption
// (AES-GCM, ChaCha20-Poly1305), Fernet, reversible encoders and classical
// ciphers. Every algorithm is verified against official NIST/RFC test vectors.
//
// SAFETY NOTES
//  * Prefer the authenticated helpers (UEncryption.seal / open, or
//    chacha20Poly1305*) for anything real — they detect tampering. Raw AES-CBC/
//    CTR/ECB and stream ciphers provide confidentiality only.
//  * All key/nonce material comes from Random.secure() (a CSPRNG).
//  * MAC/tag comparison is constant-time.
//  * 32-bit algorithms (MD5, SHA-1, SHA-224/256, HMAC-SHA256, AES, ChaCha20,
//    Salsa20, Poly1305, GCM, PBKDF2/HKDF over SHA-256) are web-safe. SHA-384/512
//    use 64-bit words and are intended for native (mobile/desktop) targets.
//  * This is symmetric crypto only. For RSA/ECC/JWT signing use a vetted native
//    implementation — do not hand-roll asymmetric crypto.
// =============================================================================

/// How a textual secret key / IV should be interpreted as raw bytes.
enum UByteEncoding { utf8, base64, hex }

/// AES block-cipher modes supported by [UEncryption]. `sic` is an alias of
/// `ctr`; the `*64` variants are normalized to their standard 128-bit forms.
enum UAesMode { cbc, cfb64, ctr, ecb, ofb64, ofb64Gctr, sic, gcm }

// ---------------------------------------------------------------------------
// Low-level bit helpers (32-bit, web-safe)
// ---------------------------------------------------------------------------

const int _m32 = 0xFFFFFFFF;

int _rotr32(int x, int n) => ((x >>> n) | (x << (32 - n))) & _m32;

int _rotl32(int x, int n) => ((x << n) | (x >>> (32 - n))) & _m32;

Uint8List _u8(String s) => Uint8List.fromList(utf8.encode(s));

// --- 64-bit arithmetic as (hi, lo) 32-bit record pairs (web/JS-safe) --------
typedef _U64 = (int, int);

const List<int> _sha512KHi = <int>[
  0x428a2f98,
  0x71374491,
  0xb5c0fbcf,
  0xe9b5dba5,
  0x3956c25b,
  0x59f111f1,
  0x923f82a4,
  0xab1c5ed5,
  0xd807aa98,
  0x12835b01,
  0x243185be,
  0x550c7dc3,
  0x72be5d74,
  0x80deb1fe,
  0x9bdc06a7,
  0xc19bf174,
  0xe49b69c1,
  0xefbe4786,
  0x0fc19dc6,
  0x240ca1cc,
  0x2de92c6f,
  0x4a7484aa,
  0x5cb0a9dc,
  0x76f988da,
  0x983e5152,
  0xa831c66d,
  0xb00327c8,
  0xbf597fc7,
  0xc6e00bf3,
  0xd5a79147,
  0x06ca6351,
  0x14292967,
  0x27b70a85,
  0x2e1b2138,
  0x4d2c6dfc,
  0x53380d13,
  0x650a7354,
  0x766a0abb,
  0x81c2c92e,
  0x92722c85,
  0xa2bfe8a1,
  0xa81a664b,
  0xc24b8b70,
  0xc76c51a3,
  0xd192e819,
  0xd6990624,
  0xf40e3585,
  0x106aa070,
  0x19a4c116,
  0x1e376c08,
  0x2748774c,
  0x34b0bcb5,
  0x391c0cb3,
  0x4ed8aa4a,
  0x5b9cca4f,
  0x682e6ff3,
  0x748f82ee,
  0x78a5636f,
  0x84c87814,
  0x8cc70208,
  0x90befffa,
  0xa4506ceb,
  0xbef9a3f7,
  0xc67178f2,
  0xca273ece,
  0xd186b8c7,
  0xeada7dd6,
  0xf57d4f7f,
  0x06f067aa,
  0x0a637dc5,
  0x113f9804,
  0x1b710b35,
  0x28db77f5,
  0x32caab7b,
  0x3c9ebe0a,
  0x431d67c4,
  0x4cc5d4be,
  0x597f299c,
  0x5fcb6fab,
  0x6c44198c,
];
const List<int> _sha512KLo = <int>[
  0xd728ae22,
  0x23ef65cd,
  0xec4d3b2f,
  0x8189dbbc,
  0xf348b538,
  0xb605d019,
  0xaf194f9b,
  0xda6d8118,
  0xa3030242,
  0x45706fbe,
  0x4ee4b28c,
  0xd5ffb4e2,
  0xf27b896f,
  0x3b1696b1,
  0x25c71235,
  0xcf692694,
  0x9ef14ad2,
  0x384f25e3,
  0x8b8cd5b5,
  0x77ac9c65,
  0x592b0275,
  0x6ea6e483,
  0xbd41fbd4,
  0x831153b5,
  0xee66dfab,
  0x2db43210,
  0x98fb213f,
  0xbeef0ee4,
  0x3da88fc2,
  0x930aa725,
  0xe003826f,
  0x0a0e6e70,
  0x46d22ffc,
  0x5c26c926,
  0x5ac42aed,
  0x9d95b3df,
  0x8baf63de,
  0x3c77b2a8,
  0x47edaee6,
  0x1482353b,
  0x4cf10364,
  0xbc423001,
  0xd0f89791,
  0x0654be30,
  0xd6ef5218,
  0x5565a910,
  0x5771202a,
  0x32bbd1b8,
  0xb8d2d0c8,
  0x5141ab53,
  0xdf8eeb99,
  0xe19b48a8,
  0xc5c95a63,
  0xe3418acb,
  0x7763e373,
  0xd6b2b8a3,
  0x5defb2fc,
  0x43172f60,
  0xa1f0ab72,
  0x1a6439ec,
  0x23631e28,
  0xde82bde9,
  0xb2c67915,
  0xe372532b,
  0xea26619c,
  0x21c0c207,
  0xcde0eb1e,
  0xee6ed178,
  0x72176fba,
  0xa2c898a6,
  0xbef90dae,
  0x131c471b,
  0x23047d84,
  0x40c72493,
  0x15c9bebc,
  0x9c100d4c,
  0xcb3e42b6,
  0xfc657e2a,
  0x3ad6faec,
  0x4a475817,
];
const List<int> _sha512IvHi = <int>[0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
const List<int> _sha512IvLo = <int>[0xf3bcc908, 0x84caa73b, 0xfe94f82b, 0x5f1d36f1, 0xade682d1, 0x2b3e6c1f, 0xfb41bd6b, 0x137e2179];
const List<int> _sha384IvHi = <int>[0xcbbb9d5d, 0x629a292a, 0x9159015a, 0x152fecd8, 0x67332667, 0x8eb44a87, 0xdb0c2e0d, 0x47b5481d];
const List<int> _sha384IvLo = <int>[0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939, 0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4];
const List<int> _sha512t256IvHi = <int>[0x22312194, 0x9f555fa3, 0x2393b86b, 0x96387719, 0x96283ee2, 0xbe5e1e25, 0x2b0199fc, 0x0eb72ddc];
const List<int> _sha512t256IvLo = <int>[0xfc2bf72c, 0xc84c64c2, 0x6f53b151, 0x5940eabd, 0xa88effe3, 0x53863992, 0x2c85b8aa, 0x81c52ca2];
const List<int> _keccakRcHi = <int>[
  0x00000000,
  0x00000000,
  0x80000000,
  0x80000000,
  0x00000000,
  0x00000000,
  0x80000000,
  0x80000000,
  0x00000000,
  0x00000000,
  0x00000000,
  0x00000000,
  0x00000000,
  0x80000000,
  0x80000000,
  0x80000000,
  0x80000000,
  0x80000000,
  0x00000000,
  0x80000000,
  0x80000000,
  0x80000000,
  0x00000000,
  0x80000000,
];
const List<int> _keccakRcLo = <int>[
  0x00000001,
  0x00008082,
  0x0000808a,
  0x80008000,
  0x0000808b,
  0x80000001,
  0x80008081,
  0x00008009,
  0x0000008a,
  0x00000088,
  0x80008009,
  0x8000000a,
  0x8000808b,
  0x0000008b,
  0x00008089,
  0x00008003,
  0x00008002,
  0x00000080,
  0x0000800a,
  0x8000000a,
  0x80008081,
  0x00008080,
  0x80000001,
  0x80008008,
];
const List<int> _blakeIvHi = <int>[0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
const List<int> _blakeIvLo = <int>[0xf3bcc908, 0x84caa73b, 0xfe94f82b, 0x5f1d36f1, 0xade682d1, 0x2b3e6c1f, 0xfb41bd6b, 0x137e2179];

_U64 _add64(_U64 a, _U64 b) {
  final int lo = a.$2 + b.$2;
  final int hi = a.$1 + b.$1 + (lo >= 0x100000000 ? 1 : 0);
  return (hi & _m32, lo & _m32);
}

_U64 _xor64(_U64 a, _U64 b) => ((a.$1 ^ b.$1) & _m32, (a.$2 ^ b.$2) & _m32);

_U64 _and64(_U64 a, _U64 b) => ((a.$1 & b.$1) & _m32, (a.$2 & b.$2) & _m32);

_U64 _not64(_U64 a) => ((~a.$1) & _m32, (~a.$2) & _m32);

_U64 _shr64(_U64 a, int n) {
  if (n == 0) return a;
  if (n < 32) return ((a.$1 >>> n) & _m32, ((a.$2 >>> n) | (a.$1 << (32 - n))) & _m32);
  return (0, (a.$1 >>> (n - 32)) & _m32);
}

_U64 _rotr64p(_U64 a, int n) {
  final int m = n & 63;
  if (m == 0) return a;
  if (m == 32) return (a.$2, a.$1);
  if (m < 32) return (((a.$1 >>> m) | (a.$2 << (32 - m))) & _m32, ((a.$2 >>> m) | (a.$1 << (32 - m))) & _m32);
  final int k = m - 32;
  return (((a.$2 >>> k) | (a.$1 << (32 - k))) & _m32, ((a.$1 >>> k) | (a.$2 << (32 - k))) & _m32);
}

_U64 _rotl64p(_U64 a, int n) => _rotr64p(a, 64 - (n & 63));

_U64 _load64BE(Uint8List b, int o) => (((b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3]) & _m32, ((b[o + 4] << 24) | (b[o + 5] << 16) | (b[o + 6] << 8) | b[o + 7]) & _m32);

_U64 _load64LEp(Uint8List b, int o) => (((b[o + 4]) | (b[o + 5] << 8) | (b[o + 6] << 16) | (b[o + 7] << 24)) & _m32, ((b[o]) | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24)) & _m32);

void _store64BE(Uint8List out, int o, _U64 v) {
  out[o] = (v.$1 >>> 24) & 0xFF;
  out[o + 1] = (v.$1 >>> 16) & 0xFF;
  out[o + 2] = (v.$1 >>> 8) & 0xFF;
  out[o + 3] = v.$1 & 0xFF;
  out[o + 4] = (v.$2 >>> 24) & 0xFF;
  out[o + 5] = (v.$2 >>> 16) & 0xFF;
  out[o + 6] = (v.$2 >>> 8) & 0xFF;
  out[o + 7] = v.$2 & 0xFF;
}

void _store64LE(Uint8List out, int o, _U64 v) {
  out[o] = v.$2 & 0xFF;
  out[o + 1] = (v.$2 >>> 8) & 0xFF;
  out[o + 2] = (v.$2 >>> 16) & 0xFF;
  out[o + 3] = (v.$2 >>> 24) & 0xFF;
  out[o + 4] = v.$1 & 0xFF;
  out[o + 5] = (v.$1 >>> 8) & 0xFF;
  out[o + 6] = (v.$1 >>> 16) & 0xFF;
  out[o + 7] = (v.$1 >>> 24) & 0xFF;
}

Uint8List _len64BE(int value) {
  final Uint8List b = Uint8List(8);
  int v = value;
  for (int i = 7; i >= 0; i--) {
    b[i] = v % 256;
    v = v ~/ 256;
  }
  return b;
}

Uint8List _len64LE(int value) {
  final Uint8List b = Uint8List(8);
  int v = value;
  for (int i = 0; i < 8; i++) {
    b[i] = v % 256;
    v = v ~/ 256;
  }
  return b;
}

List<_U64> _ivPairs(List<int> hi, List<int> lo) => List<_U64>.generate(hi.length, (int i) => (hi[i], lo[i]));

// ===========================================================================
// MD5
// ===========================================================================

final List<int> _md5S = <int>[
  7,
  12,
  17,
  22,
  7,
  12,
  17,
  22,
  7,
  12,
  17,
  22,
  7,
  12,
  17,
  22,
  5,
  9,
  14,
  20,
  5,
  9,
  14,
  20,
  5,
  9,
  14,
  20,
  5,
  9,
  14,
  20,
  4,
  11,
  16,
  23,
  4,
  11,
  16,
  23,
  4,
  11,
  16,
  23,
  4,
  11,
  16,
  23,
  6,
  10,
  15,
  21,
  6,
  10,
  15,
  21,
  6,
  10,
  15,
  21,
  6,
  10,
  15,
  21,
];

final List<int> _md5K = List<int>.generate(64, (int i) => (4294967296 * sin(i + 1).abs()).floor() & _m32);

Uint8List _md5(Uint8List msg) {
  final int origLen = msg.length;
  final int bitLen = origLen * 8;
  final int padLen = (56 - (origLen + 1) % 64) % 64;
  final BytesBuilder bb = BytesBuilder()
    ..add(msg)
    ..addByte(0x80)
    ..add(Uint8List(padLen));
  bb.add(_len64LE(bitLen));
  final Uint8List data = bb.toBytes();

  int a0 = 0x67452301;
  int b0 = 0xefcdab89;
  int c0 = 0x98badcfe;
  int d0 = 0x10325476;
  final ByteData view = ByteData.sublistView(data);
  for (int off = 0; off < data.length; off += 64) {
    final List<int> mBlk = List<int>.generate(16, (int i) => view.getUint32(off + i * 4, Endian.little));
    int a = a0;
    int b = b0;
    int c = c0;
    int d = d0;
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
        f = c ^ (b | (~d & _m32));
        g = (7 * i) % 16;
      }
      f = (f + a + _md5K[i] + mBlk[g]) & _m32;
      a = d;
      d = c;
      c = b;
      b = (b + _rotl32(f, _md5S[i])) & _m32;
    }
    a0 = (a0 + a) & _m32;
    b0 = (b0 + b) & _m32;
    c0 = (c0 + c) & _m32;
    d0 = (d0 + d) & _m32;
  }
  final ByteData out = ByteData(16)
    ..setUint32(0, a0, Endian.little)
    ..setUint32(4, b0, Endian.little)
    ..setUint32(8, c0, Endian.little)
    ..setUint32(12, d0, Endian.little);
  return out.buffer.asUint8List();
}

// ===========================================================================
// SHA-1
// ===========================================================================

Uint8List _sha1(Uint8List msg) {
  final Uint8List data = _padBE(msg);
  int h0 = 0x67452301;
  int h1 = 0xEFCDAB89;
  int h2 = 0x98BADCFE;
  int h3 = 0x10325476;
  int h4 = 0xC3D2E1F0;
  final ByteData view = ByteData.sublistView(data);
  final List<int> w = List<int>.filled(80, 0);
  for (int off = 0; off < data.length; off += 64) {
    for (int i = 0; i < 16; i++) {
      w[i] = view.getUint32(off + i * 4);
    }
    for (int i = 16; i < 80; i++) {
      w[i] = _rotl32(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
    }
    int a = h0;
    int b = h1;
    int c = h2;
    int d = h3;
    int e = h4;
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
      final int tmp = (_rotl32(a, 5) + f + e + k + w[i]) & _m32;
      e = d;
      d = c;
      c = _rotl32(b, 30);
      b = a;
      a = tmp;
    }
    h0 = (h0 + a) & _m32;
    h1 = (h1 + b) & _m32;
    h2 = (h2 + c) & _m32;
    h3 = (h3 + d) & _m32;
    h4 = (h4 + e) & _m32;
  }
  final ByteData out = ByteData(20)
    ..setUint32(0, h0)
    ..setUint32(4, h1)
    ..setUint32(8, h2)
    ..setUint32(12, h3)
    ..setUint32(16, h4);
  return out.buffer.asUint8List();
}

// ===========================================================================
// SHA-224 / SHA-256
// ===========================================================================

const List<int> _sha256K = <int>[
  0x428a2f98,
  0x71374491,
  0xb5c0fbcf,
  0xe9b5dba5,
  0x3956c25b,
  0x59f111f1,
  0x923f82a4,
  0xab1c5ed5,
  0xd807aa98,
  0x12835b01,
  0x243185be,
  0x550c7dc3,
  0x72be5d74,
  0x80deb1fe,
  0x9bdc06a7,
  0xc19bf174,
  0xe49b69c1,
  0xefbe4786,
  0x0fc19dc6,
  0x240ca1cc,
  0x2de92c6f,
  0x4a7484aa,
  0x5cb0a9dc,
  0x76f988da,
  0x983e5152,
  0xa831c66d,
  0xb00327c8,
  0xbf597fc7,
  0xc6e00bf3,
  0xd5a79147,
  0x06ca6351,
  0x14292967,
  0x27b70a85,
  0x2e1b2138,
  0x4d2c6dfc,
  0x53380d13,
  0x650a7354,
  0x766a0abb,
  0x81c2c92e,
  0x92722c85,
  0xa2bfe8a1,
  0xa81a664b,
  0xc24b8b70,
  0xc76c51a3,
  0xd192e819,
  0xd6990624,
  0xf40e3585,
  0x106aa070,
  0x19a4c116,
  0x1e376c08,
  0x2748774c,
  0x34b0bcb5,
  0x391c0cb3,
  0x4ed8aa4a,
  0x5b9cca4f,
  0x682e6ff3,
  0x748f82ee,
  0x78a5636f,
  0x84c87814,
  0x8cc70208,
  0x90befffa,
  0xa4506ceb,
  0xbef9a3f7,
  0xc67178f2,
];

Uint8List _sha256Core(Uint8List msg, List<int> h0, int outBytes) {
  final Uint8List data = _padBE(msg);
  final List<int> h = List<int>.of(h0);
  final ByteData view = ByteData.sublistView(data);
  final List<int> w = List<int>.filled(64, 0);
  for (int off = 0; off < data.length; off += 64) {
    for (int i = 0; i < 16; i++) {
      w[i] = view.getUint32(off + i * 4);
    }
    for (int i = 16; i < 64; i++) {
      final int s0 = _rotr32(w[i - 15], 7) ^ _rotr32(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      final int s1 = _rotr32(w[i - 2], 17) ^ _rotr32(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _m32;
    }
    int a = h[0];
    int b = h[1];
    int c = h[2];
    int d = h[3];
    int e = h[4];
    int f = h[5];
    int g = h[6];
    int hh = h[7];
    for (int i = 0; i < 64; i++) {
      final int s1 = _rotr32(e, 6) ^ _rotr32(e, 11) ^ _rotr32(e, 25);
      final int ch = (e & f) ^ (~e & g);
      final int t1 = (hh + s1 + ch + _sha256K[i] + w[i]) & _m32;
      final int s0 = _rotr32(a, 2) ^ _rotr32(a, 13) ^ _rotr32(a, 22);
      final int maj = (a & b) ^ (a & c) ^ (b & c);
      final int t2 = (s0 + maj) & _m32;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & _m32;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & _m32;
    }
    h[0] = (h[0] + a) & _m32;
    h[1] = (h[1] + b) & _m32;
    h[2] = (h[2] + c) & _m32;
    h[3] = (h[3] + d) & _m32;
    h[4] = (h[4] + e) & _m32;
    h[5] = (h[5] + f) & _m32;
    h[6] = (h[6] + g) & _m32;
    h[7] = (h[7] + hh) & _m32;
  }
  final ByteData out = ByteData(32);
  for (int i = 0; i < 8; i++) {
    out.setUint32(i * 4, h[i]);
  }
  return out.buffer.asUint8List().sublist(0, outBytes);
}

Uint8List _sha256(Uint8List msg) => _sha256Core(msg, <int>[0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19], 32);

Uint8List _sha224(Uint8List msg) => _sha256Core(msg, <int>[0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939, 0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4], 28);

// Big-endian length padding shared by SHA-1/224/256.
Uint8List _padBE(Uint8List msg) {
  final int bitLen = msg.length * 8;
  final int padLen = (56 - (msg.length + 1) % 64) % 64;
  final BytesBuilder bb = BytesBuilder()
    ..add(msg)
    ..addByte(0x80)
    ..add(Uint8List(padLen));
  bb.add(_len64BE(bitLen));
  return bb.toBytes();
}

// ===========================================================================
// SHA-384 / SHA-512 (64-bit; native targets)
// ===========================================================================

Uint8List _sha512Core(Uint8List msg, List<_U64> h0, int outBytes) {
  final int msgBits = msg.length * 8;
  final int padLen = (112 - (msg.length + 1) % 128) % 128;
  final BytesBuilder bb = BytesBuilder()
    ..add(msg)
    ..addByte(0x80)
    ..add(Uint8List(padLen))
    ..add(Uint8List(8))
    ..add(_len64BE(msgBits));
  final Uint8List data = bb.toBytes();
  final List<_U64> h = List<_U64>.of(h0);
  final List<_U64> w = List<_U64>.filled(80, (0, 0));
  for (int off = 0; off < data.length; off += 128) {
    for (int i = 0; i < 16; i++) {
      w[i] = _load64BE(data, off + i * 8);
    }
    for (int i = 16; i < 80; i++) {
      final _U64 s0 = _xor64(_xor64(_rotr64p(w[i - 15], 1), _rotr64p(w[i - 15], 8)), _shr64(w[i - 15], 7));
      final _U64 s1 = _xor64(_xor64(_rotr64p(w[i - 2], 19), _rotr64p(w[i - 2], 61)), _shr64(w[i - 2], 6));
      w[i] = _add64(_add64(w[i - 16], s0), _add64(w[i - 7], s1));
    }
    _U64 a = h[0];
    _U64 b = h[1];
    _U64 c = h[2];
    _U64 d = h[3];
    _U64 e = h[4];
    _U64 f = h[5];
    _U64 g = h[6];
    _U64 hh = h[7];
    for (int i = 0; i < 80; i++) {
      final _U64 s1 = _xor64(_xor64(_rotr64p(e, 14), _rotr64p(e, 18)), _rotr64p(e, 41));
      final _U64 ch = _xor64(_and64(e, f), _and64(_not64(e), g));
      final _U64 t1 = _add64(_add64(_add64(hh, s1), _add64(ch, (_sha512KHi[i], _sha512KLo[i]))), w[i]);
      final _U64 s0 = _xor64(_xor64(_rotr64p(a, 28), _rotr64p(a, 34)), _rotr64p(a, 39));
      final _U64 maj = _xor64(_xor64(_and64(a, b), _and64(a, c)), _and64(b, c));
      final _U64 t2 = _add64(s0, maj);
      hh = g;
      g = f;
      f = e;
      e = _add64(d, t1);
      d = c;
      c = b;
      b = a;
      a = _add64(t1, t2);
    }
    h[0] = _add64(h[0], a);
    h[1] = _add64(h[1], b);
    h[2] = _add64(h[2], c);
    h[3] = _add64(h[3], d);
    h[4] = _add64(h[4], e);
    h[5] = _add64(h[5], f);
    h[6] = _add64(h[6], g);
    h[7] = _add64(h[7], hh);
  }
  final Uint8List out = Uint8List(64);
  for (int i = 0; i < 8; i++) {
    _store64BE(out, i * 8, h[i]);
  }
  return Uint8List.fromList(out.sublist(0, outBytes));
}

Uint8List _sha512(Uint8List msg) => _sha512Core(msg, _ivPairs(_sha512IvHi, _sha512IvLo), 64);

Uint8List _sha384(Uint8List msg) => _sha512Core(msg, _ivPairs(_sha384IvHi, _sha384IvLo), 48);

// ===========================================================================
// HMAC + KDF (PBKDF2, HKDF)
// ===========================================================================

typedef _HashFn = Uint8List Function(Uint8List);

int _blockSize(_HashFn h) => (h == _sha512 || h == _sha384) ? 128 : 64;

Uint8List _hmac(_HashFn hash, Uint8List key, Uint8List msg) {
  final int block = _blockSize(hash);
  Uint8List k = key.length > block ? hash(key) : key;
  if (k.length < block) {
    final Uint8List padded = Uint8List(block)..setRange(0, k.length, k);
    k = padded;
  }
  final Uint8List oKey = Uint8List(block);
  final Uint8List iKey = Uint8List(block);
  for (int i = 0; i < block; i++) {
    oKey[i] = k[i] ^ 0x5c;
    iKey[i] = k[i] ^ 0x36;
  }
  final Uint8List inner = hash(_concat(<Uint8List>[iKey, msg]));
  return hash(_concat(<Uint8List>[oKey, inner]));
}

Uint8List _pbkdf2(_HashFn hash, Uint8List password, Uint8List salt, int iterations, int dkLen) {
  final int hLen = hash(Uint8List(0)).length;
  final int blocks = (dkLen / hLen).ceil();
  final BytesBuilder out = BytesBuilder();
  for (int i = 1; i <= blocks; i++) {
    final Uint8List intBlock = Uint8List(4)..buffer.asByteData().setUint32(0, i);
    Uint8List u = _hmac(hash, password, _concat(<Uint8List>[salt, intBlock]));
    final Uint8List t = Uint8List.fromList(u);
    for (int j = 1; j < iterations; j++) {
      u = _hmac(hash, password, u);
      for (int k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }
    out.add(t);
  }
  return out.toBytes().sublist(0, dkLen);
}

Uint8List _hkdf(_HashFn hash, Uint8List ikm, Uint8List salt, Uint8List info, int length) {
  final int hLen = hash(Uint8List(0)).length;
  final Uint8List prk = _hmac(hash, salt.isEmpty ? Uint8List(hLen) : salt, ikm);
  final BytesBuilder okm = BytesBuilder();
  Uint8List previous = Uint8List(0);
  int counter = 1;
  while (okm.length < length) {
    previous = _hmac(
      hash,
      prk,
      _concat(<Uint8List>[
        previous,
        info,
        Uint8List.fromList(<int>[counter]),
      ]),
    );
    okm.add(previous);
    counter++;
  }
  return okm.toBytes().sublist(0, length);
}

// ---------------------------------------------------------------------------
// Byte utilities
// ---------------------------------------------------------------------------

Uint8List _concat(List<Uint8List> parts) {
  final BytesBuilder bb = BytesBuilder();
  for (final Uint8List p in parts) {
    bb.add(p);
  }
  return bb.toBytes();
}

final Random _rng = Random.secure();

Uint8List _randomBytes(int n) => Uint8List.fromList(List<int>.generate(n, (int _) => _rng.nextInt(256)));

bool _ctEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  int diff = 0;
  for (int i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

String _toHex(List<int> bytes) => bytes.map((int b) => b.toRadixString(16).padLeft(2, "0")).join();

Uint8List _fromHex(String hex) {
  final String clean = hex.replaceAll(RegExp(r"\s"), "");
  if (clean.length.isOdd) throw const FormatException("Hex length must be even.");
  return Uint8List.fromList(<int>[for (int i = 0; i < clean.length; i += 2) int.parse(clean.substring(i, i + 2), radix: 16)]);
}

// ===========================================================================
// AES (128/192/256) — byte-oriented core with CBC/ECB/CTR/CFB/OFB + GCM
// ===========================================================================

int _rotl8(int x, int n) => ((x << n) | (x >>> (8 - n))) & 0xFF;

Uint8List _buildSbox() {
  final Uint8List box = Uint8List(256);
  int p = 1;
  int q = 1;
  do {
    p = (p ^ ((p << 1) & 0xFF) ^ (((p >> 7) & 1) * 0x1B)) & 0xFF;
    q ^= (q << 1) & 0xFF;
    q ^= (q << 2) & 0xFF;
    q ^= (q << 4) & 0xFF;
    q &= 0xFF;
    if ((q & 0x80) != 0) q ^= 0x09;
    q &= 0xFF;
    final int x = q ^ _rotl8(q, 1) ^ _rotl8(q, 2) ^ _rotl8(q, 3) ^ _rotl8(q, 4);
    box[p] = (x ^ 0x63) & 0xFF;
  } while (p != 1);
  box[0] = 0x63;
  return box;
}

final Uint8List _sbox = _buildSbox();
final Uint8List _invSbox = _buildInvSbox();

Uint8List _buildInvSbox() {
  final Uint8List inv = Uint8List(256);
  for (int i = 0; i < 256; i++) {
    inv[_sbox[i]] = i;
  }
  return inv;
}

int _xtime(int x) => ((x << 1) ^ (((x >> 7) & 1) * 0x1B)) & 0xFF;

int _gmul(int a, int b) {
  int p = 0;
  int aa = a;
  int bb = b;
  for (int i = 0; i < 8; i++) {
    if ((bb & 1) != 0) p ^= aa;
    final bool hi = (aa & 0x80) != 0;
    aa = (aa << 1) & 0xFF;
    if (hi) aa ^= 0x1B;
    bb >>= 1;
  }
  return p & 0xFF;
}

Uint8List _expandKey(Uint8List key) {
  final int nk = key.length ~/ 4;
  final int nr = nk + 6;
  final int total = 16 * (nr + 1);
  final Uint8List w = Uint8List(total)..setRange(0, key.length, key);
  int rcon = 1;
  for (int i = key.length; i < total; i += 4) {
    final List<int> t = <int>[w[i - 4], w[i - 3], w[i - 2], w[i - 1]];
    if (i % key.length == 0) {
      final int tmp = t[0];
      t[0] = _sbox[t[1]] ^ rcon;
      t[1] = _sbox[t[2]];
      t[2] = _sbox[t[3]];
      t[3] = _sbox[tmp];
      rcon = _xtime(rcon);
    } else if (nk > 6 && i % key.length == 16) {
      for (int j = 0; j < 4; j++) {
        t[j] = _sbox[t[j]];
      }
    }
    for (int j = 0; j < 4; j++) {
      w[i + j] = w[i - key.length + j] ^ t[j];
    }
  }
  return w;
}

Uint8List _aesEncBlock(Uint8List input, Uint8List w, int nr) {
  final Uint8List s = Uint8List.fromList(input);
  _addRoundKey(s, w, 0);
  for (int r = 1; r < nr; r++) {
    _subBytes(s, _sbox);
    _shiftRows(s, false);
    _mixColumns(s);
    _addRoundKey(s, w, r);
  }
  _subBytes(s, _sbox);
  _shiftRows(s, false);
  _addRoundKey(s, w, nr);
  return s;
}

Uint8List _aesDecBlock(Uint8List input, Uint8List w, int nr) {
  final Uint8List s = Uint8List.fromList(input);
  _addRoundKey(s, w, nr);
  for (int r = nr - 1; r >= 1; r--) {
    _shiftRows(s, true);
    _subBytes(s, _invSbox);
    _addRoundKey(s, w, r);
    _invMixColumns(s);
  }
  _shiftRows(s, true);
  _subBytes(s, _invSbox);
  _addRoundKey(s, w, 0);
  return s;
}

void _addRoundKey(Uint8List s, Uint8List w, int round) {
  final int base = round * 16;
  for (int i = 0; i < 16; i++) {
    s[i] ^= w[base + i];
  }
}

void _subBytes(Uint8List s, Uint8List box) {
  for (int i = 0; i < 16; i++) {
    s[i] = box[s[i]];
  }
}

void _shiftRows(Uint8List s, bool inverse) {
  final Uint8List t = Uint8List.fromList(s);
  for (int r = 1; r < 4; r++) {
    for (int c = 0; c < 4; c++) {
      final int src = inverse ? (c - r + 4) % 4 : (c + r) % 4;
      s[r + 4 * c] = t[r + 4 * src];
    }
  }
}

void _mixColumns(Uint8List s) {
  for (int c = 0; c < 4; c++) {
    final int i = 4 * c;
    final int a0 = s[i];
    final int a1 = s[i + 1];
    final int a2 = s[i + 2];
    final int a3 = s[i + 3];
    s[i] = _xtime(a0) ^ (_xtime(a1) ^ a1) ^ a2 ^ a3;
    s[i + 1] = a0 ^ _xtime(a1) ^ (_xtime(a2) ^ a2) ^ a3;
    s[i + 2] = a0 ^ a1 ^ _xtime(a2) ^ (_xtime(a3) ^ a3);
    s[i + 3] = (_xtime(a0) ^ a0) ^ a1 ^ a2 ^ _xtime(a3);
  }
}

void _invMixColumns(Uint8List s) {
  for (int c = 0; c < 4; c++) {
    final int i = 4 * c;
    final int a0 = s[i];
    final int a1 = s[i + 1];
    final int a2 = s[i + 2];
    final int a3 = s[i + 3];
    s[i] = _gmul(a0, 14) ^ _gmul(a1, 11) ^ _gmul(a2, 13) ^ _gmul(a3, 9);
    s[i + 1] = _gmul(a0, 9) ^ _gmul(a1, 14) ^ _gmul(a2, 11) ^ _gmul(a3, 13);
    s[i + 2] = _gmul(a0, 13) ^ _gmul(a1, 9) ^ _gmul(a2, 14) ^ _gmul(a3, 11);
    s[i + 3] = _gmul(a0, 11) ^ _gmul(a1, 13) ^ _gmul(a2, 9) ^ _gmul(a3, 14);
  }
}

Uint8List _pkcs7Pad(Uint8List d) {
  final int p = 16 - (d.length % 16);
  return _concat(<Uint8List>[d, Uint8List(p)..fillRange(0, p, p)]);
}

Uint8List _pkcs7Unpad(Uint8List d) {
  if (d.isEmpty) return d;
  final int p = d.last;
  if (p < 1 || p > 16 || p > d.length) throw const FormatException("Invalid PKCS7 padding.");
  return d.sublist(0, d.length - p);
}

void _incFull(Uint8List c) {
  for (int i = 15; i >= 0; i--) {
    c[i] = (c[i] + 1) & 0xFF;
    if (c[i] != 0) break;
  }
}

void _inc32(Uint8List c) {
  for (int i = 15; i >= 12; i--) {
    c[i] = (c[i] + 1) & 0xFF;
    if (c[i] != 0) break;
  }
}

Uint8List _aesEcb(Uint8List key, Uint8List data, bool encrypt, bool pad) {
  final Uint8List w = _expandKey(key);
  final int nr = key.length ~/ 4 + 6;
  final Uint8List input = encrypt && pad ? _pkcs7Pad(data) : data;
  final Uint8List out = Uint8List(input.length);
  for (int off = 0; off < input.length; off += 16) {
    final Uint8List block = input.sublist(off, off + 16);
    final Uint8List r = encrypt ? _aesEncBlock(block, w, nr) : _aesDecBlock(block, w, nr);
    out.setRange(off, off + 16, r);
  }
  return encrypt ? out : (pad ? _pkcs7Unpad(out) : out);
}

Uint8List _aesCbc(Uint8List key, Uint8List iv, Uint8List data, bool encrypt, bool pad) {
  final Uint8List w = _expandKey(key);
  final int nr = key.length ~/ 4 + 6;
  if (encrypt) {
    final Uint8List input = pad ? _pkcs7Pad(data) : data;
    final Uint8List out = Uint8List(input.length);
    Uint8List prev = iv;
    for (int off = 0; off < input.length; off += 16) {
      final Uint8List block = Uint8List(16);
      for (int j = 0; j < 16; j++) {
        block[j] = input[off + j] ^ prev[j];
      }
      final Uint8List enc = _aesEncBlock(block, w, nr);
      out.setRange(off, off + 16, enc);
      prev = enc;
    }
    return out;
  }
  final Uint8List out = Uint8List(data.length);
  Uint8List prev = iv;
  for (int off = 0; off < data.length; off += 16) {
    final Uint8List block = data.sublist(off, off + 16);
    final Uint8List dec = _aesDecBlock(block, w, nr);
    for (int j = 0; j < 16; j++) {
      out[off + j] = dec[j] ^ prev[j];
    }
    prev = block;
  }
  return pad ? _pkcs7Unpad(out) : out;
}

Uint8List _aesCtr(Uint8List key, Uint8List iv, Uint8List data) {
  final Uint8List w = _expandKey(key);
  final int nr = key.length ~/ 4 + 6;
  final Uint8List ctr = Uint8List.fromList(iv);
  final Uint8List out = Uint8List(data.length);
  for (int off = 0; off < data.length; off += 16) {
    final Uint8List ks = _aesEncBlock(ctr, w, nr);
    final int n = min(16, data.length - off);
    for (int j = 0; j < n; j++) {
      out[off + j] = data[off + j] ^ ks[j];
    }
    _incFull(ctr);
  }
  return out;
}

Uint8List _aesCfb(Uint8List key, Uint8List iv, Uint8List data, bool encrypt) {
  final Uint8List w = _expandKey(key);
  final int nr = key.length ~/ 4 + 6;
  Uint8List prev = Uint8List.fromList(iv);
  final Uint8List out = Uint8List(data.length);
  for (int off = 0; off < data.length; off += 16) {
    final Uint8List ks = _aesEncBlock(prev, w, nr);
    final int n = min(16, data.length - off);
    final Uint8List block = Uint8List(16);
    for (int j = 0; j < n; j++) {
      out[off + j] = data[off + j] ^ ks[j];
      block[j] = encrypt ? out[off + j] : data[off + j];
    }
    prev = block;
  }
  return out;
}

Uint8List _aesOfb(Uint8List key, Uint8List iv, Uint8List data) {
  final Uint8List w = _expandKey(key);
  final int nr = key.length ~/ 4 + 6;
  Uint8List feedback = Uint8List.fromList(iv);
  final Uint8List out = Uint8List(data.length);
  for (int off = 0; off < data.length; off += 16) {
    feedback = _aesEncBlock(feedback, w, nr);
    final int n = min(16, data.length - off);
    for (int j = 0; j < n; j++) {
      out[off + j] = data[off + j] ^ feedback[j];
    }
  }
  return out;
}

// --- GHASH / GCM -----------------------------------------------------------

Uint8List _gfMul(Uint8List x, Uint8List y) {
  final Uint8List z = Uint8List(16);
  final Uint8List v = Uint8List.fromList(y);
  for (int i = 0; i < 128; i++) {
    if (((x[i >> 3] >> (7 - (i & 7))) & 1) != 0) {
      for (int j = 0; j < 16; j++) {
        z[j] ^= v[j];
      }
    }
    final int lsb = v[15] & 1;
    for (int j = 15; j > 0; j--) {
      v[j] = ((v[j] >> 1) | ((v[j - 1] & 1) << 7)) & 0xFF;
    }
    v[0] = v[0] >> 1;
    if (lsb != 0) v[0] ^= 0xE1;
  }
  return z;
}

Uint8List _ghash(Uint8List h, Uint8List data) {
  Uint8List y = Uint8List(16);
  for (int off = 0; off < data.length; off += 16) {
    final int n = min(16, data.length - off);
    for (int j = 0; j < n; j++) {
      y[j] ^= data[off + j];
    }
    y = _gfMul(y, h);
  }
  return y;
}

Uint8List _lenBlock(int aadBits, int cBits) => _concat(<Uint8List>[_len64BE(aadBits), _len64BE(cBits)]);

/// Returns ciphertext concatenated with the 16-byte tag.
Uint8List _aesGcmEncrypt(Uint8List key, Uint8List nonce, Uint8List plain, Uint8List aad) {
  final Uint8List w = _expandKey(key);
  final int nr = key.length ~/ 4 + 6;
  final Uint8List h = _aesEncBlock(Uint8List(16), w, nr);
  final Uint8List j0 = _deriveJ0(h, nonce);
  final Uint8List counter = Uint8List.fromList(j0)..[15] = j0[15];
  _inc32(counter);
  final Uint8List cipher = _gctr(w, nr, counter, plain);
  final Uint8List s = _ghash(h, _concat(<Uint8List>[_padBlock(aad), _padBlock(cipher), _lenBlock(aad.length * 8, cipher.length * 8)]));
  final Uint8List ej0 = _aesEncBlock(j0, w, nr);
  final Uint8List tag = Uint8List(16);
  for (int i = 0; i < 16; i++) {
    tag[i] = s[i] ^ ej0[i];
  }
  return _concat(<Uint8List>[cipher, tag]);
}

Uint8List _aesGcmDecrypt(Uint8List key, Uint8List nonce, Uint8List cipherAndTag, Uint8List aad) {
  if (cipherAndTag.length < 16) throw const FormatException("GCM input too short.");
  final Uint8List w = _expandKey(key);
  final int nr = key.length ~/ 4 + 6;
  final Uint8List cipher = cipherAndTag.sublist(0, cipherAndTag.length - 16);
  final Uint8List tag = cipherAndTag.sublist(cipherAndTag.length - 16);
  final Uint8List h = _aesEncBlock(Uint8List(16), w, nr);
  final Uint8List j0 = _deriveJ0(h, nonce);
  final Uint8List s = _ghash(h, _concat(<Uint8List>[_padBlock(aad), _padBlock(cipher), _lenBlock(aad.length * 8, cipher.length * 8)]));
  final Uint8List ej0 = _aesEncBlock(j0, w, nr);
  final Uint8List expected = Uint8List(16);
  for (int i = 0; i < 16; i++) {
    expected[i] = s[i] ^ ej0[i];
  }
  if (!_ctEquals(expected, tag)) throw const FormatException("GCM authentication failed.");
  final Uint8List counter = Uint8List.fromList(j0);
  _inc32(counter);
  return _gctr(w, nr, counter, cipher);
}

Uint8List _deriveJ0(Uint8List h, Uint8List nonce) {
  if (nonce.length == 12) {
    return _concat(<Uint8List>[
      nonce,
      Uint8List.fromList(<int>[0, 0, 0, 1]),
    ]);
  }
  return _ghash(h, _concat(<Uint8List>[_padBlock(nonce), _lenBlock(0, nonce.length * 8)]));
}

Uint8List _gctr(Uint8List w, int nr, Uint8List startCounter, Uint8List data) {
  final Uint8List ctr = Uint8List.fromList(startCounter);
  final Uint8List out = Uint8List(data.length);
  for (int off = 0; off < data.length; off += 16) {
    final Uint8List ks = _aesEncBlock(ctr, w, nr);
    final int n = min(16, data.length - off);
    for (int j = 0; j < n; j++) {
      out[off + j] = data[off + j] ^ ks[j];
    }
    _inc32(ctr);
  }
  return out;
}

Uint8List _padBlock(Uint8List d) {
  if (d.length % 16 == 0) return d;
  final int pad = 16 - (d.length % 16);
  return _concat(<Uint8List>[d, Uint8List(pad)]);
}

// ===========================================================================
// ChaCha20 + Poly1305 (RFC 8439) — all web-safe
// ===========================================================================

void _chachaQr(Uint32List x, int a, int b, int c, int d) {
  x[a] = (x[a] + x[b]) & _m32;
  x[d] = _rotl32(x[d] ^ x[a], 16);
  x[c] = (x[c] + x[d]) & _m32;
  x[b] = _rotl32(x[b] ^ x[c], 12);
  x[a] = (x[a] + x[b]) & _m32;
  x[d] = _rotl32(x[d] ^ x[a], 8);
  x[c] = (x[c] + x[d]) & _m32;
  x[b] = _rotl32(x[b] ^ x[c], 7);
}

Uint8List _chachaBlock(Uint32List key8, int counter, Uint32List nonce3) {
  final Uint32List s = Uint32List(16);
  s[0] = 0x61707865;
  s[1] = 0x3320646e;
  s[2] = 0x79622d32;
  s[3] = 0x6b206574;
  for (int i = 0; i < 8; i++) {
    s[4 + i] = key8[i];
  }
  s[12] = counter & _m32;
  s[13] = nonce3[0];
  s[14] = nonce3[1];
  s[15] = nonce3[2];
  final Uint32List x = Uint32List.fromList(s);
  for (int i = 0; i < 10; i++) {
    _chachaQr(x, 0, 4, 8, 12);
    _chachaQr(x, 1, 5, 9, 13);
    _chachaQr(x, 2, 6, 10, 14);
    _chachaQr(x, 3, 7, 11, 15);
    _chachaQr(x, 0, 5, 10, 15);
    _chachaQr(x, 1, 6, 11, 12);
    _chachaQr(x, 2, 7, 8, 13);
    _chachaQr(x, 3, 4, 9, 14);
  }
  final Uint8List out = Uint8List(64);
  final ByteData bd = ByteData.sublistView(out);
  for (int i = 0; i < 16; i++) {
    bd.setUint32(i * 4, (x[i] + s[i]) & _m32, Endian.little);
  }
  return out;
}

Uint8List _chacha20(Uint8List key32, Uint8List nonce12, int counter, Uint8List data) {
  final Uint32List key8 = Uint32List(8);
  final ByteData kb = ByteData.sublistView(key32);
  for (int i = 0; i < 8; i++) {
    key8[i] = kb.getUint32(i * 4, Endian.little);
  }
  final Uint32List non3 = Uint32List(3);
  final ByteData nb = ByteData.sublistView(nonce12);
  for (int i = 0; i < 3; i++) {
    non3[i] = nb.getUint32(i * 4, Endian.little);
  }
  final Uint8List out = Uint8List(data.length);
  int ctr = counter;
  for (int off = 0; off < data.length; off += 64) {
    final Uint8List ks = _chachaBlock(key8, ctr, non3);
    ctr++;
    final int n = min(64, data.length - off);
    for (int j = 0; j < n; j++) {
      out[off + j] = data[off + j] ^ ks[j];
    }
  }
  return out;
}

void _add1305(List<int> h, List<int> c) {
  int u = 0;
  for (int j = 0; j < 17; j++) {
    u += h[j] + c[j];
    h[j] = u & 255;
    u >>= 8;
  }
}

const List<int> _minusp = <int>[5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 252];

Uint8List _poly1305(Uint8List m, Uint8List key32) {
  final List<int> r = List<int>.filled(17, 0);
  final List<int> h = List<int>.filled(17, 0);
  final List<int> c = List<int>.filled(17, 0);
  final List<int> g = List<int>.filled(17, 0);
  final List<int> x = List<int>.filled(17, 0);
  for (int j = 0; j < 16; j++) {
    r[j] = key32[j];
  }
  r[3] &= 15;
  r[4] &= 252;
  r[7] &= 15;
  r[8] &= 252;
  r[11] &= 15;
  r[12] &= 252;
  r[15] &= 15;

  int n = m.length;
  int off = 0;
  while (n > 0) {
    for (int j = 0; j < 17; j++) {
      c[j] = 0;
    }
    int j = 0;
    for (; j < 16 && j < n; j++) {
      c[j] = m[off + j];
    }
    c[j] = 1;
    off += j;
    n -= j;
    _add1305(h, c);
    for (int i = 0; i < 17; i++) {
      x[i] = 0;
      for (int k = 0; k < 17; k++) {
        x[i] += h[k] * ((k <= i) ? r[i - k] : 320 * r[i + 17 - k]);
      }
    }
    for (int i = 0; i < 17; i++) {
      h[i] = x[i];
    }
    int u = 0;
    for (int j2 = 0; j2 < 16; j2++) {
      u += h[j2];
      h[j2] = u & 255;
      u >>= 8;
    }
    u += h[16];
    h[16] = u & 3;
    u = 5 * (u >> 2);
    for (int j2 = 0; j2 < 16; j2++) {
      u += h[j2];
      h[j2] = u & 255;
      u >>= 8;
    }
    u += h[16];
    h[16] = u;
  }
  for (int j = 0; j < 17; j++) {
    g[j] = h[j];
  }
  _add1305(h, _minusp);
  final int s = ((h[16] >> 7) & 1) == 1 ? 0xFFFFFFFF : 0;
  for (int j = 0; j < 17; j++) {
    h[j] ^= s & (g[j] ^ h[j]);
  }
  for (int j = 0; j < 16; j++) {
    c[j] = key32[j + 16];
  }
  c[16] = 0;
  _add1305(h, c);
  final Uint8List out = Uint8List(16);
  for (int j = 0; j < 16; j++) {
    out[j] = h[j];
  }
  return out;
}

Uint8List _pad16(Uint8List d) {
  final int rem = d.length % 16;
  return rem == 0 ? Uint8List(0) : Uint8List(16 - rem);
}

Uint8List _le64(int value) => _len64LE(value);

/// Returns ciphertext concatenated with the 16-byte Poly1305 tag.
Uint8List _chachaPolyEncrypt(Uint8List key32, Uint8List nonce12, Uint8List plain, Uint8List aad) {
  final Uint8List otk = _chacha20(key32, nonce12, 0, Uint8List(32));
  final Uint8List cipher = _chacha20(key32, nonce12, 1, plain);
  final Uint8List macData = _concat(<Uint8List>[aad, _pad16(aad), cipher, _pad16(cipher), _le64(aad.length), _le64(cipher.length)]);
  final Uint8List tag = _poly1305(macData, otk);
  return _concat(<Uint8List>[cipher, tag]);
}

Uint8List _chachaPolyDecrypt(Uint8List key32, Uint8List nonce12, Uint8List cipherAndTag, Uint8List aad) {
  if (cipherAndTag.length < 16) throw const FormatException("AEAD input too short.");
  final Uint8List cipher = cipherAndTag.sublist(0, cipherAndTag.length - 16);
  final Uint8List tag = cipherAndTag.sublist(cipherAndTag.length - 16);
  final Uint8List otk = _chacha20(key32, nonce12, 0, Uint8List(32));
  final Uint8List macData = _concat(<Uint8List>[aad, _pad16(aad), cipher, _pad16(cipher), _le64(aad.length), _le64(cipher.length)]);
  if (!_ctEquals(_poly1305(macData, otk), tag)) throw const FormatException("AEAD authentication failed.");
  return _chacha20(key32, nonce12, 1, cipher);
}

// ===========================================================================
// Salsa20 (32-byte key, 8-byte nonce)
// ===========================================================================

void _salsaQr(Uint32List x, int a, int b, int c, int d) {
  x[b] ^= _rotl32((x[a] + x[d]) & _m32, 7);
  x[c] ^= _rotl32((x[b] + x[a]) & _m32, 9);
  x[d] ^= _rotl32((x[c] + x[b]) & _m32, 13);
  x[a] ^= _rotl32((x[d] + x[c]) & _m32, 18);
}

Uint8List _salsaBlock(Uint32List key8, Uint32List nonceCounter4) {
  final Uint32List s = Uint32List(16);
  s[0] = 0x61707865;
  s[5] = 0x3320646e;
  s[10] = 0x79622d32;
  s[15] = 0x6b206574;
  s[1] = key8[0];
  s[2] = key8[1];
  s[3] = key8[2];
  s[4] = key8[3];
  s[11] = key8[4];
  s[12] = key8[5];
  s[13] = key8[6];
  s[14] = key8[7];
  s[6] = nonceCounter4[0];
  s[7] = nonceCounter4[1];
  s[8] = nonceCounter4[2];
  s[9] = nonceCounter4[3];
  final Uint32List x = Uint32List.fromList(s);
  for (int i = 0; i < 10; i++) {
    _salsaQr(x, 0, 4, 8, 12);
    _salsaQr(x, 5, 9, 13, 1);
    _salsaQr(x, 10, 14, 2, 6);
    _salsaQr(x, 15, 3, 7, 11);
    _salsaQr(x, 0, 1, 2, 3);
    _salsaQr(x, 5, 6, 7, 4);
    _salsaQr(x, 10, 11, 8, 9);
    _salsaQr(x, 15, 12, 13, 14);
  }
  final Uint8List out = Uint8List(64);
  final ByteData bd = ByteData.sublistView(out);
  for (int i = 0; i < 16; i++) {
    bd.setUint32(i * 4, (x[i] + s[i]) & _m32, Endian.little);
  }
  return out;
}

Uint8List _salsa20(Uint8List key32, Uint8List nonce8, Uint8List data) {
  final Uint32List key8 = Uint32List(8);
  final ByteData kb = ByteData.sublistView(key32);
  for (int i = 0; i < 8; i++) {
    key8[i] = kb.getUint32(i * 4, Endian.little);
  }
  final ByteData nb = ByteData.sublistView(nonce8);
  final Uint8List out = Uint8List(data.length);
  int counter = 0;
  for (int off = 0; off < data.length; off += 64) {
    final Uint32List nc = Uint32List(4);
    nc[0] = nb.getUint32(0, Endian.little);
    nc[1] = nb.getUint32(4, Endian.little);
    nc[2] = counter & _m32;
    nc[3] = (counter >>> 32) & _m32;
    final Uint8List ks = _salsaBlock(key8, nc);
    final int n = min(64, data.length - off);
    for (int j = 0; j < n; j++) {
      out[off + j] = data[off + j] ^ ks[j];
    }
    counter++;
  }
  return out;
}

// ===========================================================================
// Fernet (spec-compliant: AES-128-CBC + HMAC-SHA256, base64url token)
// ===========================================================================

Uint8List _fernetEncryptBytes(Uint8List key32, Uint8List plain, int timestamp) {
  final Uint8List signKey = key32.sublist(0, 16);
  final Uint8List encKey = key32.sublist(16, 32);
  final Uint8List iv = _randomBytes(16);
  final Uint8List cipher = _aesCbc(encKey, iv, plain, true, true);
  final Uint8List pre = _concat(<Uint8List>[
    Uint8List.fromList(<int>[0x80]),
    _len64BE(timestamp),
    iv,
    cipher,
  ]);
  final Uint8List mac = _hmac(_sha256, signKey, pre);
  return _concat(<Uint8List>[pre, mac]);
}

Uint8List _fernetDecryptBytes(Uint8List key32, Uint8List token) {
  if (token.length < 57 || token[0] != 0x80) throw const FormatException("Invalid Fernet token.");
  final Uint8List signKey = key32.sublist(0, 16);
  final Uint8List encKey = key32.sublist(16, 32);
  final Uint8List pre = token.sublist(0, token.length - 32);
  final Uint8List mac = token.sublist(token.length - 32);
  if (!_ctEquals(_hmac(_sha256, signKey, pre), mac)) throw const FormatException("Fernet HMAC verification failed.");
  final Uint8List iv = token.sublist(9, 25);
  final Uint8List cipher = token.sublist(25, token.length - 32);
  return _aesCbc(encKey, iv, cipher, false, true);
}

// ===========================================================================
// CRC32
// ===========================================================================

final List<int> _crcTable = List<int>.generate(256, (int n) {
  int c = n;
  for (int k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
  }
  return c & _m32;
});

int _crc32(Uint8List data) {
  int crc = 0xFFFFFFFF;
  for (final int b in data) {
    crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >>> 8);
  }
  return (crc ^ 0xFFFFFFFF) & _m32;
}

// ===========================================================================
// Public facade
// ===========================================================================

/// Zero-dependency cryptography helpers: authenticated encryption, symmetric
/// ciphers, one-way hashes, key derivation, reversible encoders and classical
/// ciphers. All local; no method touches the network. Prefer [seal]/[open] for
/// real secrets — they authenticate and detect tampering.
abstract class UEncryption {
  // -------------------------------------------------------------------------
  // Recommended authenticated encryption (AES-256-GCM, random nonce).
  // Output = base64(nonce ‖ ciphertext ‖ tag). Key must be 32 bytes.
  // -------------------------------------------------------------------------
  static String seal({required String plainText, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List nonce = _randomBytes(12);
    final Uint8List ct = _aesGcmEncrypt(_bytes(key, keyEncoding), nonce, _u8(plainText), aad == null ? Uint8List(0) : _u8(aad));
    return base64.encode(_concat(<Uint8List>[nonce, ct]));
  }

  static String open({required String base64Cipher, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List raw = base64.decode(base64Cipher);
    return utf8.decode(_aesGcmDecrypt(_bytes(key, keyEncoding), raw.sublist(0, 12), raw.sublist(12), aad == null ? Uint8List(0) : _u8(aad)));
  }

  /// Authenticated encryption with ChaCha20-Poly1305 (fully web-safe).
  static String chacha20Poly1305Encrypt({required String plainText, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List nonce = _randomBytes(12);
    final Uint8List ct = _chachaPolyEncrypt(_bytes(key, keyEncoding), nonce, _u8(plainText), aad == null ? Uint8List(0) : _u8(aad));
    return base64.encode(_concat(<Uint8List>[nonce, ct]));
  }

  static String chacha20Poly1305Decrypt({required String base64Cipher, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List raw = base64.decode(base64Cipher);
    return utf8.decode(_chachaPolyDecrypt(_bytes(key, keyEncoding), raw.sublist(0, 12), raw.sublist(12), aad == null ? Uint8List(0) : _u8(aad)));
  }

  // -------------------------------------------------------------------------
  // AES (configurable mode / padding / key-encoding). Output/input base64.
  // -------------------------------------------------------------------------
  static String aesEncrypt({
    required String plainText,
    required String key,
    required String iv,
    UAesMode mode = UAesMode.cbc,
    bool padding = true,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding ivEncoding = UByteEncoding.utf8,
  }) {
    final Uint8List k = _bytes(key, keyEncoding);
    final Uint8List v = _bytes(iv, ivEncoding);
    final Uint8List pt = _u8(plainText);
    final Uint8List ct = switch (mode) {
      UAesMode.cbc => _aesCbc(k, v, pt, true, padding),
      UAesMode.ecb => _aesEcb(k, pt, true, padding),
      UAesMode.ctr || UAesMode.sic => _aesCtr(k, v, pt),
      UAesMode.cfb64 => _aesCfb(k, v, pt, true),
      UAesMode.ofb64 || UAesMode.ofb64Gctr => _aesOfb(k, v, pt),
      UAesMode.gcm => _aesGcmEncrypt(k, v, pt, Uint8List(0)),
    };
    return base64.encode(ct);
  }

  static String aesDecrypt({
    required String base64Encrypted,
    required String key,
    required String iv,
    UAesMode mode = UAesMode.cbc,
    bool padding = true,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding ivEncoding = UByteEncoding.utf8,
  }) {
    final Uint8List k = _bytes(key, keyEncoding);
    final Uint8List v = _bytes(iv, ivEncoding);
    final Uint8List ct = base64.decode(base64Encrypted);
    final Uint8List pt = switch (mode) {
      UAesMode.cbc => _aesCbc(k, v, ct, false, padding),
      UAesMode.ecb => _aesEcb(k, ct, false, padding),
      UAesMode.ctr || UAesMode.sic => _aesCtr(k, v, ct),
      UAesMode.cfb64 => _aesCfb(k, v, ct, false),
      UAesMode.ofb64 || UAesMode.ofb64Gctr => _aesOfb(k, v, ct),
      UAesMode.gcm => _aesGcmDecrypt(k, v, ct, Uint8List(0)),
    };
    return utf8.decode(pt);
  }

  /// AES-256-CBC/PKCS7 with UTF-8 key (32 chars) and IV (16 chars).
  static String encryptUint8List({required Uint8List data, required String key, required String iv}) {
    if (key.length != 32) throw ArgumentError("Key must be 32 bytes for AES-256.");
    if (iv.length != 16) throw ArgumentError("IV must be 16 bytes for AES.");
    return base64.encode(_aesCbc(_u8(key), _u8(iv), data, true, true));
  }

  static Uint8List decryptUint8List({required String base64Encrypted, required String key, required String iv}) {
    if (key.length != 32) throw ArgumentError("Key must be 32 bytes for AES-256.");
    if (iv.length != 16) throw ArgumentError("IV must be 16 bytes for AES.");
    return _aesCbc(_u8(key), _u8(iv), base64.decode(base64Encrypted), false, true);
  }

  // -------------------------------------------------------------------------
  // Stream ciphers.
  // -------------------------------------------------------------------------
  static String salsa20Encrypt({required String plainText, required String key, required String iv, UByteEncoding keyEncoding = UByteEncoding.utf8, UByteEncoding ivEncoding = UByteEncoding.utf8}) =>
      base64.encode(_salsa20(_fit(_bytes(key, keyEncoding), 32), _fit(_bytes(iv, ivEncoding), 8), _u8(plainText)));

  static String salsa20Decrypt({
    required String base64Encrypted,
    required String key,
    required String iv,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding ivEncoding = UByteEncoding.utf8,
  }) => utf8.decode(_salsa20(_fit(_bytes(key, keyEncoding), 32), _fit(_bytes(iv, ivEncoding), 8), base64.decode(base64Encrypted)));

  static String chacha20Encrypt({
    required String plainText,
    required String key,
    required String nonce,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding nonceEncoding = UByteEncoding.utf8,
  }) => base64.encode(_chacha20(_fit(_bytes(key, keyEncoding), 32), _fit(_bytes(nonce, nonceEncoding), 12), 1, _u8(plainText)));

  static String chacha20Decrypt({
    required String base64Encrypted,
    required String key,
    required String nonce,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding nonceEncoding = UByteEncoding.utf8,
  }) => utf8.decode(_chacha20(_fit(_bytes(key, keyEncoding), 32), _fit(_bytes(nonce, nonceEncoding), 12), 1, base64.decode(base64Encrypted)));

  // -------------------------------------------------------------------------
  // Fernet (32-byte key; recommended encoding is base64).
  // -------------------------------------------------------------------------
  static String fernetEncrypt({required String plainText, required String key, UByteEncoding keyEncoding = UByteEncoding.base64}) =>
      base64.encode(_fernetEncryptBytes(_fit(_bytes(key, keyEncoding), 32), _u8(plainText), DateTime.now().millisecondsSinceEpoch ~/ 1000));

  static String fernetDecrypt({required String base64Encrypted, required String key, UByteEncoding keyEncoding = UByteEncoding.base64}) =>
      utf8.decode(_fernetDecryptBytes(_fit(_bytes(key, keyEncoding), 32), base64.decode(base64Encrypted)));

  // -------------------------------------------------------------------------
  // Key derivation.
  // -------------------------------------------------------------------------
  static String pbkdf2({required String password, required String salt, int iterations = 100000, int length = 32, UByteEncoding saltEncoding = UByteEncoding.utf8, bool asHex = false}) {
    final Uint8List dk = _pbkdf2(_sha256, _u8(password), _bytes(salt, saltEncoding), iterations, length);
    return asHex ? _toHex(dk) : base64.encode(dk);
  }

  static String hkdf({required String secret, String salt = "", String info = "", int length = 32, bool asHex = false}) {
    final Uint8List dk = _hkdf(_sha256, _u8(secret), _u8(salt), _u8(info), length);
    return asHex ? _toHex(dk) : base64.encode(dk);
  }

  // -------------------------------------------------------------------------
  // Reversible text encoders.
  // -------------------------------------------------------------------------
  static String base64EncodeText(String text) => base64.encode(utf8.encode(text));

  static String base64DecodeText(String value) => utf8.decode(base64.decode(value));

  static String base64UrlEncodeText(String text) => base64Url.encode(utf8.encode(text));

  static String base64UrlDecodeText(String value) => utf8.decode(base64Url.decode(value));

  static String hexEncodeText(String text) => _toHex(utf8.encode(text));

  static String hexDecodeText(String value) => utf8.decode(_fromHex(value));

  static String hexEncode(List<int> bytes) => _toHex(bytes);

  static List<int> hexToBytes(String hex) => _fromHex(hex);

  static const String _base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

  static String base32EncodeText(String text) => base32Encode(utf8.encode(text));

  static String base32DecodeText(String value) => utf8.decode(base32Decode(value));

  static String base32Encode(List<int> bytes) {
    final StringBuffer buffer = StringBuffer();
    int value = 0;
    int bits = 0;
    for (final int b in bytes) {
      value = (value << 8) | b;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        buffer.write(_base32Alphabet[(value >> bits) & 31]);
      }
    }
    if (bits > 0) buffer.write(_base32Alphabet[(value << (5 - bits)) & 31]);
    while (buffer.length % 8 != 0) {
      buffer.write("=");
    }
    return buffer.toString();
  }

  static List<int> base32Decode(String input) {
    final String clean = input.toUpperCase().replaceAll("=", "").replaceAll(RegExp(r"\s"), "");
    final List<int> out = <int>[];
    int value = 0;
    int bits = 0;
    for (final int rune in clean.runes) {
      final int index = _base32Alphabet.indexOf(String.fromCharCode(rune));
      if (index < 0) throw const FormatException("Invalid Base32 character.");
      value = (value << 5) | index;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.add((value >> bits) & 0xFF);
      }
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // Classical / bitwise ciphers.
  // -------------------------------------------------------------------------
  static Uint8List _xorBytes(List<int> data, List<int> key) {
    if (key.isEmpty) throw ArgumentError("XOR key must not be empty.");
    final Uint8List out = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      out[i] = data[i] ^ key[i % key.length];
    }
    return out;
  }

  static String xorEncrypt({required String plainText, required String key, UByteEncoding keyEncoding = UByteEncoding.utf8}) => base64.encode(_xorBytes(_u8(plainText), _bytes(key, keyEncoding)));

  static String xorDecrypt({required String base64Encrypted, required String key, UByteEncoding keyEncoding = UByteEncoding.utf8}) =>
      utf8.decode(_xorBytes(base64.decode(base64Encrypted), _bytes(key, keyEncoding)));

  static String rot13(String text) => caesarShift(text, 13);

  static String caesarShift(String text, int shift) {
    final int n = ((shift % 26) + 26) % 26;
    return String.fromCharCodes(
      text.runes.map((int c) {
        if (c >= 65 && c <= 90) return (c - 65 + n) % 26 + 65;
        if (c >= 97 && c <= 122) return (c - 97 + n) % 26 + 97;
        return c;
      }),
    );
  }

  // -------------------------------------------------------------------------
  // One-way hashes (hex output).
  // -------------------------------------------------------------------------
  static String md5Hash(String text) => _toHex(_md5(_u8(text)));

  static String sha1Hash(String text) => _toHex(_sha1(_u8(text)));

  static String sha224Hash(String text) => _toHex(_sha224(_u8(text)));

  static String sha256Hash(String text) => _toHex(_sha256(_u8(text)));

  static String sha384Hash(String text) => _toHex(_sha384(_u8(text)));

  static String sha512Hash(String text) => _toHex(_sha512(_u8(text)));

  static String hmacSha256(String text, String key) => _toHex(_hmac(_sha256, _u8(key), _u8(text)));

  static String hmacSha512(String text, String key) => _toHex(_hmac(_sha512, _u8(key), _u8(text)));

  static int crc32(String text) => _crc32(_u8(text));

  // -------------------------------------------------------------------------
  // Random material + constant-time compare.
  // -------------------------------------------------------------------------
  static String randomKey({int bytes = 32}) => base64.encode(_randomBytes(bytes));

  static String randomIv({int bytes = 16}) => base64.encode(_randomBytes(bytes));

  static String randomHex({int bytes = 16}) => _toHex(_randomBytes(bytes));

  static bool constantTimeEquals(String a, String b) => _ctEquals(_u8(a), _u8(b));

  // -------------------------------------------------------------------------
  // Internal helpers.
  // -------------------------------------------------------------------------
  static Uint8List _bytes(String value, UByteEncoding encoding) => switch (encoding) {
    UByteEncoding.utf8 => _u8(value),
    UByteEncoding.base64 => base64.decode(value),
    UByteEncoding.hex => _fromHex(value),
  };

  /// Right-sizes key/nonce material by truncating or zero-padding to [size].
  static Uint8List _fit(Uint8List b, int size) {
    if (b.length == size) return b;
    final Uint8List out = Uint8List(size);
    out.setRange(0, min(size, b.length), b);
    return out;
  }

  // -------------------------------------------------------------------------
  // Extended hashes (hex output).
  // -------------------------------------------------------------------------
  static String sha3(String text, {int bits = 256}) => _toHex(_sha3(_u8(text), bits));

  static String keccak256Hash(String text) => _toHex(_keccakLegacy(_u8(text), 256));

  static String shake128(String text, {int bytes = 32}) => _toHex(_shake(_u8(text), 256, bytes));

  static String shake256(String text, {int bytes = 64}) => _toHex(_shake(_u8(text), 512, bytes));

  static String ripemd160Hash(String text) => _toHex(_ripemd160(_u8(text)));

  static String md4Hash(String text) => _toHex(_md4(_u8(text)));

  static String sm3Hash(String text) => _toHex(_sm3(_u8(text)));

  static String sha512256Hash(String text) => _toHex(_sha512t256(_u8(text)));

  static String blake2bHash(String text, {int bytes = 64}) => _toHex(_blake2b(_u8(text), bytes));

  static String hmacSha1(String text, String key) => _toHex(_hmac(_sha1, _u8(key), _u8(text)));

  // -------------------------------------------------------------------------
  // scrypt (memory-hard password KDF).
  // -------------------------------------------------------------------------
  static String scrypt({required String password, required String salt, int n = 16384, int r = 8, int p = 1, int dkLen = 32, UByteEncoding saltEncoding = UByteEncoding.utf8, bool asHex = false}) {
    final Uint8List dk = _scrypt(_u8(password), _bytes(salt, saltEncoding), n, r, p, dkLen);
    return asHex ? _toHex(dk) : base64.encode(dk);
  }

  // -------------------------------------------------------------------------
  // XChaCha20-Poly1305 (24-byte random nonce; extended-nonce AEAD).
  // -------------------------------------------------------------------------
  static String xchacha20Poly1305Encrypt({required String plainText, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List nonce = _randomBytes(24);
    final Uint8List ct = _xchachaPolyEncrypt(_bytes(key, keyEncoding), nonce, _u8(plainText), aad == null ? Uint8List(0) : _u8(aad));
    return base64.encode(_concat(<Uint8List>[nonce, ct]));
  }

  static String xchacha20Poly1305Decrypt({required String base64Cipher, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List raw = base64.decode(base64Cipher);
    return utf8.decode(_xchachaPolyDecrypt(_bytes(key, keyEncoding), raw.sublist(0, 24), raw.sublist(24), aad == null ? Uint8List(0) : _u8(aad)));
  }

  // -------------------------------------------------------------------------
  // RC4 (legacy stream cipher — INSECURE, provided for interop/testing only).
  // -------------------------------------------------------------------------
  static String rc4Encrypt({required String plainText, required String key, UByteEncoding keyEncoding = UByteEncoding.utf8}) => base64.encode(_rc4(_bytes(key, keyEncoding), _u8(plainText)));

  static String rc4Decrypt({required String base64Encrypted, required String key, UByteEncoding keyEncoding = UByteEncoding.utf8}) =>
      utf8.decode(_rc4(_bytes(key, keyEncoding), base64.decode(base64Encrypted)));

  // -------------------------------------------------------------------------
  // Checksums (integer output).
  // -------------------------------------------------------------------------
  static int crc16(String text) => _crc16(_u8(text));

  static int adler32(String text) => _adler32(_u8(text));

  static int fnv1a32(String text) => _fnv1a32(_u8(text));

  // -------------------------------------------------------------------------
  // Extended encoders.
  // -------------------------------------------------------------------------
  static String base58Encode(List<int> bytes) => _base58Encode(Uint8List.fromList(bytes));

  static List<int> base58Decode(String value) => _base58Decode(value);

  static String base58EncodeText(String text) => _base58Encode(_u8(text));

  static String base58DecodeText(String value) => utf8.decode(_base58Decode(value));

  static String base58Check(List<int> payload) => _base58Check(Uint8List.fromList(payload));

  static String ascii85EncodeText(String text) => _ascii85Encode(_u8(text));

  static String ascii85DecodeText(String value) => utf8.decode(_ascii85Decode(value));

  static String base45EncodeText(String text) => _base45Encode(_u8(text));

  static String base45DecodeText(String value) => utf8.decode(_base45Decode(value));

  static String base32HexEncodeText(String text) => _base32HexEncode(_u8(text));

  static String base32HexDecodeText(String value) => utf8.decode(_base32HexDecode(value));

  static String rot47(String text) => _rot47(text);

  static String morseEncode(String text) => _morseEncode(text);

  static String morseDecode(String code) => _morseDecode(code);

  static String urlEncode(String text) => Uri.encodeComponent(text);

  static String urlDecode(String value) => Uri.decodeComponent(value);
}

// ===========================================================================
// Extended hashes: SHA-3 / Keccak / SHAKE, RIPEMD-160, MD4, SM3, SHA-512/256
// ===========================================================================

const List<int> _keccakRotc = <int>[1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 2, 14, 27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44];
const List<int> _keccakPiln = <int>[10, 7, 11, 17, 18, 3, 5, 16, 8, 21, 24, 4, 15, 23, 19, 13, 12, 2, 20, 14, 22, 9, 6, 1];

void _keccakF(List<_U64> st) {
  final List<_U64> bc = List<_U64>.filled(5, (0, 0));
  for (int round = 0; round < 24; round++) {
    for (int i = 0; i < 5; i++) {
      bc[i] = _xor64(_xor64(_xor64(st[i], st[i + 5]), _xor64(st[i + 10], st[i + 15])), st[i + 20]);
    }
    for (int i = 0; i < 5; i++) {
      final _U64 t = _xor64(bc[(i + 4) % 5], _rotl64p(bc[(i + 1) % 5], 1));
      for (int j = 0; j < 25; j += 5) {
        st[j + i] = _xor64(st[j + i], t);
      }
    }
    _U64 t = st[1];
    for (int i = 0; i < 24; i++) {
      final int j = _keccakPiln[i];
      final _U64 tmp = st[j];
      st[j] = _rotl64p(t, _keccakRotc[i]);
      t = tmp;
    }
    for (int j = 0; j < 25; j += 5) {
      for (int i = 0; i < 5; i++) {
        bc[i] = st[j + i];
      }
      for (int i = 0; i < 5; i++) {
        st[j + i] = _xor64(st[j + i], _and64(_not64(bc[(i + 1) % 5]), bc[(i + 2) % 5]));
      }
    }
    st[0] = _xor64(st[0], (_keccakRcHi[round], _keccakRcLo[round]));
  }
}

Uint8List _keccak(int rate, Uint8List input, int pad, int outLen) {
  final List<_U64> st = List<_U64>.filled(25, (0, 0));
  final int rateLanes = rate ~/ 8;
  int off = 0;
  int remaining = input.length;
  while (remaining >= rate) {
    for (int i = 0; i < rateLanes; i++) {
      st[i] = _xor64(st[i], _load64LEp(input, off + i * 8));
    }
    _keccakF(st);
    off += rate;
    remaining -= rate;
  }
  final Uint8List block = Uint8List(rate);
  for (int i = 0; i < remaining; i++) {
    block[i] = input[off + i];
  }
  block[remaining] = pad;
  block[rate - 1] |= 0x80;
  for (int i = 0; i < rateLanes; i++) {
    st[i] = _xor64(st[i], _load64LEp(block, i * 8));
  }
  _keccakF(st);
  final Uint8List out = Uint8List(outLen);
  final Uint8List lane = Uint8List(8);
  int produced = 0;
  while (produced < outLen) {
    final int n = min(rate, outLen - produced);
    for (int i = 0; i < n; i++) {
      if (i % 8 == 0) _store64LE(lane, 0, st[i ~/ 8]);
      out[produced + i] = lane[i % 8];
    }
    produced += n;
    if (produced < outLen) _keccakF(st);
  }
  return out;
}

Uint8List _sha3(Uint8List msg, int bits) => _keccak(200 - bits ~/ 4, msg, 0x06, bits ~/ 8);

Uint8List _keccakLegacy(Uint8List msg, int bits) => _keccak(200 - bits ~/ 4, msg, 0x01, bits ~/ 8);

Uint8List _shake(Uint8List msg, int capacityBits, int outBytes) => _keccak(200 - capacityBits ~/ 8, msg, 0x1f, outBytes);

Uint8List _sha512t256(Uint8List msg) => _sha512Core(msg, _ivPairs(_sha512t256IvHi, _sha512t256IvLo), 32);

// --- MD4 -------------------------------------------------------------------

Uint8List _md4(Uint8List msg) {
  final int bitLen = msg.length * 8;
  final int padLen = (56 - (msg.length + 1) % 64) % 64;
  final BytesBuilder bb = BytesBuilder()
    ..add(msg)
    ..addByte(0x80)
    ..add(Uint8List(padLen));
  bb.add(_len64LE(bitLen));
  final Uint8List data = bb.toBytes();
  int a = 0x67452301;
  int b = 0xefcdab89;
  int c = 0x98badcfe;
  int d = 0x10325476;
  final ByteData view = ByteData.sublistView(data);
  for (int off = 0; off < data.length; off += 64) {
    final List<int> x = List<int>.generate(16, (int i) => view.getUint32(off + i * 4, Endian.little));
    int aa = a;
    int bb2 = b;
    int cc = c;
    int dd = d;
    int f(int p, int q, int r) => (p & q) | (~p & r);
    int g(int p, int q, int r) => (p & q) | (p & r) | (q & r);
    int h(int p, int q, int r) => p ^ q ^ r;
    const List<int> s1 = <int>[3, 7, 11, 19];
    for (int i = 0; i < 16; i++) {
      final int k = i;
      final int val = (aa + f(bb2, cc, dd) + x[k]) & _m32;
      aa = dd;
      dd = cc;
      cc = bb2;
      bb2 = _rotl32(val, s1[i % 4]);
    }
    const List<int> order2 = <int>[0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15];
    const List<int> s2 = <int>[3, 5, 9, 13];
    for (int i = 0; i < 16; i++) {
      final int val = (aa + g(bb2, cc, dd) + x[order2[i]] + 0x5a827999) & _m32;
      aa = dd;
      dd = cc;
      cc = bb2;
      bb2 = _rotl32(val, s2[i % 4]);
    }
    const List<int> order3 = <int>[0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15];
    const List<int> s3 = <int>[3, 9, 11, 15];
    for (int i = 0; i < 16; i++) {
      final int val = (aa + h(bb2, cc, dd) + x[order3[i]] + 0x6ed9eba1) & _m32;
      aa = dd;
      dd = cc;
      cc = bb2;
      bb2 = _rotl32(val, s3[i % 4]);
    }
    a = (a + aa) & _m32;
    b = (b + bb2) & _m32;
    c = (c + cc) & _m32;
    d = (d + dd) & _m32;
  }
  final ByteData out = ByteData(16)
    ..setUint32(0, a, Endian.little)
    ..setUint32(4, b, Endian.little)
    ..setUint32(8, c, Endian.little)
    ..setUint32(12, d, Endian.little);
  return out.buffer.asUint8List();
}

// --- RIPEMD-160 ------------------------------------------------------------

const List<int> _rmdR1 = <int>[
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  7,
  4,
  13,
  1,
  10,
  6,
  15,
  3,
  12,
  0,
  9,
  5,
  2,
  14,
  11,
  8,
  3,
  10,
  14,
  4,
  9,
  15,
  8,
  1,
  2,
  7,
  0,
  6,
  13,
  11,
  5,
  12,
  1,
  9,
  11,
  10,
  0,
  8,
  12,
  4,
  13,
  3,
  7,
  15,
  14,
  5,
  6,
  2,
  4,
  0,
  5,
  9,
  7,
  12,
  2,
  10,
  14,
  1,
  3,
  8,
  11,
  6,
  15,
  13,
];
const List<int> _rmdR2 = <int>[
  5,
  14,
  7,
  0,
  9,
  2,
  11,
  4,
  13,
  6,
  15,
  8,
  1,
  10,
  3,
  12,
  6,
  11,
  3,
  7,
  0,
  13,
  5,
  10,
  14,
  15,
  8,
  12,
  4,
  9,
  1,
  2,
  15,
  5,
  1,
  3,
  7,
  14,
  6,
  9,
  11,
  8,
  12,
  2,
  10,
  0,
  4,
  13,
  8,
  6,
  4,
  1,
  3,
  11,
  15,
  0,
  5,
  12,
  2,
  13,
  9,
  7,
  10,
  14,
  12,
  15,
  10,
  4,
  1,
  5,
  8,
  7,
  6,
  2,
  13,
  14,
  0,
  3,
  9,
  11,
];
const List<int> _rmdS1 = <int>[
  11,
  14,
  15,
  12,
  5,
  8,
  7,
  9,
  11,
  13,
  14,
  15,
  6,
  7,
  9,
  8,
  7,
  6,
  8,
  13,
  11,
  9,
  7,
  15,
  7,
  12,
  15,
  9,
  11,
  7,
  13,
  12,
  11,
  13,
  6,
  7,
  14,
  9,
  13,
  15,
  14,
  8,
  13,
  6,
  5,
  12,
  7,
  5,
  11,
  12,
  14,
  15,
  14,
  15,
  9,
  8,
  9,
  14,
  5,
  6,
  8,
  6,
  5,
  12,
  9,
  15,
  5,
  11,
  6,
  8,
  13,
  12,
  5,
  12,
  13,
  14,
  11,
  8,
  5,
  6,
];
const List<int> _rmdS2 = <int>[
  8,
  9,
  9,
  11,
  13,
  15,
  15,
  5,
  7,
  7,
  8,
  11,
  14,
  14,
  12,
  6,
  9,
  13,
  15,
  7,
  12,
  8,
  9,
  11,
  7,
  7,
  12,
  7,
  6,
  15,
  13,
  11,
  9,
  7,
  15,
  11,
  8,
  6,
  6,
  14,
  12,
  13,
  5,
  14,
  13,
  13,
  7,
  5,
  15,
  5,
  8,
  11,
  14,
  14,
  6,
  14,
  6,
  9,
  12,
  9,
  12,
  5,
  15,
  8,
  8,
  5,
  12,
  9,
  12,
  5,
  14,
  6,
  8,
  13,
  6,
  5,
  15,
  13,
  11,
  11,
];

Uint8List _ripemd160(Uint8List msg) {
  final int bitLen = msg.length * 8;
  final int padLen = (56 - (msg.length + 1) % 64) % 64;
  final BytesBuilder bb = BytesBuilder()
    ..add(msg)
    ..addByte(0x80)
    ..add(Uint8List(padLen));
  bb.add(_len64LE(bitLen));
  final Uint8List data = bb.toBytes();
  int h0 = 0x67452301;
  int h1 = 0xefcdab89;
  int h2 = 0x98badcfe;
  int h3 = 0x10325476;
  int h4 = 0xc3d2e1f0;
  final ByteData view = ByteData.sublistView(data);
  int rf(int j, int x, int y, int z) {
    if (j < 16) return x ^ y ^ z;
    if (j < 32) return (x & y) | (~x & z);
    if (j < 48) return (x | ~y & _m32) ^ z;
    if (j < 64) return (x & z) | (y & ~z & _m32);
    return x ^ (y | ~z & _m32);
  }

  const List<int> kk1 = <int>[0x00000000, 0x5a827999, 0x6ed9eba1, 0x8f1bbcdc, 0xa953fd4e];
  const List<int> kk2 = <int>[0x50a28be6, 0x5c4dd124, 0x6d703ef3, 0x7a6d76e9, 0x00000000];
  for (int off = 0; off < data.length; off += 64) {
    final List<int> x = List<int>.generate(16, (int i) => view.getUint32(off + i * 4, Endian.little));
    int a1 = h0;
    int b1 = h1;
    int c1 = h2;
    int d1 = h3;
    int e1 = h4;
    int a2 = h0;
    int b2 = h1;
    int c2 = h2;
    int d2 = h3;
    int e2 = h4;
    for (int j = 0; j < 80; j++) {
      int t = (a1 + rf(j, b1, c1, d1) + x[_rmdR1[j]] + kk1[j ~/ 16]) & _m32;
      t = (_rotl32(t, _rmdS1[j]) + e1) & _m32;
      a1 = e1;
      e1 = d1;
      d1 = _rotl32(c1, 10);
      c1 = b1;
      b1 = t;
      t = (a2 + rf(79 - j, b2, c2, d2) + x[_rmdR2[j]] + kk2[j ~/ 16]) & _m32;
      t = (_rotl32(t, _rmdS2[j]) + e2) & _m32;
      a2 = e2;
      e2 = d2;
      d2 = _rotl32(c2, 10);
      c2 = b2;
      b2 = t;
    }
    final int tmp = (h1 + c1 + d2) & _m32;
    h1 = (h2 + d1 + e2) & _m32;
    h2 = (h3 + e1 + a2) & _m32;
    h3 = (h4 + a1 + b2) & _m32;
    h4 = (h0 + b1 + c2) & _m32;
    h0 = tmp;
  }
  final ByteData out = ByteData(20)
    ..setUint32(0, h0, Endian.little)
    ..setUint32(4, h1, Endian.little)
    ..setUint32(8, h2, Endian.little)
    ..setUint32(12, h3, Endian.little)
    ..setUint32(16, h4, Endian.little);
  return out.buffer.asUint8List();
}

// --- SM3 -------------------------------------------------------------------

Uint8List _sm3(Uint8List msg) {
  final int bitLen = msg.length * 8;
  final int padLen = (56 - (msg.length + 1) % 64) % 64;
  final BytesBuilder bb = BytesBuilder()
    ..add(msg)
    ..addByte(0x80)
    ..add(Uint8List(padLen));
  bb.add(_len64BE(bitLen));
  final Uint8List data = bb.toBytes();
  final List<int> v = <int>[0x7380166f, 0x4914b2b9, 0x172442d7, 0xda8a0600, 0xa96f30bc, 0x163138aa, 0xe38dee4d, 0xb0fb0e4e];
  final ByteData view = ByteData.sublistView(data);
  final List<int> w = List<int>.filled(68, 0);
  final List<int> w1 = List<int>.filled(64, 0);
  for (int off = 0; off < data.length; off += 64) {
    for (int i = 0; i < 16; i++) {
      w[i] = view.getUint32(off + i * 4);
    }
    for (int i = 16; i < 68; i++) {
      final int x = w[i - 16] ^ w[i - 9] ^ _rotl32(w[i - 3], 15);
      w[i] = (x ^ _rotl32(x, 15) ^ _rotl32(x, 23)) ^ _rotl32(w[i - 13], 7) ^ w[i - 6];
    }
    for (int i = 0; i < 64; i++) {
      w1[i] = w[i] ^ w[i + 4];
    }
    int a = v[0];
    int b = v[1];
    int c = v[2];
    int d = v[3];
    int e = v[4];
    int f = v[5];
    int g = v[6];
    int hh = v[7];
    for (int i = 0; i < 64; i++) {
      final int tj = i < 16 ? 0x79cc4519 : 0x7a879d8a;
      final int ss1 = _rotl32((_rotl32(a, 12) + e + _rotl32(tj, i % 32)) & _m32, 7);
      final int ss2 = ss1 ^ _rotl32(a, 12);
      final int ff = i < 16 ? (a ^ b ^ c) : ((a & b) | (a & c) | (b & c));
      final int gg = i < 16 ? (e ^ f ^ g) : ((e & f) | (~e & g));
      final int tt1 = (ff + d + ss2 + w1[i]) & _m32;
      final int tt2 = (gg + hh + ss1 + w[i]) & _m32;
      d = c;
      c = _rotl32(b, 9);
      b = a;
      a = tt1;
      hh = g;
      g = _rotl32(f, 19);
      f = e;
      e = tt2 ^ _rotl32(tt2, 9) ^ _rotl32(tt2, 17);
    }
    v[0] ^= a;
    v[1] ^= b;
    v[2] ^= c;
    v[3] ^= d;
    v[4] ^= e;
    v[5] ^= f;
    v[6] ^= g;
    v[7] ^= hh;
  }
  final ByteData out = ByteData(32);
  for (int i = 0; i < 8; i++) {
    out.setUint32(i * 4, v[i]);
  }
  return out.buffer.asUint8List();
}

// ===========================================================================
// BLAKE2b, scrypt, RC4, XChaCha20-Poly1305
// ===========================================================================

const List<List<int>> _blakeSigma = <List<int>>[
  <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
  <int>[14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
  <int>[11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
  <int>[7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
  <int>[9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
  <int>[2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
  <int>[12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
  <int>[13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
  <int>[6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
  <int>[10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
  <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
  <int>[14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
];

void _blakeG(List<_U64> v, int a, int b, int c, int d, _U64 x, _U64 y) {
  v[a] = _add64(_add64(v[a], v[b]), x);
  v[d] = _rotr64p(_xor64(v[d], v[a]), 32);
  v[c] = _add64(v[c], v[d]);
  v[b] = _rotr64p(_xor64(v[b], v[c]), 24);
  v[a] = _add64(_add64(v[a], v[b]), y);
  v[d] = _rotr64p(_xor64(v[d], v[a]), 16);
  v[c] = _add64(v[c], v[d]);
  v[b] = _rotr64p(_xor64(v[b], v[c]), 63);
}

void _blake2bCompress(List<_U64> h, Uint8List block, int t, bool last) {
  final List<_U64> m = List<_U64>.generate(16, (int i) => _load64LEp(block, i * 8));
  final List<_U64> v = List<_U64>.filled(16, (0, 0));
  for (int i = 0; i < 8; i++) {
    v[i] = h[i];
    v[i + 8] = (_blakeIvHi[i], _blakeIvLo[i]);
  }
  v[12] = _xor64(v[12], (t ~/ 0x100000000, t % 0x100000000));
  if (last) v[14] = _not64(v[14]);
  for (int r = 0; r < 12; r++) {
    final List<int> s = _blakeSigma[r];
    _blakeG(v, 0, 4, 8, 12, m[s[0]], m[s[1]]);
    _blakeG(v, 1, 5, 9, 13, m[s[2]], m[s[3]]);
    _blakeG(v, 2, 6, 10, 14, m[s[4]], m[s[5]]);
    _blakeG(v, 3, 7, 11, 15, m[s[6]], m[s[7]]);
    _blakeG(v, 0, 5, 10, 15, m[s[8]], m[s[9]]);
    _blakeG(v, 1, 6, 11, 12, m[s[10]], m[s[11]]);
    _blakeG(v, 2, 7, 8, 13, m[s[12]], m[s[13]]);
    _blakeG(v, 3, 4, 9, 14, m[s[14]], m[s[15]]);
  }
  for (int i = 0; i < 8; i++) {
    h[i] = _xor64(h[i], _xor64(v[i], v[i + 8]));
  }
}

Uint8List _blake2b(Uint8List msg, int outLen) {
  final List<_U64> h = _ivPairs(_blakeIvHi, _blakeIvLo);
  h[0] = _xor64(h[0], (0, 0x01010000 ^ outLen));
  int t = 0;
  int off = 0;
  int remaining = msg.length;
  while (remaining > 128) {
    t += 128;
    _blake2bCompress(h, msg.sublist(off, off + 128), t, false);
    off += 128;
    remaining -= 128;
  }
  final Uint8List lastBlock = Uint8List(128);
  for (int i = 0; i < remaining; i++) {
    lastBlock[i] = msg[off + i];
  }
  t += remaining;
  _blake2bCompress(h, lastBlock, t, true);
  final Uint8List full = Uint8List(64);
  for (int i = 0; i < 8; i++) {
    _store64LE(full, i * 8, h[i]);
  }
  return Uint8List.fromList(full.sublist(0, outLen));
}

// --- scrypt ----------------------------------------------------------------

Uint8List _salsa208(Uint8List in64) {
  final Uint32List x = Uint32List(16);
  final ByteData bd = ByteData.sublistView(in64);
  for (int i = 0; i < 16; i++) {
    x[i] = bd.getUint32(i * 4, Endian.little);
  }
  final Uint32List orig = Uint32List.fromList(x);
  for (int r = 0; r < 4; r++) {
    _salsaQr(x, 0, 4, 8, 12);
    _salsaQr(x, 5, 9, 13, 1);
    _salsaQr(x, 10, 14, 2, 6);
    _salsaQr(x, 15, 3, 7, 11);
    _salsaQr(x, 0, 1, 2, 3);
    _salsaQr(x, 5, 6, 7, 4);
    _salsaQr(x, 10, 11, 8, 9);
    _salsaQr(x, 15, 12, 13, 14);
  }
  final Uint8List out = Uint8List(64);
  final ByteData ob = ByteData.sublistView(out);
  for (int i = 0; i < 16; i++) {
    ob.setUint32(i * 4, (x[i] + orig[i]) & _m32, Endian.little);
  }
  return out;
}

Uint8List _blockMix(Uint8List b, int r) {
  Uint8List x = b.sublist((2 * r - 1) * 64, 2 * r * 64);
  final Uint8List out = Uint8List(128 * r);
  for (int i = 0; i < 2 * r; i++) {
    final Uint8List t = Uint8List(64);
    for (int k = 0; k < 64; k++) {
      t[k] = x[k] ^ b[i * 64 + k];
    }
    x = _salsa208(t);
    final int dest = (i.isEven ? (i ~/ 2) : (r + i ~/ 2)) * 64;
    out.setRange(dest, dest + 64, x);
  }
  return out;
}

int _integerify(Uint8List x, int r) {
  final int off = (2 * r - 1) * 64;
  return x[off] | (x[off + 1] << 8) | (x[off + 2] << 16) | (x[off + 3] << 24);
}

Uint8List _roMix(Uint8List b, int n, int r) {
  Uint8List x = Uint8List.fromList(b);
  final List<Uint8List> v = List<Uint8List>.filled(n, Uint8List(0));
  for (int i = 0; i < n; i++) {
    v[i] = Uint8List.fromList(x);
    x = _blockMix(x, r);
  }
  for (int i = 0; i < n; i++) {
    final int j = _integerify(x, r) % n;
    final Uint8List t = Uint8List(x.length);
    for (int k = 0; k < x.length; k++) {
      t[k] = x[k] ^ v[j][k];
    }
    x = _blockMix(t, r);
  }
  return x;
}

Uint8List _scrypt(Uint8List pw, Uint8List salt, int n, int r, int p, int dkLen) {
  final Uint8List b = _pbkdf2(_sha256, pw, salt, 1, p * 128 * r);
  for (int i = 0; i < p; i++) {
    final Uint8List bi = b.sublist(i * 128 * r, (i + 1) * 128 * r);
    b.setRange(i * 128 * r, (i + 1) * 128 * r, _roMix(bi, n, r));
  }
  return _pbkdf2(_sha256, pw, b, 1, dkLen);
}

// --- RC4 (legacy / insecure) ----------------------------------------------

Uint8List _rc4(Uint8List key, Uint8List data) {
  final List<int> s = List<int>.generate(256, (int i) => i);
  int j = 0;
  for (int i = 0; i < 256; i++) {
    j = (j + s[i] + key[i % key.length]) & 0xFF;
    final int tmp = s[i];
    s[i] = s[j];
    s[j] = tmp;
  }
  final Uint8List out = Uint8List(data.length);
  int a = 0;
  j = 0;
  for (int n = 0; n < data.length; n++) {
    a = (a + 1) & 0xFF;
    j = (j + s[a]) & 0xFF;
    final int tmp = s[a];
    s[a] = s[j];
    s[j] = tmp;
    out[n] = data[n] ^ s[(s[a] + s[j]) & 0xFF];
  }
  return out;
}

// --- XChaCha20-Poly1305 ----------------------------------------------------

Uint8List _hchacha20(Uint8List key32, Uint8List nonce16) {
  final Uint32List x = Uint32List(16);
  x[0] = 0x61707865;
  x[1] = 0x3320646e;
  x[2] = 0x79622d32;
  x[3] = 0x6b206574;
  final ByteData kb = ByteData.sublistView(key32);
  for (int i = 0; i < 8; i++) {
    x[4 + i] = kb.getUint32(i * 4, Endian.little);
  }
  final ByteData nb = ByteData.sublistView(nonce16);
  for (int i = 0; i < 4; i++) {
    x[12 + i] = nb.getUint32(i * 4, Endian.little);
  }
  for (int i = 0; i < 10; i++) {
    _chachaQr(x, 0, 4, 8, 12);
    _chachaQr(x, 1, 5, 9, 13);
    _chachaQr(x, 2, 6, 10, 14);
    _chachaQr(x, 3, 7, 11, 15);
    _chachaQr(x, 0, 5, 10, 15);
    _chachaQr(x, 1, 6, 11, 12);
    _chachaQr(x, 2, 7, 8, 13);
    _chachaQr(x, 3, 4, 9, 14);
  }
  final Uint8List out = Uint8List(32);
  final ByteData ob = ByteData.sublistView(out);
  for (int i = 0; i < 4; i++) {
    ob.setUint32(i * 4, x[i], Endian.little);
  }
  for (int i = 0; i < 4; i++) {
    ob.setUint32(16 + i * 4, x[12 + i], Endian.little);
  }
  return out;
}

Uint8List _xchachaNonce(Uint8List nonce24) => _concat(<Uint8List>[Uint8List(4), nonce24.sublist(16, 24)]);

Uint8List _xchachaPolyEncrypt(Uint8List key32, Uint8List nonce24, Uint8List plain, Uint8List aad) => _chachaPolyEncrypt(_hchacha20(key32, nonce24.sublist(0, 16)), _xchachaNonce(nonce24), plain, aad);

Uint8List _xchachaPolyDecrypt(Uint8List key32, Uint8List nonce24, Uint8List cipherAndTag, Uint8List aad) =>
    _chachaPolyDecrypt(_hchacha20(key32, nonce24.sublist(0, 16)), _xchachaNonce(nonce24), cipherAndTag, aad);

// ===========================================================================
// Checksums + extended encoders
// ===========================================================================

int _crc16(Uint8List data) {
  int crc = 0xFFFF;
  for (final int b in data) {
    crc ^= b << 8;
    for (int i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF;
    }
  }
  return crc & 0xFFFF;
}

int _adler32(Uint8List data) {
  int a = 1;
  int b = 0;
  for (final int x in data) {
    a = (a + x) % 65521;
    b = (b + a) % 65521;
  }
  return ((b << 16) | a) & _m32;
}

int _fnv1a32(Uint8List data) {
  int h = 0x811c9dc5;
  for (final int b in data) {
    h ^= b;
    h = (((h & 0xFF) << 24) + ((h * 0x193) & _m32)) & _m32;
  }
  return h;
}

const String _b58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

String _base58Encode(Uint8List data) {
  int zeros = 0;
  while (zeros < data.length && data[zeros] == 0) {
    zeros++;
  }
  final List<int> digits = <int>[];
  for (final int b in data) {
    int carry = b;
    for (int i = 0; i < digits.length; i++) {
      carry += digits[i] << 8;
      digits[i] = carry % 58;
      carry ~/= 58;
    }
    while (carry > 0) {
      digits.add(carry % 58);
      carry ~/= 58;
    }
  }
  final StringBuffer sb = StringBuffer();
  for (int i = 0; i < zeros; i++) {
    sb.write("1");
  }
  for (int i = digits.length - 1; i >= 0; i--) {
    sb.write(_b58[digits[i]]);
  }
  return sb.toString();
}

Uint8List _base58Decode(String s) {
  int zeros = 0;
  while (zeros < s.length && s[zeros] == "1") {
    zeros++;
  }
  final List<int> bytes = <int>[];
  for (final int rune in s.runes) {
    final int val = _b58.indexOf(String.fromCharCode(rune));
    if (val < 0) throw const FormatException("Invalid Base58 character.");
    int carry = val;
    for (int i = 0; i < bytes.length; i++) {
      carry += bytes[i] * 58;
      bytes[i] = carry & 0xFF;
      carry >>= 8;
    }
    while (carry > 0) {
      bytes.add(carry & 0xFF);
      carry >>= 8;
    }
  }
  final List<int> out = <int>[];
  for (int i = 0; i < zeros; i++) {
    out.add(0);
  }
  for (int i = bytes.length - 1; i >= 0; i--) {
    out.add(bytes[i]);
  }
  return Uint8List.fromList(out);
}

String _base58Check(Uint8List payload) => _base58Encode(_concat(<Uint8List>[payload, _sha256(_sha256(payload)).sublist(0, 4)]));

String _ascii85Encode(Uint8List data) {
  final StringBuffer sb = StringBuffer();
  int i = 0;
  while (i < data.length) {
    final int n = min(4, data.length - i);
    int val = 0;
    for (int j = 0; j < 4; j++) {
      val = (val << 8) | (j < n ? data[i + j] : 0);
    }
    if (n == 4 && val == 0) {
      sb.write("z");
    } else {
      final List<int> chars = List<int>.filled(5, 0);
      int v = val;
      for (int k = 4; k >= 0; k--) {
        chars[k] = v % 85;
        v ~/= 85;
      }
      for (int k = 0; k < n + 1; k++) {
        sb.writeCharCode(33 + chars[k]);
      }
    }
    i += 4;
  }
  return sb.toString();
}

Uint8List _ascii85Decode(String s) {
  final List<int> out = <int>[];
  final List<int> group = <int>[];
  for (final int c in s.runes) {
    if (c == 122) {
      out.addAll(<int>[0, 0, 0, 0]);
      continue;
    }
    if (c < 33 || c > 117) continue;
    group.add(c - 33);
    if (group.length == 5) {
      int val = 0;
      for (final int g in group) {
        val = val * 85 + g;
      }
      out.add((val >> 24) & 0xFF);
      out.add((val >> 16) & 0xFF);
      out.add((val >> 8) & 0xFF);
      out.add(val & 0xFF);
      group.clear();
    }
  }
  if (group.isNotEmpty) {
    final int count = group.length;
    while (group.length < 5) {
      group.add(84);
    }
    int val = 0;
    for (final int g in group) {
      val = val * 85 + g;
    }
    final List<int> bytes = <int>[(val >> 24) & 0xFF, (val >> 16) & 0xFF, (val >> 8) & 0xFF, val & 0xFF];
    for (int k = 0; k < count - 1; k++) {
      out.add(bytes[k]);
    }
  }
  return Uint8List.fromList(out);
}

const String _b45 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ \$%*+-./:";

String _base45Encode(Uint8List data) {
  final StringBuffer sb = StringBuffer();
  int i = 0;
  while (i + 1 < data.length) {
    int n = data[i] * 256 + data[i + 1];
    sb.write(_b45[n % 45]);
    n ~/= 45;
    sb.write(_b45[n % 45]);
    n ~/= 45;
    sb.write(_b45[n % 45]);
    i += 2;
  }
  if (i < data.length) {
    int n = data[i];
    sb.write(_b45[n % 45]);
    n ~/= 45;
    sb.write(_b45[n % 45]);
  }
  return sb.toString();
}

Uint8List _base45Decode(String s) {
  final List<int> out = <int>[];
  int i = 0;
  while (i + 2 < s.length) {
    final int n = _b45.indexOf(s[i]) + _b45.indexOf(s[i + 1]) * 45 + _b45.indexOf(s[i + 2]) * 2025;
    out.add(n ~/ 256);
    out.add(n % 256);
    i += 3;
  }
  if (i + 1 < s.length) {
    out.add(_b45.indexOf(s[i]) + _b45.indexOf(s[i + 1]) * 45);
  }
  return Uint8List.fromList(out);
}

const String _b32hex = "0123456789ABCDEFGHIJKLMNOPQRSTUV";

String _base32HexEncode(Uint8List bytes) {
  final StringBuffer buffer = StringBuffer();
  int value = 0;
  int bits = 0;
  for (final int b in bytes) {
    value = (value << 8) | b;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      buffer.write(_b32hex[(value >> bits) & 31]);
    }
  }
  if (bits > 0) buffer.write(_b32hex[(value << (5 - bits)) & 31]);
  while (buffer.length % 8 != 0) {
    buffer.write("=");
  }
  return buffer.toString();
}

Uint8List _base32HexDecode(String input) {
  final String clean = input.toUpperCase().replaceAll("=", "").replaceAll(RegExp(r"\s"), "");
  final List<int> out = <int>[];
  int value = 0;
  int bits = 0;
  for (final int rune in clean.runes) {
    final int index = _b32hex.indexOf(String.fromCharCode(rune));
    if (index < 0) throw const FormatException("Invalid Base32Hex character.");
    value = (value << 5) | index;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      out.add((value >> bits) & 0xFF);
    }
  }
  return Uint8List.fromList(out);
}

String _rot47(String s) => String.fromCharCodes(s.runes.map((int c) => (c >= 33 && c <= 126) ? 33 + (c - 33 + 47) % 94 : c));

const Map<String, String> _morse = <String, String>{
  "A": ".-",
  "B": "-...",
  "C": "-.-.",
  "D": "-..",
  "E": ".",
  "F": "..-.",
  "G": "--.",
  "H": "....",
  "I": "..",
  "J": ".---",
  "K": "-.-",
  "L": ".-..",
  "M": "--",
  "N": "-.",
  "O": "---",
  "P": ".--.",
  "Q": "--.-",
  "R": ".-.",
  "S": "...",
  "T": "-",
  "U": "..-",
  "V": "...-",
  "W": ".--",
  "X": "-..-",
  "Y": "-.--",
  "Z": "--..",
  "0": "-----",
  "1": ".----",
  "2": "..---",
  "3": "...--",
  "4": "....-",
  "5": ".....",
  "6": "-....",
  "7": "--...",
  "8": "---..",
  "9": "----.",
  ".": ".-.-.-",
  ",": "--..--",
  "?": "..--..",
  "'": ".----.",
  "!": "-.-.--",
  "/": "-..-.",
  "(": "-.--.",
  ")": "-.--.-",
  "&": ".-...",
  ":": "---...",
  ";": "-.-.-.",
  "=": "-...-",
  "+": ".-.-.",
  "-": "-....-",
  "_": "..--.-",
  '"': ".-..-.",
  r"$": "...-..-",
  "@": ".--.-.",
};

String _morseEncode(String text) => text.toUpperCase().split("").map((String ch) => ch == " " ? "/" : (_morse[ch] ?? "")).where((String s) => s.isNotEmpty).join(" ");

String _morseDecode(String code) {
  final Map<String, String> reverse = <String, String>{for (final MapEntry<String, String> e in _morse.entries) e.value: e.key};
  return code.split(" ").map((String token) => token == "/" ? " " : (reverse[token] ?? "")).join();
}
