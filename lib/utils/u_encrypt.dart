import "dart:convert";
import "dart:typed_data";

import "package:crypto/crypto.dart";
import "package:encrypt/encrypt.dart";

/// How a textual secret key / IV should be interpreted as raw bytes.
enum UByteEncoding { utf8, base64, hex }

/// AES block-cipher modes supported by [UEncryption].
enum UAesMode { cbc, cfb64, ctr, ecb, ofb64, ofb64Gctr, sic, gcm }

/// Reusable, UI-agnostic cryptography helpers: symmetric ciphers (AES, Salsa20,
/// Fernet), reversible encoders (Base64/Hex) and one-way hashes (MD5/SHA/HMAC).
/// Everything runs locally; no method touches the network.
abstract class UEncryption {
  static String encryptUint8List({required Uint8List data, required String key, required String iv}) {
    try {
      if (key.length != 32) throw ArgumentError("Key must be 32 bytes for AES-256.");
      if (iv.length != 16) throw ArgumentError("IV must be 16 bytes for AES.");

      final Encrypter encrypter = Encrypter(AES(Key.fromUtf8(key)));
      final IV ivObject = IV.fromUtf8(iv);
      final Encrypted encrypted = encrypter.encryptBytes(data, iv: ivObject);
      return encrypted.base64;
    } catch (e) {
      throw Exception("Encryption failed: $e");
    }
  }

