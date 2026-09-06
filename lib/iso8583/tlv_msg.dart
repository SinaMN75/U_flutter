import "package:u/utilities.dart";

/// One tag-length-value item. [value] holds a `String` while the message is
/// being built and a `Uint8List` (or a nested [TlvList]) once packed.
class TlvMsg {
  TlvMsg(this.tag, this.value);

  TlvMsg.bytes(this.tag, Uint8List this.value);

  TlvMsg.text(this.tag, String this.value);

  TlvMsg.number(this.tag, int value) : value = "$value";

  TlvMsg.list(this.tag, TlvList this.value);

  int tag;
  Object? value;
  TlvMsg? parent;

  static String tagString(int tag) => tag.toRadixString(16).toUpperCase();

  static bool isConstructedTag(int tag) => IsoUtil.hex2byte(tag.toRadixString(16))[0] & 0x20 != 0;

  /// BER length bytes for [length].
  static Uint8List encodeLength(int length) {
    if (length == 0) return Uint8List(1);
    final Uint8List minimal = _toByteArray(length);
    if (length < 0x80) return minimal;
    final Uint8List out = minimal[0] > 0 ? IsoUtil.concat(Uint8List(1), minimal) : minimal;
    out[0] = 0x80 | out.length - 1;
    return out;
  }

  /// `BigInteger.toByteArray()` for a non-negative int: minimal big-endian
  /// two's complement, so a leading zero appears when the top bit is set.
  static Uint8List _toByteArray(int value) {
    final List<int> bytes = <int>[];
    int remainder = value;
    while (remainder > 0) {
      bytes.insert(0, remainder & 0xFF);
      remainder >>= 8;
    }
    if (bytes.isEmpty) bytes.add(0);
    if (bytes[0] & 0x80 != 0) bytes.insert(0, 0);
    return Uint8List.fromList(bytes);
  }

  String get completeTagString {
    final TlvMsg? currentParent = parent;
    return currentParent == null ? tagString(tag) : "${currentParent.completeTagString}.${tagString(tag)}";
  }

  TlvList? get asList {
    if (value == null) return null;
    if (value is TlvList) return value! as TlvList;
    throw StateError("value is not a tlv list. tag=${tagString(tag)}");
  }

  Uint8List? get asBytes {
    if (value == null) return null;
    if (value is Uint8List) return value! as Uint8List;
    throw StateError("value is not a byte array. tag=${tagString(tag)}");
  }

  String? get asString {
    if (value == null) return null;
    if (value is String) return value! as String;
    throw StateError("value is not a string. tag=${tagString(tag)}");
  }

  int get asInt {
    if (value is String) return int.parse(value! as String);
    throw StateError("value is not an int. tag=${tagString(tag)}");
  }

  /// Reads a `C`/`+` or `D`/`-` prefixed signed amount.
  num get asSignedNumber {
    if (value is! String) throw StateError("value is not a number. tag=${tagString(tag)}");
    final String raw = value! as String;
    final String sign = raw.substring(0, 1).toUpperCase();
    if (sign == "D" || sign == "-") return -num.parse(raw.substring(1));
    if (sign == "C" || sign == "+") return num.parse(raw.substring(1));
    return num.parse(raw);
  }

  Uint8List toTlv(int capacity) {
    final Uint8List tagBytes = IsoUtil.hex2byte(tag.toRadixString(16));
    final Object? current = value;
    if (current == null) return IsoUtil.concat(tagBytes, encodeLength(0));
    final Uint8List packedValue = current is TlvList ? current.pack(capacity) : current as Uint8List;
    return IsoUtil.concat(IsoUtil.concat(tagBytes, encodeLength(packedValue.length)), packedValue);
  }

  @override
  String toString() => "{tag: ${tagString(tag)}, value: ${value is Uint8List ? IsoUtil.hexString(value! as Uint8List) : value}}";
}
