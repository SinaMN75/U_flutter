import "package:u/utilities.dart";

/// Thrown when a single field fails to pack or unpack, carrying the field
/// number so a reject can name it.
class IsoFieldException implements Exception {
  IsoFieldException(this.field, this.message, [this.cause]);

  final int field;
  final String message;
  final Object? cause;

  @override
  String toString() => "IsoFieldException(field: $field, $message${cause == null ? "" : ", cause: $cause"})";
}

/// Walks the field table to turn an [IsoMsg] into bytes and back. Ported from
/// `ISOMsgBasePackager`.
abstract class IsoMsgPackager {
  IsoMsgPackager(this.fieldPackagers, {this.thirdBitmapField = _thirdBitmapFieldDefault});

  static const int _thirdBitmapFieldDefault = -999;

  final List<IsoFieldPackager?> fieldPackagers;
  final int thirdBitmapField;

  int get bitmapFieldIndex {
    if (fieldPackagers[0] is IsoBitMapPackager) return 0;
    if (fieldPackagers.length > 1 && fieldPackagers[1] is IsoBitMapPackager) return 1;
    return -1;
  }

  bool get emitsBitmap => bitmapFieldIndex >= 0;

  int get firstField => bitmapFieldIndex < 0 ? 1 : bitmapFieldIndex + 1;

  IsoMsg createComponent() => IsoMsg();

  /// Recalculates the bitmap and packs into a fresh buffer, the same sequence
  /// the Java encoder performs before writing to the channel.
  Uint8List packToBytes(IsoMsg message, {int maxMessageSize = 9999}) {
    message.recalcBitMap();
    final IsoBuffer buffer = IsoBuffer.allocate(maxMessageSize);
    pack(message, buffer);
    return buffer.toBytes();
  }

  IsoMsg unpackFromBytes(Uint8List bytes) {
    final IsoMsg message = createComponent();
    unpack(message, IsoBuffer.wrap(bytes));
    return message;
  }

  void pack(IsoMsg message, IsoBuffer buffer) {
    final Map<int, IsoComponent<Object>> fields = message.children;
    final int first = firstField;

    final IsoComponent<Object>? mti = fields[0];
    if (first > 0 && mti != null && fieldPackagers[0] is! IsoBitMapPackager) fieldPackagers[0]!.pack(mti, buffer);

    IsoBitSet? tertiary;
    if (emitsBitmap) {
      final IsoComponent<Object> bitmapComponent = fields[bitmapFieldIndex]!;
      final IsoBitSet primary = bitmapComponent.value! as IsoBitSet;
      if (thirdBitmapField >= 0 && fieldPackagers[thirdBitmapField] is IsoBitMapPackager) {
        if (primary.length - 1 > 128) {
          tertiary = primary.range(128, 193);
          tertiary.clear(0);
          primary.set(thirdBitmapField);
          primary.clearRange(129, 193);
          final IsoBitMapField tertiaryField = IsoBitMapField(tertiary);
          message.setComponent(thirdBitmapField, tertiaryField);
          fields[thirdBitmapField] = tertiaryField;
          primary.set(65, fields[65] != null);
        } else {
          message.unset(thirdBitmapField);
          primary.clear(thirdBitmapField);
          fields.remove(thirdBitmapField);
        }
      }
      fieldPackagers[bitmapFieldIndex]!.pack(bitmapComponent, buffer);
    }

    final int ceiling = tertiary != null || fieldPackagers.length > 129 ? 192 : 128;
    final int highest = message.maxField < ceiling ? message.maxField : ceiling;
    for (int i = first; i <= highest; i++) {
      final IsoComponent<Object>? component = fields[i];
      if (component == null) continue;
      final IsoFieldPackager? packager = fieldPackagers[i];
      if (packager == null) throw IsoFieldException(i, "null field $i packager");
      try {
        packager.pack(component, buffer);
      } catch (error) {
        throw IsoFieldException(i, "error packing field $i", error);
      }
    }
  }

  void unpack(IsoMsg message, IsoBuffer buffer) {
    if (fieldPackagers[0] != null && fieldPackagers[0] is! IsoBitMapPackager) {
      final IsoComponent<Object> mti = fieldPackagers[0]!.createComponent();
      fieldPackagers[0]!.unpack(mti, buffer);
      message.setComponent(0, mti);
    }

    IsoBitSet? bitmap;
    int bitmapBytes = 0;
    int highest = fieldPackagers.length - 1;

    if (emitsBitmap) {
      final IsoComponent<Object> bitmapComponent = fieldPackagers[bitmapFieldIndex]!.createComponent();
      fieldPackagers[bitmapFieldIndex]!.unpack(bitmapComponent, buffer);
      bitmap = bitmapComponent.value! as IsoBitSet;
      bitmapBytes = bitmap.length - 1 + 63 >> 6 << 3;
      message.setComponent(bitmapFieldIndex, bitmapComponent);
      final int fromBitmap = bitmap.length - 1;
      highest = highest < fromBitmap ? highest : fromBitmap;
    }

    for (int i = firstField; i <= highest; i++) {
      if (bitmap == null && fieldPackagers[i] == null) continue;
      if (highest > 128 && i == 65) continue;
      if (bitmap != null && !bitmap.get(i)) continue;
      final IsoFieldPackager? packager = fieldPackagers[i];
      if (packager == null) throw IsoFieldException(i, "field packager '$i' is null");
      try {
        final IsoComponent<Object> component = packager.createComponent();
        packager.unpack(component, buffer);
        message.setComponent(i, component);

        if (i == thirdBitmapField && fieldPackagers.length > 129 && bitmapBytes == 16 && packager is IsoBitMapPackager) {
          final IsoBitSet tertiary = message.getComponent(thirdBitmapField)!.value! as IsoBitSet;
          highest = 128 + (tertiary.length - 1);
          for (int bit = 1; bit <= 64; bit++) {
            bitmap!.set(bit + 128, tertiary.get(bit));
          }
        }
      } catch (error) {
        if (error is IsoFieldException) rethrow;
        throw IsoFieldException(i, "error unpacking field $i", error);
      }
    }
  }
}