  static Uint8List decryptUint8List({required String base64Encrypted, required String key, required String iv}) {
    try {
      if (key.length != 32) throw ArgumentError("Key must be 32 bytes for AES-256.");
      if (iv.length != 16) throw ArgumentError("IV must be 16 bytes for AES.");

      final Encrypter encrypter = Encrypter(AES(Key.fromUtf8(key)));
      final IV ivObject = IV.fromUtf8(iv);
      final Encrypted encrypted = Encrypted.fromBase64(base64Encrypted);
      return Uint8List.fromList(encrypter.decryptBytes(encrypted, iv: ivObject));
    } catch (e) {
      throw Exception("Decryption failed: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Byte parsing helpers.
  // ---------------------------------------------------------------------------
  static Key parseKey(final String value, final UByteEncoding encoding) => switch (encoding) {
    UByteEncoding.utf8 => Key.fromUtf8(value),
    UByteEncoding.base64 => Key.fromBase64(value),
    UByteEncoding.hex => Key(Uint8List.fromList(hexToBytes(value))),
  };

  static IV parseIv(final String value, final UByteEncoding encoding) => switch (encoding) {
    UByteEncoding.utf8 => IV.fromUtf8(value),
    UByteEncoding.base64 => IV.fromBase64(value),
    UByteEncoding.hex => IV(Uint8List.fromList(hexToBytes(value))),
  };

  static AESMode _mode(final UAesMode mode) => switch (mode) {
    UAesMode.cbc => AESMode.cbc,
    UAesMode.cfb64 => AESMode.cfb64,
    UAesMode.ctr => AESMode.ctr,
    UAesMode.ecb => AESMode.ecb,
    UAesMode.ofb64 => AESMode.ofb64,
    UAesMode.ofb64Gctr => AESMode.ofb64Gctr,
    UAesMode.sic => AESMode.sic,
    UAesMode.gcm => AESMode.gcm,
  };

  // ---------------------------------------------------------------------------
  // AES (configurable mode, padding and key/IV byte-encoding).
  // ---------------------------------------------------------------------------
  static String aesEncrypt({
    required String plainText,
    required String key,
    required String iv,
    UAesMode mode = UAesMode.cbc,
    bool padding = true,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding ivEncoding = UByteEncoding.utf8,
  }) {
    final Encrypter encrypter = Encrypter(AES(parseKey(key, keyEncoding), mode: _mode(mode), padding: padding ? "PKCS7" : null));
    return encrypter.encrypt(plainText, iv: parseIv(iv, ivEncoding)).base64;
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
    final Encrypter encrypter = Encrypter(AES(parseKey(key, keyEncoding), mode: _mode(mode), padding: padding ? "PKCS7" : null));
    return encrypter.decrypt(Encrypted.fromBase64(base64Encrypted), iv: parseIv(iv, ivEncoding));
  }

  // ---------------------------------------------------------------------------
  // Salsa20 stream cipher (32-byte key, 8-byte IV).
  // ---------------------------------------------------------------------------
  static String salsa20Encrypt({
    required String plainText,
    required String key,
    required String iv,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding ivEncoding = UByteEncoding.utf8,
  }) => Encrypter(Salsa20(parseKey(key, keyEncoding))).encrypt(plainText, iv: parseIv(iv, ivEncoding)).base64;

  static String salsa20Decrypt({
    required String base64Encrypted,
    required String key,
    required String iv,
    UByteEncoding keyEncoding = UByteEncoding.utf8,
    UByteEncoding ivEncoding = UByteEncoding.utf8,
  }) => Encrypter(Salsa20(parseKey(key, keyEncoding))).decrypt(Encrypted.fromBase64(base64Encrypted), iv: parseIv(iv, ivEncoding));

  // ---------------------------------------------------------------------------
  // Fernet (32-byte key; IV is generated internally).
  // ---------------------------------------------------------------------------
  static String fernetEncrypt({required String plainText, required String key, UByteEncoding keyEncoding = UByteEncoding.base64}) =>
      Encrypter(Fernet(parseKey(key, keyEncoding))).encrypt(plainText).base64;

  static String fernetDecrypt({required String base64Encrypted, required String key, UByteEncoding keyEncoding = UByteEncoding.base64}) =>
      Encrypter(Fernet(parseKey(key, keyEncoding))).decrypt(Encrypted.fromBase64(base64Encrypted));

  // ---------------------------------------------------------------------------
  // Reversible text encoders.
  // ---------------------------------------------------------------------------
  static String base64EncodeText(final String text) => base64.encode(utf8.encode(text));

  static String base64DecodeText(final String value) => utf8.decode(base64.decode(value));

  static String base64UrlEncodeText(final String text) => base64Url.encode(utf8.encode(text));

  static String base64UrlDecodeText(final String value) => utf8.decode(base64Url.decode(value));

  static String hexEncodeText(final String text) => hexEncode(utf8.encode(text));

  static String hexDecodeText(final String value) => utf8.decode(hexToBytes(value));

  static String hexEncode(final List<int> bytes) => bytes.map((final int b) => b.toRadixString(16).padLeft(2, "0")).join();

  static List<int> hexToBytes(final String hex) {
    final String clean = hex.replaceAll(RegExp(r"\s"), "");
    if (clean.length.isOdd) throw const FormatException("Hex length must be even.");
    return <int>[for (int i = 0; i < clean.length; i += 2) int.parse(clean.substring(i, i + 2), radix: 16)];
  }

  // ---------------------------------------------------------------------------
  // One-way hashes.
  // ---------------------------------------------------------------------------
  static String md5Hash(final String text) => md5.convert(utf8.encode(text)).toString();

  static String sha1Hash(final String text) => sha1.convert(utf8.encode(text)).toString();

  static String sha224Hash(final String text) => sha224.convert(utf8.encode(text)).toString();

  static String sha256Hash(final String text) => sha256.convert(utf8.encode(text)).toString();

  static String sha384Hash(final String text) => sha384.convert(utf8.encode(text)).toString();

  static String sha512Hash(final String text) => sha512.convert(utf8.encode(text)).toString();

  static String hmacSha256(final String text, final String key) => Hmac(sha256, utf8.encode(key)).convert(utf8.encode(text)).toString();

  // ---------------------------------------------------------------------------
  // Random material generators (returned as Base64).
  // ---------------------------------------------------------------------------
  static String randomKey({final int bytes = 32}) => Key.fromSecureRandom(bytes).base64;

  static String randomIv({final int bytes = 16}) => IV.fromSecureRandom(bytes).base64;
}
