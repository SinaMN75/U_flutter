import "package:u/utilities.dart";

/// Encodes and decodes the *value* half of a TLV, once the tag has decided
/// which representation it uses.
abstract class ValuePackager {
  Uint8List pack(Object? value);

  Object unpack(IsoBuffer buffer, int length);
}

/// Characters in the host charset (Windows-1256).
class AsciiValuePackager implements ValuePackager {
  const AsciiValuePackager();

  static const AsciiValuePackager instance = AsciiValuePackager();

  @override
  Uint8List pack(Object? value) => value == null ? Uint8List(0) : Cp1256.encode(value.toString());

  @override
  Object unpack(IsoBuffer buffer, int length) => Cp1256.decode(buffer.getBytes(length));
}

/// Packed decimal, optionally F-padded on the right for odd-length values.
class BcdValuePackager implements ValuePackager {
  const BcdValuePackager._(this.leftPadded, this.fPadded);

  static const BcdValuePackager rightPadF = BcdValuePackager._(false, true);
  static const BcdValuePackager leftPad0 = BcdValuePackager._(true, false);

  final bool leftPadded;
  final bool fPadded;

  int _packedLength(int dataUnits) => (dataUnits + 1) ~/ 2;

  @override
  Uint8List pack(Object? value) {
    if (value == null) return Uint8List(0);
    final String data = value.toString();
    final int dataLength = data.length;
    final Uint8List out = Uint8List(_packedLength(dataLength));
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
  Object unpack(IsoBuffer buffer, int length) {
    final Uint8List bytes = buffer.getBytes(length);
    final String value = IsoUtil.bcd2str(bytes, 0, length * 2, leftPadded);
    return fPadded ? value.replaceAll("F", "") : value;
  }
}

/// Raw bytes, untouched.
class BinaryValuePackager implements ValuePackager {
  const BinaryValuePackager();

  static const BinaryValuePackager instance = BinaryValuePackager();

  @override
  Uint8List pack(Object? value) => value == null ? Uint8List(0) : value as Uint8List;

  @override
  Object unpack(IsoBuffer buffer, int length) => buffer.getBytes(length);
}
