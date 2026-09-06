import "package:u/utilities.dart";

/// Byte/BCD/hex helpers ported from the Java `ISOUtil`, kept bug-for-bug so the
/// two implementations produce identical bytes.
abstract class IsoUtil {
  static final List<String> _hexStrings = List<String>.generate(256, (int i) => "${_forDigit(i >> 4 & 0x0F)}${_forDigit(i & 0x0F)}".toUpperCase());

  static String _forDigit(int nibble) => nibble < 10 ? String.fromCharCode(0x30 + nibble) : String.fromCharCode(0x61 + nibble - 10);

  /// `Character.digit(c, 16)` — the value of a hex digit, or -1.
  static int digit(int charCode, int radix) {
    int value = -1;
    if (charCode >= 0x30 && charCode <= 0x39) value = charCode - 0x30;
    if (charCode >= 0x61 && charCode <= 0x7A) value = charCode - 0x61 + 10;
    if (charCode >= 0x41 && charCode <= 0x5A) value = charCode - 0x41 + 10;
    return value < radix ? value : -1;
  }

  static String hexString(Uint8List bytes, [int offset = 0, int? length]) {
    final int end = length == null ? bytes.length : offset + length;
    final StringBuffer buffer = StringBuffer();
    for (int i = offset; i < end; i++) {
      buffer.write(_hexStrings[bytes[i] & 0xFF]);
    }
    return buffer.toString();
  }

  static Uint8List hex2byte(String value) {
    if (value.length.isOdd) return hex2byte("0$value");
    final int length = value.length >> 1;
    final Uint8List out = Uint8List(length);
    for (int i = 0; i < length * 2; i++) {
      final int shift = i.isOdd ? 0 : 4;
      out[i >> 1] |= digit(value.codeUnitAt(i), 16) << shift;
    }
    return out;
  }

  static Uint8List str2bcd(String value, bool padLeft, [Uint8List? target, int offset = 0]) {
    final int length = value.length;
    final Uint8List out = target ?? Uint8List(length + 1 >> 1);
    final int start = length.isOdd && padLeft ? 1 : 0;
    for (int i = start; i < length + start; i++) {
      out[offset + (i >> 1)] |= (value.codeUnitAt(i - start) - 0x30) << (i.isOdd ? 0 : 4);
    }
    return out;
  }

  static Uint8List str2hex(String value, bool padLeft, [Uint8List? target, int offset = 0]) {
    final int length = value.length;
    final Uint8List out = target ?? Uint8List(length + 1 >> 1);
    final int start = length.isOdd && padLeft ? 1 : 0;
    for (int i = start; i < length + start; i++) {
      out[offset + (i >> 1)] |= digit(value.codeUnitAt(i - start), 16) << (i.isOdd ? 0 : 4);
    }
    return out;
  }

  static String bcd2str(Uint8List bytes, int offset, int length, bool padLeft) {
    final StringBuffer buffer = StringBuffer();
    final int start = length.isOdd && padLeft ? 1 : 0;
    for (int i = start; i < length + start; i++) {
      final int shift = i.isOdd ? 0 : 4;
      final int nibble = bytes[offset + (i >> 1)] >> shift & 0x0F;
      buffer.write(nibble == 0x0D ? "=" : _forDigit(nibble).toUpperCase());
    }
    return buffer.toString();
  }

  static String hex2str(Uint8List bytes, int offset, int length, bool padLeft) {
    final StringBuffer buffer = StringBuffer();
    final int start = length.isOdd && padLeft ? 1 : 0;
    for (int i = start; i < length + start; i++) {
      final int shift = i.isOdd ? 0 : 4;
      buffer.write(_forDigit(bytes[offset + (i >> 1)] >> shift & 0x0F).toUpperCase());
    }
    return buffer.toString();
  }

  static Uint8List bitSet2byte(IsoBitSet bitSet, [int? bytes]) {
    final int byteCount = bytes ?? (bitSet.length + 62 >> 6 << 6) >> 3;
    final int length = byteCount * 8;
    final Uint8List out = Uint8List(byteCount);
    for (int i = 0; i < length; i++) {
      if (bitSet.get(i + 1)) out[i >> 3] |= 0x80 >> i % 8;
    }
    if (length > 64) out[0] |= 0x80;
    if (length > 128) out[8] |= 0x80;
    return out;
  }

  /// Reads a binary bitmap at the buffer's current position without consuming
  /// it — the packagers advance the position themselves.
  static IsoBitSet byte2BitSet(IsoBuffer buffer, int maxBits) {
    final int offset = buffer.position;
    final bool b1 = (buffer.getAt(offset) & 0x80) == 0x80;
    final bool b65 = buffer.limit > offset + 8 && (buffer.getAt(offset + 8) & 0x80) == 0x80;
    final int length = maxBits > 128 && b1 && b65
        ? 192
        : maxBits > 64 && b1
        ? 128
        : maxBits < 64
        ? maxBits
        : 64;
    final IsoBitSet bitSet = IsoBitSet();
    for (int i = 0; i < length; i++) {
      if (buffer.getAt(offset + (i >> 3)) & (0x80 >> i % 8) > 0) bitSet.set(i + 1);
    }
    return bitSet;
  }

  static IsoBitSet byte2BitSetFromBytes(Uint8List bytes, int offset, int maxBits) {
    final bool b1 = (bytes[offset] & 0x80) == 0x80;
    final bool b65 = bytes.length > offset + 8 && (bytes[offset + 8] & 0x80) == 0x80;
    final int length = maxBits > 128 && b1 && b65
        ? 192
        : maxBits > 64 && b1
        ? 128
        : maxBits < 64
        ? maxBits
        : 64;
    final IsoBitSet bitSet = IsoBitSet();
    for (int i = 0; i < length; i++) {
      if (bytes[offset + (i >> 3)] & (0x80 >> i % 8) > 0) bitSet.set(i + 1);
    }
    return bitSet;
  }

  /// Reads an ASCII-hex bitmap at the buffer's current position without
  /// consuming it.
  static IsoBitSet hex2BitSet(IsoBuffer buffer, int maxBits) {
    final int offset = buffer.position;
    int length = maxBits > 64 ? ((digit(buffer.getAt(offset), 16) & 0x08) == 8 ? 128 : 64) : maxBits;
    if (length > 64 && maxBits > 128 && buffer.limit > 16 && (digit(buffer.getAt(offset + 16), 16) & 0x08) == 8) length = 192;
    final IsoBitSet bitSet = IsoBitSet();
    for (int i = 0; i < length; i++) {
      final int nibble = digit(buffer.getAt(offset + (i >> 2)), 16);
      if (nibble & (0x08 >> i % 4) > 0) {
        bitSet.set(i + 1);
        if (i == 65 && maxBits > 128) length = 192;
      }
    }
    return bitSet;
  }

  static String padLeft(String value, int length, String pad) {
    final StringBuffer buffer = StringBuffer();
    for (int i = value.length; i < length; i++) {
      buffer.write(pad);
    }
    buffer.write(value);
    return buffer.toString();
  }

  static Uint8List concat(Uint8List first, Uint8List second) {
    final Uint8List out = Uint8List(first.length + second.length);
    out.setRange(0, first.length, first);
    out.setRange(first.length, out.length, second);
    return out;
  }
}
