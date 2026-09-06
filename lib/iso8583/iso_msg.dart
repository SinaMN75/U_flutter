import "dart:collection";
import "package:u/utilities.dart";

/// An ISO 8583 message: a sorted map of field number to component, plus the
/// link header, trailer and reject code the OSS transport attaches to it.
class IsoMsg implements IsoComponent<IsoMsg> {
  IsoMsg();

  final SplayTreeMap<int, IsoComponent<Object>> fields = SplayTreeMap<int, IsoComponent<Object>>();

  Uint8List? isoHeader;
  Uint8List? trailer;
  Uint8List? rawBuffer;
  int? rejectCode;
  int? captureTime;
  int? responseTime;

  int _maxField = -1;
  bool _dirty = true;
  bool _maxFieldDirty = true;

  @override
  IsoMsg get value => this;

  @override
  set value(IsoMsg? newValue) => throw StateError("setValue is not available on IsoMsg");

  @override
  String get type => "isomsg";

  bool get isReject => rejectCode != null;

  bool get approved => getString(39) == "00";

  int get maxField {
    if (_maxFieldDirty) {
      _maxField = fields.isEmpty ? 0 : fields.keys.reduce((int a, int b) => a > b ? a : b);
      _maxFieldDirty = false;
    }
    return _maxField;
  }

  void setComponent(int field, IsoComponent<Object>? component) {
    if (component != null) {
      fields[field] = component;
      if (field > _maxField) _maxField = field;
      _dirty = true;
    }
  }

  void setString(int field, String? value) => value == null ? unset(field) : setComponent(field, IsoStringField(value));

  void setInt(int field, int? value) => value == null ? unset(field) : setString(field, value.toString());

  void setBytes(int field, Uint8List? value) => value == null ? unset(field) : setComponent(field, IsoBinaryField(value));

  void unset(int field) {
    if (fields.remove(field) != null) {
      _dirty = true;
      _maxFieldDirty = true;
    }
  }

  void unsetAll(List<int> fieldNumbers) {
    for (final int field in fieldNumbers) {
      unset(field);
    }
  }

  /// Rebuilds the bitmap component at [bitmapIndex] from the fields present.
  /// A no-op while the message is unchanged, exactly as in the Java.
  void recalcBitMap([int bitmapIndex = 1]) {
    if (!_dirty || bitmapIndex < 0) return;
    final int highest = maxField < 192 ? maxField : 192;
    final IsoBitSet bitmap = IsoBitSet();
    for (int i = bitmapIndex + 1; i <= highest; i++) {
      if (fields[i] != null) bitmap.set(i);
    }
    setComponent(bitmapIndex, IsoBitMapField(bitmap));
    _dirty = false;
  }

  void markDirty() {
    _dirty = true;
    _maxFieldDirty = true;
  }

  Map<int, IsoComponent<Object>> get children => SplayTreeMap<int, IsoComponent<Object>>.from(fields);

  IsoComponent<Object>? getComponent(int field) => fields[field];

  Object? getValue(int field) => fields[field]?.value;

  bool hasField(int field) => fields[field] != null;

  bool hasFields(List<int> fieldNumbers) => fieldNumbers.every(hasField);

  bool hasAny(List<int> fieldNumbers) => fieldNumbers.any(hasField);

  bool get isNotEmpty => fields.isNotEmpty;

  String? getString(int field) {
    if (!hasField(field)) return null;
    final Object? raw = getValue(field);
    if (raw is String) return raw;
    if (raw is Uint8List) return IsoUtil.hexString(raw);
    return null;
  }

  /// Latin-1 bytes for a string field, matching `ISOUtil.CHARSET`.
  Uint8List? getBytes(int field) {
    if (!hasField(field)) return null;
    final Object? raw = getValue(field);
    if (raw is String) return Uint8List.fromList(raw.codeUnits.map((int unit) => unit & 0xFF).toList());
    if (raw is Uint8List) return raw;
    return null;
  }

  String get mti {
    if (!hasField(0)) throw StateError("MTI not available");
    return getValue(0)! as String;
  }

  void setMti(String value) => setComponent(0, IsoStringField(value));

  bool get isRequest => int.parse(mti[2]) % 2 == 0;

  bool get isResponse => !isRequest;

  bool get isRetransmission => mti[3] == "1";

  void setResponseMti() {
    if (!isRequest) return;
    final String current = mti;
    String suffix = "0";
    switch (current[3]) {
      case "0":
      case "1":
        suffix = "0";
      case "2":
      case "3":
        suffix = "2";
      case "4":
      case "5":
        suffix = "4";
    }
    setComponent(0, IsoStringField("${current.substring(0, 2)}${int.parse(current[2]) + 1}$suffix"));
  }

  void setRetransmissionMti() {
    if (!isRequest) throw StateError("not a request");
    setComponent(0, IsoStringField("${mti.substring(0, 3)}1"));
  }

  void merge(IsoMsg other) {
    for (int i = 0; i <= other.maxField; i++) {
      if (other.hasField(i)) setComponent(i, other.getComponent(i));
    }
  }

  IsoMsg copy() {
    final IsoMsg out = IsoMsg()
      ..isoHeader = isoHeader
      ..trailer = trailer
      ..rejectCode = rejectCode
      ..captureTime = captureTime
      ..responseTime = responseTime;
    fields.forEach((int field, IsoComponent<Object> component) {
      out.fields[field] = component is IsoMsg ? component.copy() : component;
    });
    out.markDirty();
    return out;
  }

  IsoMsg copyFields(List<int> fieldNumbers) {
    final IsoMsg out = IsoMsg();
    for (final int field in fieldNumbers) {
      if (hasField(field)) out.setComponent(field, getComponent(field));
    }
    return out;
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer("{");
    final Uint8List? header = isoHeader;
    if (header != null) buffer.write("\"header\":\"${IsoUtil.hexString(header)}\",");
    if (isReject) buffer.write("\"rejectCode\":\"$rejectCode\",");
    buffer.write("\"fields\":[");
    int index = 0;
    fields.forEach((int field, IsoComponent<Object> component) {
      if (index > 0) buffer.write(",");
      buffer.write("{\"id\":\"$field\",\"type\":\"${component.type}\",\"value\":\"$component\"}");
      index++;
    });
    buffer.write("]}");
    return buffer.toString();
  }
}
