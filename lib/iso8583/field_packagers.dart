import "package:u/utilities.dart";

// ---------------------------------------------------------------------------
// Bitmaps
// ---------------------------------------------------------------------------

/// Binary bitmap. `IFB_BITMAP` in the Java.
class IfbBitmap extends IsoBitMapPackager {
  IfbBitmap(super.length, super.description);

  @override
  void pack(IsoComponent<Object> component, IsoBuffer buffer) {
    final IsoBitSet bitSet = component.value! as IsoBitSet;
    final int byteCount = length >= 8 ? bitSet.length + 62 >> 6 << 3 : length;
    buffer.putBytes(IsoUtil.bitSet2byte(bitSet, byteCount));
  }

  @override
  void unpack(IsoComponent<Object> component, IsoBuffer buffer) {
    final IsoBitSet bitSet = IsoUtil.byte2BitSet(buffer, length << 3);
    (component as IsoBitMapField).value = bitSet;
    int bits = bitSet.get(1) ? 128 : 64;
    if (length > 16 && bitSet.get(1) && bitSet.get(65)) bits = 192;
    final int consumed = length < bits >> 3 ? length : bits >> 3;
    buffer.position = buffer.position + consumed;
  }
}

/// ASCII-hex bitmap. `IFA_BITMAP` in the Java.
class IfaBitmap extends IsoBitMapPackager {
  IfaBitmap(super.length, super.description);

  @override
  void pack(IsoComponent<Object> component, IsoBuffer buffer) {
    final IsoBitSet bitSet = component.value! as IsoBitSet;
    final int byteCount = length >= 8 ? bitSet.length + 62 >> 6 << 3 : length;
    buffer.putBytes(IsoUtil.hexString(IsoUtil.bitSet2byte(bitSet, byteCount)).codeUnits);
  }

  @override
  void unpack(IsoComponent<Object> component, IsoBuffer buffer) {
    final IsoBitSet bitSet = IsoUtil.hex2BitSet(buffer, length << 3);
    (component as IsoBitMapField).value = bitSet;
    int bits = bitSet.get(1) ? 128 : 64;
    if (length > 16 && bitSet.get(65)) {
      bits = 192;
      bitSet.clear(65);
    }
    final int consumed = length << 1 < bits >> 2 ? length << 1 : bits >> 2;
    buffer.position = buffer.position + consumed;
  }
}

/// Fixed-width ASCII-hex bitmap. `IFHex_BITMAP` in the Java.
class IfHexBitmap extends IsoBitMapPackager {
  IfHexBitmap(super.length, super.description);

  @override
  void pack(IsoComponent<Object> component, IsoBuffer buffer) => buffer.putBytes(IsoUtil.hexString(IsoUtil.bitSet2byte(component.value! as IsoBitSet, length)).codeUnits);

  @override
  void unpack(IsoComponent<Object> component, IsoBuffer buffer) {
    final Uint8List hexChars = buffer.getBytes(length * 2);
    final Uint8List raw = IsoUtil.hex2byte(String.fromCharCodes(hexChars));
    (component as IsoBitMapField).value = IsoUtil.byte2BitSetFromBytes(raw, 0, length << 3);
  }
}

// ---------------------------------------------------------------------------
// Fixed-length fields
// ---------------------------------------------------------------------------

/// Fixed-length characters, space padded on the right, truncating. `IF_CHAR`.
class IfChar extends IsoStringFieldPackager {
  IfChar(super.length, super.description) : super(padder: RightTruncatingPadder.spacePadder, interpreter: AsciiInterpreter.instance);
}

/// A field that occupies no bytes. `IF_NOP`.
class IfNop extends IsoStringFieldPackager {
  IfNop(super.length, super.description);

  IfNop.dummy() : super(0, "<dummy>");

  @override
  int valueLength(String value) => 0;

  @override
  void pack(IsoComponent<Object> component, IsoBuffer buffer) {}

  @override
  void unpack(IsoComponent<Object> component, IsoBuffer buffer) {}
}

/// Fixed-length ASCII digits, zero padded on the left. `IFA_NUMERIC`.
class IfaNumeric extends IsoStringFieldPackager {
  IfaNumeric(super.length, super.description) : super(padder: LeftPadder.zeroPadder, interpreter: AsciiInterpreter.instance);
}

/// Fixed-length BCD digits, zero padded on the left. `IFB_NUMERIC`.
class IfbNumeric extends IsoStringFieldPackager {
  IfbNumeric(super.length, super.description, {bool leftPadded = true})
    : super(padder: LeftPadder.zeroPadder, interpreter: leftPadded ? BcdInterpreter.leftPaddedInstance : BcdInterpreter.rightPaddedInstance);
}

