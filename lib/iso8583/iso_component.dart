import "package:u/utilities.dart";

/// Anything that can sit in an [IsoMsg] field slot: a string field, a binary
/// field, a bitmap, or a nested message.
abstract class IsoComponent<T> {
  T? get value;

  set value(T? newValue);

  String get type;
}

class IsoStringField implements IsoComponent<String> {
  IsoStringField([this.value]);

  @override
  String? value;

  @override
  String get type => "string";

  @override
  String toString() => value ?? "";
}

class IsoBinaryField implements IsoComponent<Uint8List> {
  IsoBinaryField([this.value]);

  @override
  Uint8List? value;

  @override
  String get type => "binary";

  @override
  String toString() {
    final Uint8List? current = value;
    return current == null ? "" : IsoUtil.hexString(current);
  }
}

class IsoBitMapField implements IsoComponent<IsoBitSet> {
  IsoBitMapField([this.value]);

  @override
  IsoBitSet? value;

  @override
  String get type => "bitmap";

  @override
  String toString() => value?.toString() ?? "";
}
