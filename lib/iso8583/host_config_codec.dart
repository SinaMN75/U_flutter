import "package:u/utilities.dart";

/// Reads an `Apos_android` `hostConfig.json`, whether it is plain JSON or the
/// obfuscated form the app ships: base64, then each byte XORed with
/// `(index % 253) + 4`.
abstract class HostConfigCodec {
  static HostConfig parse(String text) => HostConfig.fromJson(jsonDecode(toJson(text)) as Map<String, dynamic>);

  static String toJson(String text) {
    final String trimmed = text.trim();
    if (trimmed.startsWith("{")) return trimmed;
    final Uint8List bytes = base64Decode(trimmed);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = bytes[i] ^ (i % 253 + 4) & 0xFF;
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}