/// Fixed-length raw binary. `IFB_BINARY`.
class IfbBinary extends IsoBinaryFieldPackager {
  IfbBinary(super.length, super.description) : super(interpreter: LiteralBinaryInterpreter.instance);
}

/// Fixed-length binary written as ASCII hex. `IFA_BINARY`.
class IfaBinary extends IsoBinaryFieldPackager {
  IfaBinary(super.length, super.description) : super(interpreter: AsciiHexInterpreter.instance);
}

// ---------------------------------------------------------------------------
// ASCII length-prefixed fields
// ---------------------------------------------------------------------------

/// `IFA_LCHAR`, `IFA_LLCHAR`, `IFA_LLLCHAR`, `IFA_LLLLCHAR`, `IFA_LLNUM`.
class IfaVarChar extends IsoStringFieldPackager {
  IfaVarChar(super.length, super.description, AsciiPrefixer prefixer, int maxLength) : super(interpreter: AsciiInterpreter.instance, prefixer: prefixer) {
    checkLength(length, maxLength);
  }

  factory IfaVarChar.l(int length, String description) => IfaVarChar(length, description, AsciiPrefixer.l, 9);

  factory IfaVarChar.ll(int length, String description) => IfaVarChar(length, description, AsciiPrefixer.ll, 99);

  factory IfaVarChar.lll(int length, String description) => IfaVarChar(length, description, AsciiPrefixer.lll, 999);

  factory IfaVarChar.llll(int length, String description) => IfaVarChar(length, description, AsciiPrefixer.llll, 999);
}

/// `IFA_LBINARY`, `IFA_LLBINARY`, `IFA_LLLBINARY`, `IFA_LLLLBINARY`.
class IfaVarBinary extends IsoBinaryFieldPackager {
  IfaVarBinary(super.length, super.description, AsciiPrefixer prefixer, int maxLength) : super(interpreter: LiteralBinaryInterpreter.instance, prefixer: prefixer) {
    checkLength(length, maxLength);
  }

  factory IfaVarBinary.l(int length, String description) => IfaVarBinary(length, description, AsciiPrefixer.l, 9);

  factory IfaVarBinary.ll(int length, String description) => IfaVarBinary(length, description, AsciiPrefixer.ll, 99);

  factory IfaVarBinary.lll(int length, String description) => IfaVarBinary(length, description, AsciiPrefixer.lll, 999);

  factory IfaVarBinary.llll(int length, String description) => IfaVarBinary(length, description, AsciiPrefixer.llll, 999);
}

// ---------------------------------------------------------------------------
// BCD length-prefixed fields
// ---------------------------------------------------------------------------

/// `IFB_LLCHAR`, `IFB_LLLCHAR` — BCD length, characters in the host charset.
class IfbVarChar extends IsoStringFieldPackager {
  IfbVarChar(super.length, super.description, BcdPrefixer prefixer, int maxLength) : super(interpreter: AsciiInterpreter.instance, prefixer: prefixer) {
    checkLength(length, maxLength);
  }

  factory IfbVarChar.ll(int length, String description) => IfbVarChar(length, description, BcdPrefixer.ll, 99);

  factory IfbVarChar.lll(int length, String description) => IfbVarChar(length, description, BcdPrefixer.lll, 999);
}

/// `IFB_LLBINARY`, `IFB_LLLBINARY` — BCD length, raw binary value.
class IfbVarBinary extends IsoBinaryFieldPackager {
  IfbVarBinary(super.length, super.description, BcdPrefixer prefixer, int maxLength) : super(interpreter: LiteralBinaryInterpreter.instance, prefixer: prefixer) {
    checkLength(length, maxLength);
  }

  factory IfbVarBinary.ll(int length, String description) => IfbVarBinary(length, description, BcdPrefixer.ll, 99);

  factory IfbVarBinary.lll(int length, String description) => IfbVarBinary(length, description, BcdPrefixer.lll, 999);
}

/// `IFB_LLNUM` — BCD length, BCD digits. The PAN and acquirer-id shape.
class IfbLlnum extends IsoStringFieldPackager {
  IfbLlnum(super.length, super.description, {bool leftPadded = false, bool fPadded = false})
    : super(
        interpreter: leftPadded
            ? BcdInterpreter.leftPaddedInstance
            : fPadded
            ? BcdInterpreter.rightPaddedFInstance
            : BcdInterpreter.rightPaddedInstance,
        prefixer: BcdPrefixer.ll,
      ) {
    checkLength(length, 99);
  }
}

/// `IFB_LLLHCHAR` — two-byte binary length, characters in the host charset.
class IfbLllhChar extends IsoStringFieldPackager {
  IfbLllhChar(super.length, super.description) : super(interpreter: AsciiInterpreter.instance, prefixer: BinaryPrefixer.bb) {
    checkLength(length, 65535);
  }
}
