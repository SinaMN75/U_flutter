import "package:u/utilities.dart";

/// Turns a field value into bytes and back. [T] is `String` for character
/// fields and `Uint8List` for binary ones.
abstract class IsoInterpreter<T> {
  void interpret(T data, IsoBuffer buffer);

  T uninterpret(IsoBuffer buffer, int length);
}

/// Characters in the host charset (Windows-1256), one byte per character.
class AsciiInterpreter implements IsoInterpreter<String> {
  const AsciiInterpreter();

  static const AsciiInterpreter instance = AsciiInterpreter();

  @override
  void interpret(String data, IsoBuffer buffer) => buffer.putBytes(Cp1256.encode(data));

  @override
  String uninterpret(IsoBuffer buffer, int length) => Cp1256.decode(buffer.getBytes(length));
}

/// Packed decimal, two digits per byte.
class BcdInterpreter implements IsoInterpreter<String> {
  const BcdInterpreter._(this.leftPadded, this.fPadded);

  static const BcdInterpreter leftPaddedInstance = BcdInterpreter._(true, false);
  static const BcdInterpreter rightPaddedInstance = BcdInterpreter._(false, false);
  static const BcdInterpreter rightPaddedFInstance = BcdInterpreter._(false, true);
  static const BcdInterpreter leftPaddedFInstance = BcdInterpreter._(true, true);

  final bool leftPadded;
  final bool fPadded;

  int packedLength(int dataUnits) => (dataUnits + 1) ~/ 2;

  Uint8List toBytes(String data) {
    final int dataLength = data.length;
    final Uint8List out = Uint8List(packedLength(dataLength));
    IsoUtil.str2bcd(data, leftPadded, out);
    final int paddedSize = dataLength >> 1;
    if (fPadded && dataLength.isOdd) {
      if (leftPadded) {
        out[0] |= 0xF0;
      } else {
        out[paddedSize] |= 0x0F;
      }
    }
    return out;
  }

  @override
  void interpret(String data, IsoBuffer buffer) => buffer.putBytes(toBytes(data));

  @override
  String uninterpret(IsoBuffer buffer, int length) => IsoUtil.bcd2str(buffer.getBytes(packedLength(length)), 0, length, leftPadded);
}

/// Like [BcdInterpreter] but every nibble is a hex digit, so A-F survive.
class HexInterpreter implements IsoInterpreter<String> {
  const HexInterpreter._(this.leftPadded, this.fPadded);

  static const HexInterpreter leftPaddedInstance = HexInterpreter._(true, false);
  static const HexInterpreter rightPaddedInstance = HexInterpreter._(false, false);
  static const HexInterpreter rightPaddedFInstance = HexInterpreter._(false, true);
  static const HexInterpreter leftPaddedFInstance = HexInterpreter._(true, true);

  final bool leftPadded;
  final bool fPadded;

  int packedLength(int dataUnits) => (dataUnits + 1) ~/ 2;

  @override
  void interpret(String data, IsoBuffer buffer) {
    final int dataLength = data.length;
    final Uint8List out = Uint8List(packedLength(dataLength));
    IsoUtil.str2hex(data, leftPadded, out);
    final int paddedSize = dataLength >> 1;
    if (fPadded && dataLength.isOdd) {
      if (leftPadded) {
        out[0] |= 0xF0;
      } else {
        out[paddedSize] |= 0x0F;
      }
    }
    buffer.putBytes(out);
  }

  @override
  String uninterpret(IsoBuffer buffer, int length) => IsoUtil.hex2str(buffer.getBytes(packedLength(length)), 0, length, leftPadded);
}

/// Binary data written as-is.
class LiteralBinaryInterpreter implements IsoInterpreter<Uint8List> {
  const LiteralBinaryInterpreter();

  static const LiteralBinaryInterpreter instance = LiteralBinaryInterpreter();

  @override
  void interpret(Uint8List data, IsoBuffer buffer) => buffer.putBytes(data);

  @override
  Uint8List uninterpret(IsoBuffer buffer, int length) => buffer.getBytes(length);
}

/// Binary data written as two ASCII hex characters per byte.
class AsciiHexInterpreter implements IsoInterpreter<Uint8List> {
  const AsciiHexInterpreter();

  static const AsciiHexInterpreter instance = AsciiHexInterpreter();

  static const List<int> _hexAscii = <int>[0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46];

  @override
  void interpret(Uint8List data, IsoBuffer buffer) {
    for (final int byte in data) {
      buffer.put(_hexAscii[(byte & 0xF0) >> 4]);
      buffer.put(_hexAscii[byte & 0x0F]);
    }
  }

  @override
  Uint8List uninterpret(IsoBuffer buffer, int length) {
    final Uint8List out = Uint8List(length);
    for (int i = 0; i < length * 2; i++) {
      final int shift = i.isOdd ? 0 : 4;
      out[i >> 1] |= IsoUtil.digit(buffer.get(), 16) << shift;
    }
    return out;
  }
}
