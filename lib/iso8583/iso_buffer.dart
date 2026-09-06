import "dart:typed_data";

/// A minimal port of `java.nio.ByteBuffer` covering exactly the operations the
/// ISO 8583 packagers rely on, so the Dart codec can mirror the Java one
/// operation for operation.
class IsoBuffer {
  IsoBuffer._(this._bytes, this._position, this._limit);

  factory IsoBuffer.allocate(int capacity) => IsoBuffer._(Uint8List(capacity), 0, capacity);

  factory IsoBuffer.wrap(Uint8List bytes, [int? offset, int? length]) {
    final int start = offset ?? 0;
    final int end = length == null ? bytes.length : start + length;
    return IsoBuffer._(bytes, start, end);
  }

  final Uint8List _bytes;
  int _position;
  int _limit;

  int get position => _position;

  set position(int value) {
    if (value < 0 || value > _limit) throw RangeError("position $value out of bounds (limit $_limit)");
    _position = value;
  }

  int get limit => _limit;

  set limit(int value) {
    if (value < 0 || value > _bytes.length) throw RangeError("limit $value out of bounds (capacity ${_bytes.length})");
    _limit = value;
    if (_position > _limit) _position = _limit;
  }

  int get capacity => _bytes.length;

  int get remaining => _limit - _position;

  bool get hasRemaining => _position < _limit;

  void flip() {
    _limit = _position;
    _position = 0;
  }

  void rewind() {
    _position = 0;
  }

  int get() {
    if (_position >= _limit) throw RangeError("buffer underflow at $_position (limit $_limit)");
    return _bytes[_position++];
  }

  int getAt(int index) {
    if (index < 0 || index >= _bytes.length) throw RangeError("index $index out of bounds");
    return _bytes[index];
  }

  Uint8List getBytes(int length) {
    if (_position + length > _limit) throw RangeError("buffer underflow: need $length, have $remaining");
    final Uint8List out = Uint8List.sublistView(_bytes, _position, _position + length);
    _position += length;
    return Uint8List.fromList(out);
  }

  void put(int byte) {
    if (_position >= _limit) throw RangeError("buffer overflow at $_position (limit $_limit)");
    _bytes[_position++] = byte & 0xFF;
  }

  void putAt(int index, int byte) {
    if (index < 0 || index >= _bytes.length) throw RangeError("index $index out of bounds");
    _bytes[index] = byte & 0xFF;
  }

  void putBytes(List<int> bytes) {
    if (_position + bytes.length > _limit) throw RangeError("buffer overflow: need ${bytes.length}, have $remaining");
    _bytes.setRange(_position, _position + bytes.length, bytes);
    _position += bytes.length;
  }

  /// The bytes between 0 and [position], which is what a packager has written
  /// so far.
  Uint8List toBytes() => Uint8List.fromList(Uint8List.sublistView(_bytes, 0, _position));

  Uint8List get backingArray => _bytes;
}
