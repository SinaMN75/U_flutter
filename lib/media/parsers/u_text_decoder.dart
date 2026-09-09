import "package:u/utilities.dart";

class UDecodedText {
  const UDecodedText(this.text, this.encoding);

  final String text;
  final String encoding;
}

abstract final class UTextDecoder {
  static const List<String> supported = <String>["utf-8", "utf-16le", "utf-16be", "windows-1256", "windows-1252"];

  static UDecodedText decode(Uint8List bytes, {String? forced}) {
    if (bytes.isEmpty) return const UDecodedText("", "utf-8");
    if (forced != null) return UDecodedText(_decodeAs(bytes, forced.toLowerCase(), _bomLength(bytes)), forced.toLowerCase());

    final int bom = _bomLength(bytes);
    if (bom > 0) {
      final String name = _bomEncoding(bytes);
      return UDecodedText(_decodeAs(bytes, name, bom), name);
    }
    if (_isValidUtf8(bytes)) return UDecodedText(utf8.decode(bytes, allowMalformed: true), "utf-8");
    if (_looksArabic(bytes)) return UDecodedText(Cp1256.decode(bytes), "windows-1256");
    return UDecodedText(latin1.decode(bytes, allowInvalid: true), "windows-1252");
  }

  static int _bomLength(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) return 3;
    if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) return 2;
    if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) return 2;
    return 0;
  }

  static String _bomEncoding(Uint8List b) {
    if (b[0] == 0xEF) return "utf-8";
    return b[0] == 0xFF ? "utf-16le" : "utf-16be";
  }

  static String _decodeAs(Uint8List bytes, String encoding, int skip) {
    final Uint8List body = skip == 0 ? bytes : Uint8List.sublistView(bytes, skip);
    switch (encoding) {
      case "utf-16le":
        return _decodeUtf16(body, true);
      case "utf-16be":
        return _decodeUtf16(body, false);
      case "windows-1256":
      case "cp1256":
        return Cp1256.decode(body);
      case "windows-1252":
      case "latin1":
      case "iso-8859-1":
        return latin1.decode(body, allowInvalid: true);
      default:
        return utf8.decode(body, allowMalformed: true);
    }
  }

  static String _decodeUtf16(Uint8List bytes, bool little) {
    final int count = bytes.length ~/ 2;
    final List<int> units = List<int>.filled(count, 0);
    for (int i = 0; i < count; i++) {
      final int a = bytes[i * 2];
      final int b = bytes[i * 2 + 1];
      units[i] = little ? (b << 8) | a : (a << 8) | b;
    }
    return String.fromCharCodes(units);
  }

  static bool _isValidUtf8(Uint8List b) {
    int i = 0;
    final int limit = b.length < 65536 ? b.length : 65536;
    while (i < limit) {
      final int c = b[i];
      if (c < 0x80) {
        i++;
        continue;
      }
      int extra;
      if (c >= 0xC2 && c <= 0xDF) {
        extra = 1;
      } else if (c >= 0xE0 && c <= 0xEF) {
        extra = 2;
      } else if (c >= 0xF0 && c <= 0xF4) {
        extra = 3;
      } else {
        return false;
      }
      if (i + extra >= limit) return true;
      for (int k = 1; k <= extra; k++) {
        if ((b[i + k] & 0xC0) != 0x80) return false;
      }
      i += extra + 1;
    }
    return true;
  }

  static bool _looksArabic(Uint8List b) {
    int high = 0;
    int arabic = 0;
    final int limit = b.length < 65536 ? b.length : 65536;
    for (int i = 0; i < limit; i++) {
      final int c = b[i];
      if (c < 0x80) continue;
      high++;
      if ((c >= 0xC1 && c <= 0xDA) || (c >= 0xDE && c <= 0xF3) || c == 0x81 || c == 0x8D || c == 0x8E || c == 0x90 || c == 0x98) arabic++;
    }
    return high > 0 && arabic / high > 0.6;
  }
}

abstract final class UBidi {
  static bool isRtl(String text) {
    for (int i = 0; i < text.length; i++) {
      final int c = text.codeUnitAt(i);
      if ((c >= 0x0590 && c <= 0x08FF) || (c >= 0xFB1D && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF)) return true;
      if (c >= 0x0041 && c <= 0x024F) return false;
    }
    return false;
  }

  static TextDirection directionOf(String text) => isRtl(text) ? TextDirection.rtl : TextDirection.ltr;

  static String normalizePersian(String value) => value
      .replaceAll("\u064A", "\u06CC")
      .replaceAll("\u0649", "\u06CC")
      .replaceAll("\u0643", "\u06A9")
      .replaceAll("\u0629", "\u0647")
      .replaceAll(RegExp("[\u064B-\u0652\u0670]"), "")
      .replaceAll("\u200C", " ")
      .replaceAll(RegExp(r"\s+"), " ")
      .trim();
}
