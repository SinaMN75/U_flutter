import "package:u/utilities.dart";

/// Packs and unpacks one field of a message. The field table is a
/// heterogeneous list of these, so the interface is deliberately not generic —
/// it mirrors the raw `ISOComponentPackager[]` the Java uses.
abstract class IsoFieldPackager {
  IsoComponent<Object> createComponent();

  void pack(IsoComponent<Object> component, IsoBuffer buffer);

  void unpack(IsoComponent<Object> component, IsoBuffer buffer);

  int get length;

  String get description;
}

/// Shared pack/unpack pipeline: pad, prefix the length, interpret.
abstract class IsoComponentPackagerBase<V extends Object> implements IsoFieldPackager {
  IsoComponentPackagerBase(this._length, this._description, {this.interpreter, this.padder, this.prefixer});

  int _length;
  final String _description;

  IsoInterpreter<V>? interpreter;
  IsoPadder<V>? padder;
  IsoPrefixer? prefixer;

  @override
  int get length => _length;

  set length(int value) => _length = value;

  @override
  String get description => _description;

  int valueLength(V value);

  void checkLength(int value, int maxLength) {
    if (value > maxLength) throw ArgumentError("Length $value too long for $runtimeType");
  }

  @override
  void pack(IsoComponent<Object> component, IsoBuffer buffer) {
    final V? data = component.value as V?;
    if (data == null) throw StateError("field has no value ($_description)");
    if (valueLength(data) > _length) throw ArgumentError("Field length ${valueLength(data)} too long. Max: $_length");
    final IsoPadder<V>? currentPadder = padder;
    final V paddedData = currentPadder == null ? data : currentPadder.pad(data, _length);
    prefixer?.encodeLength(valueLength(paddedData), buffer);
    interpreter!.interpret(paddedData, buffer);
  }

  @override
  void unpack(IsoComponent<Object> component, IsoBuffer buffer) {
    int decoded = -1;
    final IsoPrefixer? currentPrefixer = prefixer;
    if (currentPrefixer != null) decoded = currentPrefixer.decodeLength(buffer);
    if (decoded == -1) {
      decoded = _length;
    } else if (_length > 0 && decoded > _length) {
      throw ArgumentError("Field length $decoded too long. Max: $_length");
    }
    (component as IsoComponent<V>).value = interpreter!.uninterpret(buffer, decoded);
  }
}

class IsoStringFieldPackager extends IsoComponentPackagerBase<String> {
  IsoStringFieldPackager(super.length, super.description, {super.interpreter, super.padder, super.prefixer});

  @override
  IsoComponent<Object> createComponent() => IsoStringField();

  @override
  int valueLength(String value) => value.length;
}

class IsoBinaryFieldPackager extends IsoComponentPackagerBase<Uint8List> {
  IsoBinaryFieldPackager(super.length, super.description, {super.interpreter, super.padder, super.prefixer});

  @override
  IsoComponent<Object> createComponent() => IsoBinaryField();

  @override
  int valueLength(Uint8List value) => value.length;
}

abstract class IsoBitMapPackager extends IsoComponentPackagerBase<IsoBitSet> {
  IsoBitMapPackager(super.length, super.description);

  @override
  IsoComponent<Object> createComponent() => IsoBitMapField();

  @override
  int valueLength(IsoBitSet value) => 0;
}
