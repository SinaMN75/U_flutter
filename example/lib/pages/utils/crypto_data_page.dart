import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// UEncryption, UUUID, UOtp, UConvert, UClipboard and UTimezone. Pure Dart, every platform.
class CryptoDataPage extends StatelessWidget {
  const CryptoDataPage({super.key});

  static final String _key = UEncryption.randomKey();
  static const String _aesKey = "01234567890123456789012345678901";
  static const String _iv = "0123456789012345";
  static const String _json = '{"name":"Sina","tags":["a","b"],"age":30}';

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Crypto, ids, data",
    intro: "Every row here runs offline and works on all 6 platforms.",
    children: <Widget>[
      DemoGroup("Tamper-proof encryption (use these)", <Widget>[
        Fn("UEncryption.randomKey()", UEncryption.randomKey, auto: true),
        Fn(
          "UEncryption.open(base64Cipher: seal(…), key: key)",
          () => UEncryption.open(
            base64Cipher: UEncryption.seal(plainText: "secret", key: _key),
            key: _key,
          ),
          auto: true,
        ),
        Fn(
          "chacha20Poly1305Encrypt → chacha20Poly1305Decrypt",
          () => UEncryption.chacha20Poly1305Decrypt(
            base64Cipher: UEncryption.chacha20Poly1305Encrypt(plainText: "secret", key: _key),
            key: _key,
          ),
        ),
        Fn(
          "xchacha20Poly1305Encrypt → xchacha20Poly1305Decrypt",
          () => UEncryption.xchacha20Poly1305Decrypt(
            base64Cipher: UEncryption.xchacha20Poly1305Encrypt(plainText: "secret", key: _key),
            key: _key,
          ),
        ),
        Fn(
          "fernetEncrypt → fernetDecrypt",
          () => UEncryption.fernetDecrypt(
            base64Encrypted: UEncryption.fernetEncrypt(plainText: "secret", key: _key),
            key: _key,
          ),
        ),
      ]),
      DemoGroup("Ciphers", <Widget>[
        Fn(
          "aesEncrypt → aesDecrypt (CBC)",
          () => UEncryption.aesDecrypt(
            base64Encrypted: UEncryption.aesEncrypt(plainText: "secret", key: _aesKey, iv: _iv),
            key: _aesKey,
            iv: _iv,
          ),
        ),
        Fn(
          "encryptUint8List → decryptUint8List",
          () => UEncryption.decryptUint8List(
            base64Encrypted: UEncryption.encryptUint8List(data: Uint8List.fromList(<int>[1, 2, 3]), key: _aesKey, iv: _iv),
            key: _aesKey,
            iv: _iv,
          ),
        ),
        Fn(
          "salsa20Encrypt → salsa20Decrypt",
          () => UEncryption.salsa20Decrypt(
            base64Encrypted: UEncryption.salsa20Encrypt(plainText: "secret", key: _aesKey, iv: "8bytesiv"),
            key: _aesKey,
            iv: "8bytesiv",
          ),
        ),
        Fn(
          "chacha20Encrypt → chacha20Decrypt",
          () => UEncryption.chacha20Decrypt(
            base64Encrypted: UEncryption.chacha20Encrypt(plainText: "secret", key: _aesKey, nonce: "twelve bytes"),
            key: _aesKey,
            nonce: "twelve bytes",
          ),
        ),
        Fn(
          "xorEncrypt → xorDecrypt",
          () => UEncryption.xorDecrypt(
            base64Encrypted: UEncryption.xorEncrypt(plainText: "secret", key: "k"),
            key: "k",
          ),
        ),
        Fn(
          "rc4Encrypt → rc4Decrypt",
          () => UEncryption.rc4Decrypt(
            base64Encrypted: UEncryption.rc4Encrypt(plainText: "secret", key: "k"),
            key: "k",
          ),
        ),
        Fn('UEncryption.rot13("abc") / rot47 / caesarShift', () => <String>[UEncryption.rot13("abc"), UEncryption.rot47("Hi!"), UEncryption.caesarShift("abc", 1)], auto: true),
      ]),
      DemoGroup("Hashes & checksums", <Widget>[
        Fn('UEncryption.sha256Hash("hi")', () => UEncryption.sha256Hash("hi"), auto: true),
        Fn(
          "md5 / sha1 / sha224 / sha384 / sha512",
          () => <String>[UEncryption.md5Hash("hi"), UEncryption.sha1Hash("hi"), UEncryption.sha224Hash("hi"), UEncryption.sha384Hash("hi"), UEncryption.sha512Hash("hi")],
        ),
        Fn("sha3 / keccak256 / shake128 / shake256", () => <String>[UEncryption.sha3("hi"), UEncryption.keccak256Hash("hi"), UEncryption.shake128("hi"), UEncryption.shake256("hi")]),
        Fn(
          "ripemd160 / md4 / sm3 / sha512256 / blake2b",
          () => <String>[UEncryption.ripemd160Hash("hi"), UEncryption.md4Hash("hi"), UEncryption.sm3Hash("hi"), UEncryption.sha512256Hash("hi"), UEncryption.blake2bHash("hi", bytes: 32)],
        ),
        Fn("hmacSha256 / hmacSha512 / hmacSha1", () => <String>[UEncryption.hmacSha256("body", "key"), UEncryption.hmacSha512("body", "key"), UEncryption.hmacSha1("body", "key")]),
        Fn("crc32 / crc16 / adler32 / fnv1a32", () => <int>[UEncryption.crc32("hi"), UEncryption.crc16("hi"), UEncryption.adler32("hi"), UEncryption.fnv1a32("hi")]),
        Fn(
          "sha1Bytes / sha256Bytes / hmacSha256Bytes",
          () => <int>[
            UEncryption.sha1Bytes(<int>[1]).length,
            UEncryption.sha256Bytes(<int>[1]).length,
            UEncryption.hmacSha256Bytes(<int>[1], <int>[2]).length,
          ],
        ),
      ]),
      DemoGroup("Keys & random", <Widget>[
        Fn('UEncryption.pbkdf2(password: "1234", salt: "user@x.com")', () => UEncryption.pbkdf2(password: "1234", salt: "user@x.com", iterations: 10000)),
        Fn('UEncryption.hkdf(secret: "shared", info: "chat")', () => UEncryption.hkdf(secret: "shared", info: "chat")),
        Fn('UEncryption.scrypt(password: "1234", salt: "salt", n: 1024)', () => UEncryption.scrypt(password: "1234", salt: "salt", n: 1024)),
        Fn("randomIv / randomHex / randomBytes", () => <Object>[UEncryption.randomIv(), UEncryption.randomHex(bytes: 8), UEncryption.randomBytes(4)]),
        Fn('UEncryption.constantTimeEquals("a", "a")', () => UEncryption.constantTimeEquals("a", "a")),
      ]),
      DemoGroup("Encoders", <Widget>[
        Fn("base64EncodeText / base64DecodeText", () => UEncryption.base64DecodeText(UEncryption.base64EncodeText("سلام"))),
        Fn("base64UrlEncodeText / base64UrlDecodeText", () => UEncryption.base64UrlDecodeText(UEncryption.base64UrlEncodeText("hi?"))),
        Fn(
          "hexEncodeText / hexDecodeText / hexEncode / hexToBytes",
          () => <Object>[
            UEncryption.hexEncodeText("hi"),
            UEncryption.hexDecodeText("6869"),
            UEncryption.hexEncode(<int>[255, 1]),
            UEncryption.hexToBytes("ff01"),
          ],
        ),
        Fn(
          "base32EncodeText / base32DecodeText / base32Encode / base32Decode",
          () => <Object>[
            UEncryption.base32EncodeText("hi"),
            UEncryption.base32DecodeText("NBUQ===="),
            UEncryption.base32Encode(<int>[1, 2]),
            UEncryption.base32Decode("AEBA===="),
          ],
        ),
        Fn("base32HexEncodeText / base32HexDecodeText", () => UEncryption.base32HexDecodeText(UEncryption.base32HexEncodeText("hi"))),
        Fn(
          "base58Encode / base58Decode / base58EncodeText / base58DecodeText / base58Check",
          () => <Object>[
            UEncryption.base58Encode(<int>[1, 2, 3]),
            UEncryption.base58Decode("Ldp"),
            UEncryption.base58DecodeText(UEncryption.base58EncodeText("hi")),
            UEncryption.base58Check(<int>[0, 1]),
          ],
        ),
        Fn("ascii85EncodeText / ascii85DecodeText", () => UEncryption.ascii85DecodeText(UEncryption.ascii85EncodeText("hello"))),
        Fn("base45EncodeText / base45DecodeText", () => UEncryption.base45DecodeText(UEncryption.base45EncodeText("hello"))),
        Fn('UEncryption.morseEncode("SOS") / morseDecode', () => <String>[UEncryption.morseEncode("SOS"), UEncryption.morseDecode("... --- ...")]),
        Fn('UEncryption.urlEncode("a b") / urlDecode', () => <String>[UEncryption.urlEncode("a b"), UEncryption.urlDecode("a%20b")]),
      ]),
      DemoGroup("UUIDs", <Widget>[
        Fn("UUUID.uuidV4()", UUUID.uuidV4, auto: true),
        Fn("UUUID.uuidV7()", UUUID.uuidV7, auto: true),
        Fn("UUUID.uuidV1() / uuidV6() / uuidV8()", () => <String>[UUUID.uuidV1(), UUUID.uuidV6(), UUUID.uuidV8()]),
        Fn('UUUID.uuidV5(UUUID.namespaceUrl, "https://x.com")', () => UUUID.uuidV5(UUUID.namespaceUrl, "https://x.com")),
        Fn("UUUID.isValid / versionOf / timeOf", () {
          final String id = UUUID.uuidV7();
          return <Object?>[UUUID.isValid(id), UUUID.versionOf(id), UUUID.timeOf(id)];
        }),
      ]),
      DemoGroup("Offline OTP (POS)", <Widget>[
        Fn('UOtp.generateVerhoeff("236")', () => UOtp.generateVerhoeff("236"), auto: true),
        Fn('UOtp.generateOtp("POS1234", 8) → verifyOtp', () {
          final String code = UOtp.generateOtp("POS1234", 8);
          return "$code → ${UOtp.verifyOtp("POS1234", code)}";
        }),
        Fn('UOtp.generateAdminOtp("POS1234", 8) → verifyAdminOtp', () {
          final String code = UOtp.generateAdminOtp("POS1234", 8);
          return "$code → ${UOtp.verifyAdminOtp("POS1234", code)}";
        }),
      ]),
      DemoGroup("Data formats", <Widget>[
        Fn("UConvert.prettyJson(json)", () => UConvert.prettyJson(_json), auto: true),
        Fn("UConvert.minifyJson(pretty)", () => UConvert.minifyJson(UConvert.prettyJson(_json))),
        Fn("UConvert.encodeJson(map, pretty: true) / decodeJson", () => UConvert.decodeJson(UConvert.encodeJson(<String, int>{"a": 1}, pretty: true))),
        Fn("UConvert.mapToQueryString / queryStringToMap", () => UConvert.queryStringToMap(UConvert.mapToQueryString(<String, dynamic>{"q": "hi there", "page": 2}))),
        Fn("UConvert.jsonToXml(json)", () => UConvert.jsonToXml(_json)),
        Fn("UConvert.valueToXml(map)", () => UConvert.valueToXml(<String, Object>{"a": 1})),
        Fn("UConvert.xmlToJson(xml)", () => UConvert.xmlToJson('<user id="1"><name>Sina</name></user>')),
        Fn("UConvert.jsonToCsv(rows) / csvToJson", () => UConvert.csvToJson(UConvert.jsonToCsv('[{"a":1,"b":"x,y"},{"a":2,"b":"z"}]'))),
      ]),
      DemoGroup("Clipboard & time zone", <Widget>[
        Fn('UClipboard.set("copied!", snackBar: true)', () => UClipboard.set("copied!", snackBar: true)),
        Fn("await UClipboard.getText()", UClipboard.getText),
        Fn("UTimezone.getLocalTimezone()", UTimezone.getLocalTimezone, auto: true),
        Fn("UTimezone.getTimezoneOffset() / offsetText()", () => <Object>[UTimezone.getTimezoneOffset(), UTimezone.offsetText()], auto: true),
      ]),
    ],
  );
}
