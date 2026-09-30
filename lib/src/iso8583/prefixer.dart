import "package:u/utilities.dart";

/// Writes and reads the length that precedes a variable-length field.
abstract class IsoPrefixer {
  int encodeLength(int length, IsoBuffer buffer);

  int decodeLength(IsoBuffer buffer);

  int get packedLength;
}

/// Length as ASCII digits: LL, LLL, LLLL.
class AsciiPrefixer implements IsoPrefixer {
  const AsciiPrefixer(this.digits);

  static const AsciiPrefixer l = AsciiPrefixer(1);
  static const AsciiPrefixer ll = AsciiPrefixer(2);
  static const AsciiPrefixer lll = AsciiPrefixer(3);
  static const AsciiPrefixer llll = AsciiPrefixer(4);

  final int digits;

  @override
  int encodeLength(int length, IsoBuffer buffer) {
    int remainder = length;
    final Uint8List out = Uint8List(digits);
    for (int i = digits - 1; i >= 0; i--) {
      out[i] = remainder % 10 + 0x30;
      remainder ~/= 10;
    }
    if (remainder != 0) throw ArgumentError("invalid len $length. Prefixing digits = $digits");
    buffer.putBytes(out);
    return digits;
  }

  @override
  int decodeLength(IsoBuffer buffer) {
    int length = 0;
    for (int i = 0; i < digits; i++) {
      length = length * 10 + buffer.get() - 0x30;
    }
    return length;
  }

  @override
  int get packedLength => digits;
}

/// Length as packed decimal: two digits per byte.
class BcdPrefixer implements IsoPrefixer {
  const BcdPrefixer(this.digits);

  static const BcdPrefixer l = BcdPrefixer(1);
  static const BcdPrefixer ll = BcdPrefixer(2);
  static const BcdPrefixer lll = BcdPrefixer(3);
  static const BcdPrefixer llll = BcdPrefixer(4);
  static const BcdPrefixer lllll = BcdPrefixer(5);
  static const BcdPrefixer llllll = BcdPrefixer(6);

  final int digits;

  @override
  int encodeLength(int length, IsoBuffer buffer) {
    final int byteCount = packedLength;
    final int start = buffer.position;
    int remainder = length;
    for (int i = byteCount - 1; i >= 0; i--) {
      final int twoDigits = remainder % 100;
      remainder ~/= 100;
      buffer.putAt(start + i, (twoDigits ~/ 10 << 4) + twoDigits % 10);
    }
    buffer.position = start + byteCount;
    return byteCount;
  }

  @override
  int decodeLength(IsoBuffer buffer) {
    int length = 0;
    for (int i = 0; i < (digits + 1) ~/ 2; i++) {
      final int byte = buffer.get();
      length = 100 * length + ((byte & 0xF0) >> 4) * 10 + (byte & 0x0F);
    }
    return length;
  }

  @override
  int get packedLength => digits + 1 >> 1;
}

/// Length as raw big-endian bytes.
class BinaryPrefixer implements IsoPrefixer {
  const BinaryPrefixer(this.bytes);

  static const BinaryPrefixer b = BinaryPrefixer(1);
  static const BinaryPrefixer bb = BinaryPrefixer(2);

  final int bytes;

  @override
  int encodeLength(int length, IsoBuffer buffer) {
    int remainder = length;
    final Uint8List out = Uint8List(bytes);
    for (int i = bytes - 1; i >= 0; i--) {
      out[i] = remainder & 0xFF;
      remainder >>= 8;
    }
    buffer.putBytes(out);
    return bytes;
  }

  @override
  int decodeLength(IsoBuffer buffer) {
    int length = 0;
    for (int i = 0; i < bytes; i++) {
      length = 256 * length + (buffer.get() & 0xFF);
    }
    return length;
  }

  @override
  int get packedLength => bytes;
}
