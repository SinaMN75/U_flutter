import "dart:convert";
import "dart:math";
import "dart:typed_data";
part "../src/crypto/u_crypto_engine.dart";

// UEncryption — hashing, encryption, key derivation and encoders in pure Dart (every platform, web included).
// For real secrets use seal/open (AES-GCM) or chacha20Poly1305*: they detect tampering. Keys come from Random.secure().
// The algorithms live in src/crypto; this file is only the API.

/// How a key/IV string is turned into bytes: utf8 (plain text), base64 or hex.
enum UByteEncoding { utf8, base64, hex }

/// AES mode for aesEncrypt/aesDecrypt; cbc is the default, gcm also authenticates, ecb is insecure.
enum UAesMode { cbc, cfb64, ctr, ecb, ofb64, ofb64Gctr, sic, gcm }

/// Hashes, encryption, key derivation and encoders, pure Dart on all 6 platforms. `UEncryption.sha256Hash("hi")`
abstract class UEncryption {
  /// Encrypts text with AES-256-GCM (tamper-proof, the one to use); returns base64. `UEncryption.seal(plainText: "secret", key: UEncryption.randomKey())`
  static String seal({required String plainText, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List nonce = _randomBytes(12);
    final Uint8List ct = _aesGcmEncrypt(_bytes(key, keyEncoding), nonce, _u8(plainText), aad == null ? Uint8List(0) : _u8(aad));
    return base64.encode(_concat(<Uint8List>[nonce, ct]));
  }

  /// Decrypts what seal() made; throws if the data or key is wrong. `UEncryption.open(base64Cipher: sealed, key: key)`
  static String open({required String base64Cipher, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List raw = base64.decode(base64Cipher);
    return utf8.decode(_aesGcmDecrypt(_bytes(key, keyEncoding), raw.sublist(0, 12), raw.sublist(12), aad == null ? Uint8List(0) : _u8(aad)));
  }

  /// Tamper-proof encryption with ChaCha20-Poly1305 (fast on phones without AES hardware); base64 out. `chacha20Poly1305Encrypt(plainText: "x", key: UEncryption.randomKey())`
  static String chacha20Poly1305Encrypt({required String plainText, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List nonce = _randomBytes(12);
    final Uint8List ct = _chachaPolyEncrypt(_bytes(key, keyEncoding), nonce, _u8(plainText), aad == null ? Uint8List(0) : _u8(aad));
    return base64.encode(_concat(<Uint8List>[nonce, ct]));
  }

  /// Decrypts chacha20Poly1305Encrypt output; throws if tampered. `chacha20Poly1305Decrypt(base64Cipher: c, key: key)`
  static String chacha20Poly1305Decrypt({required String base64Cipher, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List raw = base64.decode(base64Cipher);
    return utf8.decode(_chachaPolyDecrypt(_bytes(key, keyEncoding), raw.sublist(0, 12), raw.sublist(12), aad == null ? Uint8List(0) : _u8(aad)));
  }

  /// AES in any mode (CBC by default); key 16/24/32 chars, IV 16 chars; base64 out. `aesEncrypt(plainText: "x", key: "32-char-key...", iv: "16-char-iv......")`
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

  /// Reverses aesEncrypt with the same key, IV and mode. `aesDecrypt(base64Encrypted: c, key: k, iv: iv)`
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

  /// AES-256-CBC for raw bytes; key must be 32 chars and IV 16 chars; base64 out. `encryptUint8List(data: bytes, key: k, iv: iv)`
  static String encryptUint8List({required Uint8List data, required String key, required String iv}) {
    if (key.length != 32) throw ArgumentError("Key must be 32 bytes for AES-256.");
    if (iv.length != 16) throw ArgumentError("IV must be 16 bytes for AES.");
    return base64.encode(_aesCbc(_u8(key), _u8(iv), data, true, true));
  }

  /// Reverses encryptUint8List back to bytes. `decryptUint8List(base64Encrypted: c, key: k, iv: iv)`
  static Uint8List decryptUint8List({required String base64Encrypted, required String key, required String iv}) {
    if (key.length != 32) throw ArgumentError("Key must be 32 bytes for AES-256.");
    if (iv.length != 16) throw ArgumentError("IV must be 16 bytes for AES.");
    return _aesCbc(_u8(key), _u8(iv), base64.decode(base64Encrypted), false, true);
  }

  /// Salsa20 stream cipher (no tamper check); key 32 bytes, IV 8 bytes. `salsa20Encrypt(plainText: "x", key: k, iv: "8bytesiv")`
  static String salsa20Encrypt({required String plainText, required String key, required String iv, UByteEncoding keyEncoding = UByteEncoding.utf8, UByteEncoding ivEncoding = UByteEncoding.utf8}) =>
      base64.encode(_salsa20(_fit(_bytes(key, keyEncoding), 32), _fit(_bytes(iv, ivEncoding), 8), _u8(plainText)));

  /// Reverses salsa20Encrypt. `salsa20Decrypt(base64Encrypted: c, key: k, iv: iv)`
  static String salsa20Decrypt({
    required String base64Encrypted,
    required String key,
    required String iv,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding ivEncoding = UByteEncoding.utf8,
  }) => utf8.decode(_salsa20(_fit(_bytes(key, keyEncoding), 32), _fit(_bytes(iv, ivEncoding), 8), base64.decode(base64Encrypted)));

  /// ChaCha20 stream cipher (no tamper check); key 32 bytes, nonce 12 bytes. `chacha20Encrypt(plainText: "x", key: k, nonce: n)`
  static String chacha20Encrypt({
    required String plainText,
    required String key,
    required String nonce,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding nonceEncoding = UByteEncoding.utf8,
  }) => base64.encode(_chacha20(_fit(_bytes(key, keyEncoding), 32), _fit(_bytes(nonce, nonceEncoding), 12), 1, _u8(plainText)));

  /// Reverses chacha20Encrypt. `chacha20Decrypt(base64Encrypted: c, key: k, nonce: n)`
  static String chacha20Decrypt({
    required String base64Encrypted,
    required String key,
    required String nonce,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding nonceEncoding = UByteEncoding.utf8,
  }) => utf8.decode(_chacha20(_fit(_bytes(key, keyEncoding), 32), _fit(_bytes(nonce, nonceEncoding), 12), 1, base64.decode(base64Encrypted)));

  /// Fernet token (Python cryptography compatible); key is 32 bytes base64. `fernetEncrypt(plainText: "x", key: UEncryption.randomKey())`
  static String fernetEncrypt({required String plainText, required String key, UByteEncoding keyEncoding = UByteEncoding.base64}) =>
      base64.encode(_fernetEncryptBytes(_fit(_bytes(key, keyEncoding), 32), _u8(plainText), DateTime.now().millisecondsSinceEpoch ~/ 1000));

  /// Reads a Fernet token; throws if tampered. `fernetDecrypt(base64Encrypted: token, key: key)`
  static String fernetDecrypt({required String base64Encrypted, required String key, UByteEncoding keyEncoding = UByteEncoding.base64}) =>
      utf8.decode(_fernetDecryptBytes(_fit(_bytes(key, keyEncoding), 32), base64.decode(base64Encrypted)));

  /// Turns a password into a key with PBKDF2-SHA256 (slow on purpose). `pbkdf2(password: "1234", salt: "user@x.com")`
  static String pbkdf2({required String password, required String salt, int iterations = 100000, int length = 32, UByteEncoding saltEncoding = UByteEncoding.utf8, bool asHex = false}) {
    final Uint8List dk = _pbkdf2(_sha256, _u8(password), _bytes(salt, saltEncoding), iterations, length);
    return asHex ? _toHex(dk) : base64.encode(dk);
  }

  /// Derives a key from a strong secret with HKDF-SHA256. `hkdf(secret: sharedSecret, info: "chat")`
  static String hkdf({required String secret, String salt = "", String info = "", int length = 32, bool asHex = false}) {
    final Uint8List dk = _hkdf(_sha256, _u8(secret), _u8(salt), _u8(info), length);
    return asHex ? _toHex(dk) : base64.encode(dk);
  }

  /// Text → base64. `base64EncodeText("hi")` → "aGk="
  static String base64EncodeText(String text) => base64.encode(utf8.encode(text));

  /// Base64 → text. `base64DecodeText("aGk=")` → "hi"
  static String base64DecodeText(String value) => utf8.decode(base64.decode(value));

  /// Text → URL-safe base64 (- and _ instead of + and /). `base64UrlEncodeText("hi?")`
  static String base64UrlEncodeText(String text) => base64Url.encode(utf8.encode(text));

  /// URL-safe base64 → text. `base64UrlDecodeText(value)`
  static String base64UrlDecodeText(String value) => utf8.decode(base64Url.decode(value));

  /// Text → hex. `hexEncodeText("hi")` → "6869"
  static String hexEncodeText(String text) => _toHex(utf8.encode(text));

  /// Hex → text. `hexDecodeText("6869")` → "hi"
  static String hexDecodeText(String value) => utf8.decode(_fromHex(value));

  /// Bytes → hex. `hexEncode([255, 1])` → "ff01"
  static String hexEncode(List<int> bytes) => _toHex(bytes);

  /// Hex → bytes. `hexToBytes("ff01")` → [255, 1]
  static List<int> hexToBytes(String hex) => _fromHex(hex);

  static const String _base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

  /// Text → Base32 (RFC 4648, used by 2FA secrets). `base32EncodeText("hi")`
  static String base32EncodeText(String text) => base32Encode(utf8.encode(text));

  /// Base32 → text. `base32DecodeText("NBUQ====")` → "hi"
  static String base32DecodeText(String value) => utf8.decode(base32Decode(value));

  /// Bytes → Base32. `base32Encode(bytes)`
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

  /// Base32 → bytes (ignores spaces and padding). `base32Decode("JBSWY3DP")`
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

  static Uint8List _xorBytes(List<int> data, List<int> key) {
    if (key.isEmpty) throw ArgumentError("XOR key must not be empty.");
    final Uint8List out = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      out[i] = data[i] ^ key[i % key.length];
    }
    return out;
  }

  /// XOR with a repeating key (obfuscation, not security); base64 out. `xorEncrypt(plainText: "x", key: "k")`
  static String xorEncrypt({required String plainText, required String key, UByteEncoding keyEncoding = UByteEncoding.utf8}) => base64.encode(_xorBytes(_u8(plainText), _bytes(key, keyEncoding)));

  /// Reverses xorEncrypt. `xorDecrypt(base64Encrypted: c, key: "k")`
  static String xorDecrypt({required String base64Encrypted, required String key, UByteEncoding keyEncoding = UByteEncoding.utf8}) =>
      utf8.decode(_xorBytes(base64.decode(base64Encrypted), _bytes(key, keyEncoding)));

  /// Rotates letters by 13 (applying twice gives the original). `rot13("abc")` → "nop"
  static String rot13(String text) => caesarShift(text, 13);

  /// Shifts letters by [shift] places. `caesarShift("abc", 1)` → "bcd"
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

  /// MD5 hex (checksums only, not for passwords). `md5Hash("hi")`
  static String md5Hash(String text) => _toHex(_md5(_u8(text)));

  /// SHA-1 hex (legacy checksums only). `sha1Hash("hi")`
  static String sha1Hash(String text) => _toHex(_sha1(_u8(text)));

  /// SHA-224 hex. `sha224Hash("hi")`
  static String sha224Hash(String text) => _toHex(_sha224(_u8(text)));

  /// SHA-256 hex, the usual choice. `sha256Hash("hi")`
  static String sha256Hash(String text) => _toHex(_sha256(_u8(text)));

  /// SHA-384 hex. `sha384Hash("hi")`
  static String sha384Hash(String text) => _toHex(_sha384(_u8(text)));

  /// SHA-512 hex. `sha512Hash("hi")`
  static String sha512Hash(String text) => _toHex(_sha512(_u8(text)));

  /// HMAC-SHA256 hex, e.g. to sign API requests. `hmacSha256(body, secret)`
  static String hmacSha256(String text, String key) => _toHex(_hmac(_sha256, _u8(key), _u8(text)));

  /// HMAC-SHA512 hex. `hmacSha512(body, secret)`
  static String hmacSha512(String text, String key) => _toHex(_hmac(_sha512, _u8(key), _u8(text)));

  /// CRC-32 checksum as an int (zip/png style). `crc32("hi")`
  static int crc32(String text) => _crc32(_u8(text));

  /// New random 32-byte key as base64, ready for seal(). `final String key = UEncryption.randomKey();`
  static String randomKey({int bytes = 32}) => base64.encode(_randomBytes(bytes));

  /// New random 16-byte IV as base64. `randomIv()`
  static String randomIv({int bytes = 16}) => base64.encode(_randomBytes(bytes));

  /// Random hex string, e.g. for tokens (16 bytes = 32 chars). `randomHex(bytes: 8)`
  static String randomHex({int bytes = 16}) => _toHex(_randomBytes(bytes));

  /// Compares two secrets without leaking timing. `constantTimeEquals(sentMac, expectedMac)`
  static bool constantTimeEquals(String a, String b) => _ctEquals(_u8(a), _u8(b));

  /// Secure random bytes. `randomBytes(16)`
  static Uint8List randomBytes(int length) => _randomBytes(length);

  /// SHA-1 of bytes, as bytes. `sha1Bytes(data)`
  static Uint8List sha1Bytes(List<int> data) => _sha1(Uint8List.fromList(data));

  /// SHA-256 of bytes, as bytes. `sha256Bytes(data)`
  static Uint8List sha256Bytes(List<int> data) => _sha256(Uint8List.fromList(data));

  /// HMAC-SHA256 of bytes, as bytes. `hmacSha256Bytes(data, key)`
  static Uint8List hmacSha256Bytes(List<int> data, List<int> key) => _hmac(_sha256, Uint8List.fromList(key), Uint8List.fromList(data));

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

  /// SHA-3 hex; bits 224/256/384/512. `sha3("hi", bits: 512)`
  static String sha3(String text, {int bits = 256}) => _toHex(_sha3(_u8(text), bits));

  /// Keccak-256 hex (Ethereum style, not SHA-3). `keccak256Hash("hi")`
  static String keccak256Hash(String text) => _toHex(_keccakLegacy(_u8(text), 256));

  /// SHAKE128 hex of any length. `shake128("hi", bytes: 16)`
  static String shake128(String text, {int bytes = 32}) => _toHex(_shake(_u8(text), 256, bytes));

  /// SHAKE256 hex of any length. `shake256("hi", bytes: 32)`
  static String shake256(String text, {int bytes = 64}) => _toHex(_shake(_u8(text), 512, bytes));

  /// RIPEMD-160 hex. `ripemd160Hash("hi")`
  static String ripemd160Hash(String text) => _toHex(_ripemd160(_u8(text)));

  /// MD4 hex (legacy only). `md4Hash("hi")`
  static String md4Hash(String text) => _toHex(_md4(_u8(text)));

  /// SM3 hex (Chinese national standard). `sm3Hash("hi")`
  static String sm3Hash(String text) => _toHex(_sm3(_u8(text)));

  /// SHA-512/256 hex. `sha512256Hash("hi")`
  static String sha512256Hash(String text) => _toHex(_sha512t256(_u8(text)));

  /// BLAKE2b hex, 1-64 bytes. `blake2bHash("hi", bytes: 32)`
  static String blake2bHash(String text, {int bytes = 64}) => _toHex(_blake2b(_u8(text), bytes));

  /// HMAC-SHA1 hex (TOTP and old APIs). `hmacSha1(text, key)`
  static String hmacSha1(String text, String key) => _toHex(_hmac(_sha1, _u8(key), _u8(text)));

  /// Password → key with scrypt (memory-hard, slow on purpose). `scrypt(password: "1234", salt: "salt")`
  static String scrypt({required String password, required String salt, int n = 16384, int r = 8, int p = 1, int dkLen = 32, UByteEncoding saltEncoding = UByteEncoding.utf8, bool asHex = false}) {
    final Uint8List dk = _scrypt(_u8(password), _bytes(salt, saltEncoding), n, r, p, dkLen);
    return asHex ? _toHex(dk) : base64.encode(dk);
  }

  /// Tamper-proof XChaCha20-Poly1305 with a 24-byte random nonce; base64 out. `xchacha20Poly1305Encrypt(plainText: "x", key: key)`
  static String xchacha20Poly1305Encrypt({required String plainText, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List nonce = _randomBytes(24);
    final Uint8List ct = _xchachaPolyEncrypt(_bytes(key, keyEncoding), nonce, _u8(plainText), aad == null ? Uint8List(0) : _u8(aad));
    return base64.encode(_concat(<Uint8List>[nonce, ct]));
  }

  /// Reverses xchacha20Poly1305Encrypt; throws if tampered. `xchacha20Poly1305Decrypt(base64Cipher: c, key: key)`
  static String xchacha20Poly1305Decrypt({required String base64Cipher, required String key, String? aad, UByteEncoding keyEncoding = UByteEncoding.base64}) {
    final Uint8List raw = base64.decode(base64Cipher);
    return utf8.decode(_xchachaPolyDecrypt(_bytes(key, keyEncoding), raw.sublist(0, 24), raw.sublist(24), aad == null ? Uint8List(0) : _u8(aad)));
  }

  /// RC4 (broken, only for talking to old systems); base64 out. `rc4Encrypt(plainText: "x", key: "k")`
  static String rc4Encrypt({required String plainText, required String key, UByteEncoding keyEncoding = UByteEncoding.utf8}) => base64.encode(_rc4(_bytes(key, keyEncoding), _u8(plainText)));

  /// Reverses rc4Encrypt. `rc4Decrypt(base64Encrypted: c, key: "k")`
  static String rc4Decrypt({required String base64Encrypted, required String key, UByteEncoding keyEncoding = UByteEncoding.utf8}) =>
      utf8.decode(_rc4(_bytes(key, keyEncoding), base64.decode(base64Encrypted)));

  /// CRC-16 checksum as an int. `crc16("hi")`
  static int crc16(String text) => _crc16(_u8(text));

  /// Adler-32 checksum as an int. `adler32("hi")`
  static int adler32(String text) => _adler32(_u8(text));

  /// FNV-1a 32-bit hash as an int (fast, stable across runs). `fnv1a32("hi")`
  static int fnv1a32(String text) => _fnv1a32(_u8(text));

  /// Bytes → Base58 (Bitcoin alphabet). `base58Encode(bytes)`
  static String base58Encode(List<int> bytes) => _base58Encode(Uint8List.fromList(bytes));

  /// Base58 → bytes. `base58Decode("3yZe")`
  static List<int> base58Decode(String value) => _base58Decode(value);

  /// Text → Base58. `base58EncodeText("hi")`
  static String base58EncodeText(String text) => _base58Encode(_u8(text));

  /// Base58 → text. `base58DecodeText(value)`
  static String base58DecodeText(String value) => utf8.decode(_base58Decode(value));

  /// Base58Check (payload + 4-byte double-SHA256 checksum). `base58Check(payload)`
  static String base58Check(List<int> payload) => _base58Check(Uint8List.fromList(payload));

  /// Text → Ascii85. `ascii85EncodeText("hi")`
  static String ascii85EncodeText(String text) => _ascii85Encode(_u8(text));

  /// Ascii85 → text. `ascii85DecodeText(value)`
  static String ascii85DecodeText(String value) => utf8.decode(_ascii85Decode(value));

  /// Text → Base45 (QR-friendly, used by EU health certificates). `base45EncodeText("hi")`
  static String base45EncodeText(String text) => _base45Encode(_u8(text));

  /// Base45 → text. `base45DecodeText(value)`
  static String base45DecodeText(String value) => utf8.decode(_base45Decode(value));

  /// Text → Base32hex (sort-preserving alphabet). `base32HexEncodeText("hi")`
  static String base32HexEncodeText(String text) => _base32HexEncode(_u8(text));

  /// Base32hex → text. `base32HexDecodeText(value)`
  static String base32HexDecodeText(String value) => utf8.decode(_base32HexDecode(value));

  /// Rotates printable ASCII by 47 (applying twice gives the original). `rot47("Hi!")`
  static String rot47(String text) => _rot47(text);

  /// Text → Morse code. `morseEncode("SOS")` → "... --- ..."
  static String morseEncode(String text) => _morseEncode(text);

  /// Morse code → text. `morseDecode("... --- ...")` → "SOS"
  static String morseDecode(String code) => _morseDecode(code);

  /// Escapes text for a URL. `urlEncode("a b")` → "a%20b"
  static String urlEncode(String text) => Uri.encodeComponent(text);

  /// Un-escapes URL text. `urlDecode("a%20b")` → "a b"
  static String urlDecode(String value) => Uri.decodeComponent(value);
}
